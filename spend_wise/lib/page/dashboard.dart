import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import 'package:intl/intl.dart'; 
import '../db/api.dart';
import '../db/database.dart';

// Callback function definitions
typedef NavigateCallback = void Function(int index);
typedef ShowAddTransactionCallback = void Function();


class DashboardScreen extends StatefulWidget {
  final API api;
  final ValueNotifier<int> refreshTrigger;
  final NavigateCallback onNavigate;
  final ShowAddTransactionCallback onShowAddTransaction;

  const DashboardScreen({
    super.key, 
    required this.api, 
    required this.refreshTrigger,
    required this.onNavigate,
    required this.onShowAddTransaction,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // --- STATE AND INITIALIZATION (Functions/Logic at the Top) ---
  
  // Date range state: default to the start of the current year.
  DateTime _startDate = DateTime(DateTime.now().year, 1, 1);
  DateTime _endDate = DateTime.now();
  String _dateFilter = 'Year'; 

  // Data states
  FinancialSummary _summary = FinancialSummary(totalIncome: 0, totalExpense: 0);
  List<CategorySpending> _topCategories = [];
  
  // This list holds Cashflow data (MonthlyCashflow for 'Year', DailyCashflow for 'Month'/'Day')
  List<MonthlyCashflow> _cashflowData = []; 
  double _maxY = 5000.0; // Max Y-axis value for the chart
  
  // Navigation state (0: Home, 1: Transactions, 3: Categories, 4: Profile)
  int _selectedIndex = 0; 

  @override
  void initState() {
    super.initState();
    widget.refreshTrigger.addListener(_fetchData);
    _fetchData();
  }

  @override
  void dispose() {
    widget.refreshTrigger.removeListener(_fetchData);
    super.dispose();
  }

  /// Handles Bottom Bar tap events
  void _onItemTapped(int index) {
    if (index == 2) { // Index 2 is the Floating Action Button slot
      widget.onShowAddTransaction();
    } else {
      // 0 is Home (stay on Dashboard), others are navigation calls
      if (index != 0) {
        widget.onNavigate(index);
      }
      setState(() {
        _selectedIndex = index;
      });
    }
  }


  /// Calculates the date range based on the selected filter.
  void _calculateDateRange(String filter) {
    final now = DateTime.now();
    DateTime newStartDate;
    DateTime newEndDate;

    if (filter == 'Day') {
      newStartDate = DateTime(now.year, now.month, now.day);
      newEndDate = newStartDate.add(const Duration(hours: 23, minutes: 59));
    } else if (filter == 'Month') {
      newStartDate = DateTime(now.year, now.month, 1);
      newEndDate = DateTime(now.year, now.month + 1, 0).add(const Duration(hours: 23, minutes: 59));
    } else { // 'Year'
      newStartDate = DateTime(now.year, 1, 1);
      newEndDate = DateTime(now.year, 12, 31).add(const Duration(hours: 23, minutes: 59));
    }
    
    _startDate = newStartDate;
    _endDate = newEndDate;
  }

  /// Fetches all data required for the dashboard.
  Future<void> _fetchData() async {
    // 1. Calculate date range for current filter
    _calculateDateRange(_dateFilter);
    // Use DateTime.now() as the current end date for summary/top categories 
    // to avoid including future mock data if the filter is 'Year'
    final currentEndDate = DateTime.now();

    // 2. Fetch Summary & Top Categories (based on current filter's date range, up to today)
    final summary = await widget.api.fetchFinancialSummary(
      startDate: _startDate,
      endDate: currentEndDate,
    );
    
    final topCategories = await widget.api.fetchTopSpendingCategories(
      startDate: _startDate,
      endDate: currentEndDate,
      limit: 5,
    );

    // 3. Fetch Bar Chart Data
    List<MonthlyCashflow> cashflowData;
    
    if (_dateFilter == 'Year') {
      // For Year view, query monthly data for the full year
      cashflowData = await widget.api.fetchMonthlyCashflow(
        startDate: DateTime(currentEndDate.year, 1, 1), 
        endDate: DateTime(currentEndDate.year, 12, 31).add(const Duration(hours: 23, minutes: 59)),
      );
    } else { // 'Month' or 'Day'
      // For Month/Day view, query daily data for the current month
      cashflowData = await widget.api.fetchDailyCashflow(
        startDate: DateTime(currentEndDate.year, currentEndDate.month, 1),
        endDate: DateTime(currentEndDate.year, currentEndDate.month + 1, 0).add(const Duration(hours: 23, minutes: 59)),
      );
    }

    // Determine max Y value for scaling
    double maxIncome = cashflowData.map((m) => m.totalIncome).fold(0.0, max);
    double maxExpense = cashflowData.map((m) => m.totalExpense).fold(0.0, max);
    
    double newMaxY = max(maxIncome, maxExpense) * 1.2;
    
    // --- Y-Axis Scaling ---
    double interval = 1.0; 
    if (_dateFilter == 'Year') {
      interval = 1000.0;
    } else {
      double powerOfTen = pow(10, (newMaxY > 10 ? log(newMaxY) / log(10) : 1.0).floor()).toDouble();
      double factor = newMaxY / powerOfTen; 
      
      // Determine a visually clean interval based on the max value
      if (factor > 5) factor = 10;
      else if (factor > 2) factor = 5;
      else if (factor > 1) factor = 2;
      else factor = 1;

      interval = factor * powerOfTen / 5; 

      // Safely ensure clean intervals for smaller amounts
      if (newMaxY < 100 && interval < 10) interval = 10;
      else if (newMaxY < 20 && interval < 5) interval = 5;
      else if (newMaxY == 0) interval = 100; 
    }
    
    // Recalculate newMaxY based on the clean interval
    newMaxY = (newMaxY / interval).ceil() * interval; 

    if (mounted) {
      setState(() {
        _summary = summary;
        _topCategories = topCategories;
        _cashflowData = cashflowData;
        // Fallback for safety if the interval calculation resulted in a zero or negative max Y.
        _maxY = newMaxY > 0 ? newMaxY : 500.0; 
      });
    }
  }
  
  /// Helper for the Bar Chart: creates a single bar group with two rods (income/expense).
  BarChartGroupData _makeBarGroup(int x, double incomeAmount, double expenseAmount, {double barWidth = 8}) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: incomeAmount, 
          color: Colors.indigo.shade300,
          width: barWidth,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(3), topRight: Radius.circular(3)),
        ),
        BarChartRodData(
          toY: expenseAmount, 
          color: Colors.amber.shade300,
          width: barWidth,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(3), topRight: Radius.circular(3)),
        ),
      ],
    );
  }

  // --- UI BUILD METHODS (Widgets at the Bottom) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildCashflowHeader(),
            const SizedBox(height: 20),
            _buildBarChartContainer(),
            const SizedBox(height: 20),
            _buildIncomeExpenseSummary(),
            const SizedBox(height: 30),
            _buildExpenseInsightSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: widget.onShowAddTransaction,
        backgroundColor: Colors.indigo,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavItem(0, Icons.home_outlined, 'Home'),
            _buildNavItem(1, Icons.list_alt_outlined, 'Transactions'),
            const SizedBox(width: 40), // Spacer for FAB
            _buildNavItem(3, Icons.category_outlined, 'Categories'),
            _buildNavItem(4, Icons.person_outline, 'Profile'),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
      centerTitle: true,
    );
  }
  
  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = index == _selectedIndex;
    
    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                color: isSelected ? Colors.indigo : Colors.grey,
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.indigo : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  


  Widget _buildCashflowHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total Cashflow', style: TextStyle(fontSize: 16, color: Colors.grey)),
              Text(
                '\$${_summary.netBalance.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        // Place the filter controls in the Row's remaining space
        _buildFilterDropdown(),
      ],
    );
  }
  
  Widget _buildBarChartContainer() {
    return AspectRatio(
      aspectRatio: 1.7,
      child: _dateFilter == 'Year' ? _buildYearlyBarChart() : _buildDailyBarChart(),
    );
  }

  Widget _buildYearlyBarChart() {
    // Logic for the full 12-month chart (when filter is 'Year')
    
    // Create a map for quick lookup: {month_index: MonthlyCashflow}
    Map<int, MonthlyCashflow> monthlyMap = {
      for (var data in _cashflowData) data.month - 1: data
    };

    // Generate 12 bar groups, using real data where available, otherwise 0
    List<BarChartGroupData> barGroups = List.generate(12, (i) {
      final data = monthlyMap[i];
      return _makeBarGroup(
        i, // x value is the month index (0-11)
        data?.totalIncome ?? 0.0, 
        data?.totalExpense ?? 0.0,
      );
    });

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _maxY, 
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final month = (value.toInt() % 12) + 1; 
                final monthName = DateFormat('MMM').format(DateTime(DateTime.now().year, month));
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 4,
                  child: Text(monthName, style: const TextStyle(fontSize: 10)),
                );
              },
              interval: 1,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value % 1000 == 0) {
                    return Text('\$${(value / 1000).toInt()}K', style: const TextStyle(fontSize: 10));
                }
                return const Text('');
              },
              interval: 1000,
              reservedSize: 32,
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          horizontalInterval: 1000,
          getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xff374447), strokeWidth: 0.1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups, 
      ),
    );
  }

  Widget _buildDailyBarChart() {
    // Logic for the daily chart (when filter is 'Month' or 'Day')
    
    // Determine the number of days to display (up to the current day for 'Day' filter)
    int daysToDisplay = _dateFilter == 'Day' 
      ? DateTime.now().day // Only show one day if the data filter is set to day
      : DateTime(_endDate.year, _endDate.month + 1, 0).day; // Days in the filtered month

    // Create a map for quick lookup: {day_of_month: DailyCashflow}
    Map<int, MonthlyCashflow> dailyMap = {
      // The 'month' field in MonthlyCashflow model is holding the 'day' number (1-31)
      for (var data in _cashflowData) data.month: data 
    };

    // Determine bar width based on number of bars (smaller bar for monthly view)
    double barWidth = _dateFilter == 'Day' ? 40 : 4; 

    List<BarChartGroupData> barGroups = List.generate(daysToDisplay, (i) {
      final day = i + 1; // 1 to daysToDisplay
      final data = dailyMap[day];
      return _makeBarGroup(
        i, // x value is the index (0 to daysToDisplay-1)
        data?.totalIncome ?? 0.0, 
        data?.totalExpense ?? 0.0,
        barWidth: barWidth,
      );
    });

    // If filter is 'Day', we only show the current day's data
    if (_dateFilter == 'Day') {
       barGroups = barGroups.sublist(barGroups.length - 1);
    }
    
    // --- Y-Axis interval calculation for Daily/Monthly view ---
    // Recalculate Y-axis properties here using _maxY (which was calculated in _fetchData)
    double interval = _maxY / 5; 
    
    if (interval > 1) {
        if (interval < 5) interval = 5;
        else if (interval < 10) interval = 10;
        else if (interval < 25) interval = 25;
        else if (interval < 50) interval = 50;
        else if (interval < 100) interval = 100;
        else interval = (interval / 100).ceil() * 100.0;
    } else {
        interval = 1.0;
    }
    
    // Ensure the Y-axis interval is positive and the max Y is rounded cleanly
    if (interval <= 0 || _maxY <= 0) {
      interval = 100.0;
      _maxY = 500.0;
    }


    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _maxY, 
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                // If filter is 'Day', show today's date
                if (_dateFilter == 'Day') {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 4,
                      child: Text(DateFormat('MMM d').format(DateTime.now()), style: const TextStyle(fontSize: 10)),
                    );
                }
                
                // If filter is 'Month', show day number (1, 5, 10, etc.)
                final day = value.toInt() + 1;
                // Only show day number labels on the 1st, 5th, 10th, 15th, 20th, 25th, and last day
                if (day == 1 || day % 5 == 0 || day == daysToDisplay) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 4,
                    child: Text('$day', style: const TextStyle(fontSize: 10)),
                  );
                }
                return const Text('');
              },
              interval: 1,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                // Show label only at the calculated interval steps
                if (value == 0 || (value % interval) < 1e-6) { // Use a small epsilon for double comparison
                    return Text('\$${value.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10));
                }
                return const Text('');
              },
              // Use the calculated interval here
              interval: interval, 
              reservedSize: 32,
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          // Use the calculated interval for grid lines too
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xff374447), strokeWidth: 0.1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups, 
      ),
    );
  }

  
  Widget _buildFilterDropdown() {
    // Wrapping the DropdownButton in a Container to add a background and border radius
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100, // Light grey background
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<String>(
        value: _dateFilter, 
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.indigo),
        underline: const SizedBox(),
        // Set dropdown color to match the container background
        dropdownColor: Colors.white,
        style: const TextStyle(
            color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 14),
        items: <String>['Day', 'Month', 'Year'].map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value, style: const TextStyle(
              color: Colors.indigo, 
              fontWeight: FontWeight.bold)),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null && mounted) {
            setState(() {
              _dateFilter = newValue;
            });
            _fetchData(); 
          }
        },
      ),
    );
  }
  
  Widget _buildIncomeExpenseSummary() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        _buildSummaryCard(
          title: 'Income',
          amount: _summary.totalIncome,
          // Use Indigo/Blue for Income to match the bar chart
          icon: Icons.arrow_upward,
          color: Colors.indigo.shade400, 
        ),
        _buildSummaryCard(
          title: 'Expense',
          amount: _summary.totalExpense,
          // Use Amber/Yellow for Expense to match the bar chart
          icon: Icons.arrow_downward,
          color: Colors.amber.shade500,
        ),
      ],
    );
  }

  Widget _buildSummaryCard({required String title, required double amount, required IconData icon, required Color color}) {
    // This widget uses helper parameters, but the implementation is self-contained.
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(
                  '\$${amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseInsightSection() {
    final totalExpense = _topCategories.fold(0.0, (sum, item) => sum + item.totalAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Top 5 Expense Categories', style: TextStyle(fontWeight: FontWeight.bold))
          ],
        ),
        const SizedBox(height: 15),
        if (totalExpense > 0) ...[
          _buildPieChart(totalExpense),
          const SizedBox(height: 20),
          
        ] else ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No expense data available for this period.'),
            ),
          )
        ]
      ],
    );
  }
  
  Widget _buildPieChart(double totalExpense) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: PieChart(
        PieChartData(
          sectionsSpace: 0,
          // Increase center space radius for a thinner donut
          centerSpaceRadius: 70, 
          sections: _topCategories.asMap().entries.map((entry) {
            final category = entry.value;
            final percentage = totalExpense > 0
                ? (category.totalAmount / totalExpense) * 100
                : 0.0;
            return PieChartSectionData(
              color: Color(category.colorValue),
              value: category.totalAmount,
              // Show title (category name and percentage)
              title: '${category.categoryName} \n ${percentage.toStringAsFixed(1)}%',
              radius: 60,
              // Position the title further out
              titlePositionPercentageOffset: 1.6, 
              titleStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(category.colorValue), // Set text color to match slice color
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

}