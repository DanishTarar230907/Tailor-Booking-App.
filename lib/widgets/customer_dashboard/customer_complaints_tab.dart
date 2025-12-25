import 'package:flutter/material.dart';
import '../../models/complaint.dart';
import '../../services/firestore_complaints_service.dart';
import '../../models/tailor.dart';

class CustomerComplaintsTab extends StatefulWidget {
  final Tailor? tailor;
  final String? customerName;
  final String? customerEmail;
  final String? customerId;
  final VoidCallback onRefresh;

  const CustomerComplaintsTab({
    super.key,
    required this.tailor,
    required this.customerName,
    required this.customerEmail,
    required this.customerId,
    required this.onRefresh,
  });

  @override
  State<CustomerComplaintsTab> createState() => _CustomerComplaintsTabState();
}

class _CustomerComplaintsTabState extends State<CustomerComplaintsTab> {
  final FirestoreComplaintsService _complaintsService = FirestoreComplaintsService();
  final _complaintSubjectController = TextEditingController();
  final _complaintMessageController = TextEditingController();
  bool _isSubmittingComplaint = false;

  @override
  void dispose() {
    _complaintSubjectController.dispose();
    _complaintMessageController.dispose();
    super.dispose();
  }

  Future<void> _submitComplaint() async {
    if (_complaintSubjectController.text.isEmpty || _complaintMessageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isSubmittingComplaint = true);

    try {
      final complaint = Complaint(
        customerId: widget.customerId ?? 'unknown_customer',
        customerName: widget.customerName ?? 'Anonymous',
        customerEmail: widget.customerEmail ?? 'unknown',
        tailorId: widget.tailor?.docId ?? 'unknown_tailor',
        subject: _complaintSubjectController.text,
        message: _complaintMessageController.text,
        status: 'Pending',
        createdAt: DateTime.now(),
      );

      await _complaintsService.fileComplaint(complaint);
      
      _complaintSubjectController.clear();
      _complaintMessageController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint submitted successfully')),
        );
         widget.onRefresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting complaint: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingComplaint = false);
    }
  }

  Widget _buildComplaintForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'New Complaint',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _complaintSubjectController,
            decoration: InputDecoration(
              hintText: 'Subject',
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _complaintMessageController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Describe your issue...',
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isSubmittingComplaint ? null : _submitComplaint,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1f455b),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmittingComplaint
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Submit Complaint'),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedComplaintCard(Complaint complaint) {
    Color statusColor;
    IconData statusIcon;

    switch (complaint.status.toLowerCase()) {
      case 'resolved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      default:
        statusColor = Colors.blue;
        statusIcon = Icons.info;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor, size: 20),
        ),
        title: Text(
          complaint.subject,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(complaint.message, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    complaint.status.toUpperCase(),
                    style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(complaint.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Basic date formatting
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildComplaintForm(),
          const SizedBox(height: 32),
          const Text(
            'Complaint History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1f455b),
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<Complaint>>(
            stream: _complaintsService.getComplaintsForCustomer(widget.customerId ?? ''),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildEmptyState('Error loading complaints', 'Please try again later or check your connection.', Icons.error_outline);
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState('No complaints filed', 'Any issues you report will appear here', Icons.history);
              }
              
              final complaints = snapshot.data!;
              return Column(
                children: complaints.map((c) => _buildEnhancedComplaintCard(c)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
