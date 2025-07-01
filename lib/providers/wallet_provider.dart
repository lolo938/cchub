import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/wallet_service.dart';
import '../models/wallet_model.dart';
import 'auth_provider.dart';

// Wallet info provider
final walletInfoProvider =
    FutureProvider.family<WalletInfo?, String>((ref, userId) {
  return WalletService.getWalletInfo(userId);
});

// Current user wallet info provider
final currentUserWalletInfoProvider = FutureProvider<WalletInfo?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Future.value(null);
  return WalletService.getWalletInfo(user.uid);
});

// Wallet balance provider
final walletBalanceProvider =
    FutureProvider.family<double, String>((ref, userId) {
  return WalletService.getWalletBalance(userId);
});

// Current user wallet balance provider
final currentUserWalletBalanceProvider = FutureProvider<double>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Future.value(0.0);
  return WalletService.getWalletBalance(user.uid);
});

// Transaction history provider
final transactionHistoryProvider =
    StreamProvider.family<List<WalletTransaction>, String>((ref, userId) {
  return WalletService.getTransactionHistory(userId);
});

// Current user transaction history provider
final currentUserTransactionHistoryProvider =
    StreamProvider<List<WalletTransaction>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return WalletService.getTransactionHistory(user.uid);
});

// Wallet stats provider
final walletStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, userId) {
  return WalletService.getWalletStats(userId);
});

// Current user wallet stats provider
final currentUserWalletStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Future.value({});
  return WalletService.getWalletStats(user.uid);
});

// Monthly transaction summary provider
final monthlyTransactionSummaryProvider =
    FutureProvider.family<Map<String, double>, String>((ref, userId) {
  return WalletService.getMonthlyTransactionSummary(userId);
});

// Current user monthly transaction summary provider
final currentUserMonthlyTransactionSummaryProvider =
    FutureProvider<Map<String, double>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Future.value({'credits': 0, 'debits': 0, 'net': 0});
  return WalletService.getMonthlyTransactionSummary(user.uid);
});

// Wallet controller provider
final walletControllerProvider =
    StateNotifierProvider<WalletController, WalletState>((ref) {
  return WalletController(ref);
});

// Wallet state class
class WalletState {
  final bool isLoading;
  final String? error;
  final bool isRecharging;
  final double? pendingRechargeAmount;
  final double balance;

  const WalletState({
    this.isLoading = false,
    this.error,
    this.isRecharging = false,
    this.pendingRechargeAmount,
    this.balance = 0.0,
  });

  WalletState copyWith({
    bool? isLoading,
    String? error,
    bool? isRecharging,
    double? pendingRechargeAmount,
    double? balance,
  }) {
    return WalletState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isRecharging: isRecharging ?? this.isRecharging,
      pendingRechargeAmount:
          pendingRechargeAmount ?? this.pendingRechargeAmount,
      balance: balance ?? this.balance,
    );
  }
}

// Wallet controller class
class WalletController extends StateNotifier<WalletState> {
  final Ref ref;

  WalletController(this.ref) : super(const WalletState());

  // Dummy recharge
  Future<bool> dummyRecharge(String userId, double amount) async {
    state = state.copyWith(
      isRecharging: true,
      error: null,
      pendingRechargeAmount: amount,
    );

    try {
      final success = await WalletService.dummyRecharge(userId, amount);

      if (success) {
        state = state.copyWith(
          isRecharging: false,
          pendingRechargeAmount: null,
        );

        // Refresh wallet data
        ref.invalidate(currentUserWalletInfoProvider);
        ref.invalidate(currentUserWalletBalanceProvider);
        ref.invalidate(currentUserTransactionHistoryProvider);

        return true;
      } else {
        state = state.copyWith(
          isRecharging: false,
          error: 'Recharge failed. Please try again.',
          pendingRechargeAmount: null,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isRecharging: false,
        error: e.toString(),
        pendingRechargeAmount: null,
      );
      return false;
    }
  }

  // Check if user can afford amount
  Future<bool> canAfford(String userId, double amount) async {
    try {
      return await WalletService.canAfford(userId, amount);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // Deduct from wallet
  Future<bool> deductFromWallet(
    String userId,
    double amount,
    String description, {
    String? referenceId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await WalletService.deductFromWallet(
        userId,
        amount,
        description,
        referenceId: referenceId,
      );

      if (success) {
        state = state.copyWith(isLoading: false);

        // Refresh wallet data
        ref.invalidate(currentUserWalletInfoProvider);
        ref.invalidate(currentUserWalletBalanceProvider);
        ref.invalidate(currentUserTransactionHistoryProvider);

        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to deduct amount from wallet',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Add refund to wallet
  Future<bool> addRefund(
    String userId,
    double amount,
    String description, {
    String? referenceId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await WalletService.addRefund(
        userId,
        amount,
        description,
        referenceId: referenceId,
      );

      if (success) {
        state = state.copyWith(isLoading: false);

        // Refresh wallet data
        ref.invalidate(currentUserWalletInfoProvider);
        ref.invalidate(currentUserWalletBalanceProvider);
        ref.invalidate(currentUserTransactionHistoryProvider);

        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to add refund to wallet',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Create wallet for new user
  Future<bool> createWallet(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await WalletService.createWallet(userId);

      if (success) {
        state = state.copyWith(isLoading: false);

        // Refresh wallet data
        ref.invalidate(currentUserWalletInfoProvider);
        ref.invalidate(currentUserWalletBalanceProvider);

        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to create wallet',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Set wallet status (freeze/unfreeze)
  Future<bool> setWalletStatus(String userId, bool isActive) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await WalletService.setWalletStatus(userId, isActive);

      if (success) {
        state = state.copyWith(isLoading: false);

        // Refresh wallet data
        ref.invalidate(currentUserWalletInfoProvider);

        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to update wallet status',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Validate recharge amount
  bool validateRechargeAmount(double amount) {
    if (amount < 100) {
      state = state.copyWith(error: 'Minimum recharge amount is ₹100');
      return false;
    }
    if (amount > 10000) {
      state = state.copyWith(error: 'Maximum recharge amount is ₹10,000');
      return false;
    }
    state = state.copyWith(error: null);
    return true;
  }

  Future<bool> deductAmount(String userId, double amount, String description,
      {String? referenceId}) {
    return deductFromWallet(userId, amount, description,
        referenceId: referenceId);
  }

  double get balance => state.balance;
}

// Can afford provider - checks if user can afford a specific amount
final canAffordProvider =
    FutureProvider.family<bool, Map<String, dynamic>>((ref, params) {
  final userId = params['userId'] as String;
  final amount = params['amount'] as double;
  return WalletService.canAfford(userId, amount);
});

// Current user can afford provider
final currentUserCanAffordProvider =
    FutureProvider.family<bool, double>((ref, amount) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Future.value(false);
  return WalletService.canAfford(user.uid, amount);
});

// Transaction filter provider
final transactionFilterProvider =
    StateProvider<TransactionType?>((ref) => null);

// Filtered transactions provider
final filteredTransactionsProvider =
    Provider.family<List<WalletTransaction>, List<WalletTransaction>>(
        (ref, transactions) {
  final filter = ref.watch(transactionFilterProvider);
  if (filter == null) return transactions;
  return transactions.where((t) => t.type == filter).toList();
});

// Transaction stats provider
final transactionStatsProvider =
    Provider.family<Map<String, dynamic>, List<WalletTransaction>>(
        (ref, transactions) {
  double totalCredits = 0;
  double totalDebits = 0;
  int totalTransactions = transactions.length;

  for (final transaction in transactions) {
    if (transaction.isCredit) {
      totalCredits += transaction.amount;
    } else if (transaction.isDebit) {
      totalDebits += transaction.amount;
    }
  }

  return {
    'totalCredits': totalCredits,
    'totalDebits': totalDebits,
    'totalTransactions': totalTransactions,
    'netAmount': totalCredits - totalDebits,
  };
});

// Low balance warning provider
final lowBalanceWarningProvider = Provider.family<bool, double>((ref, balance) {
  return balance < 500; // Show warning when balance is below ₹500
});

// Current user low balance warning provider
final currentUserLowBalanceWarningProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;

  final balance = await ref.watch(currentUserWalletBalanceProvider.future);
  return ref.watch(lowBalanceWarningProvider(balance));
});

// Legacy alias for backward compatibility with older widgets
final walletProvider = walletControllerProvider;

extension WalletControllerLegacy on WalletController {
  Future<bool> deductAmount(String userId, double amount, String description,
      {String? referenceId}) {
    return deductFromWallet(userId, amount, description,
        referenceId: referenceId);
  }

  double get balance => state.balance;
}
