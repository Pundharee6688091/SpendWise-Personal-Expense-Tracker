import 'package:flutter/material.dart';
import 'dart:math';

// --- UTILITY FUNCTIONS ---

/// Utility function to convert a hex string (e.g., RRGGBB) to a Flutter Color.
Color colorFromHex(String hexColor) {
  final hex = hexColor.replaceAll('#', '');
  int colorInt;
  try {
    // Add the FF alpha component and parse as base 16
    colorInt = int.parse('FF$hex', radix: 16);
  } catch (e) {
    // Return a default error color (e.g., gray) on invalid input
    colorInt = 0xFFCCCCCC; 
  }
  return Color(colorInt);
}

/// Utility to convert Color to Hex string for display (RRGGBB format)
String colorToHex(Color color) {
  // Get the RRGGBB part by removing the 0x and the AA (alpha) prefix
  String hex = color.value.toRadixString(16).toUpperCase();
  if (hex.length > 6) {
    return hex.substring(2);
  }
  return hex;
}

// --- HSL Color Picker Implementation (CustomPainter) ---

class HSLColorPicker extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;
  static const double wheelSize = 250.0; // Fixed size to prevent layout issues

  const HSLColorPicker({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
  });

  @override
  State<HSLColorPicker> createState() => _HSLColorPickerState();
}

class _HSLColorPickerState extends State<HSLColorPicker> {
  late HSLColor _hslColor;
  late double _hue;
  late double _saturation;
  
  final double radius = HSLColorPicker.wheelSize / 2;

  @override
  void initState() {
    super.initState();
    _hslColor = HSLColor.fromColor(widget.initialColor);
    _hue = _hslColor.hue;
    _saturation = _hslColor.saturation;
  }
  
  void _updateHslFromExternalColor(Color color) {
    _hslColor = HSLColor.fromColor(color);
    _hue = _hslColor.hue;
    _saturation = _hslColor.saturation;
  }

  @override
  void didUpdateWidget(covariant HSLColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialColor.value != widget.initialColor.value) {
      _updateHslFromExternalColor(widget.initialColor);
    }
  }

  void _updateColorFromPosition(Offset localPosition) {
    final center = Offset(radius, radius);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;

    final angle = atan2(dy, dx);
    final newHue = (angle * 180 / pi + 360) % 360;

    final distance = sqrt(dx * dx + dy * dy);
    
    final newSaturation = (distance / radius).clamp(0.0, 1.0); 

    setState(() {
      _hue = newHue;
      _saturation = newSaturation;
      _hslColor = HSLColor.fromAHSL(1.0, _hue, _saturation, 0.5);
      widget.onColorChanged(_hslColor.toColor());
    });
  }

  void _handlePanStart(DragStartDetails details) {
    _updateColorFromPosition(details.localPosition);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    _updateColorFromPosition(details.localPosition);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onTapDown: (details) => _updateColorFromPosition(details.localPosition),
      child: CustomPaint(
        size: const Size(HSLColorPicker.wheelSize, HSLColorPicker.wheelSize), 
        painter: _ColorWheelPainter(
          center: Offset(radius, radius),
          radius: radius,
          selectedHue: _hue,
          selectedSaturation: _saturation,
        ),
      ),
    );
  }
}

class _ColorWheelPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final double selectedHue;
  final double selectedSaturation;

  _ColorWheelPainter({
    required this.center,
    required this.radius,
    required this.selectedHue,
    required this.selectedSaturation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final List<Color> hueColors = [];
    for (int i = 0; i <= 360; i += 5) {
      hueColors.add(HSLColor.fromAHSL(1.0, i.toDouble(), 1.0, 0.5).toColor());
    }

    final huePaint = Paint()
      ..shader = SweepGradient(
        colors: hueColors,
        tileMode: TileMode.repeated,
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, huePaint);

    final saturationPaint = Paint()
      ..shader = RadialGradient(
        colors: const [
          Colors.white, 
          Color(0x00FFFFFF),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..blendMode = BlendMode.screen; 

    canvas.drawCircle(center, radius, saturationPaint);
    
    final selectedColor = HSLColor.fromAHSL(1.0, selectedHue, selectedSaturation, 0.5).toColor();
    
    final angleRad = selectedHue * pi / 180;
    final selectorRadius = selectedSaturation * radius;
    
    final selectorX = center.dx + selectorRadius * cos(angleRad);
    final selectorY = center.dy + selectorRadius * sin(angleRad);
    final selectorCenter = Offset(selectorX, selectorY);

    canvas.drawCircle(
      selectorCenter,
      12.0,
      Paint()..color = Colors.black.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 2.0,
    );
    canvas.drawCircle(
      selectorCenter,
      10.0,
      Paint()..color = selectedColor,
    );
  }

  @override
  bool shouldRepaint(covariant _ColorWheelPainter oldDelegate) {
    return oldDelegate.selectedHue != selectedHue || oldDelegate.selectedSaturation != selectedSaturation;
  }
}