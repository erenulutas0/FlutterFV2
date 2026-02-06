import 'package:flutter/material.dart';
import '../services/social_service.dart';
import '../widgets/modern_card.dart';
import '../widgets/modern_background.dart';
import '../widgets/animated_background.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final SocialService _socialService = SocialService();
  List<dynamic> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final data = await _socialService.getNotifications();
      if (mounted) {
        setState(() {
          notifications = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bildirimler yüklenemedi')));
      }
    }
  }
  
  Future<void> _markAsRead(int id) async {
    try {
      await _socialService.markNotificationAsRead(id);
      setState(() {
          final index = notifications.indexWhere((n) => n['id'] == id);
          if (index != -1) {
            notifications[index]['isRead'] = true;
          }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(isDark: true),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Bildirimler',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : notifications.isEmpty
                          ? const Center(child: Text('Henüz bildiriminiz yok.', style: TextStyle(color: Colors.white54)))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: notifications.length,
                              itemBuilder: (context, index) {
                                final notification = notifications[index];
                                return _buildNotificationCard(notification);
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final bool isRead = notification['read'] ?? false; // Backend 'read' boolean
    final String message = notification['message'] ?? '';
    final String type = notification['type'] ?? 'INFO'; // LIKE, COMMENT, etc.
    
    IconData icon;
    Color iconColor;
    
    switch (type) {
      case 'LIKE':
        icon = Icons.favorite;
        iconColor = Colors.pink;
        break;
      case 'COMMENT':
        icon = Icons.comment;
        iconColor = Colors.blue;
        break;
      case 'MESSAGE':
        icon = Icons.chat_bubble;
        iconColor = Colors.green;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.amber;
    }

    return GestureDetector(
      onTap: () {
        if (!isRead) {
          _markAsRead(notification['id']);
        }
      },
      child: ModernCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(16),
        variant: isRead ? BackgroundVariant.secondary : BackgroundVariant.primary,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isRead ? Colors.white70 : Colors.white,
                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                ),
              ),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
