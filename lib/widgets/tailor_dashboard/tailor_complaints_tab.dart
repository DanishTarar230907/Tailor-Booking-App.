import 'package:flutter/material.dart';
import '../../models/complaint.dart';
import '../../services/firestore_complaints_service.dart';
import '../../services/firestore_faq_service.dart';

/// [Purpose]
/// This widget manages the Complaints & Support tab of the Tailor Dashboard.
/// It displays customer complaints, provides resolution tools, and shows FAQs.
///
/// [Logic]
/// - Uses a [Column] layout with a gradient summary header, statistics cards, and a list of complaints.
/// - Calculates statistics (Open, In Progress, Resolved) on the fly from the [complaints] list.
/// - Manages dialogs for Adding, Editing, and Replying to complaints.
/// - Integrates FAQ section at the bottom.
///
/// [Flow]
/// 1. Receives list of [Complaint]s from parent.
/// 2. Displays Summary Stats.
/// 3. Displays Complaints List (or Empty State).
/// 4. Provides Actions (Resolve, Reply, Delete) which update Firestore via [FirestoreComplaintsService].
/// 5. Calls [onRefresh] to reload data in parent after changes.
class TailorComplaintsTab extends StatefulWidget {
  final List<Complaint> complaints;
  final VoidCallback onRefresh;

  const TailorComplaintsTab({
    super.key,
    required this.complaints,
    required this.onRefresh,
  });

  @override
  State<TailorComplaintsTab> createState() => _TailorComplaintsTabState();
}

class _TailorComplaintsTabState extends State<TailorComplaintsTab> {
  final FirestoreComplaintsService _complaintsService = FirestoreComplaintsService();
  final FirestoreFaqService _faqService = FirestoreFaqService(); // Assuming this service exists

  // --- Statistics Helpers ---

  int _getOpenComplaintsCount() {
    return widget.complaints.where((c) => !c.isResolved && (c.reply == null || c.reply!.isEmpty)).length;
  }

  int _getInProgressComplaintsCount() {
    return widget.complaints.where((c) => !c.isResolved && c.reply != null && c.reply!.isNotEmpty).length;
  }

  int _getResolvedComplaintsCount() {
    return widget.complaints.where((c) => c.isResolved).length;
  }

  // --- UI Building ---

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade50, Colors.red.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade600, Colors.red.shade600],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.support_agent, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Customer Complaints & Support',
                            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'View and resolve customer concerns',
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Action Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showAddComplaintDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('New Complaint'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.orange.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: widget.onRefresh,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Refresh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Stats Cards Row
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: _buildComplaintStatCard(
                    '🔴 Open',
                    _getOpenComplaintsCount(),
                    Icons.error_outline,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildComplaintStatCard(
                    '🟡 In Progress',
                    _getInProgressComplaintsCount(),
                    Icons.pending,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildComplaintStatCard(
                    '🟢 Resolved',
                    _getResolvedComplaintsCount(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ),
          
          // Complaint List
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: widget.complaints.isEmpty
                ? _buildEnhancedEmpty(
                    Icons.sentiment_satisfied_alt,
                    'No Complaints',
                    Colors.green,
                    subtitle: 'All good! Your customers are happy 😊',
                  )
                : Column(
                    children: widget.complaints.map((c) => _buildEnhancedComplaintCard(c)).toList(),
                  ),
          ),
          
          // FAQ Section (Simplified placeholder or extracted logic)
          _buildFAQSection(),
        ],
      ),
    );
  }

  Widget _buildFAQSection() {
    // Basic implementation of FAQ Section if not extracting fully. 
    // Ideally this should fetch FAQs. For now, using a placeholder or calling service.
    return FutureBuilder<List<dynamic>>( // using dynamic or FaqItem
      future: _faqService.getAllFaqs(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Frequently Asked Questions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...snapshot.data!.take(3).map((faq) => ExpansionTile(
                title: Text(faq.question),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(faq.answer),
                  ),
                ],
              )),
            ],
          ),
        );
      },
    );
  }

  /// [Purpose]
  /// Helper to build stats cards.
  Widget _buildComplaintStatCard(String title, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  /// [Purpose]
  /// Builds a detailed card for a single [Complaint].
  /// 
  /// [Logic]
  /// - Shows Complaint ID, Date, Subject, Description.
  /// - Shows 'Reply' section if a reply exists.
  /// - Provides 'Resolve' toggle and 'Reply' button.
  Widget _buildEnhancedComplaintCard(Complaint complaint) {
    bool isExpanded = false; // Internal state for expansion could be handled by wrapper or simplified.
    // For simplicity, we use a specialized Card widget or build it here.
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(complaint.status.toUpperCase()),
                  backgroundColor: _getStatusColor(complaint.status).withOpacity(0.1),
                  labelStyle: TextStyle(color: _getStatusColor(complaint.status), fontSize: 12),
                ),
                Text(
                  _formatDate(complaint.createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              complaint.subject,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(complaint.message), // description -> message
            if ((complaint.replies.isNotEmpty) || (complaint.reply != null && complaint.reply!.isNotEmpty)) ...[
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Row(
                       children: const [
                         Icon(Icons.reply, size: 16, color: Colors.blue),
                         SizedBox(width: 8),
                         Text('Latest Reply:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                       ],
                     ),
                     const SizedBox(height: 4),
                     Text(complaint.replies.isNotEmpty ? complaint.replies.last.message : (complaint.reply ?? '')),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
             Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!complaint.isResolved)
                  TextButton.icon(
                    onPressed: () => _showReplyComplaintDialog(complaint),
                    icon: const Icon(Icons.reply),
                    label: const Text('Reply'),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    complaint.isResolved ? Icons.check_circle : Icons.check_circle_outline,
                    color: complaint.isResolved ? Colors.green : Colors.grey,
                  ),
                  onPressed: () => _toggleComplaintResolution(complaint),
                  tooltip: complaint.isResolved ? 'Mark as Unresolved' : 'Mark as Resolved',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _showDeleteComplaintDialog(complaint),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status.toLowerCase() == 'resolved') return Colors.green;
    if (status.toLowerCase().contains('progress')) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildEnhancedEmpty(IconData icon, String title, Color color, {String? subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: color.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.bold)),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
             Text(subtitle, style: TextStyle(color: Colors.grey[600])),
          ],
        ],
      ),
    );
  }

  // --- Dialogs ---

  void _showAddComplaintDialog() {
    // Simplification: In a real app, tailor might not add customer complaints manually often, 
    // but useful for tracking phone complaints.
     final subjectController = TextEditingController();
    final descController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Complaint Record'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: subjectController, decoration: const InputDecoration(labelText: 'Subject')),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (subjectController.text.isNotEmpty) {
                final complaint = Complaint(
                  docId: null, // Firestore generates ID
                  customerId: 'manual',
                  customerName: 'Phone/Walk-in',
                  customerEmail: 'manual@entry.com', // Placeholder
                  subject: subjectController.text,
                  message: descController.text, // 'description' -> 'message'
                  createdAt: DateTime.now(), // 'date' -> 'createdAt'
                  status: 'open',
                  isResolved: false,
                );
                await _complaintsService.addComplaint(complaint);
                if (context.mounted) Navigator.pop(context);
                widget.onRefresh();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
  
  void _showReplyComplaintDialog(Complaint complaint) {
    // Only showing latest reply for now or empty
    final existingReply = complaint.replies.isNotEmpty ? complaint.replies.last.message : (complaint.reply ?? '');
    final replyController = TextEditingController(text: existingReply);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reply to Complaint'),
        content: TextField(
          controller: replyController,
          decoration: const InputDecoration(labelText: 'Your Reply', border: OutlineInputBorder()),
          maxLines: 4,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (complaint.docId != null) {
                  final reply = ComplaintReply(
                      message: replyController.text, 
                      isFromTailor: true, 
                      senderName: 'Tailor'
                  );
                  await _complaintsService.addReply(complaint.docId!, reply);
                  if (context.mounted) Navigator.pop(context);
                  widget.onRefresh();
              }
            },
            child: const Text('Send Reply'),
          ),
        ],
      ),
    );
  }

  void _toggleComplaintResolution(Complaint complaint) async {
    if (complaint.docId != null) {
        final newStatus = !complaint.isResolved ? 'resolved' : 'open';
        await _complaintsService.updateStatus(complaint.docId!, newStatus);
        widget.onRefresh();
    }
  }

  void _showDeleteComplaintDialog(Complaint complaint) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Complaint'),
        content: const Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
             onPressed: () async {
               if (complaint.docId != null) {
                   await _complaintsService.deleteComplaint(complaint.docId!);
                   if (context.mounted) Navigator.pop(context);
                   widget.onRefresh();
               }
             },
             child: const Text('Delete', style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }
}
