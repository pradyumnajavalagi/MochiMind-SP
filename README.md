# Mochi Mind SP - Kanji Flashcards App

A Flutter-based mobile application for learning and practicing Kanji characters through flashcards. The app provides an interactive and engaging way to study Japanese characters.

## Features

- User authentication and account management
- Interactive flashcard system for Kanji learning
- Modern Material Design 3 UI
- Secure data storage with Supabase backend
- Cross-platform support (iOS, Android, Web)

## Tech Stack

- Flutter SDK (^3.5.4)
- Supabase for backend and authentication
- Material Design 3 for UI components
- Environment-based configuration

## Dependencies

- `supabase_flutter`: ^2.8.4 - Backend and authentication
- `image_picker`: ^1.1.2 - Image handling
- `http`: ^1.3.0 - Network requests
- `animated_notch_bottom_bar`: ^1.0.3 - Navigation UI
- `flutter_dotenv`: ^5.2.1 - Environment configuration

## Getting Started

1. Clone the repository
2. Create a `.env` file in the root directory with your Supabase credentials:
   ```
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart          # Application entry point
├── pages/            # Screen components
├── widgets/          # Reusable UI components
├── services/         # Business logic and API calls
├── models/           # Data models
└── utils/            # Utility functions and helpers
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

This project is licensed under the terms of the license included in the repository.

## Support

For support, please open an issue in the repository.
