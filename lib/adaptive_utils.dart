import 'package:flutter/material.dart';
import "dart:math";

class AdaptiveUtils {
  final BuildContext context;

  AdaptiveUtils(this.context);

  double get screenWidth => MediaQuery.of(context).size.width;

  double get screenHeight => MediaQuery.of(context).size.height;

  double responsiveFontSize(double baseSize, {double minSize = 12, double maxSize = 40}) {
    const double baselineWidth = 375.0;
    double scaleFactor = screenWidth / baselineWidth;

    // Apply the scaling factor to the base size.
    double responsiveSize = baseSize * scaleFactor;

    return max(minSize, min(responsiveSize, maxSize));
  }

  double widthPercent(double percent) {
    return screenWidth * (percent / 100);
  }

  double heightPercent(double percent) {
    return screenHeight * (percent / 100);
  }
}
