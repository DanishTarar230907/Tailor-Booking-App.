import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    const address = "Grace Tailor Shop, Pindi Saidpur, District Jhelum, Tehsil Pind Dadan Khan, Punjab, Pakistan";
    
    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1f455b),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.storefront, color: Colors.white70, size: 48),
          const SizedBox(height: 16),
          const Text(
            'GRACE TAILOR SHOP',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: () async {
              final query = Uri.encodeComponent(address);
              final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
              if (await canLaunchUrl(url)) launchUrl(url, mode: LaunchMode.externalApplication);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.redAccent),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      address,
                      style: TextStyle(
                        color: Colors.white70,
                        height: 1.5,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '© 2025 Grace Tailor Studio',
                style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
