import 'package:flutter/material.dart';
import '../constants/social_feed_colors.dart';
import '../screens/social_feed_page.dart';
import 'modern_card.dart';
import 'modern_background.dart';

class SocialFeedPreview extends StatelessWidget {
  const SocialFeedPreview({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(24),
      variant: BackgroundVariant.primary,
      showGlow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildPost(
            context,
            name: 'Sarah Johnson',
            time: '2 saat önce',
            content: 'Just completed my 30-day streak! 🔥 Learned 150+ words this month. Consisten...',
            likes: 124,
            comments: 15,
            avatarColor: SocialFeedColors.avatarCyan,
            avatarLetter: 'S',
          ),
          const SizedBox(height: 20),
          _buildPost(
            context,
            name: 'Emma Williams',
            time: '5 saat önce',
            content: 'Pro tip: Watch your favorite Netflix shows in English with English subtitles. I\'ve learne...',
            likes: 87,
            comments: 8,
            avatarColor: SocialFeedColors.avatarPurple,
            avatarLetter: 'E',
          ),
          const SizedBox(height: 24),
          _buildCTAButton(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            const Icon(
              Icons.trending_up_rounded,
              color: SocialFeedColors.avatarCyan,
              size: 28,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Social Feed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Toplulukla paylaş!',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPost(BuildContext context, {
    required String name,
    required String time,
    required String content,
    required int likes,
    required int comments,
    required Color avatarColor,
    required String avatarLetter,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const SocialFeedPage()));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: avatarColor.withOpacity(0.2),
                    border: Border.all(
                      color: avatarColor,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      avatarLetter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        time,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStat(Icons.thumb_up_outlined, likes),
                const SizedBox(width: 20),
                _buildStat(Icons.chat_bubble_outline, comments),
                const Spacer(),
                const Icon(
                  Icons.bookmark_border,
                  color: Colors.white60,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, int count) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white60,
          size: 22,
        ),
        const SizedBox(width: 8),
        Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCTAButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const SocialFeedPage()));
      },
      child: ModernCard(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        borderRadius: BorderRadius.circular(16),
        variant: BackgroundVariant.secondary,
        showBorder: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.trending_up,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 10),
            Text(
              'Tüm Paylaşımları Gör',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
