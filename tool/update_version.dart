// Génère lib/core/constants/app_info.dart depuis pubspec.yaml.
// Usage : dart run tool/update_version.dart

import 'dart:io';

void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final match = RegExp(r'version:\s+(\S+)').firstMatch(pubspec);
  if (match == null) {
    stderr.writeln('❌ Pas de version trouvée dans pubspec.yaml');
    exit(1);
  }

  final fullVersion = match.group(1)!;
  final version = fullVersion.split('+').first;

  const output = 'lib/core/constants/app_info.dart';
  File(output).writeAsStringSync(
    "/// Généré par tool/update_version.dart — ne pas modifier à la main.\n"
    "abstract final class AppInfo {\n"
    "  static const String version = '$version';\n"
    "}\n",
  );

  print('✅ app_info.dart → $version');
}
