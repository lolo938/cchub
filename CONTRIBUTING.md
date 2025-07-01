# Contributing to ChildcareHub Flutter App

Thank you for your interest in contributing to ChildcareHub! This document provides guidelines and instructions for contributing to the project.

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0.0+)
- Dart SDK (2.17.0+)
- Git
- Firebase CLI
- Android Studio / VS Code

### Development Setup
1. Fork the repository
2. Clone your fork: `git clone <your-fork-url>`
3. Create a development branch: `git checkout -b feature/your-feature-name`
4. Install dependencies: `flutter pub get`
5. Set up your development environment variables

## 📋 Code Standards

### Dart/Flutter Code Style
- Follow the [official Flutter style guide](https://flutter.dev/docs/development/tools/formatting)
- Use `dart format` to format your code
- Run `dart analyze` to check for issues
- Maintain consistent naming conventions:
  - `camelCase` for variables and functions
  - `PascalCase` for classes and constructors
  - `snake_case` for file names

### Code Quality
- Write clear, self-documenting code
- Add meaningful comments for complex logic
- Keep functions small and focused (single responsibility)
- Use meaningful variable and function names
- Avoid deep nesting (max 3-4 levels)

### Testing Requirements
- Write unit tests for all business logic
- Add widget tests for UI components
- Ensure integration tests pass
- Maintain minimum 80% code coverage
- Test edge cases and error scenarios

## 🏗️ Project Structure

```
lib/
├── core/                 # Core utilities and configurations
│   ├── config/          # Environment and app configuration
│   ├── constants/       # App-wide constants
│   ├── routing/         # Navigation and routing
│   ├── services/        # External services and APIs
│   └── themes/          # UI themes and styling
├── models/              # Data models and entities
├── providers/           # State management (Riverpod)
├── screens/             # UI screens and pages
├── widgets/             # Reusable UI components
└── features/            # Feature-specific modules
```

## 🔄 Development Workflow

### Branch Naming
- `feature/feature-name` - New features
- `bugfix/issue-description` - Bug fixes
- `hotfix/critical-issue` - Critical production fixes
- `refactor/component-name` - Code refactoring
- `docs/update-description` - Documentation updates

### Commit Messages
Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
type(scope): description

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(auth): add multi-factor authentication
fix(consultation): resolve video call connection issues
docs(readme): update installation instructions
refactor(providers): simplify doctor state management
```

## 🧪 Testing Guidelines

### Unit Tests
- Test all business logic and utility functions
- Use descriptive test names
- Follow AAA pattern (Arrange, Act, Assert)
- Mock external dependencies

```dart
group('UserService', () {
  test('should create user with valid data', () {
    // Arrange
    final userData = UserData(name: 'John', email: 'john@example.com');
    
    // Act
    final result = UserService.createUser(userData);
    
    // Assert
    expect(result.isSuccess, true);
    expect(result.user.name, 'John');
  });
});
```

### Widget Tests
- Test UI components and user interactions
- Verify widget rendering and state changes
- Test accessibility features

### Integration Tests
- Test complete user flows
- Verify API integrations
- Test real-world scenarios

## 🔒 Security Guidelines

### Sensitive Data
- Never commit API keys, passwords, or secrets
- Use environment variables for configuration
- Ensure `.env` files are in `.gitignore`
- Review code for potential security vulnerabilities

### Data Protection
- Follow HIPAA compliance for medical data
- Implement proper input validation
- Use secure communication (HTTPS/WSS)
- Log security-relevant events appropriately

## 📱 Platform-Specific Guidelines

### Android
- Follow Material Design principles
- Test on multiple Android versions
- Optimize for different screen sizes
- Handle permissions properly

### iOS
- Follow Apple Human Interface Guidelines
- Test on different iOS versions and devices
- Implement proper iOS-specific features
- Handle App Store review guidelines

## 🎯 Feature Development

### New Feature Checklist
- [ ] Create feature branch from `main`
- [ ] Implement feature with tests
- [ ] Update documentation
- [ ] Add error handling
- [ ] Test on multiple platforms
- [ ] Update CHANGELOG.md
- [ ] Create pull request

### API Integration
- Use proper error handling
- Implement retry mechanisms
- Add appropriate timeouts
- Handle offline scenarios
- Document API endpoints used

## 🐛 Bug Reports

### Bug Report Template
```markdown
**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

**Expected behavior**
A clear description of what you expected to happen.

**Screenshots**
If applicable, add screenshots to help explain your problem.

**Device Information:**
- Device: [e.g. iPhone 12, Samsung Galaxy S21]
- OS: [e.g. iOS 15.1, Android 12]
- App Version: [e.g. 1.0.0]

**Additional context**
Add any other context about the problem here.
```

## 📝 Pull Request Process

### Before Submitting
1. Ensure all tests pass
2. Run code analysis (`dart analyze`)
3. Format code (`dart format`)
4. Update documentation if needed
5. Add appropriate tests
6. Test on multiple platforms

### Pull Request Template
```markdown
## Description
Brief description of the changes made.

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Widget tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing completed

## Screenshots (if applicable)
Add screenshots of UI changes.

## Checklist
- [ ] My code follows the project's style guidelines
- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
```

## 🚫 What Not to Contribute

- Code that doesn't follow our style guidelines
- Features without proper tests
- Changes that break existing functionality
- Commits with sensitive data (API keys, passwords)
- Large refactors without prior discussion
- Features that don't align with project goals

## 📞 Getting Help

- **Documentation**: Check project README and wiki
- **Issues**: Search existing issues before creating new ones
- **Discussions**: Use GitHub Discussions for questions
- **Email**: Contact maintainers at dev@childcarehub.com

## 🏆 Recognition

Contributors who make significant contributions will be:
- Added to the CONTRIBUTORS.md file
- Mentioned in release notes
- Invited to join the core team (for regular contributors)

Thank you for contributing to ChildcareHub! 🚀