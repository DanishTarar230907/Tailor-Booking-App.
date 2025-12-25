import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/tailor.dart';
import '../unified_profile_card.dart';

class CustomerTailorInfoTab extends StatelessWidget {
  final Tailor? tailor;

  const CustomerTailorInfoTab({super.key, required this.tailor});

  @override
  Widget build(BuildContext context) {
    if (tailor == null) {
      return Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(40),
        child: const Center(
          child: Text('Tailor information not available yet.'),
        ),
      );
    }

    return UnifiedProfileCard(
      name: tailor!.name,
      description: tailor!.description,
      photoUrl: tailor!.photo,
      infoChips: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1f455b).withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.access_time, size: 16, color: Color(0xFF1f455b)),
              const SizedBox(width: 8),
              Text(
                tailor!.shopHours ?? 'Mon-Sat: 9 AM - 7 PM',
                style: const TextStyle(
                  color: Color(0xFF1f455b),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
      quickActions: [
        ProfileQuickAction(
          icon: Icons.chat_bubble_outline,
          label: 'WhatsApp',
          color: const Color(0xFF25D366),
          onTap: () async {
            if (tailor!.whatsapp != null && tailor!.whatsapp!.isNotEmpty) {
              final clean = tailor!.whatsapp!.replaceAll(RegExp(r'[^0-9]'), '');
              final url = Uri.parse('https://wa.me/$clean');
              if (await canLaunchUrl(url)) launchUrl(url);
            }
          },
        ),
        ProfileQuickAction(
          icon: Icons.phone_outlined,
          label: 'Call',
          color: const Color(0xFF1f455b),
          onTap: () async {
            if (tailor!.phone != null && tailor!.phone!.isNotEmpty) {
              final url = Uri.parse('tel:${tailor!.phone}');
              if (await canLaunchUrl(url)) launchUrl(url);
            }
          },
        ),
        ProfileQuickAction(
          icon: Icons.mail_outline,
          label: 'Email',
          color: Colors.blueAccent,
          onTap: () async {
            if (tailor!.email != null && tailor!.email!.isNotEmpty) {
              final url = Uri.parse('mailto:${tailor!.email}');
              if (await canLaunchUrl(url)) launchUrl(url);
            }
          },
        ),
        ProfileQuickAction(
          icon: Icons.location_on_outlined,
          label: 'Map',
          color: Colors.redAccent,
          onTap: () async {
            if (tailor!.location != null && tailor!.location!.isNotEmpty) {
              final query = Uri.encodeComponent(tailor!.location!);
              final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
              if (await canLaunchUrl(url)) launchUrl(url, mode: LaunchMode.externalApplication);
            }
          },
        ),
      ],
    );
  }
}
