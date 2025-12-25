import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/pickup_request.dart';
import '../../services/firestore_pickup_requests_service.dart';

class CustomerPickupTab extends StatefulWidget {
  final List<PickupRequest> pickupRequests;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final VoidCallback onRefresh;

  const CustomerPickupTab({
    super.key,
    required this.pickupRequests,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.onRefresh,
  });

  @override
  State<CustomerPickupTab> createState() => _CustomerPickupTabState();
}

class _CustomerPickupTabState extends State<CustomerPickupTab> {
  final FirestorePickupRequestsService _pickupService = FirestorePickupRequestsService();
  final _pickupAddressController = TextEditingController();
  final _pickupNotesController = TextEditingController();
  String _pickupType = 'courier_pickup';

  @override
  void dispose() {
    _pickupAddressController.dispose();
    _pickupNotesController.dispose();
    super.dispose();
  }

  Future<void> _submitPickupRequest() async {
    if (_pickupAddressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide an address'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      final request = PickupRequest(
        customerName: widget.customerName ?? 'Anonymous',
        customerEmail: widget.customerEmail ?? '',
        customerPhone: widget.customerPhone ?? '',
        pickupAddress: _pickupAddressController.text,
        requestType: _pickupType,
        status: 'pending',
        charges: _pickupType == 'courier_pickup' ? 15.0 : 0.0,
        requestedDate: DateTime.now(),
        // Default 3 days, logic can be refined
        expectedDeliveryDate: DateTime.now().add(const Duration(days: 3)),
        notes: _pickupNotesController.text.isNotEmpty ? _pickupNotesController.text : null,
      );

      await _pickupService.addRequest(request);
      
      _pickupAddressController.clear();
      _pickupNotesController.clear();
      setState(() => _pickupType = 'courier_pickup');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pickup request submitted successfully!'), backgroundColor: Colors.green),
        );
        widget.onRefresh();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting request: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'approved':
      case 'accepted': return Colors.green;
      case 'rejected': return Colors.red;
      case 'completed': return Colors.blue;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Icons.pending;
      case 'approved':
      case 'accepted': return Icons.check_circle;
      case 'rejected': return Icons.cancel;
      case 'completed': return Icons.done_all;
      default: return Icons.help;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold)),
          Text(subtitle, style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

   Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(
            label, 
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text('$label:', style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _statusStep(String label, bool isActive, Color color) {
    return Column(
      children: [
        Icon(isActive ? Icons.check_circle : Icons.radio_button_unchecked, color: isActive ? color : Colors.grey),
        Text(label, style: TextStyle(fontSize: 10, color: isActive ? color : Colors.grey)),
      ],
    );
  }

  Widget _buildEnhancedPickupCard(PickupRequest request) {
     return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: _getStatusColor(request.status), width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ExpansionTile(
        title: Text(request.requestType == 'sewing_request' ? 'Sewing Request' : 'Pickup Request', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Status: ${request.status.toUpperCase()}'),
        leading: CircleAvatar(
           backgroundColor: _getStatusColor(request.status).withOpacity(0.1),
           child: Icon(_getStatusIcon(request.status), color: _getStatusColor(request.status)),
        ),
        children: [
           Padding(
             padding: const EdgeInsets.all(16.0),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 _detailRow('Date', _formatDate(request.requestedDate)),
                 _detailRow('Charges', '\$${request.charges.toStringAsFixed(2)}'),
                 if (request.notes != null) _detailRow('Notes', request.notes!),
                 const Divider(),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceAround,
                   children: [
                     _statusStep('Pending', request.status == 'pending' || request.status == 'accepted' || request.status == 'completed', Colors.orange),
                     _statusStep('Accepted', request.status == 'accepted' || request.status == 'completed', Colors.blue),
                     _statusStep('Received', request.status == 'completed', Colors.green),
                   ],
                 ),
               ],
             ),
           ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int pending = widget.pickupRequests.where((r) => r.status == 'pending').length;
    int accepted = widget.pickupRequests.where((r) => r.status == 'accepted').length;
    int completed = widget.pickupRequests.where((r) => r.status == 'completed').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
           // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.purple.shade600],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_shipping, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Pickup & Delivery',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage your incoming parcels',
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Stats Row
          Row(
            children: [
              Expanded(child: _buildStatCard('Pending', pending.toString(), Icons.pending, Colors.orange)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard('Accepted', accepted.toString(), Icons.check_circle_outline, Colors.blue)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard('Received', completed.toString(), Icons.home_filled, Colors.green)),
            ],
          ),

          const SizedBox(height: 24),

          // Request Form
          Container(
             padding: const EdgeInsets.all(20),
             decoration: BoxDecoration(
               color: Colors.white,
               borderRadius: BorderRadius.circular(16),
               boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
             ),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 const Text('New Request', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 16),
                 DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Request Type',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  value: _pickupType,
                  items: const [
                    DropdownMenuItem(value: 'courier_pickup', child: Text('Courier Pickup (Sending Fabric)')),
                    DropdownMenuItem(value: 'sewing_request', child: Text('Sewing Request')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _pickupType = v);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pickupAddressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                     filled: true,
                     fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pickupNotesController,
                  decoration: InputDecoration(
                    labelText: 'Notes (Optional)',
                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                     filled: true,
                     fillColor: Colors.grey[50],
                  ),
                ),
                 const SizedBox(height: 16),
                 SizedBox(
                   width: double.infinity,
                   child: ElevatedButton(
                     onPressed: _submitPickupRequest,
                     style: ElevatedButton.styleFrom(
                       padding: const EdgeInsets.symmetric(vertical: 16),
                       backgroundColor: Colors.indigo,
                       foregroundColor: Colors.white,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                     ),
                     child: const Text('Submit Request'),
                   ),
                 ),
               ],
             ),
          ),
          
          const SizedBox(height: 24),
          const Text('Request History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          if (widget.pickupRequests.isEmpty)
             _buildEmptyState('No pickup history', 'Your requests will appear here', Icons.history)
          else
            Column(
              children: widget.pickupRequests.map((request) => _buildEnhancedPickupCard(request)).toList(),
            ),
        ],
      ),
    );
  }
}
