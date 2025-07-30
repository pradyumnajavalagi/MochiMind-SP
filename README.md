# MochiMind SP - Advanced Kanji Learning App

A comprehensive Flutter-based mobile application for learning and mastering Japanese Kanji characters through intelligent flashcards, spaced repetition, and AI-powered feedback.

## 🌟 Features

### 📚 Core Learning Features
- **Interactive Flashcard System**: Swipe-based card interface with detailed Kanji information
- **Spaced Repetition System (SRS)**: Intelligent review scheduling based on learning performance
- **Custom Kanji Creation**: Upload your own Kanji images and add detailed information
- **Comprehensive Kanji Data**: Onyomi, Kunyomi readings, and example usage for each character

### 🧠 Smart Learning Tools
- **AI-Powered Feedback**: Get personalized learning insights after each test session
- **Progress Tracking**: Monitor your learning journey with detailed statistics
- **Study Calendar**: Visual heatmap showing your daily study activity
- **Retention Analytics**: Track your deck retention and learning progress

### 🎯 Testing & Assessment
- **Customizable Tests**: Choose test parameters and difficulty levels
- **Performance Tracking**: Detailed test results with performance analytics
- **Adaptive Learning**: Cards you struggle with appear more frequently
- **Test Results Analysis**: Comprehensive feedback on your performance

### 🔍 Organization & Management
- **Tag System**: Organize flashcards with custom tags for better categorization
- **Search Functionality**: Find specific Kanji by readings or example usage
- **Flashcard Management**: Edit, delete, and organize your learning materials
- **Grid View**: Browse all your flashcards in an organized grid layout

### 👤 User Experience
- **Modern Material Design 3**: Beautiful, intuitive interface
- **Cross-Platform Support**: Works on iOS, Android, and Web
- **Offline Capability**: Study without internet connection
- **Responsive Design**: Optimized for all screen sizes

## 🛠 Tech Stack

### Frontend
- **Flutter SDK**: ^3.5.4 - Cross-platform UI framework
- **Material Design 3**: Modern, adaptive design system
- **State Management**: Flutter's built-in state management

### Backend & Services
- **Supabase**: Authentication, database, and real-time features
- **Firebase**: Core services and analytics
- **Google Sign-In**: OAuth authentication
- **Supabase Edge Functions**: AI feedback generation

### Key Dependencies
- `supabase_flutter`: ^2.8.4 - Backend integration
- `firebase_core`: ^2.31.0 - Firebase services
- `firebase_auth`: ^4.19.5 - Authentication
- `google_sign_in`: ^6.2.1 - Google OAuth
- `flutter_card_swiper`: ^7.0.0 - Interactive card interface
- `flutter_heatmap_calendar`: ^1.0.5 - Study calendar visualization
- `fl_chart`: ^0.64.0 - Data visualization
- `image_picker`: ^1.1.2 - Image handling
- `animated_notch_bottom_bar`: ^1.0.3 - Navigation UI
- `flutter_dotenv`: ^5.2.1 - Environment configuration

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (^3.5.4)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Supabase account
- Firebase project
- Google Cloud Console project (for OAuth)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/mochi_mind_sp.git
   cd mochi_mind_sp
   ```

2. **Set up environment variables**
   Create a `.env` file in the root directory:
   ```env
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

3. **Configure Firebase**
   - Set up a Firebase project
   - Add your `firebase_options.dart` file
   - Configure Google Sign-In

4. **Set up Supabase**
   - Create a Supabase project
   - Set up the database schema
   - Configure storage buckets
   - Deploy Edge Functions

5. **Install dependencies**
   ```bash
   flutter pub get
   ```

6. **Run the app**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── main.dart                 # Application entry point
├── firebase_options.dart     # Firebase configuration
├── models/
│   └── flashcard_model.dart  # Data models for flashcards and tags
├── pages/
│   ├── auth.dart            # Authentication screen
│   ├── home_page.dart       # Main flashcard interface
│   ├── add_edit_page.dart   # Create/edit flashcards
│   ├── search_page.dart     # Search and manage flashcards
│   ├── grid_page.dart       # Grid view of flashcards
│   ├── test_setup_page.dart # Test configuration
│   ├── test_page.dart       # Flashcard testing interface
│   ├── test_results_page.dart # Test results and AI feedback
│   ├── profile_page.dart    # User profile and statistics
│   └── reset_password_page.dart # Password reset
├── services/
│   └── api_service.dart     # Backend API integration
├── utils/
│   ├── auth_gate.dart       # Authentication routing
│   └── navigation_wrapper.dart # Navigation management
└── widgets/
    ├── app_drawer.dart      # Navigation drawer
    ├── flashcard_widget.dart # Flashcard display component
    └── logout_button.dart   # Logout functionality

supabase/
├── config.toml             # Supabase configuration
└── functions/
    └── get-ai-feedback/    # AI feedback generation
```

## 🎯 Key Features Explained

### Spaced Repetition System (SRS)
The app implements a sophisticated SRS algorithm that:
- Tracks your performance on each Kanji
- Adjusts review intervals based on difficulty
- Prioritizes cards you struggle with
- Optimizes learning efficiency

### AI-Powered Feedback
After each test session, the app provides:
- Personalized learning insights
- Specific improvement suggestions
- Analysis of your strengths and weaknesses
- Actionable tips for better retention

### Study Analytics
Comprehensive tracking including:
- Daily study streaks
- Overall retention rates
- Test performance trends
- Visual study calendar

## 🔧 Configuration

### Supabase Setup
1. Create tables for flashcards, users, and test results
2. Set up storage buckets for Kanji images
3. Configure Row Level Security (RLS)
4. Deploy Edge Functions for AI feedback

### Firebase Setup
1. Configure Authentication providers
2. Set up Google Sign-In
3. Add platform-specific configurations

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the terms included in the repository.

## 🆘 Support

- **Issues**: Open an issue in the repository
- **Documentation**: Check the inline code comments
- **Community**: Join our discussion forum

## 🔮 Roadmap

- [ ] Advanced SRS algorithms
- [ ] Social learning features
- [ ] Offline mode improvements
- [ ] Additional language support
- [ ] Advanced analytics dashboard
- [ ] Integration with external Kanji APIs

---

**Built with ❤️ for Japanese language learners**
