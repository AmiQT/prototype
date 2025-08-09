import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../models/profile_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  Future<ProfileModel?> _getProfile(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final profileService = Provider.of<ProfileService>(context, listen: false);
    final userId = authService.currentUser?.uid;
    if (userId == null) return null;
    return await profileService.getProfileByUserId(userId);
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _controller.clear();

    final profile = await _getProfile(context);
    final userInfo = profile != null
        ? '\nUser Profile:\nName: ${profile.fullName}\nProgram: ${profile.program}\nDepartment: ${profile.department}\nBio: ${profile.bio ?? ''}\nSkills: ${profile.skills.join(', ')}\nInterests: ${profile.interests.join(', ')}'
        : '';
    final prompt = '$text\n$userInfo';

    try {
      final apiKey = dotenv.env['OPENROUTER_API_KEY'];
      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'qwen/qwen1.5-32b-chat',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply =
            data['choices'][0]['message']['content'] ?? 'No response.';
        setState(() {
          _messages.add(_ChatMessage(text: reply, isUser: false));
          _isLoading = false;
        });
      } else {
        setState(() {
          String errorMessage = 'Failed to get response from chatbot';
          if (response.statusCode == 401) {
            errorMessage =
                'API authentication failed. Please check configuration.';
          } else if (response.statusCode == 429) {
            errorMessage = 'Rate limit exceeded. Please try again later.';
          } else if (response.statusCode >= 500) {
            errorMessage = 'Server error. Please try again later.';
          }

          _messages.add(_ChatMessage(text: errorMessage, isUser: false));
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        String errorMessage =
            'Connection error. Please check your internet connection.';
        if (e.toString().contains('timeout')) {
          errorMessage = 'Request timed out. Please try again.';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your connection.';
        }

        _messages.add(_ChatMessage(text: errorMessage, isUser: false));
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chatbot'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment:
                      msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: msg.isUser ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg.text),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: _sendMessage,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed:
                      _isLoading ? null : () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}
