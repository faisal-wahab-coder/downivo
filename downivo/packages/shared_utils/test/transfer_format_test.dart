import 'package:shared_utils/shared_utils.dart';
import 'package:test/test.dart';

void main() {
  test('formats bytes and speed', () {
    expect(TransferFormat.bytes(1536), '1.5 KB');
    expect(TransferFormat.speed(2048), '2.0 KB/s');
  });

  test('formats eta', () {
    expect(
      TransferFormat.eta(bytesRemaining: 10 * 1024 * 1024, bytesPerSec: 1024 * 1024),
      '10s left',
    );
  });
}
