import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/core/constants/app_info.dart';

void main() {
  test('AppInfo.version doit correspondre au pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(r'version:\s+(\S+)').firstMatch(pubspec);
    expect(match, isNotNull, reason: 'Pas de version trouvée dans pubspec.yaml');

    // pubspec version est au format "1.1.0+4", on ne garde que la partie avant le "+"
    final pubspecVersion = match!.group(1)!.split('+').first;

    expect(
      AppInfo.version,
      equals(pubspecVersion),
      reason:
          'AppInfo.version (${AppInfo.version}) != pubspec ($pubspecVersion). '
          'Pense à mettre à jour lib/core/constants/app_info.dart !',
    );
  });
}
