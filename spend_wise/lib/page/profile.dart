import 'package:flutter/material.dart';
import '../db/api.dart';

class ProfileScreen extends StatelessWidget {
  final API api;

  const ProfileScreen({super.key, required this.api});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context, true), 
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.indigo.shade100,
                    child: Icon(Icons.person, size: 50, color: Colors.indigo.shade700),
                  ),
                  const SizedBox(height: 10),
                  Text('Local SpendWise Tracker', style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold)),
                  Text('Your data is stored locally on this device.', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            _buildSectionTitle(context, 'Data & Backup'),
            _buildSettingsTile(icon: Icons.archive_outlined, title: 'Export Data (CSV)', onTap: () {}),
            _buildSettingsTile(icon: Icons.restore_outlined, title: 'Import Data', onTap: () {}),

            const SizedBox(height: 20),
            
            _buildSectionTitle(context, 'App Settings'),
            _buildSettingsTile(icon: Icons.notifications_none, title: 'Notifications', onTap: () {}),
            _buildSettingsTile(icon: Icons.color_lens_outlined, title: 'Theme (Light/Dark)', onTap: () {}),

            const SizedBox(height: 20),

            _buildSectionTitle(context, 'About'),
            _buildSettingsTile(icon: Icons.info_outline, title: 'App Version 1.0.0', onTap: () {}),

          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 10),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Colors.indigo, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSettingsTile({required IconData icon, required String title, required VoidCallback onTap, Color color = Colors.black87}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}