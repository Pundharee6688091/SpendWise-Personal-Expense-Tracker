import 'package:flutter/material.dart';
import 'dart:math';

import '../db/database.dart'; 
import '../db/api.dart';       

// --- UTILITY FUNCTIONS ---

// Utility function to convert a hex string (e.g., RRGGBB) to a Flutter Color.
Color colorFromHex(String hexColor) {
  final hex = hexColor.replaceAll('#', '');
  int colorInt;
  try {
    colorInt = int.parse('FF$hex', radix: 16);
  } catch (e) {
    colorInt = 0xFFCCCCCC; 
  }
  return Color(colorInt);
}

// Utility to convert Color to Hex string for display
String colorToHex(Color color) {
  String hex = color.value.toRadixString(16).toUpperCase();
  if (hex.length > 6) {
    return hex.substring(2);
  }
  return hex;
}

// --- HSL Color Picker Implementation (CustomPainter) ---
// Note: HSLColorPicker and _ColorWheelPainter classes are identical to the ones in edit_category_dialog.dart
// They are duplicated here for the AddCategoryDialog.dart file to be self-contained and runnable.

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


// --- ADD CATEGORY DIALOG WIDGET ---

class AddCategoryDialog extends StatefulWidget {
  final API api;

  const AddCategoryDialog({super.key, required this.api});

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  late TextEditingController _nameController;
  // --- DEFAULT VALUES FOR NEW CATEGORY ---
  TransactionType _selectedType = TransactionType.expense; // Default to Expense
  int _selectedColorValue = Colors.indigo.value;          // Default color
  int _selectedIconCodePoint = Icons.label.codePoint;     // Default icon
  // ----------------------------------------
  
  late TextEditingController _hexController; 
  final RegExp _hexColorPattern = RegExp(r'^[0-9a-fA-F]{6}$');

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
    _nameController = TextEditingController();
    
    // Initialize Hex Controller with default color
    String initialHex = colorToHex(Color(_selectedColorValue));
    _hexController = TextEditingController(text: initialHex);
    
    _hexController.addListener(_updateColorFromHex);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hexController.removeListener(_updateColorFromHex);
    _hexController.dispose();
    super.dispose();
  }
  
  // --- Color Sync Logic (Same as Edit Dialog) ---

  void _updateColorFromHex() {
    final hexInput = _hexController.text.trim();
    if (_hexColorPattern.hasMatch(hexInput)) {
      final newColor = colorFromHex(hexInput);
      if (newColor.value != _selectedColorValue) {
        setState(() {
          _selectedColorValue = newColor.value;
        });
      }
    }
  }

  void _onColorChanged(Color newColor) {
    setState(() {
      _selectedColorValue = newColor.value;
      _hexController.text = colorToHex(newColor);
    });
  }

  // --- API Handlers ---

  Future<void> _createCategory() async {
    if (!_hexColorPattern.hasMatch(_hexController.text.trim()) || _nameController.text.trim().isEmpty) {
      debugPrint("Invalid data provided. Cannot create category.");
      return; 
    }
    
    final newCategory = Category(
      // ID is null for creation
      name: _nameController.text.trim(),
      defaultType: _selectedType,
      colorValue: _selectedColorValue, 
      iconCodePoint: _selectedIconCodePoint,
    );
    
    await widget.api.addCategory(newCategory); // New API call
    
    // Close the dialog and return true to refresh the category list
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }
  
  // --- UI Builder Widgets (Adapted from Edit Dialog) ---

  Widget _buildIconSelector() {
    final Color currentColor = Color(_selectedColorValue);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select Icon", style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          height: 100, 
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
            Expanded(
              child: TextField(
                controller: _hexController,
                maxLength: 6,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  prefixText: '#',
                  hintText: 'e.g., FF5733',
                  errorText: isValidHex || hexInput.isEmpty ? null : 'Requires 6 hex characters',
                  counterText: "", 
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
            initialColor: Color(_selectedColorValue),
            onColorChanged: _onColorChanged, 
          ),
        ),
        const SizedBox(height: 16),
        _buildColorCodeChooser(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add New Category"),
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
            
            // Icon Selector
            _buildIconSelector(),
            const SizedBox(height: 16),
            
            // Color Wheel Chooser
            _buildColorWheel(),
            
            // Icon/Color Preview
            const SizedBox(height: 16),
            Row(
              children: [
                const Text("Preview:", style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(_selectedColorValue).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: Icon(
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
        // Only Cancel and Save buttons
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _createCategory, // Call the new creation handler
          child: const Text("Add Category"),
        ),
      ],
    );
  }
}