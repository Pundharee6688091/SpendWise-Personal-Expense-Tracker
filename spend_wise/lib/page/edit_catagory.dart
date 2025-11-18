import 'package:flutter/material.dart';
import 'dart:math';

// CRITICAL IMPORTS ADDED
import '../db/database.dart'; 
import '../db/api.dart';       

// Utility function to convert a hex string (e.g., RRGGBB) to a Flutter Color.
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

// Utility to convert Color to Hex string for display
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
    // Ensure initial color is converted to HSL for math
    _hslColor = HSLColor.fromColor(widget.initialColor);
    _hue = _hslColor.hue;
    _saturation = _hslColor.saturation;
  }
  
  // New method to update internal HSL state from an external Color
  void _updateHslFromExternalColor(Color color) {
    _hslColor = HSLColor.fromColor(color);
    _hue = _hslColor.hue;
    _saturation = _hslColor.saturation;
  }

  // Use didUpdateWidget to catch color changes coming from the Hex Input field
  @override
  void didUpdateWidget(covariant HSLColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialColor.value != widget.initialColor.value) {
      // If the color changed externally (e.g., via hex input), update HSL state
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
    
    // Saturation is distance normalized by the radius, clamped to 1.0
    final newSaturation = (distance / radius).clamp(0.0, 1.0); 

    setState(() {
      _hue = newHue;
      _saturation = newSaturation;
      // Use L=0.5 for the color model to get a middle-brightness color
      _hslColor = HSLColor.fromAHSL(
        1.0, 
        _hue, 
        _saturation, 
        0.5 
      );
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

// CustomPainter FIXED (No changes here, relying on the previous fix)
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
    // 1. Draw the full Hue Ring (Sweep Gradient)
    final List<Color> hueColors = [];
    for (int i = 0; i <= 360; i += 5) {
      // Use full Saturation (1.0) and full Lightness (0.5) for the sweep
      hueColors.add(HSLColor.fromAHSL(1.0, i.toDouble(), 1.0, 0.5).toColor());
    }

    final huePaint = Paint()
      ..shader = SweepGradient(
        colors: hueColors,
        tileMode: TileMode.repeated,
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, huePaint);

    // 2. Draw the Saturation Mask (Radial Gradient: White to Transparent)
    final saturationPaint = Paint()
      ..shader = RadialGradient(
        colors: const [
          Colors.white, // Center (0.0) is pure white
          Color(0x00FFFFFF), // Edge (1.0) is transparent
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..blendMode = BlendMode.screen; 

    canvas.drawCircle(center, radius, saturationPaint);
    
    // 3. Draw the Selector Dot
    final selectedColor = HSLColor.fromAHSL(1.0, selectedHue, selectedSaturation, 0.5).toColor();
    
    final angleRad = selectedHue * pi / 180;
    final selectorRadius = selectedSaturation * radius;
    
    final selectorX = center.dx + selectorRadius * cos(angleRad);
    final selectorY = center.dy + selectorRadius * sin(angleRad);
    final selectorCenter = Offset(selectorX, selectorY);

    // Draw outer ring (border)
    canvas.drawCircle(
      selectorCenter,
      12.0,
      Paint()..color = Colors.black.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 2.0,
    );
    // Draw solid inner dot
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

// --- EditCategoryDialog (The rest of the file remains the same) ---

class EditCategoryDialog extends StatefulWidget {
  final Category category;
  final API api;

  const EditCategoryDialog({super.key, required this.category, required this.api});

  @override
  State<EditCategoryDialog> createState() => _EditCategoryDialogState();
}

class _EditCategoryDialogState extends State<EditCategoryDialog> {
  late TextEditingController _nameController;
  late TransactionType _selectedType;
  late int _selectedColorValue;
  late int _selectedIconCodePoint;
  
  late TextEditingController _hexController; 
  final RegExp _hexColorPattern = RegExp(r'^[0-9a-fA-F]{6}$');

  // List of icons available for selection
  final List<IconData> availableIcons = [
    Icons.fastfood,
    Icons.shopping_cart,
    Icons.receipt_long,
    Icons.directions_car,
    Icons.movie_filter,
    Icons.home,
    Icons.work,
    Icons.fitness_center,
    Icons.school,
    Icons.medical_services,
    Icons.pets,
    Icons.public,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.name);
    _selectedType = widget.category.defaultType;
    _selectedIconCodePoint = widget.category.iconCodePoint;
    
    _selectedColorValue = widget.category.colorValue;
    
    // Initialize Hex Controller
    String initialHex = colorToHex(Color(_selectedColorValue));
    _hexController = TextEditingController(text: initialHex);
    
    // Add listener for real-time updates from text input
    _hexController.addListener(_updateColorFromHex);
  }

  @override
  void dispose() {
    _nameController.dispose();
    // Dispose the hex controller
    _hexController.removeListener(_updateColorFromHex);
    _hexController.dispose();
    super.dispose();
  }
  
  // --- New Logic: Hex Input -> Color Wheel ---
  void _updateColorFromHex() {
    final hexInput = _hexController.text.trim();
    if (_hexColorPattern.hasMatch(hexInput)) {
      final newColor = colorFromHex(hexInput);
      if (newColor.value != _selectedColorValue) {
        // Only update state if the color is valid and actually changed
        setState(() {
          _selectedColorValue = newColor.value;
        });
      }
    }
  }

  // --- Color Wheel -> Hex Input ---
  void _onColorChanged(Color newColor) {
    setState(() {
      _selectedColorValue = newColor.value;
      // Update the hex controller's text when color wheel changes
      _hexController.text = colorToHex(newColor);
    });
  }

  // --- API Handlers ---

  Future<void> _saveChanges() async {
    // Check for a valid hex code before attempting to save
    if (!_hexColorPattern.hasMatch(_hexController.text.trim())) {
      debugPrint("Invalid hex code provided. Cannot save.");
      return; 
    }
    
    final updatedCategory = Category(
      id: widget.category.id,
      name: _nameController.text.trim(),
      defaultType: _selectedType,
      colorValue: _selectedColorValue, 
      iconCodePoint: _selectedIconCodePoint, // Save the selected icon code point
    );
    
    await widget.api.updateCategory(updatedCategory);
    
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _deleteCategory() async {
    if (widget.category.id != null) {
      await widget.api.deleteCategory(widget.category.id!);
    }
    
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  // --- UI Builder: Icon Selector ---

  Widget _buildIconSelector() {
    final Color currentColor = Color(_selectedColorValue);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select Icon", style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          height: 100, // Fixed height for scrollable view
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: availableIcons.map((icon) {
                final isSelected = icon.codePoint == _selectedIconCodePoint;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIconCodePoint = icon.codePoint;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? currentColor.withOpacity(0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? currentColor : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(icon, color: currentColor, size: 24),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorCodeChooser() {
    final hexInput = _hexController.text.trim();
    final isValidHex = _hexColorPattern.hasMatch(hexInput);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Hex Code", style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            // Color Preview
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Color(_selectedColorValue),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.black12),
              ),
            ),
            const SizedBox(width: 10),
            // Hex Input Field (NOW EDITABLE)
            Expanded(
              child: TextField(
                controller: _hexController,
                maxLength: 6,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  prefixText: '#',
                  hintText: 'e.g., FF5733',
                  // Show error if the input does not match the 6-character pattern
                  errorText: isValidHex || hexInput.isEmpty ? null : 'Requires 6 hex characters',
                  counterText: "", // Hide the default counter
                ),
                style: const TextStyle(letterSpacing: 1.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColorWheel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select Category Color", style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Center(
          child: HSLColorPicker(
            // Pass the current color value to the wheel, which ensures it stays synced 
            // even when the color changes via hex input.
            initialColor: Color(_selectedColorValue),
            onColorChanged: _onColorChanged, // Updates _selectedColorValue and _hexController
          ),
        ),
        const SizedBox(height: 16),
        
        // Hex Code Chooser
        _buildColorCodeChooser(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Edit ${widget.category.name}"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name Field
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Category Name"),
            ),
            const SizedBox(height: 16),

            // Type Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Type:", style: TextStyle(fontWeight: FontWeight.w600)),
                DropdownButton<TransactionType>(
                  value: _selectedType,
                  items: TransactionType.values.map((TransactionType type) {
                    return DropdownMenuItem<TransactionType>(
                      value: type,
                      child: Text(type.toString().split('.').last, style: TextStyle(color: type == TransactionType.expense ? Colors.red : Colors.green)),
                    );
                  }).toList(),
                  onChanged: (TransactionType? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedType = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Icon Selector (NEW)
            _buildIconSelector(),
            const SizedBox(height: 16),
            
            // Color Wheel Chooser
            _buildColorWheel(),
            
            // Icon/Color Preview (Moved to the top for better grouping)
            const SizedBox(height: 16),
            Row(
              children: [
                const Text("Icon Preview:", style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(_selectedColorValue).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: Icon(
                    // Use the selected icon code point
                    IconData(_selectedIconCodePoint, fontFamily: 'MaterialIcons'),
                    color: Color(_selectedColorValue),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _deleteCategory,
          child: const Text("Delete", style: TextStyle(color: Colors.red)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _saveChanges,
          child: const Text("Save"),
        ),
      ],
    );
  }
}