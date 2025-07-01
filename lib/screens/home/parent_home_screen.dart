import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_sizes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../providers/consultation_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/home/doctor_marquee.dart';
import '../../widgets/home/quick_actions.dart';
import '../../widgets/home/consultation_summary.dart';
import '../../widgets/common/custom_button.dart';

class ParentHomeScreen extends ConsumerWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final walletBalance = ref.watch(currentUserWalletBalanceProvider);
    final activeConsultations = ref.watch(currentUserActiveConsultationsProvider);
    final unreadNotificationsCount = ref.watch(currentUserUnreadNotificationsCountProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(currentUserWalletBalanceProvider);
            ref.invalidate(currentUserActiveConsultationsProvider);
            ref.invalidate(doctorMarqueeProvider);
          },
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                    ),
                    padding: const EdgeInsets.only(
                      left: AppSizes.paddingLarge,
                      right: AppSizes.paddingLarge,
                      top: AppSizes.paddingLarge,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back,',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                                Text(
                                  authState.userData?.name ?? 'Parent',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Stack(
                                  children: [
                                    IconButton(
                                      onPressed: () => context.push('/notifications'),
                                      icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                                    ),
                                    if (unreadNotificationsCount > 0)
                                      Positioned(
                                        right: 8,
                                        top: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: AppColors.error,
                                            shape: BoxShape.circle,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 16,
                                            minHeight: 16,
                                          ),
                                          child: Text(
                                            unreadNotificationsCount > 99 ? '99+' : unreadNotificationsCount.toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                IconButton(
                                  onPressed: () => context.push('/profile'),
                                  icon: const Icon(Icons.person_outlined, color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Wallet Balance Card
                      _buildWalletCard(context, walletBalance),
                      
                      const SizedBox(height: AppSizes.spacingLarge),
                      
                      // Active Consultations
                      activeConsultations.when(
                        data: (consultations) => consultations.isNotEmpty
                            ? _buildActiveConsultations(context, consultations)
                            : const SizedBox.shrink(),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      
                      // Quick Actions
                      _buildQuickActions(context),
                      
                      const SizedBox(height: AppSizes.spacingLarge),
                      
                      // Doctor Marquee
                      _buildDoctorMarquee(context),
                      
                      const SizedBox(height: AppSizes.spacingLarge),
                      
                      // Recent Consultations
                      _buildRecentConsultations(context),
                      
                      const SizedBox(height: AppSizes.spacingLarge),
                      
                      // Health Tips
                      _buildHealthTips(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context, AsyncValue<double> balanceAsync) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.walletPrimary, AppColors.walletSecondary],
        ),
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.walletPrimary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wallet Balance',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingXSmall),
                  balanceAsync.when(
                    data: (balance) => Text(
                      '₹${balance.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    loading: () => const SizedBox(
                      width: 100,
                      height: 20,
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    error: (_, __) => Text(
                      '₹0.00',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => context.push('/wallet'),
                icon: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 32),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingMedium),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Recharge Wallet',
              onPressed: () => context.push('/wallet/recharge'),
              type: ButtonType.secondary,
              backgroundColor: Colors.white,
              textColor: AppColors.walletPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveConsultations(BuildContext context, List consultations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Consultations',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSizes.spacingMedium),
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          decoration: BoxDecoration(
            color: AppColors.consultation.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            border: Border.all(color: AppColors.consultation.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.video_call, color: AppColors.consultation),
              const SizedBox(width: AppSizes.spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You have ${consultations.length} active consultation${consultations.length > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Tap to view details',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => context.push('/consultation/history'),
                icon: const Icon(Icons.arrow_forward_ios),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.spacingLarge),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSizes.spacingMedium),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                'Instant\nConsultation',
                Icons.emergency,
                AppColors.error,
                () => context.push('/consultation/book'),
              ),
            ),
            const SizedBox(width: AppSizes.spacingMedium),
            Expanded(
              child: _buildActionCard(
                context,
                'Book\nAppointment',
                Icons.calendar_today,
                AppColors.primary,
                () => context.push('/doctors'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spacingMedium),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                'Find\nDoctors',
                Icons.search,
                AppColors.secondary,
                () => context.push('/doctors'),
              ),
            ),
            const SizedBox(width: AppSizes.spacingMedium),
            Expanded(
              child: _buildActionCard(
                context,
                'Manage\nChildren',
                Icons.child_care,
                AppColors.success,
                () => context.push('/children'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorMarquee(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Doctors',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSizes.spacingMedium),
        const DoctorMarquee(),
      ],
    );
  }

  Widget _buildRecentConsultations(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Consultations',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/consultation/history'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spacingMedium),
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
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
          child: const ConsultationSummary(),
        ),
      ],
    );
  }

  Widget _buildHealthTips(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health Tips',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSizes.spacingMedium),
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.success.withOpacity(0.1), AppColors.success.withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: AppColors.success),
                  const SizedBox(width: AppSizes.spacingMedium),
                  Text(
                    'Daily Health Tip',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.spacingMedium),
              Text(
                'Ensure your child drinks plenty of water throughout the day. Proper hydration is essential for healthy growth and development.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}