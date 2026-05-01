/// API origin – override at build time with:
///   flutter run --dart-define=API_ORIGIN=http://192.168.1.x:8000
///
/// Default: 10.0.2.2 maps to host-machine localhost on the Android emulator.
/// For a physical device on the same Wi-Fi, replace with the machine's LAN IP.
const String kApiOrigin = String.fromEnvironment(
  'API_ORIGIN',
  defaultValue: 'http://10.0.2.2:8000',
);

const String _kApiPrefix = '/api/v1/';

String buildApiUrl(String path) {
  final clean = path.startsWith('/') ? path.substring(1) : path;
  return '$kApiOrigin$_kApiPrefix$clean';
}
