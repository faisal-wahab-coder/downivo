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
    if (_first(boxes, 'ftyp') == null) {
      return const Mp4AudioUnchanged();
    }

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

    final progressive = _audioSamples(bytes, audioTrak);
    final fromFragments = progressive == null || progressive.isEmpty;
    final samples = fromFragments
        ? _fragmentSamples(bytes, boxes, audioTrak)
        : progressive;
    if (samples == null || samples.isEmpty) {
      return const Mp4AudioFailed('Could not save audio from this video.');
    }

    final audioBytes = BytesBuilder(copy: false);
    for (final sample in samples) {
      audioBytes.add(
        bytes.sublist(sample.offset, sample.offset + sample.size),
      );
    }
    final payload = audioBytes.toBytes();
    if (payload.isEmpty) {
      return const Mp4AudioFailed('This video has no audio track to save.');
    }

    final ftyp = _serialize(_first(boxes, 'ftyp')!);
    final audioStart = ftyp.length + 8;
    final rewritten = _rewriteMoov(
      moov,
      audioTrak,
      audioStart,
      samples,
      rewriteTables: fromFragments,
    );
    final mdat = _serialize(_leaf('mdat', payload));
    final moovBytes = _serialize(rewritten);

    final out = BytesBuilder(copy: false);
    out.add(ftyp);
    out.add(mdat);
    out.add(moovBytes);
    return Mp4AudioReady(out.toBytes());
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

  static List<_Sample>? _audioSamples(Uint8List file, _Box trak) {
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
    for (var chunk = 0; chunk < chunkOffsets.length; chunk++) {
      var offset = chunkOffsets[chunk];
      final count = samplesPerChunk[chunk];
      for (var i = 0; i < count; i++) {
        if (sampleIndex >= sizes.length) return null;
        final size = sizes[sampleIndex];
        if (size < 0 || offset < 0 || offset + size > file.length) return null;
        samples.add(_Sample(offset, size));
        offset += size;
        sampleIndex++;
      }
    }
    if (sampleIndex != sizes.length) return null;
    return samples;
  }

  static List<int>? _sampleSizes(Uint8List payload) {
    if (payload.length < 12) return null;
    final constant = _u32(payload, 4);
    final count = _u32(payload, 8);
    if (count < 0) return null;
    if (constant > 0) return List<int>.filled(count, constant);
    if (payload.length < 12 + count * 4) return null;
    return [for (var i = 0; i < count; i++) _u32(payload, 12 + i * 4)];
  }

  static List<int>? _samplesPerChunk(Uint8List payload, int chunkCount) {
    if (payload.length < 8) return null;
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
    if (payload.length < 8 + count * 4) return null;
    return [for (var i = 0; i < count; i++) _u32(payload, 8 + i * 4)];
  }

  static List<int>? _chunkOffsets64(Uint8List payload) {
    if (payload.length < 8) return null;
    final count = _u32(payload, 4);
    if (payload.length < 8 + count * 8) return null;
    return [for (var i = 0; i < count; i++) _u64(payload, 8 + i * 8)];
  }

  /// Audio samples live in moof/trun when the moov tables are empty.
  static List<_Sample>? _fragmentSamples(
    Uint8List file,
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
            if (sample.size < 0 ||
                sample.offset < 0 ||
                sample.offset + sample.size > file.length) {
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
    if (count < 0) return null;
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
      size = limit - offset;
    }
    if (size < headerSize) return null;
    final end = offset + size;
    if (end > limit) return null;
    final type = String.fromCharCodes(data.sublist(offset + 4, offset + 8));
    return _Header(type, offset + headerSize, end);
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
