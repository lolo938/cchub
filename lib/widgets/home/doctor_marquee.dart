import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../providers/doctor_provider.dart';
import '../../models/doctor_model.dart';

class DoctorMarquee extends ConsumerStatefulWidget {
  const DoctorMarquee({super.key});

  @override
  ConsumerState<DoctorMarquee> createState() => _DoctorMarqueeState();
}

class _DoctorMarqueeState extends ConsumerState<DoctorMarquee>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late ScrollController _scrollController;
  bool _isAnimating = true;
  bool _userScrolling = false;
  Timer? _resumeTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..addListener(_onTick);
    _startAnimation();
  }

  void _onTick() {
    if (_isAnimating && !_userScrolling && _scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final pixels = _scrollController.offset + 1.2;
      if (pixels >= maxScroll) {
        _scrollController.jumpTo(0);
      } else {
        _scrollController.jumpTo(pixels);
      }
    }
  }

  void _startAnimation() {
    if (_isAnimating) {
      _animationController.repeat();
    }
  }

  void _stopAnimation() {
    _animationController.stop();
  }

  void _onUserScrollStart() {
    setState(() {
      _userScrolling = true;
      _stopAnimation();
    });
    _resumeTimer?.cancel();
  }

  void _onUserScrollEnd() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(seconds: 2), () {
      setState(() {
        _userScrolling = false;
        if (_isAnimating) _startAnimation();
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _resumeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctorsAsync = ref.watch(doctorMarqueeProvider);

    return doctorsAsync.when(
      data: (doctors) =>
          doctors.isEmpty ? _buildEmptyState() : _buildMarquee(doctors),
      loading: () => _buildLoadingState(),
      error: (error, _) => _buildErrorState(),
    );
  }

  Widget _buildMarquee(List<Doctor> doctors) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth * 0.8;
        final cardSpacing = 24.0;
        final totalCards = doctors.length * 2; // duplicate for seamless loop
        return Container(
          height: 190,
          color: Colors.transparent, // Use parent's background
          child: Stack(
            children: [
              // Marquee List
              Positioned.fill(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollStartNotification) {
                      _onUserScrollStart();
                    } else if (notification is ScrollEndNotification) {
                      _onUserScrollEnd();
                    }
                    return false;
                  },
                  child: ClipRect(
                    child: ListView.builder(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: totalCards,
                      itemBuilder: (context, index) {
                        final doctor = doctors[index % doctors.length];
                        return Container(
                          width: cardWidth,
                          margin: EdgeInsets.only(
                            right: cardSpacing,
                            top: 24,
                            bottom: 24,
                          ),
                          child: _buildDoctorCard(doctor),
                        );
                      },
                    ),
                  ),
                ),
              ),
              // View All Button (top right)
              Positioned(
                top: 0,
                right: 16,
                child: TextButton(
                  onPressed: () => context.push('/doctors'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View All', style: TextStyle(color: Colors.white70)),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios,
                          size: 14, color: Colors.white70),
                    ],
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black.withOpacity(0.5),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(AppSizes.borderRadius * 1.5),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Doctor Avatar
            Container(
              width: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                image: DecorationImage(
                  image: NetworkImage(doctor.photoUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Doctor Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDetailRow(
                    context,
                    text: doctor.designation,
                    isTitle: true,
                  ),
                  _buildDetailRow(
                    context,
                    text: 'Reg: ${doctor.registrationNumber ?? 'N/A'}',
                  ),
                  _buildDetailRow(
                    context,
                    text: 'State: ${doctor.state ?? 'N/A'}',
                  ),
                  _buildDetailRow(
                    context,
                    text: doctor.specialization,
                    isSpecialization: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    String? text,
    bool isTitle = false,
    bool isSpecialization = false,
  }) {
    if (text == null || text.isEmpty) {
      return const SizedBox.shrink();
    }
    return Flexible(
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: isTitle ? 18 : 14,
          fontWeight: isTitle ? FontWeight.bold : FontWeight.normal,
          color: isSpecialization
              ? AppColors.primary
              : Colors.white.withOpacity(isTitle ? 0.9 : 0.7),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'No doctors available',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.grey.shade400,
              size: 32,
            ),
            const SizedBox(height: AppSizes.spacingSmall),
            Text(
              'Failed to load doctors',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
