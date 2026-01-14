import 'package:flutter/material.dart';
import '../widgets/animated_background.dart';
import '../widgets/modern_card.dart';
import '../widgets/modern_background.dart';

class ChatDetailPage extends StatefulWidget {
  final String name;
  final String avatar;
  final String status;

  const ChatDetailPage({
    Key? key,
    required this.name,
    required this.avatar,
    required this.status,
  }) : super(key: key);

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();

  final List<Map<String, dynamic>> messages = [
    {
      'text': 'Hey! Bugün İngilizce pratiği yapalım mı?',
      'isMe': false,
      'time': '14:30',
    },
    {
      'text': 'Tabii, harika fikir! Hangi konuda pratik yapalım?',
      'isMe': true,
      'time': '14:32',
    },
    {
      'text': 'Daily routines hakkında konuşalım. What\'s your morning routine?',
      'isMe': false,
      'time': '14:33',
    },
    {
      'text': 'I usually wake up at 7 AM, then I have breakfast and go for a walk.',
      'isMe': true,
      'time': '14:35',
    },
    {
      'text': 'That sounds great! I also enjoy morning walks. They help me clear my mind.',
      'isMe': false,
      'time': '14:37',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent for AnimatedBackground
      body: Stack(
        children: [
          const AnimatedBackground(isDark: true),
          Column(
            children: [
              // Custom AppBar
              // Custom AppBar
              // Custom AppBar
              SafeArea(
                bottom: false,
                child: ModernCard(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  variant: BackgroundVariant.primary,
                  showBorder: false, // Cleaner look for full width
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFF22d3ee),
                            child: Text(widget.avatar, style: const TextStyle(fontSize: 20)),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF1e1b4b), width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.name,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const Row(
                              children: [
                                CircleAvatar(radius: 3, backgroundColor: Colors.green),
                                SizedBox(width: 4),
                                Text('Çevrimiçi', style: TextStyle(color: Colors.white54, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.videocam_outlined, color: Colors.white70), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.phone_outlined, color: Colors.white70), onPressed: () {}),
                    ],
                  ),
                ),
              ),

              // Messages
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return _buildMessageBubble(msg);
                  },
                ),
              ),

              // Message Input
              // Message Input
              // Message Input
              SafeArea(
                top: false,
                child: ModernCard(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), // Extra bottom padding for safe area logic
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  variant: BackgroundVariant.primary,
                  showBorder: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: TextField(
                            controller: _messageController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Mesajınızı yazın...',
                              hintStyle: TextStyle(color: Colors.white38),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Send Button
                      GestureDetector(
                        onTap: () {},
                        child: ModernCard(
                          width: 48,
                          height: 48,
                          padding: EdgeInsets.zero,
                          borderRadius: BorderRadius.circular(12),
                          variant: BackgroundVariant.accent,
                          showGlow: true,
                          child: const Center(
                            child: Icon(Icons.send, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isMe = msg['isMe'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              gradient: isMe
                  ? const LinearGradient(colors: [Color(0xFF06b6d4), Color(0xFF3182ce)])
                  : null,
              color: isMe ? null : const Color(0xFF334155).withOpacity(0.5),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              msg['text'],
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            msg['time'],
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
