import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../providers/consultation_provider.dart';
import '../../models/consultation_model.dart';

class ConsultationSummary extends ConsumerWidget {
  const ConsultationSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consultationsAsync = ref.watch(currentUserConsultationsProvider);

    return consultationsAsync.when(
      data: (consultations) => consultations.isEmpty
          ? _buildEmptyState(context)
          : _buildSummary(context, consultations),
      loading: () => _buildLoadingState(),
      error: (error, _) => _buildErrorState(context),
    );
  }

  Widget _buildSummary(BuildContext context, List<ConsultationRequest> consultations) {
    final recentConsultations = consultations.take(3).toList();
    final stats = _calculateStats(consultations);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats Row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Total',
                stats['total'].toString(),
                AppColors.primary,
                Icons.medical_services,
              ),
            ),
            const SizedBox(width: AppSizes.spacingMedium),
            Expanded(
              child: _buildStatCard(
                context,
                'Completed',
                stats['completed'].toString(),
                AppColors.success,
                Icons.check_circle,
              ),
            ),
            const SizedBox(width: AppSizes.spacingMedium),
            Expanded(
              child: _buildStatCard(
                context,
                'Pending',
                stats['pending'].toString(),
                AppColors.warning,
                Icons.schedule,
              ),
            ),
          ],
        ),
        
        if (recentConsultations.isNotEmpty) ...[
          const SizedBox(height: AppSizes.spacingLarge),
          Text(
            'Recent Consultations',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.spacingMedium),
          ...recentConsultations.map((consultation) => _buildConsultationItem(context, consultation)),
        ],
        
        const SizedBox(height: AppSizes.spacingMedium),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.push('/consultation/history'),
            child: const Text('View All Consultations'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSizes.spacingSmall),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationItem(BuildContext context, ConsultationRequest consultation) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacingSmall),
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 40,
            decoration: BoxDecoration(
              color: _getStatusColor(consultation.status),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: AppSizes.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${consultation.typeDisplayName} Consultation',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Child: ${consultation.childName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  _formatDate(consultation.requestedAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingSmall,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: _getStatusColor(consultation.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              consultation.statusDisplayName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _getStatusColor(consultation.status),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.medical_services_outlined,
          size: 64,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: AppSizes.spacingMedium),
        Text(
          'No Consultations Yet',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSizes.spacingSmall),
        Text(
          'Your consultation history will appear here',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.spacingLarge),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.push('/consultation/book'),
            child: const Text('Book Your First Consultation'),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.error_outline,
          size: 64,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: AppSizes.spacingMedium),
        Text(
          'Unable to load consultations',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSizes.spacingMedium),
        OutlinedButton(
          onPressed: () {
            // Trigger refresh
          },
          child: const Text('Retry'),
        ),
      ],
    );
  }

  Map<String, int> _calculateStats(List<ConsultationRequest> consultations) {
    int total = consultations.length;
    int completed = 0;
    int pending = 0;

    for (final consultation in consultations) {
      switch (consultation.status) {
        case ConsultationStatus.completed:
          completed++;
          break;
        case ConsultationStatus.pending:
        case ConsultationStatus.waitingForDoctor:
        case ConsultationStatus.accepted:
        case ConsultationStatus.scheduled:
        case ConsultationStatus.inProgress:
          pending++;
          break;
        default:
          break;
      }
    }

    return {
      'total': total,
      'completed': completed,
      'pending': pending,
    };
  }

  Color _getStatusColor(ConsultationStatus status) {
    switch (status) {
      case ConsultationStatus.completed:
        return AppColors.success;
      case ConsultationStatus.pending:
      case ConsultationStatus.waitingForDoctor:
        return AppColors.warning;
      case ConsultationStatus.accepted:
      case ConsultationStatus.scheduled:
      case ConsultationStatus.inProgress:
        return AppColors.primary;
      case ConsultationStatus.rejected:
      case ConsultationStatus.cancelled:
        return AppColors.error;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}