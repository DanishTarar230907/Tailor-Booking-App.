import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/tailor.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_tailor_service.dart';
import '../../widgets/unified_profile_card.dart';

/// [Purpose]
/// This widget handles the display and editing of the Tailor's profile information.
/// It encapsulates the profile card UI and the side-panel editing form.
///
/// [Logic]
/// - Uses [UnifiedProfileCard] for consistent UI presentation.
/// - Manages editing state internally using a Side Panel pattern invoked via [showGeneralDialog].
/// - Handles image picking and base64 encoding/decoding for profile photos.
///
/// [Flow]
/// 1. Receives [Tailor] data and extra user info from parent.
/// 2. Displays data.
/// 3. On 'Edit' click -> Opens Side Panel.
/// 4. User edits -> 'Save' -> Updates Firestore Collections (Tailor & User) -> Calls [onRefresh].
class TailorProfileSection extends StatefulWidget {
  final Tailor? tailor;
  final String email;
  final String phone;
  final String whatsapp;
  final String location;
  final String shopHours;
  final VoidCallback onRefresh;

  const TailorProfileSection({
    super.key,
    required this.tailor,
    required this.email,
    required this.phone,
    required this.whatsapp,
    required this.location,
    required this.shopHours,
    required this.onRefresh,
  });

  @override
  State<TailorProfileSection> createState() => _TailorProfileSectionState();
}

class _TailorProfileSectionState extends State<TailorProfileSection> {
  final AuthService _authService = AuthService();
  final FirestoreTailorService _tailorService = FirestoreTailorService();
  final ImagePicker _imagePicker = ImagePicker();

  /// [Purpose]
  /// Opens the side panel for editing profile details.
  ///
  /// [Logic]
  /// We use [showGeneralDialog] instead of [showModalBottomSheet] to achieve a checking-from-side effect.
  /// A [SlideTransition] animates the panel from Right to Left.
  ///
  /// [Flow]
  /// - Initializes controllers with current data.
  /// - Shows dialog.
  /// - Returns control to user.
  void _openEditProfileSidePanel() {
    final nameController = TextEditingController(text: widget.tailor?.name ?? '');
    final descController = TextEditingController(text: widget.tailor?.description ?? '');
    final announcementController = TextEditingController(text: widget.tailor?.announcement ?? '');
    final phoneController = TextEditingController(text: widget.phone);
    final whatsappController = TextEditingController(text: widget.whatsapp);
    final gmailController = TextEditingController(text: widget.email);
    final locationController = TextEditingController(text: widget.location);
    final hoursController = TextEditingController(text: widget.shopHours);
    XFile? selectedImage;
    bool isUploading = false;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            elevation: 16,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(30)),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85, // 85% width side panel
              height: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(30)),
              ),
              child: StatefulBuilder(
                builder: (context, setPanelState) => Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 50, 24, 20),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Edit Profile',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Content Form
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Profile Image Picker
                            Center(
                              child: Stack(
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      final image = await _imagePicker.pickImage(
                                        source: ImageSource.gallery,
                                        maxWidth: 600,
                                        imageQuality: 70,
                                      );
                                      if (image != null) {
                                        setPanelState(() => selectedImage = image);
                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: CircleAvatar(
                                        radius: 60,
                                        backgroundColor: Colors.grey[100],
                                        backgroundImage: selectedImage != null
                                            ? (kIsWeb
                                                ? NetworkImage(selectedImage!.path) as ImageProvider
                                                : FileImage(File(selectedImage!.path)))
                                            : _getProfileImage(widget.tailor?.photo),
                                        child: (selectedImage == null && (widget.tailor?.photo == null || widget.tailor!.photo!.isEmpty))
                                            ? const Icon(Icons.person, size: 60, color: Colors.grey)
                                            : null,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            const Text('Personal Info', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 16),
                            _buildSidePanelField('Full Name', nameController, Icons.person_outline),
                            const SizedBox(height: 16),
                            _buildSidePanelField('Business Description', descController, Icons.description_outlined, maxLines: 3),
                            
                             const SizedBox(height: 32),
                            const Text('Shop Announcements', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Visible to all customers on their dashboard', style: TextStyle(fontSize: 12, color: Colors.orange)),
                                  const SizedBox(height: 8),
                                  _buildSidePanelField('Current Announcement', announcementController, Icons.campaign_outlined, maxLines: 2),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            const Text('Contact Details', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 16),
                            _buildSidePanelField('Phone Number', phoneController, Icons.phone_outlined),
                            const SizedBox(height: 16),
                            _buildSidePanelField('WhatsApp', whatsappController, Icons.chat_bubble_outline),
                            const SizedBox(height: 16),
                            _buildSidePanelField('Email Address', gmailController, Icons.email_outlined),
                            
                            const SizedBox(height: 32),
                            const Text('Shop Details', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 16),
                            _buildSidePanelField('Shop Location', locationController, Icons.location_on_outlined),
                            const SizedBox(height: 16),
                            _buildSidePanelField('Business Hours', hoursController, Icons.access_time),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                    
                    // Footer / Save Button
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            offset: const Offset(0, -4),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: isUploading ? null : () async {
                          setPanelState(() => isUploading = true);
                          try {
                             String? photoUrl = widget.tailor?.photo;
                            if (selectedImage != null) {
                              try {
                                final bytes = await selectedImage!.readAsBytes();
                                final base64String = base64Encode(bytes);
                                photoUrl = 'data:image/jpeg;base64,\$base64String';
                              } catch (e) {
                                print('Error encoding image: \$e');
                              }
                            }

                            final tailor = Tailor(
                              name: nameController.text.trim(),
                              photo: photoUrl,
                              description: descController.text.trim(),
                              announcement: announcementController.text.trim().isEmpty ? null : announcementController.text.trim(),
                              phone: phoneController.text.trim(),
                              whatsapp: whatsappController.text.trim(),
                              email: gmailController.text.trim(),
                              location: locationController.text.trim(),
                              shopHours: hoursController.text.trim(),
                            );

                            final user = _authService.currentUser;
                            final updates = [
                              _tailorService.insertOrUpdateTailor(tailor),
                              if (user != null)
                                _authService.updateUserData(user.uid, {
                                  'phone': phoneController.text.trim(),
                                  'whatsappNumber': whatsappController.text.trim(),
                                  'gmailId': gmailController.text.trim(),
                                  'shopLocation': locationController.text.trim(),
                                  'shopHours': hoursController.text.trim(),
                                }),
                            ];

                            await Future.wait(updates);
                            
                            if (context.mounted) Navigator.pop(context);
                            
                            // Trigger refresh in parent
                            widget.onRefresh();

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: const [
                                      Icon(Icons.check_circle, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text('Profile Updated Successfully'),
                                    ],
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  margin: const EdgeInsets.all(20),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              setPanelState(() => isUploading = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: \$e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        child: isUploading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
    );
  }

  /// [Purpose]
  /// Helper to build consistent text fields in the side panel.
  Widget _buildSidePanelField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
    );
  }

  /// [Purpose]
  /// Helper to decode base64 profile image string or return Network provider.
  ImageProvider? _getProfileImage(String? photo) {
    if (photo == null || photo.isEmpty) {
      return null;
    }
    
    try {
      if (photo.startsWith('data:')) {
        final parts = photo.split(',');
        if (parts.length > 1) {
          final base64String = parts[1];
          final bytes = base64Decode(base64String);
          return MemoryImage(bytes);
        }
      } else if (photo.startsWith('http://') || photo.startsWith('https://')) {
        return CachedNetworkImageProvider(photo);
      }
    } catch (e) {
      print('Error loading profile image: \$e');
      return null;
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return _buildProfileSection();
  }

  /// [Purpose]
  /// Builds the main profile card displayed on the dashboard.
  ///
  /// [Logic]
  /// Uses [UnifiedProfileCard] to display name, photo, and metrics.
  /// Configures 'Quick Actions' (Call, Email, Map) which launch external apps via [url_launcher].
  Widget _buildProfileSection() {
    final tailor = widget.tailor;
    if (tailor == null) {
      return Container(
         height: 200,
         child: const Center(child: CircularProgressIndicator()),
      );
    }

    return UnifiedProfileCard(
      name: tailor.name,
      description: tailor.description ?? 'Professional Tailor',
      photoUrl: tailor.photo,
      onEdit: _openEditProfileSidePanel,
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
                widget.shopHours, // Use passed shop hours which is synced
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
            if (widget.whatsapp.isNotEmpty) {
              final clean = widget.whatsapp.replaceAll(RegExp(r'[^0-9]'), '');
              final url = Uri.parse('https://wa.me/\$clean');
              if (await canLaunchUrl(url)) launchUrl(url);
            }
          },
        ),
        ProfileQuickAction(
          icon: Icons.phone_outlined,
          label: 'Call',
          color: const Color(0xFF1f455b),
          onTap: () async {
            if (widget.phone.isNotEmpty) {
               final url = Uri.parse('tel:\${widget.phone}');
              if (await canLaunchUrl(url)) launchUrl(url);
            }
          },
        ),
        ProfileQuickAction(
          icon: Icons.location_on_outlined,
          label: 'Map',
          color: Colors.redAccent,
          onTap: () async {
            if (widget.location.isNotEmpty) {
              final query = Uri.encodeComponent(widget.location);
              final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=\$query');
              if (await canLaunchUrl(url)) launchUrl(url, mode: LaunchMode.externalApplication);
            }
          },
        ),
      ],
    );
  }
}
