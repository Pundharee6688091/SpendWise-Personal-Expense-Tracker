import 'package:flutter/material.dart';

// color picker widgets
import '../utils/colorPicker.dart'; 

import '../db/database.dart'; 
import '../db/api.dart';       


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


  Future<void> _saveChanges() async {
    if (!_hexColorPattern.hasMatch(_hexController.text.trim())) {
      debugPrint("Invalid hex code provided. Cannot save.");
      return; 
    }
    
    final updatedCategory = Category(
      id: widget.category.id,
      name: _nameController.text.trim(),
      defaultType: _selectedType,
      colorValue: _selectedColorValue, 
      iconCodePoint: _selectedIconCodePoint,
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

  // --- Icon Selector ---

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
            // Hex Input Field
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