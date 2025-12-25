import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UnifiedProfileCard extends StatelessWidget {
  final String name;
  final String description;
  final String? photoUrl;
  final List<Widget> infoChips;
  final List<ProfileQuickAction> quickActions;
  final VoidCallback? onEdit;
  final Widget? extraContent;

  const UnifiedProfileCard({
    super.key,
    required this.name,
    required this.description,
    this.photoUrl,
    this.infoChips = const [],
    this.quickActions = const [],
    this.onEdit,
    this.extraContent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Card(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Image
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[100],
                  backgroundImage: _getProfileImage(),
                  child: (photoUrl == null || photoUrl!.isEmpty)
                      ? Icon(Icons.person, size: 50, color: Colors.grey[400])
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              
              // Name and Edit Button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: FittedBox(
                       fit: BoxFit.scaleDown,
                       child: Text(
                        name,
                        style: const TextStyle(
                          color: Color(0xFF1f455b),
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  if (onEdit != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.edit,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  height: 1.5,
                  fontSize: 15,
                ),
              ),
              
              if (infoChips.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: infoChips,
                ),
              ],

              if (quickActions.isNotEmpty) ...[
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: quickActions.map((action) => _buildQuickAction(action)).toList(),
                ),
              ],
              
              if (extraContent != null) ...[
                const SizedBox(height: 24),
                extraContent!,
              ]
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider? _getProfileImage() {
    if (photoUrl == null || photoUrl!.isEmpty) return null;
    try {
      if (photoUrl!.startsWith('data:')) {
        final parts = photoUrl!.split(',');
        if (parts.length > 1) {
          final base64String = parts[1];
          final bytes = base64Decode(base64String);
          return MemoryImage(bytes);
        }
      } else if (photoUrl!.startsWith('http://') || photoUrl!.startsWith('https://')) {
        return CachedNetworkImageProvider(photoUrl!);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Widget _buildQuickAction(ProfileQuickAction action) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: action.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: action.color.withOpacity(0.2)),
            ),
            child: Icon(action.icon, color: action.color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            action.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileQuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  ProfileQuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
