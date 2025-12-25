import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/design.dart';

class CustomerDesignsTab extends StatelessWidget {
  final List<Design> designs;

  const CustomerDesignsTab({super.key, required this.designs});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: designs.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75, // Adjust for card height
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: designs.length,
                  itemBuilder: (context, index) {
                    return _buildDesignCard(designs[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'My Designs (${designs.length})',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          // No Add Button for Customer
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checkroom, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No designs available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new styles!',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildDesignCard(Design design) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Section
            Expanded(
              flex: 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildDesignImage(design.photo),
                  // No Edit/Delete Icons here
                ],
              ),
            ),
            // Details Section
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          design.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rs. ${design.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.green, // Matching image green price
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesignImage(String? photo) {
    if (photo == null || photo.isEmpty) {
      return Container(
        color: Colors.grey[100],
        child: Icon(Icons.checkroom, color: Colors.grey[300], size: 40),
      );
    }

    if (photo.startsWith('data:')) {
      return Image.memory(
        const Base64Decoder().convert(photo.split(',').last),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: Colors.grey[100]),
      );
    }

    return CachedNetworkImage(
      imageUrl: photo,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: Colors.grey[100]),
      errorWidget: (_, __, ___) => Container(color: Colors.grey[100]),
    );
  }
}
