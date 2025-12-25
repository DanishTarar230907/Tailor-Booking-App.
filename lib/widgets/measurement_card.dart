import 'package:flutter/material.dart';
import '../models/measurement.dart' as models;
import '../services/firestore_measurements_service.dart';
import 'communication_section.dart';
import 'measurement_receipt.dart';

/// Visual measurement card with grid layout - matches Aisha Khan template
class MeasurementCard extends StatefulWidget {
  final models.Measurement measurement;
  final VoidCallback onDelete;
  final VoidCallback onRefresh;

  const MeasurementCard({
    super.key,
    required this.measurement,
    required this.onDelete,
    required this.onRefresh,
  });

  @override
  State<MeasurementCard> createState() => _MeasurementCardState();
}

class _MeasurementCardState extends State<MeasurementCard> {
  final _service = FirestoreMeasurementsService();

  Future<void> _showUpdateDialog() async {
    final controllers = <String, TextEditingController>{};
    
    // Initialize controllers with current values
    final measurementsList = [
      'Chest', 'Waist', 'Hip', 'Shoulder',
      'Sleeve', 'Kurta Length', 'Inseam', 'Neck'
    ];
    
    for (var key in measurementsList) {
      final value = widget.measurement.measurements[key] ?? 0.0;
      controllers[key] = TextEditingController(text: value.toString());
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Measurements'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: measurementsList.map((key) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: controllers[key],
                  decoration: InputDecoration(
                    labelText: key,
                    border: const OutlineInputBorder(),
                    suffixText: 'in',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      final updatedMeasurements = <String, double>{};
      controllers.forEach((key, controller) {
        final value = double.tryParse(controller.text) ?? 0.0;
        updatedMeasurements[key] = value;
      });

      final updated = widget.measurement.copyWith(
        measurements: updatedMeasurements,
        updatedAt: DateTime.now(),
      );

      await _service.insertOrUpdate(updated);
      widget.onRefresh();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Measurements updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }

    // Dispose controllers
    controllers.values.forEach((c) => c.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final measurementsList = [
      {'label': 'CHEST', 'key': 'Chest'},
      {'label': 'WAIST', 'key': 'Waist'},
      {'label': 'HIP', 'key': 'Hip'},
      {'label': 'SHOULDER', 'key': 'Shoulder'},
      {'label': 'SLEEVE LENGTH', 'key': 'Sleeve'},
      {'label': 'TORSO LENGTH', 'key': 'Kurta Length'},
      {'label': 'INSEAM', 'key': 'Inseam'},
      {'label': 'NECK LINE', 'key': 'Neck'},
    ];

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: widget.measurement.updateRequested 
            ? const BorderSide(color: Colors.red, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with avatar and info
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.purple.shade100,
                  child: Text(
                    widget.measurement.customerName[0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.purple.shade700,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.measurement.customerName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Measured: ${widget.measurement.createdAt.day}/${widget.measurement.createdAt.month}/${widget.measurement.createdAt.year}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Edit button
                IconButton(
                  onPressed: _showUpdateDialog,
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Body Measurements Header
            Row(
              children: [
                Icon(Icons.straighten, color: Colors.teal.shade700, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Body Measurements',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Grid of measurement cards
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 4,
                childAspectRatio: 1.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: measurementsList.length,
              itemBuilder: (context, index) {
                final item = measurementsList[index];
                final value = widget.measurement.measurements[item['key']] ?? 0.0;
                
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['label']!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              value.toStringAsFixed(value == value.toInt() ? 0 : 1),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'in',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),



            const SizedBox(height: 24),
            
 
            // Correcting block to ALWAYS show:
            const Divider(),
            const SizedBox(height: 8),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Customer Communication', style: TextStyle(fontWeight: FontWeight.bold)),
                  if (widget.measurement.updateRequested)
                    TextButton.icon(
                      onPressed: () async {
                         final updated = widget.measurement.copyWith(updateRequested: false);
                         await _service.insertOrUpdate(updated);
                         widget.onRefresh();
                         if (mounted) setState(() {});
                      },
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Mark Resolved'),
                      style: TextButton.styleFrom(foregroundColor: Colors.green),
                    ),
                ],
            ),
            const SizedBox(height: 8),
            CommunicationSection(
                measurement: widget.measurement,
                onUpdate: (updated) async {
                  await _service.insertOrUpdate(updated);
                  widget.onRefresh();
                  if (mounted) setState(() {});
                },
            ),
            const SizedBox(height: 24),

            // Action buttons
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 360; // Breakpoint for stacking
                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _showUpdateDialog,
                        icon: const Icon(Icons.edit, size: 20),
                        label: const Text('Update Measurements'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MeasurementReceipt(
                                measurement: widget.measurement,
                                tailorName: null,
                                tailorPhone: null,
                              ),
                              fullscreenDialog: true,
                            ),
                          );
                        },
                        icon: const Icon(Icons.print, size: 20),
                        label: const Text('Print Card'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showUpdateDialog,
                          icon: const Icon(Icons.edit, size: 20),
                          label: const Text(
                            'Update Measurements',
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis, // Safety
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MeasurementReceipt(
                                  measurement: widget.measurement,
                                  tailorName: null,
                                  tailorPhone: null,
                                ),
                                fullscreenDialog: true,
                              ),
                            );
                          },
                          icon: const Icon(Icons.print, size: 20),
                          label: const Text('Print Card'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
