import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
// Web URL handling - using url_launcher would be better for cross-platform
// For now, URLs will be logged on non-web platforms
import '../models/tailor.dart' as models;
import '../models/design.dart' as models;
import '../models/complaint.dart' as models;
import '../models/booking.dart' as models;
import '../models/measurement.dart' as models;
import '../models/pickup_request.dart' as models;
import '../models/faq_item.dart' as models;
import '../models/measurement_request.dart'; // Added
import '../widgets/communication_section.dart';
import '../widgets/unified_profile_card.dart';
import 'tailor_measurement_page.dart';
import 'tailor_bookings_screen.dart';
import 'tailor_measurements_tab.dart';
import 'tailor_pickup_requests_tab.dart';
import '../widgets/measurement_dummy.dart';
import '../widgets/measurement_card.dart';
import '../widgets/announcement_card.dart';
import '../widgets/tailor_dashboard/tailor_profile_section.dart';
import '../widgets/tailor_dashboard/tailor_designs_tab.dart';
import '../widgets/tailor_dashboard/tailor_complaints_tab.dart';
import '../widgets/tailor_dashboard/tailor_bookings_tab.dart';
import '../services/auth_service.dart';
import '../services/firestore_designs_service.dart';
import '../services/firestore_bookings_service.dart';
import '../services/firestore_complaints_service.dart';
import '../services/firestore_pickup_requests_service.dart';
import '../services/firestore_tailor_service.dart';
import '../services/firestore_measurements_service.dart';
import '../services/firestore_faq_service.dart';
import '../services/firestore_measurement_requests_service.dart'; // Added
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firebase_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';
import 'package:intl/intl.dart';

class TailorDashboard extends StatefulWidget {
  const TailorDashboard({super.key});

  @override
  State<TailorDashboard> createState() => _TailorDashboardState();
}

class _TailorDashboardState extends State<TailorDashboard>
    with SingleTickerProviderStateMixin {
  // All entities now via Firestore services.
  final AuthService _authService = AuthService();
  final FirestoreDesignsService _designsService = FirestoreDesignsService();
  final FirestoreBookingsService _bookingsService = FirestoreBookingsService();
  final FirestoreComplaintsService _complaintsService =
      FirestoreComplaintsService();
  final FirestorePickupRequestsService _pickupService =
      FirestorePickupRequestsService();
  final FirestoreFaqService _faqService = FirestoreFaqService();
  final FirestoreMeasurementRequestsService _measurementRequestsService = FirestoreMeasurementRequestsService(); // Added
  final FirestoreTailorService _tailorService = FirestoreTailorService();
  final FirestoreMeasurementsService _measurementsService =
      FirestoreMeasurementsService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final ImagePicker _imagePicker = ImagePicker();
  final ScrollController _scrollController = ScrollController();
  // Section anchors for quick navigation
  final GlobalKey _profileKey = GlobalKey();
  final GlobalKey _designsKey = GlobalKey();
  final GlobalKey _bookingsKey = GlobalKey();
  final GlobalKey _pickupKey = GlobalKey();
  final GlobalKey _complaintsKey = GlobalKey();
  final GlobalKey _measurementsKey = GlobalKey();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  models.Tailor? _tailor;
  List<models.Design> _designs = [];
  List<models.Complaint> _complaints = [];
  List<models.Booking> _bookings = [];
  List<models.PickupRequest> _pickupRequests = [];
  List<models.FaqItem> _faqs = [];
  List<MeasurementRequest> _measurementRequests = []; // Added
  bool _isLoading = true;

  int _selectedTabIndex = 0; // For bottom navigation

  // Enhanced profile fields
  String _phone = '';
  String _email = '';
  String _whatsappNumber = '';
  String _gmailId = '';
  String _shopLocation = 'Grace Tailor Shop, Pindi Saidpur';
  String _shopHours = 'Mon-Sat: 9 AM - 7 PM';
  double _rating = 4.8;
  int _totalReviews = 127;
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadData();
    _loadUserInfo();
    _setupRealtimeListeners();
    _animationController.forward();
  }

  StreamSubscription<List<models.Design>>? _designsSubscription;
  StreamSubscription<List<models.Booking>>? _bookingsSubscription;
  StreamSubscription<List<models.PickupRequest>>? _pickupSubscription;
  StreamSubscription<List<models.Complaint>>? _complaintsSubscription;
  StreamSubscription<List<models.FaqItem>>? _faqSubscription;
  StreamSubscription<List<MeasurementRequest>>? _measurementRequestsSubscription; // Added
  DateTime _lastUpdate = DateTime.now();

  void _setupRealtimeListeners() {
    // Measurement Requests Listener
    _measurementRequestsSubscription = _measurementRequestsService.streamRequests().listen(
      (requests) {
        if (mounted) {
          setState(() {
            _measurementRequests = requests;
          });
        }
      },
      onError: (e) => print('Error in measurement requests stream: $e'),
    );

    // Debounce updates to prevent excessive rebuilds (max once per 500ms)
    _designsSubscription = _designsService.streamDesigns().listen(
      (designs) {
        if (mounted && DateTime.now().difference(_lastUpdate).inMilliseconds > 500) {
          _lastUpdate = DateTime.now();
          setState(() {
            _designs = designs;
          });
        } else if (mounted) {
          _designs = designs;
        }
      },
      onError: (e) => print('Error in designs stream: $e'),
    );
     
    _bookingsSubscription = _bookingsService.streamAllBookings().listen(
      (bookings) {
        if (mounted && DateTime.now().difference(_lastUpdate).inMilliseconds > 500) {
          _lastUpdate = DateTime.now();
          setState(() {
            _bookings = bookings;
          });
        } else if (mounted) {
          _bookings = bookings;
        }
      },
      onError: (e) => print('Error in bookings stream: $e'),
    );

    _pickupSubscription = _pickupService.streamRequests().listen(
      (requests) {
        if (mounted && DateTime.now().difference(_lastUpdate).inMilliseconds > 500) {
          _lastUpdate = DateTime.now();
          setState(() {
            _pickupRequests = requests;
          });
        } else if (mounted) {
          _pickupRequests = requests;
        }
      },
      onError: (e) => print('Error in pickup stream: $e'),
    );

    _complaintsSubscription = _complaintsService.streamComplaints().listen(
      (complaints) {
        if (mounted && DateTime.now().difference(_lastUpdate).inMilliseconds > 500) {
          _lastUpdate = DateTime.now();
          setState(() {
            _complaints = complaints;
          });
        } else if (mounted) {
          _complaints = complaints;
        }
      },
      onError: (e) => print('Error in complaints stream: $e'),
    );
  }

  @override
  void dispose() {
    _designsSubscription?.cancel();
    _bookingsSubscription?.cancel();
    _pickupSubscription?.cancel();
    _complaintsSubscription?.cancel();
    _faqSubscription?.cancel();
    _measurementRequestsSubscription?.cancel(); // Added
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final user = _authService.currentUser;
    if (user != null) {
      setState(() {
        _email = user.email ?? '';
      });
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // Load data in parallel for better performance
      final results = await Future.wait([
        _tailorService.getTailor(),
        _designsService.getAllDesigns(),
        _complaintsService.getAllComplaints(),
        _bookingsService.getAllBookings(),
        _pickupService.getAllRequests(),
      ], eagerError: false);
      
      final tailor = results[0] as models.Tailor?;
      final designs = results[1] as List<models.Design>;
      final complaints = results[2] as List<models.Complaint>;
      final bookings = results[3] as List<models.Booking>;
      final pickupRequests = results[4] as List<models.PickupRequest>;

      // Load profile data from Firestore - load regardless of tailor existence
      final user = _authService.currentUser;
      if (user != null) {
        final userData = await _authService.getUserData(user.uid);
        if (userData != null) {
          _phone = userData['phone'] as String? ?? '';
          _whatsappNumber = userData['whatsappNumber'] as String? ?? '';
          _gmailId = userData['gmailId'] as String? ?? '';
          _shopLocation = userData['shopLocation'] as String? ?? 'Grace Tailor Shop, Pindi Saidpur';
          _shopHours = userData['shopHours'] as String? ?? 'Mon-Sat: 9 AM - 7 PM';
          _rating = (userData['rating'] as num?)?.toDouble() ?? 4.8;
          _totalReviews = userData['totalReviews'] as int? ?? 127;
          _reviews = (userData['reviews'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        }
      }

      if (mounted) {
        setState(() {
          _tailor = tailor;
          _designs = designs;
          _complaints = complaints;
          _bookings = bookings;
          _pickupRequests = pickupRequests;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  // Optimized refresh methods - only update specific data without full reload
  Future<void> _refreshDesigns() async {
    if (!mounted) return;
    try {
      final designs = await _designsService.getAllDesigns();
      if (mounted) {
        setState(() => _designs = designs);
      }
    } catch (e) {
      print('Error refreshing designs: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing designs: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _refreshBookings() async {
    try {
      final bookings = await _bookingsService.getAllBookings();
      if (mounted) {
        setState(() => _bookings = bookings);
      }
    } catch (e) {
      print('Error refreshing bookings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing bookings: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _refreshMeasurements() async {
    // Measurements are loaded on demand, no need to refresh
  }

  Future<void> _refreshPickupRequests() async {
    try {
      final pickupRequests = await _pickupService.getAllRequests();
      if (mounted) {
        setState(() => _pickupRequests = pickupRequests);
      }
    } catch (e) {
      print('Error refreshing pickup requests: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing pickup requests: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _refreshComplaints() async {
    try {
      final complaints = await _complaintsService.getAllComplaints();
      if (mounted) {
        setState(() => _complaints = complaints);
      }
    } catch (e) {
      print('Error refreshing complaints: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing complaints: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Grace Tailor Studio',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  content: const Text(
                    'Are you sure you want to logout?',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE11D48),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await _authService.signOut();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: IndexedStack(
          index: _selectedTabIndex,
          children: [
            // Tab 0: Profile
            SingleChildScrollView(
              child: Column(
                children: [
                  TailorProfileSection(
                    tailor: _tailor,
                    email: _email,
                    phone: _phone,
                    whatsapp: _whatsappNumber,
                    location: _shopLocation,
                    shopHours: _shopHours,
                    onRefresh: () {
                      _loadData();
                      _loadUserInfo();
                    },
                  ),


                  _buildQuickStats(),
                  
                  // Announcement Display (Below Stats as requested)
                  if (_tailor?.announcement != null && _tailor!.announcement!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: AnnouncementCard(announcement: _tailor!.announcement!),
                    ),
                ],
              ),
            ),

            // Tab 1: Designs
            SingleChildScrollView(
              child: TailorDesignsTab(
                designs: _designs,
                onRefresh: () => _refreshDesigns(),
              ),
            ),

            // Tab 2: Bookings
            SingleChildScrollView(
              child: _tailor != null 
                  ? TailorBookingsTab(
                      tailor: _tailor!,
                      bookings: _bookings,
                      onRefresh: _loadData, // Reloads tailor (settings) and bookings
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),

            // Tab 3: Measurements
            SingleChildScrollView(
              child: _buildMeasurementsSection(),
            ),

            // Tab 4: Pickup
            SingleChildScrollView(
              child: _buildPickupRequestsSection(),
            ),

            // Tab 5: Complaints
            SingleChildScrollView(
              child: TailorComplaintsTab(
                complaints: _complaints,
                onRefresh: () => _refreshComplaints(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, // Center if plenty of space
                children: [
                  _buildNavItem(0, Icons.person, 'Profile'),
                  const SizedBox(width: 4),
                  _buildNavItem(1, Icons.checkroom, 'Designs'),
                  const SizedBox(width: 4),
                  _buildNavItem(2, Icons.calendar_today, 'Bookings'),
                  const SizedBox(width: 4),
                  _buildNavItem(3, Icons.straighten, 'Measure'),
                  const SizedBox(width: 4),
                  _buildNavItem(4, Icons.local_shipping, 'Pickup'),
                  const SizedBox(width: 4),
                  _buildNavItem(5, Icons.forum, 'Complaints'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // Reduced padding
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.purple : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10, // Slightly smaller font
                color: isSelected ? Colors.purple : Colors.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 2),
                height: 3,
                width: 20,
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _scrollToSection(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.05,
      );
    }
  }


  Widget _buildReviewsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Reviews',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('See All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...(_reviews.take(3).map((review) => _buildReviewItem(review))),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    final customerName = review['customerName'] as String? ?? 'Anonymous';
    final initial = customerName.isNotEmpty ? customerName[0].toUpperCase() : 'A';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            child: Text(initial),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...List.generate(5, (index) {
                      final rating = (review['rating'] as num?)?.toDouble() ?? 5.0;
                      return Icon(
                        Icons.star,
                        size: 14,
                        color: index < rating ? Colors.amber : Colors.grey[300],
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  review['comment'] as String? ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 450;
          if (isNarrow) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _buildStatCard(
                            'Bookings',
                            _bookings.length.toString(),
                            Icons.event,
                            Colors.blue)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildStatCard(
                            'Designs',
                            _designs.length.toString(),
                            Icons.design_services,
                            Colors.purple)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _buildStatCard(
                            'Complaints',
                            _complaints.length.toString(),
                            Icons.message,
                            Colors.orange)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildStatCard(
                            'Pickups',
                            _pickupRequests.where((p) => p.status != 'delivered').length.toString(),
                            Icons.local_shipping,
                            Colors.green)),
                  ],
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Bookings',
                  _bookings.length.toString(),
                  Icons.event,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Designs',
                  _designs.length.toString(),
                  Icons.design_services,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Complaints',
                  _complaints.length.toString(),
                  Icons.message,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Pickups',
                  _pickupRequests.where((p) => p.status != 'delivered').length.toString(),
                  Icons.local_shipping,
                  Colors.green,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * animValue),
          child: Opacity(opacity: animValue, child: child),
        );
      },
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeasurementsSection() {
    return _buildSection(
      title: 'Customer Measurements',
      icon: Icons.straighten,
      actionButton: IconButton(
        icon: const Icon(Icons.add_circle, size: 28),
        color: Theme.of(context).colorScheme.primary,
        onPressed: _showAddMeasurementDialog,
        tooltip: 'Add New Measurement',
      ),
      child: _buildMeasurementsContent(),
    );
  }

  // Search and Sort State
  String _measurementSearchQuery = '';
  String _measurementSortOption = 'Name'; // Name, Date

  Widget _buildMeasurementsContent() {
    final pendingRequests = _measurementRequests.where((r) => r.status == 'pending' || r.status == 'replied').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pendingRequests.isNotEmpty)
          Container(
            height: 160,
            margin: const EdgeInsets.only(bottom: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: pendingRequests.length,
              itemBuilder: (context, index) {
                final req = pendingRequests[index];
                return GestureDetector(
                  onTap: () => _showMeasurementRequestActionDialog(req),
                  child: Container(
                    width: 300,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.shade200),
                      boxShadow: [
                        BoxShadow(color: Colors.orange.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: req.customerPhoto != null 
                                  ? CachedNetworkImageProvider(req.customerPhoto!) 
                                  : null,
                              child: req.customerPhoto == null 
                                  ? Text(req.customerName[0], style: const TextStyle(fontSize: 12)) 
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(req.customerName, style: const TextStyle(fontWeight: FontWeight.bold))),
                            StatusBadge(status: req.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                         Text(
                          '${req.requestType == 'new' ? 'New Measurement Request' : 'Renewal Request'}',
                          style: const TextStyle(color: Color(0xFF1f455b), fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          req.notes ?? 'No notes',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        const Spacer(),
                        const Row(
                           mainAxisAlignment: MainAxisAlignment.end,
                           children: [
                             Text('Tap to Manage', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                             Icon(Icons.arrow_forward_ios, size: 12, color: Colors.orange),
                           ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
        SizedBox(
          height: MediaQuery.of(context).size.height - (pendingRequests.isNotEmpty ? 380 : 200),
          child: const TailorMeasurementPage(),
        ),
      ],
    );
  }



  Widget _buildDetailedMeasurementTable(models.Measurement m) {
    // Combine standard and dynamic measurements
    // Standard set for sorting order
    final standardKeys = ['Chest', 'Waist', 'Hips', 'Shoulder', 'Sleeve Length', 'Shirt Length', 'Trouser Length'];
    Map<String, double> displayed = Map.from(m.measurements);
    
    // Ensure all standard keys exist for display (even if null/0)
    for (var key in standardKeys) {
       displayed.putIfAbsent(key, () => 0.0);
    }

    final sortedEntries = displayed.entries.toList()
      ..sort((a, b) {
         // Standard first, then alphabetical
         int idxA = standardKeys.indexOf(a.key);
         int idxB = standardKeys.indexOf(b.key);
         if (idxA != -1 && idxB != -1) return idxA.compareTo(idxB);
         if (idxA != -1) return -1;
         if (idxB != -1) return 1;
         return a.key.compareTo(b.key);
      });

    return Container(
      padding: const EdgeInsets.all(16),
      child: Table(
        border: TableBorder.all(color: Colors.grey[300]!, borderRadius: BorderRadius.circular(8)),
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.grey[100]),
            children: const [
              Padding(padding: EdgeInsets.all(8), child: Text('Measurement', style: TextStyle(fontWeight: FontWeight.bold))),
              Padding(padding: EdgeInsets.all(8), child: Text('Value', style: TextStyle(fontWeight: FontWeight.bold))),
              Padding(padding: EdgeInsets.all(8), child: Text('Edit', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          ...sortedEntries.map((entry) {
            return TableRow(
              children: [
                Padding(padding: const EdgeInsets.all(8), child: Text(entry.key)),
                Padding(padding: const EdgeInsets.all(8), child: Text(entry.value == 0.0 ? '-' : entry.value.toStringAsFixed(1))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  child: m.stitchingStarted
                      ? const Icon(Icons.lock, size: 16, color: Colors.grey)
                      : IconButton(
                          icon: const Icon(Icons.edit, size: 16),
                          onPressed: () {
                            _showQuickUpdateDialog(m, entry.key, entry.value);
                          },
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  void _showQuickUpdateDialog(models.Measurement m, String fieldName, double? currentValue) {
    if (m.stitchingStarted) return; // double check

    final controller = TextEditingController(text: (currentValue == 0.0 ? '' : currentValue?.toString()) ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update $fieldName'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'New Value (Inches)'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(controller.text);
              if (val != null) {
                Map<String, double> newMap = Map.from(m.measurements);
                newMap[fieldName] = val;
                
                final updated = m.copyWith(measurements: newMap);
                
                await _measurementsService.insertOrUpdate(updated);
                if (context.mounted) Navigator.pop(context);
                setState(() {}); // refresh
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showAddDynamicRowDialog(models.Measurement m) {
    final nameController = TextEditingController();
    final valController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Measurement Row'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             TextField(
               controller: nameController,
               decoration: const InputDecoration(labelText: 'Measurement Name (e.g. Neck)'),
             ),
             TextField(
               controller: valController,
               decoration: const InputDecoration(labelText: 'Value (e.g. 15.5)'),
               keyboardType: TextInputType.number,
             ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final val = double.tryParse(valController.text);
              
              if (name.isNotEmpty && val != null) {
                 Map<String, double> newMap = Map.from(m.measurements);
                 newMap[name] = val;
                 final updated = m.copyWith(measurements: newMap);
                 await _measurementsService.insertOrUpdate(updated);
                 if (context.mounted) Navigator.pop(context);
                 setState(() {});
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  String _simpleDateFormat(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }

  void _showMeasurementDetails(models.Measurement measurement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return _MeasurementDetailsSheet(
            measurement: measurement, 
            service: _measurementsService,
          );
        }
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    Widget? actionButton,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (actionButton != null) actionButton,
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildEnhancedEmpty(IconData icon, String title, Color color, {String? subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.bold)),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle, style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[500], fontSize: 16)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAddMeasurementDialog() {
    // Placeholder - Ideally this opens TailorMeasurementPage
    Navigator.push(context, MaterialPageRoute(builder: (_) => const TailorMeasurementPage()));
  }

  void _showAddPickupRequestDialog() {
     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not implemented yet')));
     // Implement if needed or link to tab
  }

  void _showEditPickupRequestDialog(models.PickupRequest request) {
    // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit not implemented yet')));
    // Minimal impl for compilation
  }

  void _showDeletePickupRequestDialog(models.PickupRequest request) {
    // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delete not implemented yet')));
  }

  Widget _buildPickupRequestsSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.purple.shade50],
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
                colors: [Colors.blue.shade600, Colors.purple.shade600],
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
                      child: const Icon(Icons.local_shipping, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pickup Requests',
                            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage incoming parcels and dress pickups',
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
                        onPressed: _showAddPickupRequestDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('New Pickup Request'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _refreshPickupRequests,
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
                const SizedBox(height: 16),
                // Status Summary Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildStatusChip('🟡 Pending', _getPendingPickupsCount(), Colors.orange),
                    _buildStatusChip('🟢 Accepted', _getAcceptedPickupsCount(), Colors.green),
                    _buildStatusChip('🔵 Completed', _getCompletedPickupsCount(), Colors.blue),
                  ],
                ),
              ],
            ),
          ),
          
          // Summary Cards - Responsive Layout
          Padding(
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate item width for 2-column layout (minus spacing)
                double itemWidth = (constraints.maxWidth - 12) / 2;
                // If screen is very wide (tablet), maybe 4 columns?
                if (constraints.maxWidth > 600) itemWidth = (constraints.maxWidth - 36) / 4;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: _buildPickupSummaryCard(
                        '📦 Today\'s Pickups',
                        _getTodayPickupsCount(),
                        Icons.today,
                        Colors.blue,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildPickupSummaryCard(
                        '🚚 Incoming',
                        _getIncomingParcelsCount(),
                        Icons.local_shipping,
                        Colors.purple,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildPickupSummaryCard(
                        '✅ Completed',
                        _getCompletedPickupsCount(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildPickupSummaryCard(
                        '⏳ Pending',
                        _getPendingPickupsCount(),
                        Icons.pending_actions,
                        Colors.orange,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          
          // Pickup List
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _buildPickupRequestsContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedPickupCard(models.PickupRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: _getRequestStatusColor(request.status), width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.blue.shade400, Colors.purple.shade400]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request.customerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(request.customerEmail, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                StatusBadge(status: request.status, type: 'pickup'),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.category, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text('Type:', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      const Spacer(),
                      Text(request.requestType.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  if (request.trackingNumber != null) ...[
                    const Divider(height: 16),
                    Row(
                      children: [
                        Icon(Icons.qr_code, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text('Tracking:', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        const Spacer(),
                        Text(request.trackingNumber!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditPickupRequestDialog(request),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showDeletePickupRequestDialog(request),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickupRequestsContent() {
    if (_pickupRequests.isEmpty) {
      return _buildEnhancedEmpty(
        Icons.local_shipping,
        'No pickup requests',
        Colors.blue,
        subtitle: 'Pickup requests will appear here',
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _pickupRequests.take(5).map((request) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Avatar + Name
                    Expanded(
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: _getRequestStatusColor(request.status).withOpacity(0.2),
                            child: Icon(
                              Icons.local_shipping,
                              color: _getRequestStatusColor(request.status),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              request.customerName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Menu
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditPickupRequestDialog(request);
                        } else if (value == 'delete') {
                          _showDeletePickupRequestDialog(request);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Address + Date + Status
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.pickupAddress,
                            style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _formatDate(request.requestedDate),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getRequestStatusColor(request.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _getRequestStatusColor(request.status).withOpacity(0.3)),
                      ),
                      child: Text(
                        request.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getRequestStatusColor(request.status),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getRequestStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Pickup Statistics Helper Methods
  int _getTodayPickupsCount() {
    final today = DateTime.now();
    return _pickupRequests.where((r) {
      return r.requestedDate.year == today.year &&
          r.requestedDate.month == today.month &&
          r.requestedDate.day == today.day;
    }).length;
  }

  int _getIncomingParcelsCount() {
    return _pickupRequests.where((r) => 
        r.status == 'pending' || r.status == 'accepted').length;
  }

  int _getCompletedPickupsCount() {
    return _pickupRequests.where((r) => r.status == 'completed').length;
  }

  int _getPendingPickupsCount() {
    return _pickupRequests.where((r) => r.status == 'pending').length;
  }

  int _getAcceptedPickupsCount() {
    return _pickupRequests.where((r) => r.status == 'accepted').length;
  }

  // Pickup UI Helper Methods
  Widget _buildPickupSummaryCard(String title, int count, IconData icon, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: 0.85 + (0.15 * animValue),
          child: Opacity(
            opacity: animValue,
            child: Container(
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    // Encode the location for URL
    final encodedLocation = Uri.encodeComponent(_shopLocation);
    final mapSearchUrl = 'https://www.google.com/maps/search/?api=1&query=$encodedLocation';
    
    // Create a clickable map preview that opens Google Maps
    return InkWell(
      onTap: () {
        // On web, URLs can be opened via browser
        print('Map URL: $mapSearchUrl');
        // TODO: Implement URL opening with url_launcher package
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[50]!, Colors.blue[100]!],
          ),
        ),
        child: Stack(
          children: [
            // Map-like background pattern
            Positioned.fill(
              child: CustomPaint(
                painter: _MapPatternPainter(),
              ),
            ),
            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(Icons.location_on, size: 48, color: Colors.blue[700]),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _shopLocation,
                      style: TextStyle(
                        color: Colors.blue[900],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.blue[700],
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Open in Google Maps',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _showMeasurementRequestActionDialog(MeasurementRequest request) {
    final messageController = TextEditingController();
    final scrollController = ScrollController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Stream updates for this specific request to show real-time chat
          return StreamBuilder<List<MeasurementRequest>>(
            stream: _measurementRequestsService.streamRequests(), // Not optimal but works for now
            builder: (context, snapshot) {
              final updatedReq = snapshot.data?.firstWhere(
                (r) => r.id == request.id, 
                orElse: () => request
              ) ?? request;

              return Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Container(
                  width: 500,
                  height: 600,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Header
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: updatedReq.customerPhoto != null 
                              ? CachedNetworkImageProvider(updatedReq.customerPhoto!) 
                              : null,
                            child: updatedReq.customerPhoto == null ? Text(updatedReq.customerName[0]) : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Request from ${updatedReq.customerName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text('Status: ${updatedReq.status.toUpperCase()}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              ],
                            ),
                          ),
                          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                        ],
                      ),
                      const Divider(height: 32),
                      
                      // Chat Area
                      Expanded(
                        child: updatedReq.messages.isEmpty 
                            ? Center(child: Text('No messages yet. Start a conversation!', style: TextStyle(color: Colors.grey[400])))
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: updatedReq.messages.length,
                                itemBuilder: (context, index) {
                                  final msg = updatedReq.messages[index];
                                  final isMe = msg['senderId'] == _authService.currentUser?.uid; // Assuming tailor is current user
                                  return Align(
                                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(vertical: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isMe ? const Color(0xFF1f455b) : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            msg['text'] ?? '',
                                            style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                                          ),
                                          Text(
                                            DateFormat('HH:mm').format(DateTime.parse(msg['timestamp'])),
                                            style: TextStyle(color: isMe ? Colors.white70 : Colors.grey, fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Input Area
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: messageController,
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: const Color(0xFF1f455b),
                            child: IconButton(
                              icon: const Icon(Icons.send, color: Colors.white, size: 20),
                              onPressed: () async {
                                if (messageController.text.trim().isEmpty) return;
                                final text = messageController.text.trim();
                                messageController.clear();
                                
                                final msg = {
                                  'senderId': _authService.currentUser?.uid,
                                  'senderName': 'Tailor', // Should get real name
                                  'text': text,
                                  'timestamp': DateTime.now().toIso8601String(),
                                };
                                await _measurementRequestsService.addMessage(updatedReq.id, msg);
                                // Also update status to 'replied' if pending
                                if (updatedReq.status == 'pending') {
                                   await _measurementRequestsService.updateRequest(updatedReq.copyWith(status: 'replied'));
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      // Action Buttons
                      if (updatedReq.status == 'pending' || updatedReq.status == 'replied')
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  await _measurementRequestsService.updateRequest(updatedReq.copyWith(status: 'rejected'));
                                  if (context.mounted) Navigator.pop(context);
                                }, 
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                child: const Text('Reject'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Processing...')));
                                    
                                    try {
                                      // 1. Sync with Measurements System (Create/Update Measurement Record)
                                      // Check if measurement profile exists to preserve data
                                      final existing = await _measurementsService.getByCustomerEmail(updatedReq.customerEmail);
                                      
                                      final measurementRecord = models.Measurement(
                                        customerId: updatedReq.customerId,
                                        customerName: updatedReq.customerName,
                                        customerEmail: updatedReq.customerEmail,
                                        customerPhone: updatedReq.customerPhone,
                                        status: 'Scheduled',
                                        measurements: existing?.measurements ?? {}, // Preserve existing
                                        appointmentDate: updatedReq.scheduledDate ?? DateTime.now().add(const Duration(days: 3)), // Default or from request
                                        updatedAt: DateTime.now(),
                                      );
                                      
                                      await _measurementsService.insertOrUpdate(measurementRecord);

                                      // 2. Update Request Status
                                      await _measurementRequestsService.updateRequest(updatedReq.copyWith(status: 'scheduled'));
                                      
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Appointment Scheduled & Added to Measurement List'), backgroundColor: Colors.green),
                                        );
                                      }
                                    } catch (e) {
                                      print('Error scheduling: $e');
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), 
                                  child: const Text('Accept / Schedule'),
                                ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            }
          );
        },
      ),
    );
  }
}

// Custom painter for map-like pattern
class _MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue[100]!.withOpacity(0.3)
      ..strokeWidth = 1.5;

    // Draw grid lines
    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }
    for (double i = 0; i < size.height; i += 30) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SimpleDateFormatter {
  final String pattern;
  _SimpleDateFormatter(this.pattern);

  String format(DateTime date) {
    if (pattern == 'E') {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[date.weekday - 1]; // weekday is 1-7
    }
    if (pattern == 'day') {
      return '${date.day}/${date.month}';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _MeasurementDetailsSheet extends StatefulWidget {
  final models.Measurement measurement;
  final FirestoreMeasurementsService service;
  const _MeasurementDetailsSheet({required this.measurement, required this.service});
  
  @override
  _MeasurementDetailsSheetState createState() => _MeasurementDetailsSheetState();
}

class _MeasurementDetailsSheetState extends State<_MeasurementDetailsSheet> {
  late bool _showGrid;
  
  @override
  void initState() {
    super.initState();
    _showGrid = widget.measurement.measurements.values.any((v) => v > 0) || widget.measurement.status == 'Completed';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _showGrid 
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: MeasurementDummy( // Assuming this is the editable table widget
                    measurement: widget.measurement,
                    isEditable: true,
                    onMeasurementUpdated: (updated) async {
                      await widget.service.insertOrUpdate(updated);
                    },
                  ),
                )
              : _buildPendingView(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[300]!))),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          Expanded(child: Text(widget.measurement.customerName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          StatusBadge(status: widget.measurement.status),
        ],
      ),
    );
  }

  Widget _buildPendingView() {
    final date = widget.measurement.appointmentDate;
    final dateStr = date != null ? '${date.day}/${date.month} at ${date.hour}:${date.minute.toString().padLeft(2,'0')}' : 'Not scheduled';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 80, color: Colors.orange.shade200),
          const SizedBox(height: 24),
          const Text('Measurements Pending', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          Text('Customer is scheduled to visit:', style: TextStyle(color: Colors.grey[600])),
          Text(dateStr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => setState(() => _showGrid = true),
            icon: const Icon(Icons.add),
            label: const Text('Add Measurements'),
            style: ElevatedButton.styleFrom(
               padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
               textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

