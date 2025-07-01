# Firestore Security Rules Documentation

## Overview

This document explains the comprehensive Firestore security rules implemented for the ChildcareHub Flutter application. The rules are designed to enforce proper access controls while maintaining functionality for all user roles.

## User Roles and Permissions

### 1. **Parent (PARENT)**
- **Default role** for new user registrations
- **Can read**: Own profile, own children, all active doctors, own consultations, own wallet data, own notifications
- **Can write**: Own profile (except role/financial data), own children, create consultations, mark notifications as read
- **Cannot**: Access other users' data, modify doctor profiles, change own role, directly modify wallet balance

### 2. **Doctor (DOCTOR)**
- **Can read**: Own doctor profile, assigned consultations, patient children data (during consultations), basic user info for consultations
- **Can write**: Own profile (limited fields), consultation status updates, own reserved time slots
- **Cannot**: Access wallet data, read all user data, modify other doctors' profiles

### 3. **Admin (ADMIN)**
- **Full access** to all collections for management purposes
- **Can read**: All users, doctors, consultations, analytics, system logs
- **Can write**: Doctor profiles, user roles, app configuration, global notifications, financial data
- **Special permissions**: Create doctor accounts, manage system settings, access audit logs

## Collection-Specific Rules

### Users Collection (`/users/{userId}`)

```dart
// Structure
{
  id: String,
  name: String,
  email: String,
  role: String, // "PARENT", "DOCTOR", "ADMIN"
  isActive: bool,
  walletBalance: double, // Protected field
  children: [...], // Embedded or subcollection
  createdAt: Timestamp
}
```

**Security Features:**
- ✅ Users can only read/write their own profile
- ✅ Role changes require admin privileges
- ✅ Wallet balance cannot be modified directly by users
- ✅ New users automatically get 'PARENT' role
- ✅ Doctors can read basic user info only for active consultations

### Children Subcollection (`/users/{userId}/children/{childId}`)

```dart
// Structure
{
  id: String,
  parentId: String, // Must match userId
  name: String,
  dateOfBirth: Timestamp,
  medicalHistory: List<String>,
  allergies: List<String>
}
```

**Security Features:**
- ✅ Only parent can access their children's data
- ✅ parentId field must match the user document ID
- ✅ Complete isolation between families
- ✅ Medical data is protected and private

### Wallet Subcollection (`/users/{userId}/wallet/{walletDoc}`)

```dart
// Structure - /users/{userId}/wallet/info
{
  balance: double,
  currency: String,
  isActive: bool,
  lastUpdated: Timestamp
}

// Transactions - /users/{userId}/wallet/info/transactions/{transactionId}
{
  type: String, // "CREDIT", "DEBIT", "REFUND"
  amount: double,
  status: String,
  referenceId: String, // Links to consultation
  createdAt: Timestamp
}
```

**Security Features:**
- ✅ Only owner and admin can read wallet data
- ✅ Direct wallet modifications require admin privileges
- ✅ Transactions are append-only (create but no update/delete)
- ✅ All financial operations are auditable
- ✅ Reference IDs link transactions to consultations

### Doctors Collection (`/doctors/{doctorId}`)

```dart
// Structure
{
  id: String,
  name: String,
  specialization: String,
  rating: double,
  isActive: bool,
  isOnline: bool,
  consultationFee: double,
  availability: Map<String, List<String>>,
  createdBy: String // Admin who created this doctor
}
```

**Security Features:**
- ✅ Public read access for active doctors (discovery)
- ✅ Admin-only creation with createdBy tracking
- ✅ Doctors can update limited fields only (availability, online status)
- ✅ Rating and consultation fees are admin-managed
- ✅ Reserved slots are private to each doctor

### Consultations Collection (`/consultations/{consultationId}`)

```dart
// Structure
{
  id: String,
  parentId: String,
  doctorId: String,
  childId: String,
  status: String,
  fee: double,
  type: String, // "INSTANT", "SCHEDULED", "EMERGENCY"
  requestedAt: Timestamp,
  completedAt: Timestamp?
}
```

**Security Features:**
- ✅ Only consultation participants can access data
- ✅ Parents can create new consultations
- ✅ Status updates limited to participants
- ✅ Financial data (fees) are protected
- ✅ Admin has full access for support/management

## Advanced Security Features

### 1. **Role-Based Field Restrictions**
```javascript
// Users can update profile but not role or financial data
allow update: if isOwner(userId) && 
                 isValidRoleChange(request.resource.data) &&
                 request.resource.data.walletBalance == resource.data.walletBalance;
```

### 2. **Temporal Access Controls**
- Consultation data access may be time-limited
- Expired consultations have restricted modification rights
- Reserved slots are protected during active bookings

### 3. **Cross-Collection Validation**
```javascript
// Ensure consultation participants can access related data
function isConsultationParticipant(consultation) {
  return request.auth.uid == consultation.parentId || 
         request.auth.uid == consultation.doctorId;
}
```

### 4. **Financial Data Protection**
- Wallet balances cannot be modified directly by users
- All transactions require admin privileges or cloud functions
- Transaction history is immutable (append-only)

### 5. **Medical Data Privacy**
- Children's medical data accessible only to parents
- Doctor access limited to active consultation periods
- Sensitive health information is properly isolated

## Cloud Functions Integration

Some operations should be handled by Cloud Functions with admin privileges:

### Recommended Cloud Functions:
1. **Wallet Operations** (`processPayment`, `refundConsultation`)
2. **Consultation Matching** (`assignDoctorToConsultation`)
3. **Notification Delivery** (`sendConsultationNotification`)
4. **Data Analytics** (`generateReports`, `updateDoctorRatings`)
5. **Audit Logging** (`logSecurityEvents`, `trackDataAccess`)

## Security Best Practices Implemented

### ✅ **Authentication Required**
- All operations require valid Firebase Authentication
- No anonymous access to sensitive data

### ✅ **Principle of Least Privilege**
- Users have minimal required permissions
- Role-based access controls
- Field-level restrictions

### ✅ **Data Isolation**
- Family data is completely isolated
- Medical information is private
- Financial data is protected

### ✅ **Audit Trail**
- All financial transactions are logged
- Doctor creation tracked with createdBy
- System events recorded

### ✅ **Input Validation**
- Role changes validated
- Required fields enforced
- Data type validation

### ✅ **Defense in Depth**
- Multiple layers of security checks
- Helper functions for complex logic
- Consistent pattern enforcement

## Testing Your Security Rules

Use Firebase Emulator Suite to test these rules:

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Initialize Firebase emulators
firebase init emulators

# Start emulators with security rules
firebase emulators:start --only firestore
```

### Test Scenarios:
1. **Parent Access**: Verify parents can only access their own data
2. **Doctor Permissions**: Test doctor profile updates and consultation access
3. **Admin Operations**: Verify admin can perform system operations
4. **Cross-User Access**: Ensure users cannot access other users' data
5. **Financial Security**: Test wallet operation restrictions

## Monitoring and Maintenance

### Regular Security Audits:
1. Review access logs for unusual patterns
2. Monitor failed authentication attempts
3. Validate rule effectiveness with real usage data
4. Update rules as features evolve

### Key Metrics to Monitor:
- Unauthorized access attempts
- Financial transaction patterns
- Data access frequency by role
- Rule violation incidents

This comprehensive security implementation ensures your ChildcareHub application maintains the highest standards of data protection while providing seamless functionality for all user roles.