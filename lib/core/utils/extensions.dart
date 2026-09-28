import 'package:flutter/material.dart';

/// Extension on [BuildContext] for convenient access to theme and media query.
extension BuildContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  EdgeInsets get padding => MediaQuery.of(this).padding;
}

/// Extension on [String] for common string operations.
extension StringExtensions on String {
  /// Capitalizes the first letter of the string.
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Returns true if the string is null or empty.
  bool get isNullOrEmpty => isEmpty;

  /// Returns true if the string is not null and not empty.
  bool get isNotNullOrEmpty => isNotEmpty;
}
