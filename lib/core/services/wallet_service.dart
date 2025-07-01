import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../models/wallet_model.dart';

class WalletService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _uuid = Uuid();

  // Get wallet info
  static Future<WalletInfo?> getWalletInfo(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('wallet')
          .doc('info')
          .get();

      if (doc.exists) {
        return WalletInfo.fromMap(doc.data()!, userId);
      }
      return null;
    } catch (e) {
      print('Error getting wallet info: $e');
      return null;
    }
  }

  // Get wallet balance
  static Future<double> getWalletBalance(String userId) async {
    final walletInfo = await getWalletInfo(userId);
    return walletInfo?.balance ?? 0.0;
  }

  // Check if user can afford amount
  static Future<bool> canAfford(String userId, double amount) async {
    final balance = await getWalletBalance(userId);
    return balance >= amount;
  }

  // DUMMY RECHARGE - Not connected to real payment gateway
  static Future<bool> dummyRecharge(String userId, double amount) async {
    if (amount < 100 || amount > 10000) {
      throw Exception('Amount must be between ₹100 and ₹10,000');
    }

    try {
      return await _firestore.runTransaction((transaction) async {
        final walletRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('wallet')
            .doc('info');

        final walletDoc = await transaction.get(walletRef);
        
        if (!walletDoc.exists) {
          // Create wallet if doesn't exist
          transaction.set(walletRef, {
            'balance': amount,
            'currency': 'INR',
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        } else {
          final currentBalance = (walletDoc.data()?['balance'] ?? 0).toDouble();
          transaction.update(walletRef, {
            'balance': currentBalance + amount,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }

        // Add transaction record
        final transactionId = _uuid.v4();
        final transactionRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('wallet')
            .doc('info')
            .collection('transactions')
            .doc(transactionId);

        transaction.set(transactionRef, {
          'walletId': 'info',
          'type': 'CREDIT',
          'amount': amount,
          'description': 'Wallet Recharge (DUMMY)',
          'status': 'COMPLETED',
          'paymentMethod': 'dummy_payment',
          'gatewayTransactionId': 'dummy_${DateTime.now().millisecondsSinceEpoch}',
          'createdAt': FieldValue.serverTimestamp(),
          'completedAt': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } catch (e) {
      print('Error in dummy recharge: $e');
      return false;
    }
  }

  // Deduct amount from wallet
  static Future<bool> deductFromWallet(
    String userId, 
    double amount, 
    String description, {
    String? referenceId,
  }) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        final walletRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('wallet')
            .doc('info');

        final walletDoc = await transaction.get(walletRef);
        
        if (!walletDoc.exists) {
          throw Exception('Wallet not found');
        }

        final currentBalance = (walletDoc.data()?['balance'] ?? 0).toDouble();
        
        if (currentBalance < amount) {
          throw Exception('Insufficient balance');
        }

        // Update wallet balance
        transaction.update(walletRef, {
          'balance': currentBalance - amount,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        // Add transaction record
        final transactionId = _uuid.v4();
        final transactionRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('wallet')
            .doc('info')
            .collection('transactions')
            .doc(transactionId);

        transaction.set(transactionRef, {
          'walletId': 'info',
          'type': 'DEBIT',
          'amount': amount,
          'description': description,
          'status': 'COMPLETED',
          'referenceId': referenceId,
          'createdAt': FieldValue.serverTimestamp(),
          'completedAt': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } catch (e) {
      print('Error deducting from wallet: $e');
      return false;
    }
  }

  // Add refund to wallet
  static Future<bool> addRefund(
    String userId, 
    double amount, 
    String description, {
    String? referenceId,
  }) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        final walletRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('wallet')
            .doc('info');

        final walletDoc = await transaction.get(walletRef);
        
        if (!walletDoc.exists) {
          throw Exception('Wallet not found');
        }

        final currentBalance = (walletDoc.data()?['balance'] ?? 0).toDouble();

        // Update wallet balance
        transaction.update(walletRef, {
          'balance': currentBalance + amount,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        // Add transaction record
        final transactionId = _uuid.v4();
        final transactionRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('wallet')
            .doc('info')
            .collection('transactions')
            .doc(transactionId);

        transaction.set(transactionRef, {
          'walletId': 'info',
          'type': 'REFUND',
          'amount': amount,
          'description': description,
          'status': 'COMPLETED',
          'referenceId': referenceId,
          'createdAt': FieldValue.serverTimestamp(),
          'completedAt': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } catch (e) {
      print('Error adding refund: $e');
      return false;
    }
  }

  // Get transaction history
  static Stream<List<WalletTransaction>> getTransactionHistory(String userId, {int limit = 50}) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('wallet')
        .doc('info')
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WalletTransaction.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get specific transaction
  static Future<WalletTransaction?> getTransaction(String userId, String transactionId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('wallet')
          .doc('info')
          .collection('transactions')
          .doc(transactionId)
          .get();

      if (doc.exists) {
        return WalletTransaction.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting transaction: $e');
      return null;
    }
  }

  // Get wallet statistics
  static Future<Map<String, dynamic>> getWalletStats(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('wallet')
          .doc('info')
          .collection('transactions')
          .get();

      double totalCredits = 0;
      double totalDebits = 0;
      int totalTransactions = snapshot.docs.length;

      for (final doc in snapshot.docs) {
        final transaction = WalletTransaction.fromMap(doc.data(), doc.id);
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
    } catch (e) {
      print('Error getting wallet stats: $e');
      return {};
    }
  }

  // Create wallet for new user
  static Future<bool> createWallet(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('wallet')
          .doc('info')
          .set({
        'balance': 0.0,
        'currency': 'INR',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error creating wallet: $e');
      return false;
    }
  }

  // Freeze/Unfreeze wallet
  static Future<bool> setWalletStatus(String userId, bool isActive) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('wallet')
          .doc('info')
          .update({
        'isActive': isActive,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating wallet status: $e');
      return false;
    }
  }

  // Get monthly transaction summary
  static Future<Map<String, double>> getMonthlyTransactionSummary(String userId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('wallet')
          .doc('info')
          .collection('transactions')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .get();

      double credits = 0;
      double debits = 0;

      for (final doc in snapshot.docs) {
        final transaction = WalletTransaction.fromMap(doc.data(), doc.id);
        if (transaction.isCredit) {
          credits += transaction.amount;
        } else if (transaction.isDebit) {
          debits += transaction.amount;
        }
      }

      return {
        'credits': credits,
        'debits': debits,
        'net': credits - debits,
      };
    } catch (e) {
      print('Error getting monthly summary: $e');
      return {'credits': 0, 'debits': 0, 'net': 0};
    }
  }
}