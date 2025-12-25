import 'package:flutter/material.dart';
import '../../widgets/unified_profile_card.dart';
import '../../services/auth_service.dart';

/// [Purpose]
/// Displays the Customer's profile information using the [UnifiedProfileCard].
/// Allows navigation to Edit Profile and other account settings.
class CustomerProfileSection extends StatelessWidget {
  final String? customerName;
  final String? customerProfilePic;
  final String? customerPhone;
  final String? customerWhatsapp;
  final String? customerEmail;
  final VoidCallback onEditProfile;
  final VoidCallback onLogout;
  final Function(int) onNavigateToTab;

  const CustomerProfileSection({
    super.key,
    required this.customerName,
    required this.customerProfilePic,
    required this.customerPhone,
    required this.customerWhatsapp,
    required this.customerEmail,
    required this.onEditProfile,
    required this.onLogout,
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    return UnifiedProfileCard(
      name: customerName ?? 'Valued Customer',
      description: 'Member since 2024',
      photoUrl: customerProfilePic,
      onEdit: onEditProfile,
      infoChips: [
        if (customerPhone != null && customerPhone!.isNotEmpty)
           _buildInfoChip(Icons.phone, customerPhone!, Colors.grey[100]!, Colors.grey[600]!, Colors.grey[800]!),
        if (customerWhatsapp != null && customerWhatsapp!.isNotEmpty)
           _buildInfoChip(Icons.chat_bubble, customerWhatsapp!, Colors.green.withOpacity(0.1), Colors.green, Colors.green[700]!),
        if (customerEmail != null)
           _buildInfoChip(Icons.email, customerEmail!, Colors.grey[100]!, Colors.grey[600]!, Colors.grey[800]!),
      ],
      extraContent: Column(
        children: [
          _buildSettingsTile(
            context,
            icon: Icons.tune,
            color: Colors.indigo,
            title: 'Preferences',
            subtitle: 'Style and fit preferences',
            onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preferences coming soon!')));
            },
          ),
          const Divider(),
          _buildSettingsTile(
            context,
            icon: Icons.straighten,
            color: Colors.teal,
            title: 'My Measurements',
            subtitle: 'View and update your body stats',
            onTap: () => onNavigateToTab(3), // Assuming index 3 or 4 is measurements
          ),
          const Divider(),
          _buildSettingsTile(
            context,
            icon: Icons.logout,
            color: Colors.red,
            title: 'Logout',
            textColor: Colors.red,
            onTap: onLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color bg, Color iconColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, {
    required IconData icon, 
    required Color color, 
    required String title, 
    String? subtitle, 
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
