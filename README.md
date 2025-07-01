# 🏥 ChildcareHub Flutter App

A comprehensive healthcare management platform built with Flutter, designed specifically for pediatric consultations and family healthcare management.

## 📱 Features

### 👨‍👩‍👧‍👦 **For Parents**
- **Child Profile Management** - Add and manage multiple children with medical history
- **Instant Consultations** - Book immediate video consultations with available doctors
- **Scheduled Appointments** - Plan consultations for specific dates and times
- **Consultation History** - Track all past and upcoming appointments
- **Integrated Wallet** - Secure payment system for consultation fees
- **Real-time Notifications** - Stay updated on consultation status

### 👨‍⚕️ **For Doctors**
- **Professional Profile** - Showcase specialization, experience, and availability
- **Consultation Management** - Accept, reject, and manage consultation requests
- **Video Calling** - High-quality video consultations with patients
- **Patient Records** - Access patient information during consultations
- **Availability Management** - Set and update available time slots
- **Earnings Dashboard** - Track consultation revenue and statistics

### 👥 **For Administrators**
- **User Management** - Manage parent and doctor accounts
- **Doctor Onboarding** - Create and verify doctor profiles
- **System Configuration** - Manage consultation fees and app settings
- **Analytics Dashboard** - Monitor platform usage and performance
- **Security Management** - Oversee data protection and compliance

## 🛠️ Tech Stack

### **Frontend**
- **Flutter** - Cross-platform mobile development
- **Riverpod** - State management and dependency injection
- **Go Router** - Type-safe navigation and routing
- **Material Design** - Modern and accessible UI components

### **Backend & Services**
- **Firebase Authentication** - Secure user authentication
- **Cloud Firestore** - NoSQL database with real-time sync
- **Firebase Storage** - File and image storage
- **Firebase Cloud Messaging** - Push notifications
- **Zego Cloud** - Video calling and real-time communication

### **Additional Integrations**
- **Payment Gateway** - Secure payment processing
- **SMS/Email Services** - Multi-channel notifications
- **Analytics** - User behavior and performance tracking

## 🚀 Getting Started

### **Prerequisites**
- Flutter SDK (3.0.0 or higher)
- Dart SDK (2.17.0 or higher)
- Android Studio / VS Code
- Git
- Firebase CLI (for deployment)

### **Installation**

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd new_childcarehub_flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   ```bash
   # Install Firebase CLI
   npm install -g firebase-tools
   
   # Login to Firebase
   firebase login
   
   # Initialize Firebase (if not already done)
   firebase init
   ```

4. **Set up environment variables**
   ```bash
   # Copy environment template
   cp .env.example .env
   
   # Edit .env with your configuration
   # Add Firebase config, Zego credentials, etc.
   ```

5. **Configure platform-specific files**
   - **Android**: Add `google-services.json` to `android/app/`
   - **iOS**: Add `GoogleService-Info.plist` to `ios/Runner/`

6. **Run the application**
   ```bash
   # Debug mode
   flutter run
   
   # Release mode
   flutter run --release
   ```

## 🔧 Configuration

### **Environment Variables**
Create `.env` file in the project root:
```env
# Firebase Configuration
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_APP_ID=your_app_id

# Zego Cloud Configuration
ZEGO_APP_ID=your_zego_app_id
ZEGO_APP_SIGN=your_zego_app_sign

# Payment Gateway
PAYMENT_GATEWAY_KEY=your_payment_key
PAYMENT_GATEWAY_SECRET=your_payment_secret
```

### **Firebase Setup**
1. Create a new Firebase project
2. Enable Authentication (Email/Password, Google Sign-In)
3. Set up Cloud Firestore database
4. Configure Firebase Storage
5. Deploy Firestore security rules:
   ```bash
   firebase deploy --only firestore:rules
   ```

### **Zego Cloud Setup**
1. Create account at [Zego Cloud](https://www.zegocloud.com/)
2. Create a new project for video calling
3. Get App ID and App Sign from console
4. Add credentials to environment variables

## 🗄️ Database Structure

### **Collections**
```
📦 Firestore Database
├── 👥 users/{userId}
│   ├── 👶 children/{childId}
│   ├── 💰 wallet/
│   │   ├── 📄 info
│   │   └── 💳 transactions/{transactionId}
│   └── 🔔 notifications/{notificationId}
├── 👨‍⚕️ doctors/{doctorId}
│   └── 📅 reservedSlots/{slotId}
├── 🏥 consultations/{consultationId}
├── ⚙️ appConfig/{configId}
└── 🔔 notifications/{notificationId}
```

## 🔒 Security

### **Firestore Security Rules**
Comprehensive security rules are implemented to ensure:
- **Data Privacy** - Users can only access their own data
- **Role-based Access** - Different permissions for parents, doctors, and admins
- **Medical Data Protection** - HIPAA-compliant access controls
- **Financial Security** - Protected wallet and transaction data

### **Authentication**
- Multi-factor authentication support
- Secure session management
- Role-based authorization
- Token-based API access

## 🧪 Testing

### **Run Tests**
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Widget tests
flutter test test/
```

### **Test Coverage**
```bash
# Generate coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## 📦 Building & Deployment

### **Android**
```bash
# Build APK
flutter build apk --release

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

### **iOS**
```bash
# Build iOS app
flutter build ios --release
```

### **Web**
```bash
# Build web version
flutter build web --release
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### **Code Style**
- Follow [Flutter style guide](https://flutter.dev/docs/development/tools/formatting)
- Use meaningful variable and function names
- Add comments for complex logic
- Write tests for new features

## 📝 License

This project is proprietary software. All rights reserved.

## 🆘 Support

For support and queries:
- **Email**: support@childcarehub.com
- **Documentation**: [Project Wiki](link-to-wiki)
- **Issues**: [GitHub Issues](link-to-issues)

## 🔄 Changelog

### **Version 1.0.0** (Initial Release)
- Multi-role authentication system
- Video consultation platform
- Wallet integration
- Doctor management system
- Real-time notifications
- Comprehensive security implementation

---

**Built with ❤️ for better healthcare management**