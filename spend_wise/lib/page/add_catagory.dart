import 'package:flutter/material.dart';

// color picker widgets
import '../utils/colorPicker.dart'; 

import '../db/database.dart'; 
import '../db/api.dart';       

class AddCategoryDialog extends StatefulWidget {
  final API api;

  const AddCategoryDialog({super.key, required this.api});

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  late TextEditingController _nameController;
  // --- DEFAULT VALUES ---
  TransactionType _selectedType = TransactionType.expense;
  int _selectedColorValue = Colors.indigo.value;
  int _selectedIconCodePoint = Icons.label.codePoint;
  
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
  
  // --- move color picker when the user edit hex value ---
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


  Future<void> _createCategory() async {
    if (!_hexColorPattern.hasMatch(_hexController.text.trim()) || _nameController.text.trim().isEmpty) {
      debugPrint("Invalid data provided. Cannot create category.");
      return; 
    }
    
    final newCategory = Category(
      name: _nameController.text.trim(),
      defaultType: _selectedType,
      colorValue: _selectedColorValue, 
      iconCodePoint: _selectedIconCodePoint,
    );
    
    await widget.api.addCategory(newCategory); // API call
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }


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
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _createCategory,
          child: const Text("Add Category"),
        ),
      ],
    );
  }
}