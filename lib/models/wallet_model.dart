import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  credit,
  debit,
  refund,
}

enum TransactionStatus {
  pending,
  completed,
  failed,
  cancelled,
}

class WalletInfo {
  final String userId;
  final double balance;
  final String currency;
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastUpdated;

  WalletInfo({
    required this.userId,
    required this.balance,
    this.currency = 'INR',
    this.isActive = true,
    required this.createdAt,
    required this.lastUpdated,
  });

  factory WalletInfo.fromMap(Map<String, dynamic> map, String userId) {
    return WalletInfo(
      userId: userId,
      balance: (map['balance'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'INR',
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'balance': balance,
      'currency': currency,
      'isActive': isActive,
      'createdAt': createdAt,
      'lastUpdated': lastUpdated,
    };
  }

  String get formattedBalance => '₹${balance.toStringAsFixed(2)}';

  bool get hasSufficientBalance => balance > 0;

  bool canAfford(double amount) => balance >= amount;

  WalletInfo copyWith({
    double? balance,
    String? currency,
    bool? isActive,
    DateTime? lastUpdated,
  }) {
    return WalletInfo(
      userId: userId,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'WalletInfo(userId: $userId, balance: $formattedBalance, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WalletInfo && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}

class WalletTransaction {
  final String id;
  final String walletId;
  final TransactionType type;
  final double amount;
  final String description;
  final TransactionStatus status;
  final String? referenceId;
  final String? paymentMethod;
  final String? gatewayTransactionId;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? completedAt;

  WalletTransaction({
    required this.id,
    required this.walletId,
    required this.type,
    required this.amount,
    required this.description,
    required this.status,
    this.referenceId,
    this.paymentMethod,
    this.gatewayTransactionId,
    this.metadata,
    required this.createdAt,
    this.completedAt,
  });

  factory WalletTransaction.fromMap(Map<String, dynamic> map, String id) {
    return WalletTransaction(
      id: id,
      walletId: map['walletId'] ?? '',
      type: TransactionType.values.firstWhere(
        (type) => type.toString().split('.').last == map['type']?.toLowerCase(),
        orElse: () => TransactionType.credit,
      ),
      amount: (map['amount'] ?? 0).toDouble(),
      description: map['description'] ?? '',
      status: TransactionStatus.values.firstWhere(
        (status) => status.toString().split('.').last == map['status']?.toLowerCase(),
        orElse: () => TransactionStatus.pending,
      ),
      referenceId: map['referenceId'],
      paymentMethod: map['paymentMethod'],
      gatewayTransactionId: map['gatewayTransactionId'],
      metadata: map['metadata'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'walletId': walletId,
      'type': type.toString().split('.').last.toUpperCase(),
      'amount': amount,
      'description': description,
      'status': status.toString().split('.').last.toUpperCase(),
      'referenceId': referenceId,
      'paymentMethod': paymentMethod,
      'gatewayTransactionId': gatewayTransactionId,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  String get typeDisplayName {
    switch (type) {
      case TransactionType.credit:
        return 'Credit';
      case TransactionType.debit:
        return 'Debit';
      case TransactionType.refund:
        return 'Refund';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.failed:
        return 'Failed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get formattedAmount {
    final prefix = type == TransactionType.credit || type == TransactionType.refund ? '+' : '-';
    return '$prefix₹${amount.toStringAsFixed(2)}';
  }

  bool get isCredit => type == TransactionType.credit || type == TransactionType.refund;
  bool get isDebit => type == TransactionType.debit;
  bool get isCompleted => status == TransactionStatus.completed;
  bool get isPending => status == TransactionStatus.pending;
  bool get isFailed => status == TransactionStatus.failed;

  WalletTransaction copyWith({
    TransactionStatus? status,
    DateTime? completedAt,
    String? gatewayTransactionId,
    Map<String, dynamic>? metadata,
  }) {
    return WalletTransaction(
      id: id,
      walletId: walletId,
      type: type,
      amount: amount,
      description: description,
      status: status ?? this.status,
      referenceId: referenceId,
      paymentMethod: paymentMethod,
      gatewayTransactionId: gatewayTransactionId ?? this.gatewayTransactionId,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  String toString() {
    return 'WalletTransaction(id: $id, type: $typeDisplayName, amount: $formattedAmount, status: $statusDisplayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WalletTransaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}