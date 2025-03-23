// test/utils/theme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sugar_tracker/utils/theme.dart';

void main() {
  test('AppTheme should have valid theme data', () {
    // Test that the light theme is properly configured
    final theme = AppTheme.lightTheme;

    // Basic theme validity checks
    expect(theme, isA<ThemeData>());
    expect(theme.primaryColor, isNotNull);
    expect(theme.colorScheme, isNotNull);

    // Test specific color constants
    expect(AppTheme.primaryColor, isA<Color>());
    expect(AppTheme.backgroundColor, isA<Color>());
    expect(AppTheme.textPrimary, isA<Color>());
    expect(AppTheme.lowSugar, isA<Color>());
    expect(AppTheme.mediumSugar, isA<Color>());
    expect(AppTheme.highSugar, isA<Color>());
  });
}
