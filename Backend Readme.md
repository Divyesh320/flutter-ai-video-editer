# 🤖 Multimodal AI Assistant - Complete Backend System

[![Node.js](https://img.shields.io/badge/Node.js-18+-green.svg)](https://nodejs.org/)
[![MongoDB](https://img.shields.io/badge/MongoDB-Atlas-green.svg)](https://www.mongodb.com/atlas)
[![OpenAI](https://img.shields.io/badge/OpenAI-GPT--4-blue.svg)](https://openai.com/)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://docker.com/)
[![Flutter](https://img.shields.io/badge/Flutter-Optimized-blue.svg)](https://flutter.dev/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A **production-ready**, **enterprise-grade** Node.js backend system specifically designed for Flutter multimodal AI applications. This comprehensive backend provides authentication, AI services, video processing, embeddings, and user management with MongoDB Atlas integration.

## 🌟 **System Overview**

This backend powers modern AI-driven mobile applications with:
- **🔐 Complete Authentication System** - JWT + OAuth with session management
- **🤖 Advanced AI Services** - Chat, Vision, Speech, Text-to-Speech, Embeddings
- **🎥 Video Processing Pipeline** - Upload, frame extraction, thumbnail generation
- **📊 User Management** - Profiles, quotas, analytics, usage tracking
- **🚀 Production Ready** - Docker, MongoDB Atlas, comprehensive monitoring
- **📱 Flutter Optimized** - Mobile-first API design with proper error handling

## 🏗️ **System Architecture**

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Flutter App   │◄──►│   Backend API    │◄──►│  MongoDB Atlas  │
│                 │    │                  │    │                 │
│ • Authentication│    │ • JWT Auth       │    │ • User Data     │
│ • AI Chat       │    │ • AI Services    │    │ • AI Jobs       │
│ • Video Upload  │    │ • Video Process  │    │ • Embeddings    │
│ • File Management│   │ • Rate Limiting  │    │ • Video Jobs    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                       ┌────────▼────────┐
                       │   External APIs │
                       │                 │
                       │ • OpenAI GPT-4  │
                       │ • Whisper STT   │
                       │ • DALL-E Vision │
                       │ • TTS Synthesis │
                       └─────────────────┘
```

## 🚀 **Core Features**

### 🔐 **Enterprise Authentication System**
- **JWT Authentication** - Secure token-based auth with refresh tokens
- **OAuth Integration** - Google social login
- **Session Management** - Multi-device session tracking and control
- **Rate Limiting** - Advanced protection against abuse
- **Quota Management** - Usage tracking and limits per user
- **Security Headers** - Helmet.js protection with CORS

### 🤖 **Advanced AI Services**
- **💬 Chat Completion** - GPT-4 powered conversations with context memory
- **🎤 Speech-to-Text** - Whisper integration for high-accuracy transcription
- **🔊 Text-to-Speech** - Premium voice synthesis with multiple voices
- **👁️ Computer Vision** - Image analysis and description with GPT-4 Vision
- **🧠 Embeddings** - Semantic search and similarity matching
- **📊 Job Tracking** - Complete AI operation history and analytics

### 🎥 **Professional Video Processing**
- **📤 Smart Upload** - Multi-format video support with validation
- **🖼️ Frame Extraction** - Customizable interval frame extraction
- **🖼️ Thumbnail Generation** - Automatic video thumbnail creation
- **⚡ FFmpeg Integration** - Professional video processing pipeline
- **📏 Format Validation** - Size, duration, and format restrictions
- **🗂️ Asset Management** - Organized file storage and cleanup

### 👤 **Comprehensive User Management**
- **👤 Profile System** - Complete user profiles with avatar upload
- **📊 Usage Analytics** - Detailed usage statistics and insights
- **💳 Quota Tracking** - Real-time usage monitoring and limits
- **🔧 Account Controls** - Profile updates, password changes, deactivation
- **📱 Session Management** - View and revoke active sessions
- **📈 Performance Metrics** - User engagement and API usage analytics

## ⚡ **Quick Start Guide**

### 📋 **Prerequisites**
- **Node.js 18+** - [Download](https://nodejs.org/)
- **MongoDB Atlas Account** - [Free Signup](https://www.mongodb.com/atlas) (Recommended)
- **OpenAI API Key** - [Get API Key](https://platform.openai.com/api-keys)
- **Docker & Docker Compose** - [Install Docker](https://docs.docker.com/get-docker/)
- **FFmpeg** - For video processing (included in Docker)

### 🎯 **5-Minute Setup**

#### **Step 1: Clone & Setup** (1 minute)
```bash
# Clone the repository
git clone https://github.com/your-username/multimodal-ai-assistant.git
cd multimodal-ai-assistant

# Install dependencies
npm install

# Setup environment
cp .env.example .env
```

#### **Step 2: Configure MongoDB Atlas** (2 minutes)
1. **Create Account**: [MongoDB Atlas](https://www.mongodb.com/atlas) → Sign up free
2. **Create Cluster**: Choose M0 (Free) → Select region → Create
3. **Database User**: Add user with read/write permissions
4. **Network Access**: Add IP `0.0.0.0/0` (development) or your specific IP
5. **Get Connection String**: Connect → Application → Copy connection string

#### **Step 3: Environment Configuration** (1 minute)
Edit `.env` file with your credentials:
```env
# 🗄️ Database (MongoDB Atlas)
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/multimodal-ai-assistant?retryWrites=true&w=majority

# 🔑 Authentication
JWT_SECRET_KEY=your-super-secret-jwt-key-change-in-production

# 🤖 OpenAI API (Required)
OPENAI_API_KEY=sk-your-openai-api-key

# 🔐 OAuth (Optional - for Google login)
GOOGLE_CLIENT_ID=your-google-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-google-client-secret

# ⚙️ App Configuration
APP_NAME=Multimodal AI Assistant
APP_ENVIRONMENT=development
DEBUG_MODE=true
PORT=3000
```

#### **Step 4: Launch Backend** (1 minute)

**🌟 Option A: MongoDB Atlas (Recommended)**
```bash
# Start with MongoDB Atlas (no local database needed)
docker-compose -f docker-compose.atlas.yml up -d

# Check status
docker-compose -f docker-compose.atlas.yml ps

# View logs
docker-compose -f docker-compose.atlas.yml logs -f app
```

**🔧 Option B: Local Development**
```bash
# For development with hot reload
npm run dev

# Or with local MongoDB
docker-compose up -d
```

#### **Step 5: Verify Setup** (30 seconds)
```bash
# Health check
curl http://localhost:3000/health

# Expected response:
{
  "status": "OK",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "version": "1.0.0",
  "environment": "production"
}
```

### 🎉 **You're Ready!**
- **🌐 API Base URL**: `http://localhost:3000/api`
- **📚 API Documentation**: `http://localhost:3000/api-docs`
- **❤️ Health Check**: `http://localhost:3000/health`

## 🗄️ **Database Architecture**

### 🌟 **MongoDB Atlas (Production Ready)**
**Why Atlas is Perfect for Your Flutter App:**

| Feature | Benefit | Impact |
|---------|---------|---------|
| 🚀 **Zero Setup** | No database management | Focus on app development |
| 🌍 **Global Clusters** | Deploy worldwide | Low latency for users |
| 🔒 **Enterprise Security** | Built-in encryption | Secure user data |
| 📊 **Real-time Monitoring** | Performance insights | Optimize app performance |
| 💾 **Automatic Backups** | Point-in-time recovery | Never lose data |
| 💰 **Free Tier** | 512MB free forever | Perfect for development |

**Atlas Setup Guide**: See `MONGODB_ATLAS_SETUP.md` for detailed instructions.

### 📊 **Database Schema Design**

```javascript
// User Collection
{
  _id: ObjectId,
  email: "user@example.com",
  name: "John Doe",
  provider: "local|google",
  quota: {
    limit: 100,
    used: 25,
    resetDate: ISODate
  },
  avatar: "/uploads/avatars/user_123.jpg",
  isActive: true,
  createdAt: ISODate,
  lastLogin: ISODate
}

// AI Jobs Collection
{
  _id: ObjectId,
  userId: ObjectId,
  type: "chat|whisper|tts|vision|embedding",
  status: "pending|processing|completed|failed",
  input: { message: "Hello AI" },
  output: { response: "Hello! How can I help?" },
  tokensUsed: 150,
  processingTime: 1250,
  createdAt: ISODate
}

// Video Jobs Collection
{
  _id: ObjectId,
  userId: ObjectId,
  filename: "video_123.mp4",
  status: "uploaded|processing|completed|failed",
  metadata: {
    duration: 120.5,
    width: 1920,
    height: 1080,
    fps: 30
  },
  frames: [
    {
      timestamp: 1.0,
      filename: "frame_001.jpg",
      filePath: "/uploads/frames/frame_001.jpg"
    }
  ]
}
```

## 📱 **Flutter Integration**

### 🔧 **Complete Flutter Setup**

#### **Dependencies** (`pubspec.yaml`)
```yaml
dependencies:
  dio: ^5.3.2                    # HTTP client
  flutter_secure_storage: ^9.0.0 # Secure token storage
  image_picker: ^1.0.4           # Image/video picker
  file_picker: ^6.1.1            # File picker
  audioplayers: ^5.2.1           # Audio playback
  record: ^5.0.4                 # Audio recording
  video_player: ^2.8.1           # Video playback
  cached_network_image: ^3.3.0   # Image caching
  permission_handler: ^11.0.1    # Permissions
```

#### **API Client Setup**
```dart
// lib/services/api_client.dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String baseUrl = 'http://10.0.2.2:3000/api'; // Android emulator
  // static const String baseUrl = 'http://localhost:3000/api'; // iOS simulator
  // static const String baseUrl = 'https://your-api.com/api'; // Production
  
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: Duration(seconds: 30),
    receiveTimeout: Duration(seconds: 30),
  ));
  
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  
  static Future<void> initialize() async {
    // Auto-attach auth token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Auto token refresh on 401
        if (error.response?.statusCode == 401) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            // Retry original request
            final token = await _storage.read(key: 'access_token');
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            final response = await _dio.fetch(error.requestOptions);
            handler.resolve(response);
            return;
          }
        }
        handler.next(error);
      },
    ));
  }
}
```

#### **Authentication Service**
```dart
// lib/services/auth_service.dart
class AuthService {
  // Register new user
  static Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await ApiClient.dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'name': name,
      });
      
      if (response.data['success']) {
        final data = response.data['data'];
        await _storeTokens(data['accessToken'], data['refreshToken']);
        return AuthResult.success(User.fromJson(data['user']));
      }
      return AuthResult.error(response.data['message']);
    } catch (e) {
      return AuthResult.error('Registration failed: $e');
    }
  }
  
  // Login existing user
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      if (response.data['success']) {
        final data = response.data['data'];
        await _storeTokens(data['accessToken'], data['refreshToken']);
        return AuthResult.success(User.fromJson(data['user']));
      }
      return AuthResult.error(response.data['message']);
    } catch (e) {
      return AuthResult.error('Login failed: $e');
    }
  }
  
  // Store tokens securely
  static Future<void> _storeTokens(String accessToken, String refreshToken) async {
    await ApiClient.storage.write(key: 'access_token', value: accessToken);
    await ApiClient.storage.write(key: 'refresh_token', value: refreshToken);
  }
}

class AuthResult {
  final bool success;
  final User? user;
  final String? error;
  
  AuthResult.success(this.user) : success = true, error = null;
  AuthResult.error(this.error) : success = false, user = null;
}
```

#### **AI Services Integration**
```dart
// lib/services/ai_service.dart
class AIService {
  // 💬 Chat with GPT-4
  static Future<ChatResponse> sendMessage({
    required String message,
    String? conversationId,
    String? model = 'gpt-4',
  }) async {
    final response = await ApiClient.dio.post('/ai/chat', data: {
      'message': message,
      'conversationId': conversationId,
      'model': model,
    });
    return ChatResponse.fromJson(response.data['data']);
  }
  
  // 🎤 Speech to Text (Whisper)
  static Future<TranscriptionResponse> transcribeAudio(File audioFile) async {
    final formData = FormData.fromMap({
      'audio': await MultipartFile.fromFile(audioFile.path),
    });
    
    final response = await ApiClient.dio.post('/ai/speech-to-text', data: formData);
    return TranscriptionResponse.fromJson(response.data['data']);
  }
  
  // 🔊 Text to Speech
  static Future<Uint8List> synthesizeSpeech({
    required String text,
    String voice = 'alloy',
  }) async {
    final response = await ApiClient.dio.post('/ai/text-to-speech',
      data: {'text': text, 'voice': voice},
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data;
  }
  
  // 👁️ Image Analysis (GPT-4 Vision)
  static Future<VisionResponse> analyzeImage({
    required File imageFile,
    String? prompt,
  }) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imageFile.path),
      if (prompt != null) 'prompt': prompt,
    });
    
    final response = await ApiClient.dio.post('/ai/analyze-image', data: formData);
    return VisionResponse.fromJson(response.data['data']);
  }
  
  // 🧠 Create Embeddings
  static Future<EmbeddingResponse> createEmbedding(String text) async {
    final response = await ApiClient.dio.post('/embeddings/create', data: {
      'text': text,
      'autoChunk': true,
    });
    return EmbeddingResponse.fromJson(response.data['data']);
  }
  
  // 🔍 Semantic Search
  static Future<List<SearchResult>> searchSimilar({
    required String query,
    int limit = 10,
    double threshold = 0.7,
  }) async {
    final response = await ApiClient.dio.post('/embeddings/search', data: {
      'query': query,
      'limit': limit,
      'threshold': threshold,
    });
    
    final results = response.data['data']['results'] as List;
    return results.map((r) => SearchResult.fromJson(r)).toList();
  }
}
```

#### **Video Processing Service**
```dart
// lib/services/video_service.dart
class VideoService {
  // 📤 Upload and Process Video
  static Future<VideoUploadResponse> uploadVideo({
    required File videoFile,
    bool extractFrames = true,
    double frameInterval = 1.0,
    int maxFrames = 100,
  }) async {
    final formData = FormData.fromMap({
      'video': await MultipartFile.fromFile(videoFile.path),
      'extractFrames': extractFrames,
      'frameInterval': frameInterval,
      'maxFrames': maxFrames,
    });
    
    final response = await ApiClient.dio.post('/video/upload', data: formData);
    return VideoUploadResponse.fromJson(response.data['data']);
  }
  
  // 📊 Get Processing Status
  static Future<VideoJob> getVideoJob(String jobId) async {
    final response = await ApiClient.dio.get('/video/jobs/$jobId');
    return VideoJob.fromJson(response.data['data']);
  }
  
  // 🖼️ Get Extracted Frame
  static Future<Uint8List> getFrame(String jobId, int frameIndex) async {
    final response = await ApiClient.dio.get('/video/jobs/$jobId/frames/$frameIndex',
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data;
  }
  
  // 🖼️ Get Video Thumbnail
  static Future<Uint8List> getThumbnail(String jobId, {double timestamp = 1.0}) async {
    final response = await ApiClient.dio.get('/video/jobs/$jobId/thumbnail',
      queryParameters: {'timestamp': timestamp},
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data;
  }
  
  // 📋 List User Videos
  static Future<List<VideoJob>> getUserVideos({int page = 1, int limit = 20}) async {
    final response = await ApiClient.dio.get('/video/jobs',
      queryParameters: {'page': page, 'limit': limit},
    );
    
    final jobs = response.data['data'] as List;
    return jobs.map((job) => VideoJob.fromJson(job)).toList();
  }
}
```

**📖 Complete Flutter Integration Guide**: See `FLUTTER_INTEGRATION.md` for detailed examples, widgets, and best practices.

## 🛠️ **API Reference**

### 📡 **Complete Endpoint Documentation**

| Category | Endpoint | Method | Description | Auth Required |
|----------|----------|---------|-------------|---------------|
| **🔐 Authentication** |
| | `/api/auth/register` | POST | Register new user | ❌ |
| | `/api/auth/login` | POST | Login user | ❌ |
| | `/api/auth/refresh` | POST | Refresh access token | ❌ |
| | `/api/auth/logout` | POST | Logout user | ❌ |
| | `/api/auth/me` | GET | Get current user | ✅ |
| | `/api/auth/logout-all` | POST | Logout all devices | ✅ |
| | `/api/auth/sessions` | GET | List active sessions | ✅ |
| **🤖 AI Services** |
| | `/api/ai/chat` | POST | GPT-4 chat completion | ✅ |
| | `/api/ai/speech-to-text` | POST | Whisper transcription | ✅ |
| | `/api/ai/text-to-speech` | POST | Voice synthesis | ✅ |
| | `/api/ai/analyze-image` | POST | GPT-4 Vision analysis | ✅ |
| | `/api/ai/jobs` | GET | AI job history | ✅ |
| | `/api/ai/jobs/:id` | GET | Specific AI job details | ✅ |
| **🎥 Video Processing** |
| | `/api/video/upload` | POST | Upload & process video | ✅ |
| | `/api/video/jobs` | GET | List video jobs | ✅ |
| | `/api/video/jobs/:id` | GET | Video job details | ✅ |
| | `/api/video/jobs/:id/frames/:index` | GET | Get frame image | ✅ |
| | `/api/video/jobs/:id/thumbnail` | GET | Get video thumbnail | ✅ |
| | `/api/video/jobs/:id` | DELETE | Delete video job | ✅ |
| **🧠 Embeddings** |
| | `/api/embeddings/create` | POST | Create text embedding | ✅ |
| | `/api/embeddings/search` | POST | Semantic search | ✅ |
| | `/api/embeddings` | GET | List user embeddings | ✅ |
| | `/api/embeddings/stats` | GET | Embedding statistics | ✅ |
| | `/api/embeddings/:id` | GET | Embedding details | ✅ |
| | `/api/embeddings/:id` | DELETE | Delete embedding | ✅ |
| | `/api/embeddings/bulk-delete` | POST | Delete multiple embeddings | ✅ |
| **👤 User Management** |
| | `/api/user/profile` | GET | Get user profile | ✅ |
| | `/api/user/profile` | PUT | Update profile | ✅ |
| | `/api/user/avatar` | POST | Upload avatar | ✅ |
| | `/api/user/avatar` | DELETE | Delete avatar | ✅ |
| | `/api/user/quota` | GET | Quota information | ✅ |
| | `/api/user/usage-stats` | GET | Usage statistics | ✅ |
| | `/api/user/deactivate` | POST | Deactivate account | ✅ |

### 📋 **Standard Response Format**

**✅ Success Response:**
```json
{
  "success": true,
  "message": "Operation completed successfully",
  "data": {
    // Response data object
  },
  "meta": {
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 100,
      "pages": 5
    }
  }
}
```

**❌ Error Response:**
```json
{
  "success": false,
  "message": "Descriptive error message",
  "error": "Detailed error information (development only)"
}
```

### 🔒 **Authentication Examples**

**Register User:**
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "securePassword123",
    "name": "John Doe"
  }'
```

**Login User:**
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "securePassword123"
  }'
```

**Chat with AI:**
```bash
curl -X POST http://localhost:3000/api/ai/chat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "message": "Explain quantum computing in simple terms",
    "model": "gpt-4"
  }'
```

## ⚡ **Performance & Security**

### 🛡️ **Security Features**

| Feature | Implementation | Benefit |
|---------|----------------|---------|
| **🔐 JWT Authentication** | Access + Refresh tokens | Secure, stateless auth |
| **🚫 Rate Limiting** | IP-based limits | Prevent API abuse |
| **📊 Quota Management** | User-based limits | Control resource usage |
| **🔒 Input Validation** | Joi + Express Validator | Prevent injection attacks |
| **🛡️ Security Headers** | Helmet.js | XSS, CSRF protection |
| **🌐 CORS Protection** | Configurable origins | Control access |
| **📝 Request Logging** | Winston logger | Audit trail |
| **🔍 File Validation** | Type & size checks | Prevent malicious uploads |

### 🚀 **Rate Limiting Configuration**

| Endpoint Category | Rate Limit | Window | Burst Allowed |
|-------------------|------------|---------|---------------|
| **General API** | 60 req/min | 1 minute | 20 requests |
| **Authentication** | 5 attempts | 15 minutes | 2 attempts |
| **AI Services** | 10 req/min | 1 minute | 5 requests |
| **Video Upload** | 3 uploads | 1 minute | 1 upload |
| **File Downloads** | 100 req/min | 1 minute | 50 requests |

### 💳 **Intelligent Quota System**

| Service | Quota Cost | Calculation | Example |
|---------|------------|-------------|---------|
| **💬 Chat** | 2 units | Per request | 1 chat = 2 units |
| **🎤 Speech-to-Text** | 1 unit | Per minute of audio | 3min audio = 3 units |
| **🔊 Text-to-Speech** | 1 unit | Per 1000 characters | 2000 chars = 2 units |
| **👁️ Vision** | 3 units | Per image analysis | 1 image = 3 units |
| **🎥 Video Processing** | 5 units | Per video | 1 video = 5 units |
| **🧠 Embeddings** | 1 unit | Per 1000 tokens | 2000 tokens = 2 units |

**Default Quota**: 100 units/month (resets monthly)  
**Quota Warning**: Alert at 80% usage  
**Quota Reset**: Automatic monthly reset

### 📁 **File Upload Specifications**

| File Type | Max Size | Duration Limit | Supported Formats | Processing |
|-----------|----------|----------------|-------------------|------------|
| **🖼️ Images** | 5MB | - | JPEG, PNG, GIF, WebP | Auto-resize, optimization |
| **🎵 Audio** | 25MB | 10 minutes | WAV, MP3, M4A, OGG | Whisper transcription |
| **🎥 Video** | 100MB | 5 minutes | MP4, AVI, MOV, WMV, WebM | Frame extraction, thumbnails |
| **👤 Avatar** | 5MB | - | JPEG, PNG, GIF, WebP | Auto-crop to 200x200 |

**Upload Features:**
- ✅ **Real-time validation** - Instant feedback on file issues
- ✅ **Progress tracking** - Upload progress indicators
- ✅ **Auto-optimization** - Automatic image compression
- ✅ **Virus scanning** - File safety validation
- ✅ **CDN integration** - Fast global file delivery

## 🚀 **Deployment & Production**

### 🌐 **Production Deployment Options**

#### **🔥 Quick Deploy (5 minutes)**
```bash
# 1. Setup MongoDB Atlas (free tier)
# 2. Configure environment variables
# 3. Deploy with Docker
docker-compose -f docker-compose.atlas.yml up -d

# 4. Setup SSL (Let's Encrypt)
certbot --nginx -d your-domain.com

# 5. Configure monitoring
docker-compose logs -f app
```

#### **☁️ Cloud Platform Deployment**

**AWS EC2:**
```bash
# Launch t3.medium instance (2 vCPU, 4GB RAM)
# Install Docker & Docker Compose
# Clone repository and configure .env
# Start services with docker-compose
```

**Google Cloud Platform:**
```bash
# Deploy to Compute Engine or Cloud Run
gcloud run deploy multimodal-ai-assistant \
  --image gcr.io/PROJECT_ID/multimodal-ai-assistant \
  --platform managed \
  --memory 2Gi
```

**DigitalOcean:**
```bash
# Create 4GB RAM droplet
# Follow standard Docker deployment
# Configure domain and SSL
```

### 📊 **Monitoring & Analytics**

**Built-in Monitoring:**
- ✅ **Health Checks** - `/health` endpoint with detailed status
- ✅ **Request Logging** - Winston with daily rotation
- ✅ **Error Tracking** - Comprehensive error logging
- ✅ **Performance Metrics** - Response time tracking
- ✅ **Usage Analytics** - User activity and API usage
- ✅ **Database Monitoring** - MongoDB Atlas dashboard

**Production Monitoring Stack:**
```yaml
# docker-compose.monitoring.yml
services:
  prometheus:    # Metrics collection
  grafana:       # Visualization dashboard
  alertmanager:  # Alert notifications
  node-exporter: # System metrics
```

### 🔧 **Development Environment**

**Development Scripts:**
```bash
npm run dev      # Start with hot reload (nodemon)
npm run lint     # ESLint code checking
npm run test     # Run test suite
npm start        # Production server
npm run build    # Build for production
```

**Development Tools:**
- **🔄 Hot Reload** - Nodemon for instant code changes
- **🧪 Testing** - Jest test framework
- **📏 Code Quality** - ESLint + Prettier
- **📚 API Docs** - Auto-generated Swagger documentation
- **🐛 Debugging** - VS Code debug configuration
- **📊 Logging** - Detailed development logs

### 🏗️ **Project Architecture**

```
multimodal-ai-assistant/
├── 📁 src/
│   ├── 📁 config/          # Configuration management
│   │   ├── index.js        # Main config loader
│   │   ├── database.js     # MongoDB connection
│   │   ├── logger.js       # Winston logging setup
│   │   └── swagger.js      # API documentation
│   ├── 📁 controllers/     # Request handlers
│   │   ├── authController.js
│   │   ├── aiController.js
│   │   ├── videoController.js
│   │   ├── embeddingsController.js
│   │   └── userController.js
│   ├── 📁 middleware/      # Express middleware
│   │   ├── auth.js         # JWT authentication
│   │   ├── rateLimiter.js  # Rate limiting
│   │   ├── quota.js        # Usage quotas
│   │   ├── validator.js    # Input validation
│   │   └── errorHandler.js # Error handling
│   ├── 📁 models/          # MongoDB schemas
│   │   ├── User.js         # User model
│   │   ├── AIJob.js        # AI jobs tracking
│   │   ├── VideoJob.js     # Video processing
│   │   ├── Embedding.js    # Text embeddings
│   │   └── RefreshToken.js # Token management
│   ├── 📁 routes/          # API route definitions
│   │   ├── auth.js         # Authentication routes
│   │   ├── ai.js           # AI service routes
│   │   ├── video.js        # Video processing routes
│   │   ├── embeddings.js   # Embedding routes
│   │   └── user.js         # User management routes
│   ├── 📁 services/        # Business logic
│   │   ├── authService.js  # Authentication logic
│   │   ├── openaiService.js # OpenAI API integration
│   │   ├── videoService.js # Video processing
│   │   └── embeddingService.js # Embedding operations
│   ├── 📁 utils/           # Utility functions
│   │   └── index.js        # Helper functions
│   └── server.js           # Main application entry
├── 📁 uploads/             # File storage
│   ├── videos/             # Uploaded videos
│   ├── frames/             # Extracted frames
│   └── avatars/            # User avatars
├── 📁 logs/                # Application logs
├── 📄 docker-compose.yml   # Local development
├── 📄 docker-compose.atlas.yml # MongoDB Atlas
├── 📄 Dockerfile           # Container definition
├── 📄 .env.example         # Environment template
└── 📚 Documentation/
    ├── MONGODB_ATLAS_SETUP.md
    ├── FLUTTER_INTEGRATION.md
    ├── DEPLOYMENT.md
    └── QUICK_START_ATLAS.md
```

## 🤝 **Contributing & Support**

### 🛠️ **Contributing Guidelines**

1. **🍴 Fork the Repository**
   ```bash
   git clone https://github.com/your-username/multimodal-ai-assistant.git
   cd multimodal-ai-assistant
   ```

2. **🌿 Create Feature Branch**
   ```bash
   git checkout -b feature/amazing-new-feature
   ```

3. **💻 Make Your Changes**
   - Follow existing code style
   - Add tests for new features
   - Update documentation
   - Ensure all tests pass

4. **📝 Commit Changes**
   ```bash
   git commit -m "feat: add amazing new feature"
   ```

5. **🚀 Submit Pull Request**
   - Describe your changes
   - Link related issues
   - Request review

### 📚 **Documentation Resources**

| Document | Description | Use Case |
|----------|-------------|----------|
| **📖 README.md** | Main documentation | Overview and setup |
| **🚀 QUICK_START_ATLAS.md** | 5-minute setup guide | Fast deployment |
| **🗄️ MONGODB_ATLAS_SETUP.md** | Database setup | MongoDB Atlas configuration |
| **📱 FLUTTER_INTEGRATION.md** | Flutter client code | Mobile app development |
| **🌐 DEPLOYMENT.md** | Production deployment | Server deployment |
| **📡 API Documentation** | Interactive API docs | Available at `/api-docs` |

### 🆘 **Getting Help**

**🐛 Found a Bug?**
- Check existing [GitHub Issues](https://github.com/your-repo/issues)
- Create detailed bug report with:
  - Steps to reproduce
  - Expected vs actual behavior
  - Environment details
  - Error logs

**💡 Feature Request?**
- Open a [Feature Request](https://github.com/your-repo/issues/new)
- Describe the use case
- Explain expected behavior
- Consider implementation approach

**❓ Need Support?**
- 📚 Check documentation first
- 🔍 Search existing issues
- 💬 Join our [Discord Community](https://discord.gg/your-server)
- 📧 Email: support@your-domain.com

### 🏆 **Contributors**

Thanks to all contributors who have helped make this project better!

<!-- Add contributor avatars here -->

### 📄 **License**

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2024 Multimodal AI Assistant

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
```

---

## 🌟 **Why Choose This Backend?**

### ✅ **Production Ready**
- Enterprise-grade security and authentication
- Comprehensive error handling and logging
- Docker containerization for easy deployment
- MongoDB Atlas integration for scalability

### ✅ **Flutter Optimized**
- Mobile-first API design
- Efficient file upload handling
- Proper error responses for mobile apps
- Complete Flutter integration examples

### ✅ **AI-Powered**
- Latest OpenAI GPT-4 integration
- Multi-modal AI capabilities (text, speech, vision)
- Semantic search with embeddings
- Professional video processing pipeline

### ✅ **Developer Friendly**
- Comprehensive documentation
- Interactive API documentation
- Easy local development setup
- Extensive Flutter code examples

### ✅ **Scalable Architecture**
- Microservices-ready design
- Rate limiting and quota management
- MongoDB Atlas for global scaling
- Cloud deployment ready

---

**🚀 Ready to build the next generation of AI-powered mobile apps? Get started now!**

```bash
# Quick start in 5 minutes
git clone https://github.com/your-repo/multimodal-ai-assistant.git
cd multimodal-ai-assistant
cp .env.example .env
# Add your MongoDB Atlas URI and OpenAI API key
docker-compose -f docker-compose.atlas.yml up -d
```

**📱 Start building your Flutter app with our complete integration guide!**

