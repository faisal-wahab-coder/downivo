import 'dart:typed_data';

/// Copies the audio track out of an MP4 into a standalone M4A.
///
/// Stream copy only: sample bytes are moved, not re-encoded. Handles
/// progressive files and fragmented MP4 (moof/trun), which is what TikTok
/// and several other social CDNs return. Already-audio files and non-MP4
/// containers are left unchanged.
class Mp4AudioExtractor {
  const Mp4AudioExtractor._();

  static const _containers = {
    'moov',
    'trak',
    'mdia',
    'minf',
    'stbl',
    'moof',
    'traf',
  };

  static Mp4AudioExtractResult extract(Uint8List bytes) {
    if (bytes.length < 8) return const Mp4AudioUnchanged();
    final boxes = _parse(bytes, 0, bytes.length, recursive: true);
    return _fromBoxes(boxes, bytes.length, (offset, length) {
      if (offset < 0 || length <= 0 || offset >= bytes.length) {
        return Uint8List(0);
      }
      final end = offset + length;
      return Uint8List.sublistView(
        bytes,
        offset,
        end > bytes.length ? bytes.length : end,
      );
    });
  }

  /// Copies audio by reading the index and the audio frames.
  ///
  /// YouTube stores the index after a large video payload. The video bytes
  /// are skipped.
  static Future<Mp4AudioExtractResult> extractRead({
    required int length,
    required Future<Uint8List> Function(int offset, int length) read,
  }) async {
    if (length < 8) return const Mp4AudioUnchanged();
    final index = await _indexFile(length, read);
    if (index.ftyp == null) return const Mp4AudioUnchanged();
    if (index.moov == null) {
      return const Mp4AudioFailed('Could not save audio from this video.');
    }

    if (index.ftyp!.size > _maxIndexRead ||
        index.moov!.size > _maxIndexRead ||
        index.moofs.any((span) => span.size > _maxIndexRead)) {
      return const Mp4AudioFailed('Could not save audio from this video.');
    }
    final ftypBytes = await read(index.ftyp!.offset, index.ftyp!.size);
    final moovBytes = await read(index.moov!.offset, index.moov!.size);
    final boxes = <_Box>[
      ..._parse(ftypBytes, 0, ftypBytes.length, recursive: true),
      ..._parse(moovBytes, 0, moovBytes.length, recursive: true),
    ];
    for (final span in index.moofs) {
      final bytes = await read(span.offset, span.size);
      final parsed = _parse(bytes, 0, bytes.length, recursive: true);
      if (parsed.isEmpty) continue;
      final moof = parsed.first;
      boxes.add(_Box(moof.type, moof.payload, moof.children, span.offset));
    }

    final planned = _plan(boxes, length);
    if (planned is Mp4AudioExtractResult) return planned;
    final plan = planned as _AudioPlan;
    final payload = await _readSamples(plan.samples, read);
    if (payload == null) {
      return const Mp4AudioFailed('Could not save audio from this video.');
    }
    return _package(
      boxes: boxes,
      moov: plan.moov,
      audioTrak: plan.audioTrak,
      samples: plan.samples,
      rewriteTables: plan.rewriteTables,
      payload: payload,
    );
  }

  static Mp4AudioExtractResult _fromBoxes(
    List<_Box> boxes,
    int fileLength,
    Uint8List Function(int offset, int length) copy,
  ) {
    final planned = _plan(boxes, fileLength);
    if (planned is Mp4AudioExtractResult) return planned;
    final plan = planned as _AudioPlan;

    final audioBytes = BytesBuilder(copy: false);
    for (final sample in plan.samples) {
      final piece = copy(sample.offset, sample.size);
      if (piece.length != sample.size) {
        return const Mp4AudioFailed('Could not save audio from this video.');
      }
      audioBytes.add(piece);
    }
    final payload = audioBytes.toBytes();
    if (payload.isEmpty) {
      return const Mp4AudioFailed('This video has no audio track to save.');
    }
    return _package(
      boxes: boxes,
      moov: plan.moov,
      audioTrak: plan.audioTrak,
      samples: plan.samples,
      rewriteTables: plan.rewriteTables,
      payload: payload,
    );
  }

  static Object _plan(List<_Box> boxes, int fileLength) {
    if (_first(boxes, 'ftyp') == null) return const Mp4AudioUnchanged();
    final moov = _first(boxes, 'moov');
    if (moov == null || moov.children == null) {
      return const Mp4AudioFailed('Could not save audio from this video.');
    }

    _Box? audioTrak;
    var hasVideo = false;
    for (final child in moov.children!) {
      if (child.type != 'trak') continue;
      final kind = _trackKind(child);
      if (kind == 'vide') hasVideo = true;
      if (kind == 'soun' && audioTrak == null) audioTrak = child;
    }

    if (audioTrak == null) {
      if (!hasVideo) return const Mp4AudioUnchanged();
      return const Mp4AudioFailed('This video has no audio track to save.');
    }
    if (!hasVideo) return const Mp4AudioUnchanged();

    final progressive = _audioSamples(fileLength, audioTrak);
    final fromFragments = progressive == null || progressive.samples.isEmpty;
    final fragmented = fromFragments
        ? _fragmentSamples(fileLength, boxes, audioTrak)
        : null;
    final samples = fromFragments ? fragmented : progressive.samples;
    if (samples == null || samples.isEmpty) {
      return const Mp4AudioFailed('Could not save audio from this video.');
    }
    return _AudioPlan(
      moov: moov,
      audioTrak: audioTrak,
      samples: samples,
      rewriteTables: fromFragments ? true : progressive.rewriteTables,
    );
  }

  static Mp4AudioExtractResult _package({
    required List<_Box> boxes,
    required _Box moov,
    required _Box audioTrak,
    required List<_Sample> samples,
    required bool rewriteTables,
    required Uint8List payload,
  }) {
    final ftyp = _serialize(_first(boxes, 'ftyp')!);
    final audioStart = ftyp.length + 8;
    final rewritten = _rewriteMoov(
      moov,
      audioTrak,
      audioStart,
      samples,
      rewriteTables: rewriteTables,
    );
    final mdat = _serialize(_leaf('mdat', payload));
    final moovBytes = _serialize(rewritten);

    final out = BytesBuilder(copy: false);
    out.add(ftyp);
    out.add(mdat);
    out.add(moovBytes);
    return Mp4AudioReady(out.toBytes());
  }

  static const _maxIndexRead = 64 * 1024 * 1024;

  static Future<_FileIndex> _indexFile(
    int length,
    Future<Uint8List> Function(int offset, int length) read,
  ) async {
    _Span? ftyp;
    _Span? moov;
    final moofs = <_Span>[];
    var offset = 0;
    while (offset + 8 <= length) {
      final header = await read(offset, length - offset < 16 ? length - offset : 16);
      if (header.length < 8) break;
      final type = String.fromCharCodes(header.sublist(4, 8));
      final sizeField = _u32(header, 0);
      int size;
      if (sizeField == 1) {
        if (header.length < 16) break;
        size = _u64(header, 8);
      } else if (sizeField == 0 &&
          (type == 'mdat' || type == 'free' || type == 'skip')) {
        final next = await _followingBoxRead(offset + 8, length, read);
        size = (next ?? length) - offset;
      } else if (sizeField == 0) {
        size = length - offset;
      } else {
        size = sizeField;
      }
      final headerSize = sizeField == 1 ? 16 : 8;
      if (size < headerSize || offset + size > length) break;
      final span = _Span(offset, size);
      if (type == 'ftyp' && ftyp == null) ftyp = span;
      if (type == 'moov') moov = span;
      if (type == 'moof') moofs.add(span);
      offset += size;
    }
    return _FileIndex(ftyp: ftyp, moov: moov, moofs: moofs);
  }

  static Future<Uint8List?> _readSamples(
    List<_Sample> samples,
    Future<Uint8List> Function(int offset, int length) read,
  ) async {
    final pieces = <Uint8List>[];
    var index = 0;
    while (index < samples.length) {
      final start = samples[index].offset;
      var end = start + samples[index].size;
      var next = index + 1;
      while (next < samples.length && samples[next].offset == end) {
        end += samples[next].size;
        next++;
      }
      final bytes = await read(start, end - start);
      if (bytes.length != end - start) return null;
      var cursor = 0;
      for (var i = index; i < next; i++) {
        final size = samples[i].size;
        pieces.add(Uint8List.sublistView(bytes, cursor, cursor + size));
        cursor += size;
      }
      index = next;
    }
    if (pieces.isEmpty) return null;
    final out = BytesBuilder(copy: false);
    for (final piece in pieces) {
      out.add(piece);
    }
    final payload = out.toBytes();
    return payload.isEmpty ? null : payload;
  }

  static _Box _rewriteMoov(
    _Box moov,
    _Box audioTrak,
    int audioStart,
    List<_Sample> samples, {
    required bool rewriteTables,
  }) {
    final rewrittenTrak = _rewriteTrak(
      audioTrak,
      audioStart,
      samples,
      rewriteTables: rewriteTables,
    );
    final children = <_Box>[];
    var inserted = false;
    for (final child in moov.children!) {
      if (child.type == 'mvex') continue;
      if (child.type == 'trak') {
        if (!inserted && identical(child, audioTrak)) {
          children.add(rewrittenTrak);
          inserted = true;
        }
        continue;
      }
      children.add(child);
    }
    if (!inserted) children.add(rewrittenTrak);
    return _Box('moov', Uint8List(0), children);
  }

  static _Box _rewriteTrak(
    _Box trak,
    int audioStart,
    List<_Sample> samples, {
    required bool rewriteTables,
  }) {
    final count = samples.length;
    return _map(trak, (box) {
      if (rewriteTables && box.type == 'mdhd') {
        return _Box('mdhd', _patchMdhdDuration(box.payload, count * 1024));
      }
      if (box.type != 'stbl' || box.children == null) return box;
      final kept = [
        for (final child in box.children!)
          if (child.type != 'stsc' &&
              child.type != 'stco' &&
              child.type != 'co64' &&
              (!rewriteTables ||
                  (child.type != 'stsz' &&
                      child.type != 'stts' &&
                      child.type != 'ctts' &&
                      child.type != 'stss')))
            child,
      ];
      if (rewriteTables) {
        kept.add(_leaf('stts', _stts(count)));
        kept.add(_leaf('stsz', _stsz(samples)));
      }
      kept.add(_leaf('stsc', _stsc(count)));
      kept.add(_leaf('stco', _stco(audioStart)));
      return _Box('stbl', Uint8List(0), kept);
    });
  }

  static _Box _map(_Box box, _Box Function(_Box box) visit) {
    if (box.children == null) return visit(box);
    final mapped = _Box(
      box.type,
      box.payload,
      [for (final child in box.children!) _map(child, visit)],
      box.start,
    );
    return visit(mapped);
  }

  static ({List<_Sample> samples, bool rewriteTables})? _audioSamples(
    int fileLength,
    _Box trak,
  ) {
    final stbl = _find(trak, 'stbl');
    if (stbl == null) return null;
    final stsz = _first(stbl.children ?? const [], 'stsz')?.payload;
    final stsc = _first(stbl.children ?? const [], 'stsc')?.payload;
    final stco = _first(stbl.children ?? const [], 'stco')?.payload;
    final co64 = _first(stbl.children ?? const [], 'co64')?.payload;
    if (stsz == null || stsc == null) return null;
    List<int>? chunkOffsets;
    if (stco != null) chunkOffsets = _chunkOffsets32(stco);
    if ((chunkOffsets == null || chunkOffsets.isEmpty) && co64 != null) {
      chunkOffsets = _chunkOffsets64(co64);
    }
    if (chunkOffsets == null || chunkOffsets.isEmpty) return null;

    final sizes = _sampleSizes(stsz);
    final samplesPerChunk = _samplesPerChunk(stsc, chunkOffsets.length);
    if (sizes == null || samplesPerChunk == null) return null;

    final samples = <_Sample>[];
    var sampleIndex = 0;
    var rewriteTables = false;
    var stop = false;
    for (var chunk = 0; chunk < chunkOffsets.length && !stop; chunk++) {
      var offset = chunkOffsets[chunk];
      final count = samplesPerChunk[chunk];
      for (var i = 0; i < count; i++) {
        if (sampleIndex >= sizes.length) {
          rewriteTables = true;
          stop = true;
          break;
        }
        final size = sizes[sampleIndex];
        if (size <= 0 || offset < 0 || offset + size > fileLength) {
          rewriteTables = true;
          stop = true;
          break;
        }
        samples.add(_Sample(offset, size));
        offset += size;
        sampleIndex++;
      }
    }
    if (samples.isEmpty) return null;
    if (sampleIndex != sizes.length) rewriteTables = true;
    return (samples: samples, rewriteTables: rewriteTables);
  }

  static List<int>? _sampleSizes(Uint8List payload) {
    if (payload.length < 12) return null;
    final constant = _u32(payload, 4);
    final count = _u32(payload, 8);
    if (count < 0 || count > 16000000) return null;
    if (constant > 0) return List<int>.filled(count, constant);
    if (payload.length < 12 + count * 4) return null;
    return [for (var i = 0; i < count; i++) _u32(payload, 12 + i * 4)];
  }

  static List<int>? _samplesPerChunk(Uint8List payload, int chunkCount) {
    if (payload.length < 8 || chunkCount <= 0 || chunkCount > 16000000) {
      return null;
    }
    final entries = _u32(payload, 4);
    if (entries <= 0 || payload.length < 8 + entries * 12) return null;
    final table = <({int first, int samples})>[];
    for (var i = 0; i < entries; i++) {
      final base = 8 + i * 12;
      table.add((first: _u32(payload, base), samples: _u32(payload, base + 4)));
    }
    table.sort((a, b) => a.first.compareTo(b.first));
    final perChunk = List<int>.filled(chunkCount, table.first.samples);
    for (var chunk = 1; chunk <= chunkCount; chunk++) {
      var samples = table.first.samples;
      for (final entry in table) {
        if (entry.first <= chunk) samples = entry.samples;
      }
      perChunk[chunk - 1] = samples;
    }
    return perChunk;
  }

  static List<int>? _chunkOffsets32(Uint8List payload) {
    if (payload.length < 8) return null;
    final count = _u32(payload, 4);
    if (count < 0 || count > 16000000) return null;
    if (payload.length < 8 + count * 4) return null;
    return [for (var i = 0; i < count; i++) _u32(payload, 8 + i * 4)];
  }

  static List<int>? _chunkOffsets64(Uint8List payload) {
    if (payload.length < 8) return null;
    final count = _u32(payload, 4);
    if (count < 0 || count > 16000000) return null;
    if (payload.length < 8 + count * 8) return null;
    return [for (var i = 0; i < count; i++) _u64(payload, 8 + i * 8)];
  }

  /// Audio samples live in moof/trun when the moov tables are empty.
  static List<_Sample>? _fragmentSamples(
    int fileLength,
    List<_Box> boxes,
    _Box audioTrak,
  ) {
    final trackId = _trackId(audioTrak);
    if (trackId == null) return null;
    final samples = <_Sample>[];
    for (final moof in boxes) {
      if (moof.type != 'moof' || moof.children == null) continue;
      for (final traf in moof.children!) {
        if (traf.type != 'traf' || traf.children == null) continue;
        final tfhdBox = _first(traf.children!, 'tfhd');
        if (tfhdBox == null) continue;
        final header = _parseTfhd(tfhdBox.payload);
        if (header == null || header.trackId != trackId) continue;
        for (final child in traf.children!) {
          if (child.type != 'trun') continue;
          final parsed = _parseTrun(
            child.payload,
            _sampleBase(header, moof),
            header.defaultSampleSize,
          );
          if (parsed == null) return null;
          for (final sample in parsed) {
            if (sample.size <= 0 ||
                sample.offset < 0 ||
                sample.offset + sample.size > fileLength) {
              return null;
            }
            samples.add(sample);
          }
        }
      }
    }
    return samples.isEmpty ? null : samples;
  }

  static int _sampleBase(_Tfhd header, _Box moof) {
    if (header.baseDataOffset != null) return header.baseDataOffset!;
    if (header.defaultBaseIsMoof) return moof.start;
    return 0;
  }

  static _Tfhd? _parseTfhd(Uint8List payload) {
    if (payload.length < 8) return null;
    final flags = _fullBoxFlags(payload);
    final trackId = _u32(payload, 4);
    if (trackId <= 0) return null;
    var cursor = 8;
    int? baseDataOffset;
    int? defaultSampleSize;
    if (_flag(flags, 0x000001)) {
      if (payload.length < cursor + 8) return null;
      baseDataOffset = _u64(payload, cursor);
      cursor += 8;
    }
    if (_flag(flags, 0x000002)) cursor += 4;
    if (_flag(flags, 0x000008)) cursor += 4;
    if (_flag(flags, 0x000010)) {
      if (payload.length < cursor + 4) return null;
      defaultSampleSize = _u32(payload, cursor);
    }
    return _Tfhd(
      trackId: trackId,
      baseDataOffset: baseDataOffset,
      defaultBaseIsMoof: _flag(flags, 0x020000),
      defaultSampleSize: defaultSampleSize,
    );
  }

  static List<_Sample>? _parseTrun(
    Uint8List payload,
    int base,
    int? defaultSampleSize,
  ) {
    if (payload.length < 8) return null;
    final flags = _fullBoxFlags(payload);
    final count = _u32(payload, 4);
    if (count < 0 || count > 16000000) return null;
    if (count == 0) return const [];
    var cursor = 8;
    var dataOffset = 0;
    if (_flag(flags, 0x000001)) {
      if (payload.length < cursor + 4) return null;
      dataOffset = _i32(payload, cursor);
      cursor += 4;
    }
    if (_flag(flags, 0x000004)) cursor += 4;
    final perSample = (_flag(flags, 0x000100) ? 4 : 0) +
        (_flag(flags, 0x000200) ? 4 : 0) +
        (_flag(flags, 0x000400) ? 4 : 0) +
        (_flag(flags, 0x000800) ? 4 : 0);
    if (payload.length < cursor + count * perSample) return null;
    final samples = <_Sample>[];
    var offset = base + dataOffset;
    for (var i = 0; i < count; i++) {
      var size = defaultSampleSize;
      if (_flag(flags, 0x000100)) cursor += 4;
      if (_flag(flags, 0x000200)) {
        size = _u32(payload, cursor);
        cursor += 4;
      }
      if (_flag(flags, 0x000400)) cursor += 4;
      if (_flag(flags, 0x000800)) cursor += 4;
      if (size == null || size < 0) return null;
      samples.add(_Sample(offset, size));
      offset += size;
    }
    return samples;
  }

  static int? _trackId(_Box trak) {
    final tkhd = _find(trak, 'tkhd');
    if (tkhd == null || tkhd.payload.isEmpty) return null;
    final version = tkhd.payload[0];
    final offset = version == 1 ? 20 : 12;
    if (tkhd.payload.length < offset + 4) return null;
    final id = _u32(tkhd.payload, offset);
    return id == 0 ? null : id;
  }

  static String? _handlerType(_Box trak) {
    final hdlr = _find(trak, 'hdlr');
    if (hdlr == null) return null;
    final payload = hdlr.payload;
    for (final offset in [8, 4]) {
      if (payload.length < offset + 4) continue;
      final type = String.fromCharCodes(payload.sublist(offset, offset + 4));
      if (type == 'soun' || type == 'vide') return type;
    }
    return null;
  }

  static String? _trackKind(_Box trak) {
    final handler = _handlerType(trak);
    if (handler == 'soun' || handler == 'vide') return handler;
    final stsd = _find(trak, 'stsd');
    if (stsd == null) return null;
    final bytes = stsd.payload;
    for (var i = 0; i + 4 <= bytes.length; i++) {
      final code = String.fromCharCodes(bytes.sublist(i, i + 4));
      switch (code) {
        case 'mp4a':
        case 'Opus':
        case 'fLaC':
        case 'ac-3':
        case 'ec-3':
          return 'soun';
        case 'avc1':
        case 'avc3':
        case 'hvc1':
        case 'hev1':
        case 'vp09':
        case 'av01':
        case 'mp4v':
          return 'vide';
      }
    }
    return null;
  }

  static _Box? _find(_Box box, String type) {
    if (box.type == type) return box;
    for (final child in box.children ?? const <_Box>[]) {
      final found = _find(child, type);
      if (found != null) return found;
    }
    return null;
  }

  static _Box? _first(List<_Box> boxes, String type) {
    for (final box in boxes) {
      if (box.type == type) return box;
    }
    return null;
  }

  static List<_Box> _parse(
    Uint8List data,
    int start,
    int end, {
    required bool recursive,
  }) {
    final boxes = <_Box>[];
    var offset = start;
    while (offset + 8 <= end) {
      final header = _header(data, offset, end);
      if (header == null) break;
      final payload = Uint8List.sublistView(
        data,
        header.dataStart,
        header.end,
      );
      final nest = recursive && _containers.contains(header.type);
      boxes.add(
        _Box(
          header.type,
          payload,
          nest
              ? _parse(data, header.dataStart, header.end, recursive: true)
              : null,
          offset,
        ),
      );
      if (header.end <= offset) break;
      offset = header.end;
    }
    return boxes;
  }

  static _Header? _header(Uint8List data, int offset, int limit) {
    if (offset + 8 > limit) return null;
    var size = _u32(data, offset);
    var headerSize = 8;
    if (size == 1) {
      if (offset + 16 > limit) return null;
      size = _u64(data, offset + 8);
      headerSize = 16;
    } else if (size == 0) {
      final type = String.fromCharCodes(data.sublist(offset + 4, offset + 8));
      if (type == 'mdat' || type == 'free' || type == 'skip') {
        final next = _followingBox(data, offset + 8, limit, limit, 0);
        size = (next ?? limit) - offset;
      } else {
        size = limit - offset;
      }
    }
    if (size < headerSize) return null;
    final end = offset + size;
    if (end > limit) return null;
    final type = String.fromCharCodes(data.sublist(offset + 4, offset + 8));
    return _Header(type, offset + headerSize, end);
  }

  /// Locates a moov or moof that a size-0 mdat would otherwise swallow.
  static int? _followingBox(
    Uint8List data,
    int from,
    int dataLimit,
    int fileLimit,
    int dataFileOffset,
  ) {
    var i = from;
    final end = dataLimit < data.length ? dataLimit : data.length;
    while (i + 16 <= end) {
      final type = String.fromCharCodes(data.sublist(i + 4, i + 8));
      if (type == 'moov' || type == 'moof') {
        final remaining = fileLimit - (dataFileOffset + i);
        final size = _boxSizeAt(data, i, remaining);
        if (size != null && _childVisible(data, i, type)) return i;
      }
      i++;
    }
    return null;
  }

  static Future<int?> _followingBoxRead(
    int from,
    int limit,
    Future<Uint8List> Function(int offset, int length) read,
  ) async {
    const window = 65536;
    const overlap = 32;
    var pos = from;
    while (pos + 16 <= limit) {
      final n = limit - pos < window ? limit - pos : window;
      final chunk = await read(pos, n);
      if (chunk.length < 16) return null;
      final local = _followingBox(chunk, 0, chunk.length, limit, pos);
      if (local != null) return pos + local;
      if (n <= overlap) break;
      pos += n - overlap;
    }
    return null;
  }

  static int? _boxSizeAt(Uint8List data, int start, int remaining) {
    if (start + 8 > data.length) return null;
    final sizeField = _u32(data, start);
    if (sizeField == 1) {
      if (start + 16 > data.length) return null;
      final size = _u64(data, start + 8);
      if (size < 16 || size > remaining) return null;
      return size;
    }
    if (sizeField == 0) {
      if (remaining < 8) return null;
      return remaining;
    }
    if (sizeField < 8 || sizeField > remaining) return null;
    return sizeField;
  }

  static bool _childVisible(Uint8List data, int start, String type) {
    final header = _u32(data, start) == 1 ? 16 : 8;
    final child = start + header;
    if (child + 8 > data.length) return false;
    final childType = String.fromCharCodes(data.sublist(child + 4, child + 8));
    if (type == 'moov') {
      return childType == 'mvhd' || childType == 'trak' || childType == 'udta';
    }
    return childType == 'mfhd' || childType == 'traf';
  }

  static Uint8List _serialize(_Box box) {
    final body = box.children == null
        ? box.payload
        : _concat([for (final child in box.children!) _serialize(child)]);
    final size = 8 + body.length;
    final out = Uint8List(size);
    _putU32(out, 0, size);
    out.setRange(4, 8, box.type.codeUnits);
    out.setRange(8, size, body);
    return out;
  }

  static _Box _leaf(String type, Uint8List payload) => _Box(type, payload);

  static Uint8List _stts(int sampleCount) {
    final payload = Uint8List(16);
    _putU32(payload, 4, 1);
    _putU32(payload, 8, sampleCount);
    _putU32(payload, 12, 1024);
    return payload;
  }

  static Uint8List _stsz(List<_Sample> samples) {
    final payload = Uint8List(12 + samples.length * 4);
    _putU32(payload, 4, 0);
    _putU32(payload, 8, samples.length);
    for (var i = 0; i < samples.length; i++) {
      _putU32(payload, 12 + i * 4, samples[i].size);
    }
    return payload;
  }

  static Uint8List _patchMdhdDuration(Uint8List payload, int duration) {
    if (payload.length < 20 || payload[0] != 0) return payload;
    final copy = Uint8List.fromList(payload);
    _putU32(copy, 16, duration);
    return copy;
  }

  static int _fullBoxFlags(Uint8List payload) {
    return (payload[1] << 16) | (payload[2] << 8) | payload[3];
  }

  static bool _flag(int flags, int mask) => (flags & mask) != 0;

  static int _i32(Uint8List data, int offset) {
    final value = _u32(data, offset);
    return value >= 0x80000000 ? value - 0x100000000 : value;
  }

  static Uint8List _stsc(int sampleCount) {
    final payload = Uint8List(20);
    _putU32(payload, 4, 1);
    _putU32(payload, 8, 1);
    _putU32(payload, 12, sampleCount);
    _putU32(payload, 16, 1);
    return payload;
  }

  static Uint8List _stco(int offset) {
    final payload = Uint8List(12);
    _putU32(payload, 4, 1);
    _putU32(payload, 8, offset);
    return payload;
  }

  static Uint8List _concat(List<Uint8List> parts) {
    final builder = BytesBuilder(copy: false);
    for (final part in parts) {
      builder.add(part);
    }
    return builder.toBytes();
  }

  static int _u32(Uint8List data, int offset) {
    return (data[offset] << 24) |
        (data[offset + 1] << 16) |
        (data[offset + 2] << 8) |
        data[offset + 3];
  }

  static int _u64(Uint8List data, int offset) {
    var value = 0;
    for (var i = 0; i < 8; i++) {
      value = (value << 8) | data[offset + i];
    }
    return value;
  }

  static void _putU32(Uint8List data, int offset, int value) {
    data[offset] = (value >> 24) & 0xff;
    data[offset + 1] = (value >> 16) & 0xff;
    data[offset + 2] = (value >> 8) & 0xff;
    data[offset + 3] = value & 0xff;
  }
}

class _Box {
  _Box(this.type, this.payload, [this.children, this.start = 0]);

  final String type;
  final Uint8List payload;
  final List<_Box>? children;
  final int start;
}

class _Header {
  const _Header(this.type, this.dataStart, this.end);

  final String type;
  final int dataStart;
  final int end;
}

class _Sample {
  const _Sample(this.offset, this.size);

  final int offset;
  final int size;
}

class _Span {
  const _Span(this.offset, this.size);

  final int offset;
  final int size;
}

class _FileIndex {
  const _FileIndex({this.ftyp, this.moov, this.moofs = const []});

  final _Span? ftyp;
  final _Span? moov;
  final List<_Span> moofs;
}

class _AudioPlan {
  const _AudioPlan({
    required this.moov,
    required this.audioTrak,
    required this.samples,
    required this.rewriteTables,
  });

  final _Box moov;
  final _Box audioTrak;
  final List<_Sample> samples;
  final bool rewriteTables;
}

class _Tfhd {
  const _Tfhd({
    required this.trackId,
    required this.baseDataOffset,
    required this.defaultBaseIsMoof,
    required this.defaultSampleSize,
  });

  final int trackId;
  final int? baseDataOffset;
  final bool defaultBaseIsMoof;
  final int? defaultSampleSize;
}

sealed class Mp4AudioExtractResult {
  const Mp4AudioExtractResult();
}

/// File is not an MP4, or it is already audio-only.
class Mp4AudioUnchanged extends Mp4AudioExtractResult {
  const Mp4AudioUnchanged();
}

class Mp4AudioReady extends Mp4AudioExtractResult {
  const Mp4AudioReady(this.bytes);

  final Uint8List bytes;
}

class Mp4AudioFailed extends Mp4AudioExtractResult {
  const Mp4AudioFailed(this.message);

  final String message;
}
