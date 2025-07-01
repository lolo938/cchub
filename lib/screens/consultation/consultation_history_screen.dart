import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/child_model.dart';
import '../../models/doctor_model.dart';
import '../../models/consultation_model.dart';
import '../../providers/consultation_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../core/themes/app_theme.dart';
import '../../widgets/common/cached_image.dart';
import '../../core/services/logger_service.dart';
import '../../core/constants/app_colors.dart';

class ConsultationHistoryScreen extends ConsumerStatefulWidget {
  final Child? child;

  const ConsultationHistoryScreen({super.key, this.child});

  @override
  ConsumerState<ConsultationHistoryScreen> createState() =>
      _ConsultationHistoryScreenState();
}

class _ConsultationHistoryScreenState
    extends ConsumerState<ConsultationHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedChildId = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    if (widget.child != null) {
      _selectedChildId = widget.child!.id;
    }

    LoggerService.userAction('consultation_history_screen_opened', parameters: {
      'child_id': widget.child?.id,
    });

    // Data loading is handled by providers automatically
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final consultationsAsync = ref.watch(currentUserConsultationsProvider);
    final authState = ref.watch(authControllerProvider);
    final appUser = authState.userData;
    final children = appUser?.children ?? [];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.child != null
              ? '${widget.child!.name}\'s History'
              : 'Consultation History',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              LoggerService.userAction('book_new_consultation_pressed');
              context.push('/consultation/book');
            },
            icon: const Icon(Icons.add),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Child Filter (only show if no specific child is selected)
          if (widget.child == null && children.isNotEmpty)
            _buildChildFilter(children),

          // Tab Content
          Expanded(
            child: consultationsAsync.when(
              data: (consultations) => TabBarView(
                controller: _tabController,
                children: [
                  _buildConsultationList(_filterConsultations(
                      consultations, null)),
                  _buildConsultationList(_filterConsultations(
                      consultations,
                      ConsultationStatus.scheduled)),
                  _buildConsultationList(_filterConsultations(
                      consultations,
                      ConsultationStatus.completed)),
                  _buildConsultationList(_filterConsultations(
                      consultations,
                      ConsultationStatus.cancelled)),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text('Error loading consultations: $err'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          LoggerService.userAction('book_consultation_fab_pressed');
          context.push('/consultation/book', extra: widget.child);
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.video_call, color: Colors.white),
        label: const Text(
          'Book Consultation',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildChildFilter(List<Child> children) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter by Child',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildChildFilterChip('All Children', 'all'),
                const SizedBox(width: 8),
                ...children.map((child) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildChildFilterChip(child.name, child.id),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildFilterChip(String label, String childId) {
    final isSelected = _selectedChildId == childId;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedChildId = childId;
        });
        LoggerService.userAction('consultation_filter_changed',
            parameters: {'child_id': childId});
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }

  List<ConsultationRequest> _filterConsultations(
      List<ConsultationRequest> consultations, ConsultationStatus? status) {
    var filtered = consultations;

    // Filter by child if specific child is selected
    if (_selectedChildId != 'all') {
      filtered = filtered.where((c) => c.childId == _selectedChildId).toList();
    }

    // Filter by status
    if (status != null) {
      filtered = filtered.where((c) => c.status == status).toList();
    }

    // Sort by date (most recent first)
    filtered.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return filtered;
  }

  Widget _buildConsultationList(List<ConsultationRequest> consultations) {
    if (consultations.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh happens automatically through stream provider
        ref.invalidate(currentUserConsultationsProvider);
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: consultations.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _buildConsultationCard(consultations[index]);
        },
      ),
    );
  }

  Widget _buildConsultationCard(ConsultationRequest consultation) {
    final doctor = consultation.doctorId != null ? _getDoctorById(consultation.doctorId!) : null;
    final child = _getChildById(consultation.childId);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onConsultationTap(consultation),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Status Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          _getStatusColor(consultation.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(consultation.status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(consultation.status),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDateTime(consultation.dateTime),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Doctor Info
              Row(
                children: [
                  CachedAvatar(
                    imageUrl: doctor?.photoUrl ?? '',
                    radius: 20,
                    placeholder: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dr. ${doctor?.name ?? 'Unknown Doctor'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          doctor?.specialty ?? 'General Medicine',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${consultation.consultationFee}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Child Info
              Row(
                children: [
                  Icon(Icons.child_care, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    'Patient: ${child?.name ?? 'Unknown Child'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (child != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '• ${child.age} years',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // Chief Complaints
              Row(
                children: [
                  Icon(Icons.medical_services,
                      size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      consultation.chiefComplaints.join(', '),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Action Buttons
              Row(
                children: [
                  if (consultation.status == ConsultationStatus.scheduled) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _joinConsultation(consultation),
                        icon: const Icon(Icons.video_call, size: 18),
                        label: const Text('Join Call'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rescheduleConsultation(consultation),
                        icon: const Icon(Icons.schedule, size: 18),
                        label: const Text('Reschedule'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange[600],
                          side: BorderSide(color: Colors.orange[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ] else if (consultation.status ==
                      ConsultationStatus.completed) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewPrescription(consultation),
                        icon: const Icon(Icons.description, size: 18),
                        label: const Text('View Prescription'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green[600],
                          side: BorderSide(color: Colors.green[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _bookFollowup(consultation),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Book Follow-up'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewDetails(consultation),
                        icon: const Icon(Icons.info, size: 18),
                        label: const Text('View Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history,
                size: 60,
                color: Colors.blue[300],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Consultations Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedChildId == 'all'
                  ? 'You haven\'t booked any consultations yet.'
                  : 'No consultations found for the selected child.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                LoggerService.userAction('book_first_consultation_pressed');
                context.push('/consultation/book', extra: widget.child);
              },
              icon: const Icon(Icons.video_call),
              label: const Text('Book Your First Consultation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Doctor? _getDoctorById(String doctorId) {
    final doctorsAsync = ref.watch(allDoctorsProvider);
    final doctors = doctorsAsync.value ?? [];
    try {
      return doctors.firstWhere((doctor) => doctor.id == doctorId);
    } catch (e) {
      return null;
    }
  }

  Child? _getChildById(String childId) {
    final authState = ref.read(authControllerProvider);
    final appUser = authState.userData;
    if (appUser?.children == null) return null;

    try {
      return appUser!.children.firstWhere((child) => child.id == childId);
    } catch (e) {
      return null;
    }
  }

  Color _getStatusColor(ConsultationStatus status) {
    switch (status) {
      case ConsultationStatus.scheduled:
        return Colors.blue;
      case ConsultationStatus.inProgress:
        return Colors.orange;
      case ConsultationStatus.completed:
        return Colors.green;
      case ConsultationStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(ConsultationStatus status) {
    switch (status) {
      case ConsultationStatus.scheduled:
        return 'Scheduled';
      case ConsultationStatus.inProgress:
        return 'In Progress';
      case ConsultationStatus.completed:
        return 'Completed';
      case ConsultationStatus.cancelled:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final consultationDate =
        DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dateStr;
    if (consultationDate == today) {
      dateStr = 'Today';
    } else if (consultationDate == yesterday) {
      dateStr = 'Yesterday';
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      dateStr = '${dateTime.day} ${months[dateTime.month - 1]}';
    }

    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$dateStr at $displayHour:$minute $period';
  }

  void _onConsultationTap(ConsultationRequest consultation) {
    LoggerService.userAction('consultation_card_tapped',
        parameters: {'consultation_id': consultation.id});
    context.push('/consultation/details/${consultation.id}');
  }

  void _joinConsultation(ConsultationRequest consultation) {
    LoggerService.userAction('join_consultation_pressed',
        parameters: {'consultation_id': consultation.id});
    context.push('/consultation/video/${consultation.id}');
  }

  void _rescheduleConsultation(ConsultationRequest consultation) {
    LoggerService.userAction('reschedule_consultation_pressed',
        parameters: {'consultation_id': consultation.id});
    // TODO: Implement reschedule functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reschedule functionality coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _viewPrescription(ConsultationRequest consultation) {
    LoggerService.userAction('view_prescription_pressed',
        parameters: {'consultation_id': consultation.id});
    // TODO: Implement prescription view
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Prescription view coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _bookFollowup(ConsultationRequest consultation) {
    LoggerService.userAction('book_followup_pressed',
        parameters: {'consultation_id': consultation.id});
    final child = _getChildById(consultation.childId);
    final doctor = consultation.doctorId != null ? _getDoctorById(consultation.doctorId!) : null;
    context.push('/consultation/book', extra: child);
  }

  void _viewDetails(ConsultationRequest consultation) {
    LoggerService.userAction('view_consultation_details_pressed',
        parameters: {'consultation_id': consultation.id});
    context.push('/consultation/details/${consultation.id}');
  }
}
