import 'package:flutter/material.dart';
import '../widgets/chat/rich_text_message.dart';
import '../utils/app_theme.dart';

/// Demo screen to showcase rich text formatting capabilities
class RichTextDemo extends StatelessWidget {
  const RichTextDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rich Text Chat Demo'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDemoMessage(
            'User Message (Plain Text)',
            'How can I improve my programming skills for web development?',
            isUser: true,
          ),
          const SizedBox(height: 16),
          _buildDemoMessage(
            'AI Response (Rich Text with Markdown)',
            '''Hello! I'm here to help you with your **academic guidance** and *career development*. It's great to see that you're already skilled in React and interested in web development. Keep up the good work!

**In terms of your academic journey**, focus on leveraging your React skills to build projects that can demonstrate your capabilities. This practical experience will be *invaluable* when you start looking for internships or jobs after graduation.

**For career advice**, consider exploring roles like:
- **Frontend Developer** - Perfect match for your React skills
- **Junior Web Developer** - Great starting position
- **Full-Stack Developer** - Expand into backend technologies

Here are some **actionable steps** you can take:

1. **Build a portfolio** with 3-5 React projects
2. **Learn complementary technologies** like `Node.js`, `Express`, or `TypeScript`
3. **Practice with real-world projects** - contribute to open source
4. **Network with professionals** in the web development field
5. **Apply for internships** to gain practical experience

> Remember: *Consistent practice and building real projects* is the key to mastering web development!

For technical skills, focus on:
- `JavaScript ES6+` fundamentals
- `React Hooks` and modern patterns  
- `CSS Grid` and `Flexbox` for layouts
- `Git` version control
- `REST APIs` and data fetching

Would you like me to elaborate on any of these areas or discuss specific learning resources?''',
            isUser: false,
          ),
        ],
      ),
    );
  }

  Widget _buildDemoMessage(String title, String content, {required bool isUser}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isUser ? AppTheme.primaryColor : AppTheme.surfaceColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: RichTextMessage(
            content: content,
            isUser: isUser,
          ),
        ),
      ],
    );
  }
}
