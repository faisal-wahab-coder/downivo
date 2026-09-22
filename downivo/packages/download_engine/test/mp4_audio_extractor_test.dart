import 'dart:typed_data';

import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('copies the audio track out of a muxed MP4', () {
    final video = Uint8List.fromList('VIDEO!!!!'.codeUnits);
    final audio = Uint8List.fromList('AUDIO!!!!'.codeUnits);
    final file = _muxedMp4(videoSample: video, audioSample: audio);

    final result = Mp4AudioExtractor.extract(file);
    expect(result, isA<Mp4AudioReady>());
    final bytes = (result as Mp4AudioReady).bytes;
    expect(String.fromCharCodes(bytes), contains('AUDIO!!!!'));
    expect(String.fromCharCodes(bytes), isNot(contains('VIDEO!!!!')));
    expect(_handlerTypes(bytes), ['soun']);
  });

  test('copies audio samples out of a fragmented MP4', () {
    final video = Uint8List.fromList('VIDEO!!!!'.codeUnits);
    final audio = Uint8List.fromList('AUDIO!!!!'.codeUnits);
    final file = _fragmentedMp4(videoSample: video, audioSample: audio);

    final result = Mp4AudioExtractor.extract(file);
    expect(result, isA<Mp4AudioReady>());
    final bytes = (result as Mp4AudioReady).bytes;
    expect(String.fromCharCodes(bytes), contains('AUDIO!!!!'));
    expect(String.fromCharCodes(bytes), isNot(contains('VIDEO!!!!')));
    expect(_handlerTypes(bytes), ['soun']);
  });

  test('leaves an audio-only MP4 unchanged', () {
    final audio = Uint8List.fromList('AUDIO!!!!'.codeUnits);
    final file = _audioOnlyMp4(audio);
    expect(Mp4AudioExtractor.extract(file), isA<Mp4AudioUnchanged>());
  });

  test('fails when the video has no audio track', () {
    final file = _videoOnlyMp4(Uint8List.fromList('VIDEO!!!!'.codeUnits));
    final result = Mp4AudioExtractor.extract(file);
    expect(result, isA<Mp4AudioFailed>());
    expect((result as Mp4AudioFailed).message, contains('no audio'));
  });

  test('leaves non-MP4 bytes unchanged', () {
    final webm = Uint8List.fromList('not an mp4'.codeUnits);
    expect(Mp4AudioExtractor.extract(webm), isA<Mp4AudioUnchanged>());
  });

  test('finds moov that follows a size-0 mdat', () {
    final video = Uint8List.fromList('VIDEO!!!!'.codeUnits);
    final audio = Uint8List.fromList('AUDIO!!!!'.codeUnits);
    final file = _sizeZeroMdatMp4(videoSample: video, audioSample: audio);

    final result = Mp4AudioExtractor.extract(file);
    expect(result, isA<Mp4AudioReady>());
    final bytes = (result as Mp4AudioReady).bytes;
    expect(String.fromCharCodes(bytes), contains('AUDIO!!!!'));
    expect(String.fromCharCodes(bytes), isNot(contains('VIDEO!!!!')));
  });

  test('keeps audio samples that fit when the table runs past the file', () {
    final video = Uint8List.fromList('VIDEO!!!!'.codeUnits);
    final audio = Uint8List.fromList('AUDIO!!!!'.codeUnits);
    final file = _overlongSampleTableMp4(videoSample: video, audioSample: audio);

    final result = Mp4AudioExtractor.extract(file);
    expect(result, isA<Mp4AudioReady>());
    expect(String.fromCharCodes((result as Mp4AudioReady).bytes), contains('AUDIO!!!!'));
  });

  test('extractRead skips the video payload', () async {
    final video = Uint8List(4096);
    final audio = Uint8List.fromList('AUDIO!!!!'.codeUnits);
    final file = _muxedMp4(videoSample: video, audioSample: audio);
    var readTotal = 0;
    final result = await Mp4AudioExtractor.extractRead(
      length: file.length,
      read: (offset, length) async {
        readTotal += length;
        final end = offset + length > file.length ? file.length : offset + length;
        if (offset < 0 || offset >= file.length || length <= 0) {
          return Uint8List(0);
        }
        return Uint8List.sublistView(file, offset, end);
      },
    );
    expect(result, isA<Mp4AudioReady>());
    expect(String.fromCharCodes((result as Mp4AudioReady).bytes), contains('AUDIO!!!!'));
    expect(readTotal, lessThan(file.length));
  });

  test('does not add audio to images or playlists', () {
    const image = DiscoveredResource(
      directUrl: 'https://cdn.example/pic.jpg',
      fileName: 'pic.jpg',
      platform: 'Instagram',
      mimeType: 'image/jpeg',
      kind: DiscoveredResourceKind.image,
    );
    expect(AudioDownloadOption.decorate(image).formats, isEmpty);

    const playlist = DiscoveredResource(
      directUrl: 'https://cdn.example/index.m3u8',
      fileName: 'clip.mp4',
      platform: 'Twitch',
      mimeType: 'video/mp4',
      kind: DiscoveredResourceKind.video,
    );
    expect(AudioDownloadOption.decorate(playlist).offersAudio, isFalse);
  });
}

Uint8List _muxedMp4({
  required Uint8List videoSample,
  required Uint8List audioSample,
}) {
  final ftyp = _box('ftyp', Uint8List.fromList('isom'.codeUnits + _u32(0)));
  final mdat = _box('mdat', _concat([videoSample, audioSample]));
  final audioOffset = ftyp.length + 8 + videoSample.length;
  final moov = _box('moov', _concat([
    _box('mvhd', Uint8List(8)),
    _trak('vide', ftyp.length + 8, videoSample.length),
    _trak('soun', audioOffset, audioSample.length),
  ]));
  return _concat([ftyp, mdat, moov]);
}

Uint8List _sizeZeroMdatMp4({
  required Uint8List videoSample,
  required Uint8List audioSample,
}) {
  final ftyp = _box('ftyp', Uint8List.fromList('isom'.codeUnits + _u32(0)));
  final header = Uint8List(8);
  header.setRange(4, 8, 'mdat'.codeUnits);
  final mdat = _concat([header, videoSample, audioSample]);
  final audioOffset = ftyp.length + 8 + videoSample.length;
  final moov = _box('moov', _concat([
    _box('mvhd', Uint8List(8)),
    _trak('vide', ftyp.length + 8, videoSample.length),
    _trak('soun', audioOffset, audioSample.length),
  ]));
  return _concat([ftyp, mdat, moov]);
}

Uint8List _overlongSampleTableMp4({
  required Uint8List videoSample,
  required Uint8List audioSample,
}) {
  final ftyp = _box('ftyp', Uint8List.fromList('isom'.codeUnits + _u32(0)));
  final mdat = _box('mdat', _concat([videoSample, audioSample]));
  final audioOffset = ftyp.length + 8 + videoSample.length;
  final moov = _box('moov', _concat([
    _box('mvhd', Uint8List(8)),
    _trak('vide', ftyp.length + 8, videoSample.length),
    _trak(
      'soun',
      audioOffset,
      audioSample.length,
      extraSampleSize: 1 << 30,
    ),
  ]));
  return _concat([ftyp, mdat, moov]);
}

Uint8List _fragmentedMp4({
  required Uint8List videoSample,
  required Uint8List audioSample,
}) {
  final ftyp = _box('ftyp', Uint8List.fromList('isom'.codeUnits + _u32(0)));
  final moov = _box('moov', _concat([
    _box('mvhd', Uint8List(8)),
    _box('mvex', Uint8List(8)),
    _emptyTrak('vide', 1),
    _emptyTrak('soun', 2),
  ]));
  final videoTfhd = _tfhd(1);
  final audioTfhd = _tfhd(2);
  const trunLen = 24;
  final moofLen = 8 +
      (8 + videoTfhd.length + trunLen) +
      (8 + audioTfhd.length + trunLen);
  final videoDataOffset = moofLen + 8;
  final audioDataOffset = videoDataOffset + videoSample.length;
  final moof = _box('moof', _concat([
    _box('traf', _concat([videoTfhd, _trun(videoDataOffset, videoSample.length)])),
    _box('traf', _concat([audioTfhd, _trun(audioDataOffset, audioSample.length)])),
  ]));
  final mdat = _box('mdat', _concat([videoSample, audioSample]));
  return _concat([ftyp, moov, moof, mdat]);
}

Uint8List _emptyTrak(String handler, int trackId) {
  final hdlr = Uint8List(12)..setRange(8, 12, handler.codeUnits);
  final tkhd = Uint8List(20);
  _putU32(tkhd, 12, trackId);
  final stsd = handler == 'soun'
      ? Uint8List.fromList('mp4a'.codeUnits)
      : Uint8List.fromList('avc1'.codeUnits);
  return _box('trak', _concat([
    _box('tkhd', tkhd),
    _box('mdia', _concat([
      _box('mdhd', Uint8List(8)),
      _box('hdlr', hdlr),
      _box('minf', _box('stbl', _concat([
        _box('stsd', stsd),
        _box('stts', Uint8List(8)),
        _box('stsc', Uint8List(8)),
        _box('stsz', Uint8List(12)),
        _box('stco', Uint8List(8)),
      ]))),
    ])),
  ]));
}

Uint8List _tfhd(int trackId) {
  final payload = Uint8List(8);
  _putU32(payload, 0, 0x00020000);
  _putU32(payload, 4, trackId);
  return _box('tfhd', payload);
}

Uint8List _trun(int dataOffset, int sampleSize) {
  final payload = Uint8List(16);
  _putU32(payload, 0, 0x201);
  _putU32(payload, 4, 1);
  _putU32(payload, 8, dataOffset);
  _putU32(payload, 12, sampleSize);
  return _box('trun', payload);
}

Uint8List _audioOnlyMp4(Uint8List audioSample) {
  final ftyp = _box('ftyp', Uint8List.fromList('isom'.codeUnits + _u32(0)));
  final mdat = _box('mdat', audioSample);
  final moov = _box('moov', _concat([
    _box('mvhd', Uint8List(8)),
    _trak('soun', ftyp.length + 8, audioSample.length),
  ]));
  return _concat([ftyp, mdat, moov]);
}

Uint8List _videoOnlyMp4(Uint8List videoSample) {
  final ftyp = _box('ftyp', Uint8List.fromList('isom'.codeUnits + _u32(0)));
  final mdat = _box('mdat', videoSample);
  final moov = _box('moov', _concat([
    _box('mvhd', Uint8List(8)),
    _trak('vide', ftyp.length + 8, videoSample.length),
  ]));
  return _concat([ftyp, mdat, moov]);
}

Uint8List _trak(
  String handler,
  int offset,
  int sampleSize, {
  int? extraSampleSize,
}) {
  final hdlr = Uint8List(12)..setRange(8, 12, handler.codeUnits);
  final sampleCount = extraSampleSize == null ? 1 : 2;
  final stsz = Uint8List(12 + sampleCount * 4);
  _putU32(stsz, 8, sampleCount);
  _putU32(stsz, 12, sampleSize);
  if (extraSampleSize != null) _putU32(stsz, 16, extraSampleSize);
  final stsc = Uint8List(20);
  _putU32(stsc, 4, 1);
  _putU32(stsc, 8, 1);
  _putU32(stsc, 12, sampleCount);
  _putU32(stsc, 16, 1);
  final stco = Uint8List(12);
  _putU32(stco, 4, 1);
  _putU32(stco, 8, offset);
  return _box('trak', _concat([
    _box('tkhd', Uint8List(8)),
    _box('mdia', _concat([
      _box('mdhd', Uint8List(8)),
      _box('hdlr', hdlr),
      _box('minf', _box('stbl', _concat([
        _box('stsd', Uint8List(8)),
        _box('stts', Uint8List(8)),
        _box('stsc', stsc),
        _box('stsz', stsz),
        _box('stco', stco),
      ]))),
    ])),
  ]));
}

List<String> _handlerTypes(Uint8List file) {
  final found = <String>[];
  for (var i = 0; i + 12 < file.length; i++) {
    if (String.fromCharCodes(file.sublist(i, i + 4)) != 'hdlr') continue;
    found.add(String.fromCharCodes(file.sublist(i + 12, i + 16)));
  }
  return found;
}

Uint8List _box(String type, Uint8List payload) {
  final out = Uint8List(8 + payload.length);
  _putU32(out, 0, out.length);
  out.setRange(4, 8, type.codeUnits);
  out.setRange(8, out.length, payload);
  return out;
}

Uint8List _concat(List<Uint8List> parts) {
  final builder = BytesBuilder(copy: false);
  for (final part in parts) {
    builder.add(part);
  }
  return builder.toBytes();
}

Uint8List _u32(int value) {
  final bytes = Uint8List(4);
  _putU32(bytes, 0, value);
  return bytes;
}

void _putU32(Uint8List data, int offset, int value) {
  data[offset] = (value >> 24) & 0xff;
  data[offset + 1] = (value >> 16) & 0xff;
  data[offset + 2] = (value >> 8) & 0xff;
  data[offset + 3] = value & 0xff;
}
