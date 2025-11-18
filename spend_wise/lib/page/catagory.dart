import 'package:flutter/material.dart';
import '../db/api.dart';
import '../db/database.dart';
import '../page/edit_catagory.dart';
import '../page/add_catagory.dart';

class CategoriesScreen extends StatefulWidget {
  final API api;

  const CategoriesScreen({super.key, required this.api});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {

  late Future<List<Category>> _categoriesFuture;
  TransactionType _selectedType = TransactionType.income;

  @override
  void initState() {
    super.initState();

    _categoriesFuture = widget.api.fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildHeader(),
          _buildContent(),
          _buildBackButton(),
        ],
      ),
    );
  }


  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6A7BFF), Color(0xFF4958C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(60.0),
          bottomRight: Radius.circular(60.0),
        ),
      ),
      child: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 48),
              Text(
                'Category Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Create / View / Edit categories',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: 40.0,
      left: 0.0,
      child: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 180.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            _buildRecentRecipients(),
            const SizedBox(height: 24),
            _buildAllCategories(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentRecipients() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Recipient',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildRecipientItem('Audrey', Icons.person),
                _buildRecipientItem('Arlene', Icons.person_outline),
                _buildAddItem('Add'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientItem(String name, IconData icon) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.grey[200],
          child: Icon(icon, size: 30, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(
          '+123123123',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildAddItem(String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.grey[100],
          child: Icon(Icons.add, size: 30, color: Colors.grey[700]),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(
          '',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildAllCategories() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'All Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildCategoryToggle(),
            const SizedBox(height: 16),
            _buildCategoryGrid(),
            const SizedBox(height: 16),
            _buildAddCategoryButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChoiceChip(
          label: const Text('Expense'),
          selected: _selectedType == TransactionType.expense,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedType = TransactionType.expense;
              });
            }
          },
          selectedColor: const Color(0xFFE8EAF6),
          labelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            color: _selectedType == TransactionType.expense
                ? const Color(0xFF4958C7)
                : Colors.black54,
          ),
        ),
        const SizedBox(width: 12),
        ChoiceChip(
          label: const Text('Income'),
          selected: _selectedType == TransactionType.income,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedType = TransactionType.income;
              });
            }
          },
          selectedColor: const Color(0xFFE8EAF6),
          labelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            color: _selectedType == TransactionType.income
                ? const Color(0xFF4958C7)
                : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid() {
    return FutureBuilder<List<Category>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No categories found.'));
        }

        final allCategories = snapshot.data!;
        final filteredCategories = allCategories
            .where((category) => category.defaultType == _selectedType)
            .toList();

        if (filteredCategories.isEmpty) {
          return Center(child: Text('No $_selectedType categories found.'));
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: filteredCategories.length,
          itemBuilder: (context, index) {
            final category = filteredCategories[index];

            return _buildCategoryItem(category);
          },
        );
      },
    );
  }

  Future<void> _reloadCategories() async {
    setState(() {
      _categoriesFuture = widget.api.fetchCategories();
    });
  }

  Widget _buildCategoryItem(Category category) {
    final Color itemColor = Color(category.colorValue);
    final Color tileBackgroundColor = itemColor.withOpacity(0.15);
    final IconData iconData =
        IconData(category.iconCodePoint, fontFamily: 'MaterialIcons');

    return GestureDetector(
      onTap: () async {
        final result = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return EditCategoryDialog(
              category: category,
              api: widget.api,
            );
          },
        );
        if (result == true) {
          _reloadCategories();
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: tileBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              iconData,
              size: 30,
              color: itemColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category.name,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCategoryButton() {
    return Center(
      child: GestureDetector(
        onTap: _showAddCategoryDialog,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, size: 30, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

      //show the add category pop up
  void _showAddCategoryDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AddCategoryDialog(api: widget.api);
      },
    );

    if (result == true) {
      _reloadCategories();
    }
  }
}
