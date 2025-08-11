# Enhanced AI Chatbot Setup Guide

This guide will help you set up and test the enhanced AI chatbot module that's optimized for Firebase's free tier.

## 🚀 Quick Start

### 1. API Key Configuration (Gemini Only)

The chatbot now uses Google Gemini exclusively. Provide your Gemini API key using one of these methods:

#### Option A: Assets .env (Recommended for development)
1. Create a file at `mobile_app/assets/.env`
2. Add your key:
```
GEMINI_API_KEY=your-gemini-api-key
```
3. Save and restart the app

#### Option B: Dart define (CI/production without bundling secrets)
```
flutter run --dart-define=GEMINI_API_KEY=your-gemini-api-key
```

### 2. Get Gemini API Key

1. Visit Google AI Studio
2. Create or use an existing API key
3. Copy the key and keep it secure

### 3. Test the Implementation (Gemini)

1. Run the app: `flutter run`
2. Navigate to the chat screen (floating action button)
3. Try sending a message
4. Use the beaker icon on the chat screen to run the built-in Gemini test

## 📊 Firebase Usage Optimization

The enhanced chatbot is designed to work within Firebase's free tier limits:

### Free Tier Limits
- **Firestore Reads**: 50,000/day
- **Firestore Writes**: 20,000/day
- **Firestore Deletes**: 20,000/day
- **Cloud Functions**: 2M invocations/month
- **Storage**: 5GB total

### Optimization Features
- **Local Caching**: Reduces repeated Firestore reads
- **Batch Operations**: Minimizes write operations
- **Usage Monitoring**: Tracks daily consumption
- **Smart Querying**: Efficient data retrieval
- **Content Compression**: Reduces storage usage

## 🔧 Configuration Options

### Chat Configuration
Edit `lib/models/chat_models.dart` to adjust:

```dart
class ChatConfig {
  static const int maxMessagesPerConversation = 50;  // Limit message history
  static const int maxMessageLength = 1000;          // Limit message size
  static const int maxConversationsPerUser = 10;     // Limit conversations
  static const Duration cacheExpiration = Duration(hours: 2);
  static const String defaultModel = 'qwen/qwen1.5-32b-chat';
  static const int maxTokens = 1000;
  static const double temperature = 0.7;
}
```

### Model Selection
Supported OpenRouter models:
- `qwen/qwen1.5-32b-chat` (Default - good balance)
- `openai/gpt-3.5-turbo` (More expensive but better)
- `anthropic/claude-3-haiku` (Fast and efficient)
- `meta-llama/llama-2-70b-chat` (Open source)

## 🧪 Testing Checklist

### Basic Functionality
- [ ] App starts without errors
- [ ] Chat screen loads
- [ ] Can send messages
- [ ] Receives AI responses
- [ ] Error handling works

### API Key Testing
- [ ] Invalid key shows Gemini-specific error
- [ ] Valid key works
- [ ] Retry mechanism works

### Firebase Usage
- [ ] Usage monitoring displays correctly
- [ ] Warnings appear at 80% usage
- [ ] Caching reduces repeated reads
- [ ] Batch operations work

### Error Scenarios
- [ ] Network errors handled gracefully
- [ ] Rate limiting handled
- [ ] Server errors handled
- [ ] Offline functionality

## 🐛 Troubleshooting

### Common Issues

#### "Gemini API key not configured"
- Ensure `assets/.env` exists and contains `GEMINI_API_KEY`
- Or pass via `--dart-define=GEMINI_API_KEY=...`
- Restart the app after adding the key

#### "API authentication failed"
- Verify API key is correct
- Check OpenRouter account status
- Ensure sufficient credits

#### "Daily usage limit reached"
- Check Firebase usage in settings
- Wait for daily reset (midnight UTC)
- Optimize usage patterns

#### Chat not loading
- Check internet connection
- Verify Firebase configuration
- Check console for errors

### Debug Mode
Enable debug logging by setting:
```dart
debugPrint('EnhancedChatService: Debug message');
```

## 📈 Monitoring Usage

### Usage Dashboard
Access through Chat Settings screen:
- Real-time usage statistics
- Percentage of daily limits used
- Optimization suggestions
- Cost estimates for Blaze plan

### Manual Monitoring
Check Firebase Console:
1. Go to Firebase Console
2. Select your project
3. Navigate to Usage tab
4. Monitor Firestore operations

## 🔄 Upgrading to Paid Plan

If you exceed free tier limits:

### When to Upgrade
- Consistent usage above 80% of limits
- More than 500 daily active users
- Need for real-time features

### Blaze Plan Benefits
- Pay-as-you-go pricing
- No daily limits
- Priority support
- Advanced monitoring

### Cost Estimation
Current implementation with 1000+ users:
- Estimated cost: $5-15/month
- Scales with actual usage
- No minimum monthly fee

## 🚀 Advanced Features

### Future Enhancements
- Voice input/output
- File attachments
- Conversation search
- Multi-language support
- Custom AI models

### Performance Optimization
- Implement conversation pagination
- Add message compression
- Use CDN for static content
- Optimize image handling

## 📝 Development Notes

### Architecture
- **Service Layer**: `EnhancedChatService`, `ConversationService`
- **Models**: `ChatMessage`, `ChatConversation`, `ChatUserContext`
- **UI Components**: Modular chat widgets
- **Monitoring**: `FirebaseUsageMonitor`

### Code Structure
```
lib/
├── models/chat_models.dart              # Data models
├── services/
│   ├── enhanced_chat_service.dart       # Main chat logic
│   ├── conversation_service.dart        # Conversation management
│   └── firebase_usage_monitor.dart      # Usage tracking
├── screens/chat/
│   ├── enhanced_chat_screen.dart        # Main chat UI
│   └── chat_settings_screen.dart        # Configuration UI
└── widgets/chat/                        # Reusable components
```

### Testing
Run tests with:
```bash
flutter test test/services/enhanced_chat_service_test.dart
```

## 📞 Support

For issues or questions:
1. Check this guide first
2. Review console logs
3. Test with settings screen
4. Check Firebase usage
5. Verify API key status

## 🎯 Success Metrics

The enhanced chatbot is working correctly when:
- ✅ Messages send and receive within 5 seconds
- ✅ Firebase usage stays under 80% of daily limits
- ✅ Error rates are below 5%
- ✅ User context is properly integrated
- ✅ Caching reduces redundant operations

## 🔐 Security Notes

- API keys are stored securely in `.env`
- User data is cached locally with encryption
- Firebase rules restrict access appropriately
- Content moderation prevents abuse
- Rate limiting prevents spam

---

**Ready to test?** Start with the Quick Start section and work through the testing checklist!
