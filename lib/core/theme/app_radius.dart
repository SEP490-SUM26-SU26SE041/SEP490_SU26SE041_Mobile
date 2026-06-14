import 'package:flutter/material.dart';

abstract class AppRadius {
  static const double xs     = 8.0;
  static const double small   = 12.0;
  static const double medium  = 16.0;
  static const double large   = 20.0;
  static const double hero    = 24.0;
  static const double xxl     = 28.0;
  static const double sheet   = 32.0;

  static const BorderRadius cardRadius   = BorderRadius.all(Radius.circular(medium));
  static const BorderRadius chipRadius  = BorderRadius.all(Radius.circular(small));
  static const BorderRadius heroRadius  = BorderRadius.all(Radius.circular(hero));
  static const BorderRadius sheetRadius = BorderRadius.vertical(top: Radius.circular(sheet));
  static const BorderRadius largeRadius = BorderRadius.all(Radius.circular(large));
}
