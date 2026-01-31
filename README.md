# SMART SE2026 - Agentic AI for Census Analysis

<div align="center">
  <img src="assets/icons/favicon.png" alt="SMART SE2026 Logo" width="120"/>

[![Flutter](https://img.shields.io/badge/Flutter-3.10.1+-02569B?style=for-the-badge&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10.1+-0175C2?style=for-the-badge&logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-Private-red?style=for-the-badge)](LICENSE)

**AI-Powered Assistant for Indonesian Economic Census 2026 Analysis**

[Features](#features) • [Installation](#installation) • [Architecture](#architecture) • [Documentation](#documentation)
</div>

---

## 📋 Overview

SMART SE2026 is a sophisticated Flutter mobile application that leverages AI to provide intelligent analysis and insights for the Indonesian Economic Census 2026 (Sensus Ekonomi 2026). The app features an agentic AI assistant powered by a backend LLM system that can analyze census data, generate visualizations, provide policy insights, and offer data-driven recommendations.

### Key Highlights

- 🤖 **AI-Powered Chat Interface** - Interactive conversational AI for census data analysis
- 📊 **Dynamic Visualizations** - Real-time charts and graphs (bar, line, pie, treemap, heatmap, radar)
- 💡 **Intelligent Insights** - AI-generated insights from census data
- 📈 **Policy Recommendations** - Data-driven policy suggestions with implementation steps
- 🔒 **Secure Authentication** - Email/Password and Google Sign-In support
- 🌓 **Theme Support** - Light, Dark, and System adaptive themes
- 💾 **Session Management** - Persistent chat history and session recovery
- 📱 **Modern UI/UX** - Beautiful glassmorphic design with smooth animations

---

## ✨ Features

### 🎯 Core Features

#### 1. **AI Chat Assistant**
- Natural language processing for census-related queries
- Context-aware responses based on Indonesian Economic Census data
- Multi-turn conversations with session persistence
- Real-time streaming responses

#### 2. **Data Visualization**
- **Chart Types**: Bar, Line, Pie, Treemap, Heatmap, Radar
- Interactive and expandable visualizations
- ECharts backend integration with fl_chart rendering
- Responsive design for mobile screens

#### 3. **Insights & Analytics**
- AI-generated key insights from census data
- Confidence scoring for insights
- Supporting data references
- Expandable insight cards with detailed explanations

#### 4. **Policy Recommendations**
- Priority-based policy suggestions (High, Medium, Low)
- Detailed implementation steps
- Impact assessments
- Category-based organization (Economic, Social, Environmental, etc.)

#### 5. **Session Management**
- Automatic session creation and persistence
- Session history with timestamps
- Search and filter capabilities
- Batch delete operations
- Export functionality (JSON format)

### 🔐 Authentication

- **Email/Password Authentication**
    - Secure registration and login
    - Password validation (minimum 6 characters)
    - Email verification support

- **Google Sign-In**
    - One-tap Google authentication
    - Profile picture integration
    - Seamless user experience

### 🎨 Design Features

- **Modern UI Components**
    - Glassmorphic cards with backdrop blur
    - Gradient buttons and interactive elements
    - Smooth page transitions and animations
    - Custom text fields with validation

- **Theme System**
    - Light mode with warm tones
    - Dark mode with deep blacks
    - System adaptive theme
    - Persistent theme preferences

### 📱 User Experience

- **Welcome Screen** with suggestion chips
- **Voice Input** support (UI ready)
- **Message Actions**: Copy, feedback (thumbs up/down)
- **Profile Management** with statistics
- **Settings Panel** for app customization

---

## 🏗️ Architecture

### Tech Stack

#### Frontend (Flutter)
```
smart_se2026_agentic_ai/
├── lib/
│   ├── core/
│   │   ├── models/           # Data models (ChatMessage, PolicyRecommendation, etc.)
│   │   ├── providers/        # State management (Auth, Chat, Theme)
│   │   ├── services/         # API and Storage services
│   │   └── theme/           # App themes and styling
│   ├── features/
│   │   ├── auth/            # Login & Registration screens
│   │   ├── chat/            # Chat interface and components
│   │   ├── profile/         # User profile management
│   │   ├── settings/        # App settings
│   │   ├── splash/          # Splash screen
│   │   └── widgets/         # Reusable UI components
│   └── main.dart
```

#### Backend Integration
- **API Base URL**: `https://smart-se26-agentic-ai.onrender.com/api`
- **Authentication**: JWT-based session tokens
- **Data Format**: JSON
- **Storage**: Secure storage for tokens, SharedPreferences for settings

### State Management

The app uses **Provider** for state management with three main providers:

1. **AuthProvider** - Manages user authentication state
2. **ChatProvider** - Handles chat sessions and messages
3. **ThemeProvider** - Controls app theme preferences

### Data Models

#### Core Models
```dart
- ChatMessage        # Individual chat messages
- ChatSession        # Chat conversation sessions
- ChatResponse       # API response wrapper
- VisualizationConfig # Chart/graph configurations
- PolicyInsight      # AI-generated insights
- PolicyRecommendation # Policy suggestions
- HealthStatus       # Backend health monitoring
```

#### Enums
```dart
- DataSource         # government, economic, news, academic, socialMedia
- PolicyCategory     # economic, social, environmental, healthcare, etc.
- ThemeModeType      # light, dark, system
```

---

## 🚀 Installation

### Prerequisites

- Flutter SDK 3.10.1 or higher
- Dart SDK 3.10.1 or higher
- Android Studio / VS Code with Flutter extensions
- Google Cloud Console project (for Google Sign-In)

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd smart_se2026_agentic_ai
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Google Sign-In** (Optional)

   For Android:
    - Create a project in [Google Cloud Console](https://console.cloud.google.com)
    - Enable Google Sign-In API
    - Add SHA-1 fingerprint from your keystore
    - Download `google-services.json` to `android/app/`

   For iOS:
    - Add GoogleService-Info.plist to `ios/Runner/`
    - Update URL schemes in Info.plist

4. **Run the app**
   ```bash
   # Debug mode
   flutter run
   
   # Release mode
   flutter run --release
   ```

### Building for Production

**Android APK:**
```bash
flutter build apk --release
```

**Android App Bundle:**
```bash
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

---

## 🔧 Configuration

### API Configuration

Update the API base URL in `lib/core/services/api_service.dart`:

```dart
static const String baseUrl = 'YOUR_BACKEND_URL/api';
```

### Theme Customization

Modify colors in `lib/core/theme/app_theme.dart`:

```dart
class AppColors {
  static const Color primaryRed = Color(0xFFEF4444);
  static const Color primaryOrange = Color(0xFFF97316);
  // ... customize colors
}
```

---

## 📱 Screenshots

<div align="center">
  <img src="screenshots/splash.png" width="200" alt="Splash Screen"/>
  <img src="screenshots/login.png" width="200" alt="Login Screen"/>
  <img src="screenshots/chat.png" width="200" alt="Chat Interface"/>
  <img src="screenshots/visualization.png" width="200" alt="Data Visualization"/>
</div>

---

## 🔌 API Integration

### Authentication Endpoints

```
POST   /api/auth/login              # Email/password login
POST   /api/auth/register           # User registration
POST   /api/auth/google/mobile      # Google Sign-In
GET    /api/auth/me                 # Get current user
POST   /api/auth/logout             # User logout
```

### Chat Endpoints

```
POST   /api/chat                    # Send message and get AI response
GET    /api/sessions                # Get all chat sessions
GET    /api/sessions/{id}           # Get specific session
DELETE /api/sessions/{id}           # Delete session
DELETE /api/sessions/batch          # Batch delete sessions
DELETE /api/sessions/all            # Delete all sessions
```

### Health & Status

```
GET    /api/health                  # Backend health check
GET    /api/scraper/status          # Data scraping status
```

### Report Generation

```
GET    /api/report/{id}/{format}    # Generate report (pdf/docx/xlsx)
GET    /api/report/{id}/preview     # Report preview
```

---

## 🧪 Testing

### Run Unit Tests
```bash
flutter test
```

### Run Integration Tests
```bash
flutter test integration_test
```

### Code Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## 📦 Dependencies

### Core Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter` | SDK | Framework |
| `provider` | ^6.1.1 | State management |
| `dio` | ^5.4.0 | HTTP client |
| `fl_chart` | ^0.66.0 | Charts & graphs |
| `google_fonts` | ^6.1.0 | Typography |
| `google_sign_in` | ^6.2.1 | Google authentication |
| `shared_preferences` | ^2.2.2 | Local storage |
| `flutter_secure_storage` | ^9.0.0 | Secure storage |
| `hive` | ^2.2.3 | NoSQL database |
| `flutter_animate` | ^4.3.0 | Animations |
| `intl` | ^0.18.1 | Internationalization |

See `pubspec.yaml` for complete dependency list.

---

## 🛠️ Development

### Project Structure

```
lib/
├── core/
│   ├── models/
│   │   └── chat_models.dart          # Data models
│   ├── providers/
│   │   ├── auth_provider.dart        # Authentication state
│   │   ├── chat_provider.dart        # Chat state
│   │   └── theme_provider.dart       # Theme state
│   ├── services/
│   │   ├── api_service.dart          # API client
│   │   └── storage_service.dart      # Storage wrapper
│   └── theme/
│       └── app_theme.dart            # App styling
├── features/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── chat/
│   │   ├── chat_screen.dart
│   │   ├── chat_detail_screen.dart
│   │   └── widgets/
│   │       ├── chat_message_list.dart
│   │       ├── chat_sidebar.dart
│   │       ├── message_bubble.dart
│   │       ├── visualization_card.dart
│   │       ├── insight_card.dart
│   │       ├── policy_card.dart
│   │       ├── welcome_view.dart
│   │       └── user_menu.dart
│   ├── profile/
│   │   └── profile_screen.dart
│   ├── settings/
│   │   └── settings_screen.dart
│   ├── splash/
│   │   └── splash_screen.dart
│   └── widgets/
│       ├── custom_text_field.dart
│       ├── glass_card.dart
│       └── gradient_button.dart
└── main.dart
```

### Code Style

The project follows Flutter's official style guide:
- Use `flutter_lints` for linting
- Follow effective Dart guidelines
- Document public APIs
- Use meaningful variable names

### Git Workflow

```bash
# Create feature branch
git checkout -b feature/your-feature-name

# Commit changes
git add .
git commit -m "feat: add your feature description"

# Push to remote
git push origin feature/your-feature-name

# Create Pull Request
```

---

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Coding Standards

- Write clear, self-documenting code
- Add comments for complex logic
- Follow Flutter best practices
- Write tests for new features
- Update documentation

---

## 📄 License

This project is private and proprietary. All rights reserved.

---

## 👥 Team

### Development Team
- **Project Lead**: [Your Name]
- **Flutter Developer**: [Developer Name]
- **Backend Developer**: [Developer Name]
- **UI/UX Designer**: [Designer Name]

---

## 📞 Support

### Contact

- **Email**: support@smartse2026.id
- **Website**: [https://smartse2026.id](https://smartse2026.id)
- **Documentation**: [docs.smartse2026.id](https://docs.smartse2026.id)

### Reporting Issues

Please report bugs and issues through:
1. GitHub Issues (for internal team)
2. Email support for urgent matters

---

## 🗺️ Roadmap

### Version 1.1 (Planned)
- [ ] Voice input/output support
- [ ] Offline mode capability
- [ ] Enhanced data export options
- [ ] Multi-language support (English, Indonesian)
- [ ] Advanced filtering and search

### Version 1.2 (Future)
- [ ] Push notifications
- [ ] Real-time collaboration
- [ ] Advanced analytics dashboard
- [ ] Custom report templates
- [ ] Data synchronization

---

## 🙏 Acknowledgments

- Flutter Team for the amazing framework
- Anthropic for AI capabilities
- Indonesian Statistics Agency (BPS) for census data
- All contributors and testers

---

## 📚 Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Provider Package](https://pub.dev/packages/provider)
- [fl_chart Documentation](https://pub.dev/packages/fl_chart)
- [Material Design Guidelines](https://material.io/design)

---

<div align="center">

**Built with ❤️ using Flutter**

© 2026 SMART SE2026. All Rights Reserved.

</div>