# Multimodal AI Assistant - Flutter App

Cross-platform Flutter app for AI-powered video editing and chat.

## 🆓 100% FREE APIs

This app connects to a backend that uses only FREE APIs:

| Feature | Technology | Cost |
|---------|------------|------|
| AI Chat | Google Gemini 1.5 Flash | **FREE** |
| Image Analysis | Google Gemini Vision | **FREE** |
| Video Processing | FFmpeg (Backend) | **FREE** |
| Authentication | JWT | **FREE** |

### ❌ Removed PAID Features:
- Speech-to-Text (OpenAI Whisper - PAID)
- Text-to-Speech (OpenAI TTS - PAID)
- Embeddings (OpenAI - PAID)

## 🚀 Quick Start

### 1. Prerequisites
- Flutter 3.9+
- Dart 3.0+
- Backend server running (see backend README)

### 2. Setup

```bash
# Get dependencies
flutter pub get

# Copy environment file
cp .env.example .env

# Edit .env with your backend URL
```

### 3. Configure .env

```env
# For Android Emulator
API_BASE_URL=http://10.0.2.2:3000/api

# For iOS Simulator
API_BASE_URL=http://localhost:3000/api

# For Physical Device (use your computer's IP)
API_BASE_URL=http://192.168.x.x:3000/api
```

### 4. Run

```bash
# Run on connected device/emulator
flutter run

# Run on specific platform
flutter run -d chrome    # Web
flutter run -d macos     # macOS
flutter run -d windows   # Windows
```

## 📱 Features

### Available (FREE)
- ✅ AI Chat with Google Gemini
- ✅ Image Analysis with AI Vision
- ✅ Video Upload & Processing
- ✅ Video Frame Extraction
- ✅ User Authentication
- ✅ Conversation History

### Removed (PAID)
- ❌ Voice Input (Speech-to-Text)
- ❌ Voice Output (Text-to-Speech)
- ❌ Semantic Search (Embeddings)

## 📁 Project Structure

```
lib/
├── core/
│   ├── config/      # Environment config
│   ├── models/      # Data models
│   ├── providers/   # Riverpod providers
│   ├── services/    # API services
│   └── utils/       # Utilities
├── features/
│   ├── auth/        # Authentication
│   ├── chat/        # AI Chat
│   ├── media/       # Media handling
│   ├── navigation/  # App navigation
│   └── settings/    # App settings
└── main.dart
```

## 🔧 Backend Setup

Make sure the backend server is running:

```bash
cd ../backend-ai-video-editer
npm install
npm run dev
```

See backend README for full setup instructions.

## 📦 Dependencies

Key packages used:
- `flutter_riverpod` - State management
- `dio` - HTTP client
- `flutter_secure_storage` - Secure storage
- `image_picker` - Image selection
- `video_player` - Video playback
- `flutter_markdown` - Markdown rendering

## 🏗️ Build

```bash
# Android APK
flutter build apk

# iOS
flutter build ios

# Web
flutter build web

# macOS
flutter build macos
```

## 📄 License

MIT
