import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/global_matchmaking_sheet.dart';
import '../widgets/navigation_menu_panel.dart';
import '../main.dart'; // For MainScreen
import 'chat_list_page.dart';
import 'quick_dictionary_page.dart';
import 'review_page.dart';
import 'profile_page.dart';
import 'stats_page.dart';

// ---------------------------------------------------------------------------
// DATA MODELS
// ---------------------------------------------------------------------------

class Award {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final List<Color> gradientColors;
  int count;

  Award({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.gradientColors,
    this.count = 0,
  });
}

class Comment {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String content;
  final String timestamp;
  final int likes;

  Comment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.content,
    required this.timestamp,
    required this.likes,
  });
}

class Post {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String userHandle;
  final String timestamp;
  final String content;
  final String? imageUrl;
  int likes;
  final List<Comment> comments;
  bool bookmarked;
  bool liked;
  bool following;
  final List<Award> awards;

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.userHandle,
    required this.timestamp,
    required this.content,
    this.imageUrl,
    required this.likes,
    required this.comments,
    required this.bookmarked,
    required this.liked,
    required this.following,
    required this.awards,
  });
}

// ---------------------------------------------------------------------------
// MAIN PAGE
// ---------------------------------------------------------------------------

class SocialFeedPage extends StatefulWidget {
  const SocialFeedPage({Key? key}) : super(key: key);

  @override
  _SocialFeedPageState createState() => _SocialFeedPageState();
}

class _SocialFeedPageState extends State<SocialFeedPage> 
    with TickerProviderStateMixin {
  List<Post> posts = [];
  bool showCreatePost = false;
  TextEditingController newPostController = TextEditingController();
  Set<String> expandedComments = {};
  Map<String, TextEditingController> commentControllers = {};
  String? activeAwardMenu;
  late List<AnimationController> _rainControllers;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _initPosts();
    _initRainAnimations();
  }

  @override
  void dispose() {
    newPostController.dispose();
    for (var c in commentControllers.values) {
      c.dispose();
    }
    for (var c in _rainControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _initRainAnimations() {
    _rainControllers = List.generate(40, (i) {
      final duration = 3.0 + Random().nextDouble() * 3;
      final delay = Random().nextDouble() * 5;
      
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: (duration * 1000).toInt()),
      );
      
      Future.delayed(Duration(milliseconds: (delay * 1000).toInt()), () {
        if (mounted) controller.repeat();
      });
      
      return controller;
    });
  }

  // ---------------------------------------------------------------------------
  // SAMPLE DATA
  // ---------------------------------------------------------------------------

  List<Award> _getAvailableAwards() {
    return [
      Award(
        id: 'wholesome',
        name: 'Wholesome',
        icon: Icons.favorite,  // Heart
        color: const Color(0xFFFF6B9D),
        gradientColors: [const Color(0xFFF9A8D4), const Color(0xFFF43F5E)],  // pink-400 to rose-500
      ),
      Award(
        id: 'helpful',
        name: 'Helpful',
        icon: Icons.lightbulb,
        color: const Color(0xFFFBBF24),
        gradientColors: [const Color(0xFFFBBF24), const Color(0xFFF97316)],  // yellow-400 to orange-500
      ),
      Award(
        id: 'rocket',
        name: 'Rocket',
        icon: Icons.rocket_launch,
        color: const Color(0xFF06B6D4),
        gradientColors: [const Color(0xFF22D3EE), const Color(0xFF3B82F6)],  // cyan-400 to blue-500
      ),
      Award(
        id: 'star',
        name: 'Star',
        icon: Icons.star,
        color: const Color(0xFFA78BFA),
        gradientColors: [const Color(0xFFC084FC), const Color(0xFF6366F1)],  // purple-400 to indigo-500
      ),
      Award(
        id: 'fire',
        name: 'Fire',
        icon: Icons.local_fire_department,
        color: const Color(0xFFF97316),
        gradientColors: [const Color(0xFFF97316), const Color(0xFFDC2626)],  // orange-500 to red-600
      ),
    ];
  }

  void _initPosts() {
    posts = [
      Post(
        id: '1',
        userId: 'user1',
        userName: 'Sarah Johnson',
        userAvatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Sarah',
        userHandle: '@sarahj',
        timestamp: '2 saat önce',
        content: "Just completed my 100-day streak on VocabMaster! 🎉 The key is consistency. Every single day, even if it's just 5 minutes, makes a huge difference. What's your longest streak? #EnglishLearning #Motivation",
        imageUrl: null,
        likes: 42,
        comments: [
          Comment(
            id: 'c1',
            userId: 'user2',
            userName: 'Mike Chen',
            userAvatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Mike',
            content: 'Congrats! That\'s amazing dedication 👏',
            timestamp: '1 saat önce',
            likes: 5,
          ),
        ],
        bookmarked: false,
        liked: false,
        following: false,
        awards: [
          Award(id: 'wholesome', name: 'Wholesome', icon: Icons.favorite, 
                color: const Color(0xFFFF6B9D), 
                gradientColors: [const Color(0xFFF9A8D4), const Color(0xFFF43F5E)], count: 3),
          Award(id: 'helpful', name: 'Helpful', icon: Icons.lightbulb, 
                color: const Color(0xFFFBBF24), 
                gradientColors: [const Color(0xFFFBBF24), const Color(0xFFF97316)], count: 0),
          Award(id: 'rocket', name: 'Rocket', icon: Icons.rocket_launch, 
                color: const Color(0xFF06B6D4), 
                gradientColors: [const Color(0xFF22D3EE), const Color(0xFF3B82F6)], count: 5),
          Award(id: 'star', name: 'Star', icon: Icons.star, 
                color: const Color(0xFFA78BFA), 
                gradientColors: [const Color(0xFFC084FC), const Color(0xFF6366F1)], count: 0),
          Award(id: 'fire', name: 'Fire', icon: Icons.local_fire_department, 
                color: const Color(0xFFF97316), 
                gradientColors: [const Color(0xFFF97316), const Color(0xFFDC2626)], count: 2),
        ],
      ),
      
      Post(
        id: '2',
        userId: 'user3',
        userName: 'Emma Williams',
        userAvatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Emma',
        userHandle: '@emmaw',
        timestamp: '5 saat önce',
        content: "Pro tip: Watch your favorite Netflix shows in English with English subtitles. I've learned so many phrasal verbs this way! Currently binge-watching Stranger Things 📺 What shows do you recommend?",
        imageUrl: 'https://images.unsplash.com/photo-1522869635100-9f4c5e86aa37?w=800&q=80',
        likes: 87,
        comments: [],
        bookmarked: true,
        liked: true,
        following: true,
        awards: [
          Award(id: 'wholesome', name: 'Wholesome', icon: Icons.favorite, 
                color: const Color(0xFFFF6B9D), 
                gradientColors: [const Color(0xFFF9A8D4), const Color(0xFFF43F5E)], count: 1),
          Award(id: 'helpful', name: 'Helpful', icon: Icons.lightbulb, 
                color: const Color(0xFFFBBF24), 
                gradientColors: [const Color(0xFFFBBF24), const Color(0xFFF97316)], count: 12),
          Award(id: 'rocket', name: 'Rocket', icon: Icons.rocket_launch, 
                color: const Color(0xFF06B6D4), 
                gradientColors: [const Color(0xFF22D3EE), const Color(0xFF3B82F6)], count: 0),
          Award(id: 'star', name: 'Star', icon: Icons.star, 
                color: const Color(0xFFA78BFA), 
                gradientColors: [const Color(0xFFC084FC), const Color(0xFF6366F1)], count: 7),
          Award(id: 'fire', name: 'Fire', icon: Icons.local_fire_department, 
                color: const Color(0xFFF97316), 
                gradientColors: [const Color(0xFFF97316), const Color(0xFFDC2626)], count: 0),
        ],
      ),
      
      Post(
        id: '3',
        userId: 'user4',
        userName: 'David Lee',
        userAvatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=David',
        userHandle: '@davidlee',
        timestamp: '1 gün önce',
        content: "Finally understood the difference between 'affect' and 'effect'! 💡\n\nAffect = verb (to influence)\nEffect = noun (the result)\n\nExample: The weather affected my mood. The effect was immediate.\n\nGrammar is tough but we got this! 💪",
        imageUrl: null,
        likes: 156,
        comments: [
          Comment(
            id: 'c2',
            userId: 'user5',
            userName: 'Lisa Park',
            userAvatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Lisa',
            content: 'This is so helpful! I always mix these up 😅',
            timestamp: '20 saat önce',
            likes: 8,
          ),
          Comment(
            id: 'c3',
            userId: 'user6',
            userName: 'Tom Anderson',
            userAvatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Tom',
            content: 'Great explanation! Saved this post for future reference.',
            timestamp: '18 saat önce',
            likes: 3,
          ),
        ],
        bookmarked: false,
        liked: false,
        following: false,
        awards: [
          Award(id: 'wholesome', name: 'Wholesome', icon: Icons.favorite, 
                color: const Color(0xFFFF6B9D), 
                gradientColors: [const Color(0xFFF9A8D4), const Color(0xFFF43F5E)], count: 0),
          Award(id: 'helpful', name: 'Helpful', icon: Icons.lightbulb, 
                color: const Color(0xFFFBBF24), 
                gradientColors: [const Color(0xFFFBBF24), const Color(0xFFF97316)], count: 24),
          Award(id: 'rocket', name: 'Rocket', icon: Icons.rocket_launch, 
                color: const Color(0xFF06B6D4), 
                gradientColors: [const Color(0xFF22D3EE), const Color(0xFF3B82F6)], count: 3),
          Award(id: 'star', name: 'Star', icon: Icons.star, 
                color: const Color(0xFFA78BFA), 
                gradientColors: [const Color(0xFFC084FC), const Color(0xFF6366F1)], count: 0),
          Award(id: 'fire', name: 'Fire', icon: Icons.local_fire_department, 
                color: const Color(0xFFF97316), 
                gradientColors: [const Color(0xFFF97316), const Color(0xFFDC2626)], count: 1),
        ],
      ),
    ];
  }

  void _createPost() {
    if (newPostController.text.trim().isEmpty) return;
    
    setState(() {
      posts.insert(0, Post(
        id: 'post-${DateTime.now().millisecondsSinceEpoch}',
        userId: 'current-user',
        userName: 'Ahmet Yılmaz',
        userAvatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=current',
        userHandle: '@ahmetyilmaz',
        timestamp: 'Şimdi',
        content: newPostController.text,
        imageUrl: null,
        likes: 0,
        comments: [],
        bookmarked: false,
        liked: false,
        following: false,
        awards: _getAvailableAwards(),
      ));
      newPostController.clear();
      showCreatePost = false;
    });
  }
  
  void _addComment(Post post, String text) {
    if (text.trim().isEmpty) return;
    
    setState(() {
      post.comments.add(
        Comment(
          id: 'comment-${DateTime.now().millisecondsSinceEpoch}',
          userId: 'current-user',
          userName: 'Ahmet Yılmaz',
          userAvatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=current',
          content: text,
          timestamp: 'Şimdi',
          likes: 0,
        ),
      );
      commentControllers[post.id]!.clear();
    });
  }

  // ---------------------------------------------------------------------------
  // WIDGET BUILDERS
  // ---------------------------------------------------------------------------

  Widget _buildRainDrop(int index) {
    final size = 2.0 + Random().nextDouble() * 4;
    // Ensure we have enough controllers or default to 0
    if (index >= _rainControllers.length) return const SizedBox();
    
    final initialX = Random().nextDouble() * MediaQuery.of(context).size.width;
    
    return AnimatedBuilder(
      animation: _rainControllers[index],
      builder: (context, child) {
        final value = _rainControllers[index].value;
        final yPos = -20 + (MediaQuery.of(context).size.height + 100) * value;
        
        double opacity = 1.0;
        if (value < 0.2) {
          opacity = value / 0.2;
        } else if (value > 0.8) {
          opacity = (1 - value) / 0.2;
        }
        
        return Positioned(
          left: initialX,
          top: yPos,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: size,
              height: size * 3,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x9906B6D4),  // cyan-500 60%
                    Color(0x4D06B6D4),  // cyan-500 30%
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(size),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x6606B6D4),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedBackground() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: List.generate(40, (i) => _buildRainDrop(i)),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0x1A06B6D4),  // cyan-500 10%
            Color(0x1A3B82F6),  // blue-500 10%
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: Color(0x3322D3EE),  // cyan-400 20%
            width: 1,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Menu Button -> Changed to Back Button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF22D3EE), size: 24),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0x1AFFFFFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  
                  // Title
                  Row(
                    children: [
                      const Icon(Icons.trending_up, color: Color(0xFF22D3EE), size: 24),
                      const SizedBox(width: 8),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFF22D3EE),  // cyan-400
                            Color(0xFF3B82F6),  // blue-500
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          'Social Feed',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Friends Button
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.people, color: Color(0xFF22D3EE), size: 24),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0x1AFFFFFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String name, {double size = 48}) {
    // Generate initials
    String initials = '';
    final nameParts = name.trim().split(' ');
    if (nameParts.isNotEmpty) {
      initials = nameParts[0][0].toUpperCase();
      if (nameParts.length > 1) {
        initials += nameParts[1][0].toUpperCase();
      }
    }
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF22D3EE), Color(0xFF3B82F6)], // Cyan to Blue
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0x8022D3EE),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildUserHeader(Post post) {
    return Row(
      children: [
        // Avatar
        _buildAvatar(post.userName),
        
        const SizedBox(width: 12),
        
        // User Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      post.userHandle,
                      style: const TextStyle(
                        color: Color(0xB367E8F9),
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '•',
                    style: TextStyle(color: Color(0xB367E8F9)),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    post.timestamp,
                    style: const TextStyle(
                      color: Color(0xB367E8F9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Follow Button
        ElevatedButton(
          onPressed: () {
            setState(() {
              post.following = !post.following;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: post.following ? const Color(0x1AFFFFFF) : const Color(0xFF06B6D4), // Cyan if not following
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: Size.zero, 
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: post.following 
                ? const BorderSide(color: Color(0x4D22D3EE))
                : BorderSide.none,
            ),
          ),
          child: Text(
            post.following ? 'Takipte' : 'Takip Et',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        
        const SizedBox(width: 4),
        
        // More Button
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.more_horiz, color: Color(0xB3FFFFFF)),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Widget _buildPostContent(Post post) {
    return Text(
      post.content,
      style: const TextStyle(
        color: Color(0xE6FFFFFF),  // white 90%
        fontSize: 15,
        height: 1.5,
      ),
    );
  }

  Widget _buildPostImage(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0x3322D3EE),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Image.network(
          imageUrl,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
             // Fallback if post content image fails (less likely than avatar issues for now)
             return Container(
               height: 200,
               color: Colors.white.withOpacity(0.05),
               child: const Center(child: Icon(Icons.image_not_supported, color: Colors.white24, size: 48)),
             );
          },
        ),
      ),
    );
  }

  Widget _buildAwardsDisplay(Post post) {
    final activeAwards = post.awards.where((a) => a.count > 0).toList();
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: activeAwards.map((award) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: award.gradientColors.map((c) => c.withOpacity(0.2)).toList(),
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0x33FFFFFF),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                award.icon,
                size: 16,
                color: award.color,
              ),
              const SizedBox(width: 6),
              Text(
                '${award.count}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                award.name,
                style: const TextStyle(
                  color: Color(0xB3FFFFFF),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    List<Color>? activeGradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // Reduced padding
        decoration: BoxDecoration(
          gradient: isActive && activeGradient != null
            ? LinearGradient(colors: activeGradient)
            : null,
          color: isActive && activeGradient == null 
            ? const Color(0x1AFFFFFF) 
            : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive && activeGradient != null
            ? [
                BoxShadow(
                  color: activeGradient[0].withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ]
            : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18, // Slightly smaller icon
              color: Colors.white,
            ),
            if (label.isNotEmpty) ...[
               const SizedBox(width: 4),
               Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13, // Slightly smaller font
                  fontWeight: FontWeight.w500,
                ),
               ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAwardButton(Post post) {
    return PopupMenuButton<Award>(
      offset: const Offset(0, -10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0x4D22D3EE)),
      ),
      color: const Color(0xFF1E293B),  // slate-800
      onSelected: (award) {
        setState(() {
          final index = post.awards.indexWhere((a) => a.id == award.id);
          if (index != -1) {
            post.awards[index].count++;
          }
        });
      },
      itemBuilder: (context) {
        return _getAvailableAwards().map((award) {
          return PopupMenuItem<Award>(
            value: award,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: award.gradientColors),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      award.icon,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    award.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: Color(0xB3FFFFFF), size: 18),
            // Removed text 'Award' to save space or just keep it small if preferred, 
            // but for overflow fix, removing or flexible is best. Let's keep icon only or very short.
            // Sized box was here.
          ],
        ),
      ),
    );
  }

  Widget _buildCommentItem(Comment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(comment.userName, size: 32),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x0DFFFFFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        comment.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        comment.timestamp,
                        style: const TextStyle(
                          color: Color(0x80FFFFFF),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment.content,
                    style: const TextStyle(
                      color: Color(0xCCFFFFFF),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(Post post) {
    if (!commentControllers.containsKey(post.id)) {
      commentControllers[post.id] = TextEditingController();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Existing Comments
        ...post.comments.map((comment) => _buildCommentItem(comment)),
        
        if (post.comments.isNotEmpty) const SizedBox(height: 16),
        
        // Add Comment
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildAvatar('Ahmet Yılmaz', size: 32),
            
            const SizedBox(width: 12),
            
            Expanded(
              child: TextField(
                controller: commentControllers[post.id],
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Yorum ekle...',
                  hintStyle: const TextStyle(color: Color(0x66FFFFFF)),
                  filled: true,
                  fillColor: const Color(0x0DFFFFFF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0x3322D3EE)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0x3322D3EE)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0x8022D3EE)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (text) => _addComment(post, text),
              ),
            ),
            
            const SizedBox(width: 8),
            
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x4D06B6D4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () {
                  final text = commentControllers[post.id]!.text;
                  _addComment(post, text);
                },
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(Post post) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute space evenly
      children: [
        // Like Button
        _buildActionButton(
          icon: post.liked ? Icons.favorite : Icons.favorite_border,
          label: '${post.likes}',
          isActive: post.liked,
          activeGradient: [const Color(0xFFEC4899), const Color(0xFFF43F5E)],  // pink to rose
          onTap: () {
            setState(() {
              post.liked = !post.liked;
              post.likes += post.liked ? 1 : -1;
            });
          },
        ),
        
        // Comment Button
        _buildActionButton(
          icon: Icons.chat_bubble_outline,
          label: '${post.comments.length}',
          isActive: false,
          onTap: () {
            setState(() {
              if (expandedComments.contains(post.id)) {
                expandedComments.remove(post.id);
              } else {
                expandedComments.add(post.id);
              }
            });
          },
        ),
        
        // Award Button with Menu
        _buildAwardButton(post),
        
        // Bookmark Button
        IconButton(
          onPressed: () {
            setState(() {
              post.bookmarked = !post.bookmarked;
            });
          },
          icon: Icon(
            post.bookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: Colors.white,
            size: 20,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        
        // Share Button
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.share, color: Color(0xB3FFFFFF), size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          style: IconButton.styleFrom(
             tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Widget _buildPostCard(Post post, int index) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16), // Slightly reduced padding
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0x661E293B),  // slate-800 40%
              Color(0x661E3A8A),  // blue-900 40%
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0x3322D3EE),  // cyan-400 20%
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserHeader(post),
                const SizedBox(height: 12),
                _buildPostContent(post),
                if (post.imageUrl != null) ...[
                  const SizedBox(height: 16),
                  _buildPostImage(post.imageUrl!),
                ],
                if (post.awards.any((a) => a.count > 0)) ...[
                  const SizedBox(height: 16),
                  _buildAwardsDisplay(post),
                ],
                const SizedBox(height: 16),
                const Divider(color: Color(0x1AFFFFFF), height: 1),
                const SizedBox(height: 12),
                _buildActionButtons(post),
                if (expandedComments.contains(post.id)) ...[
                  const SizedBox(height: 16),
                  const Divider(color: Color(0x1AFFFFFF), height: 1),
                  const SizedBox(height: 16),
                  _buildCommentsSection(post),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Positioned(
      right: 24,
      bottom: 96,  // Above bottom nav
      child: GestureDetector(
        onTap: () {
          setState(() {
            showCreatePost = true;
          });
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x8006B6D4),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildCreatePostModal() {
    return Stack(
      children: [
        // Backdrop
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              setState(() {
                showCreatePost = false;
              });
            },
            child: Container(
              color: const Color(0x99000000),  // black 60%
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
        ),
        
        // Modal
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E293B),  // slate-800
                  Color(0xFF1E3A8A),  // blue-900
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x4D22D3EE)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF22D3EE), Color(0xFF3B82F6)],
                          ).createShader(bounds),
                          child: const Text(
                            'Yeni Paylaşım',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              showCreatePost = false;
                            });
                          },
                          icon: const Icon(Icons.close, color: Color(0xB3FFFFFF)),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // User + Input
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAvatar('Ahmet Yılmaz'),
                        
                        const SizedBox(width: 12),
                        
                        Expanded(
                          child: TextField(
                            controller: newPostController,
                            maxLines: 5,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'İngilizce öğrenme deneyiminizi paylaşın...',
                              hintStyle: const TextStyle(color: Color(0x66FFFFFF)),
                              filled: true,
                              fillColor: const Color(0x0DFFFFFF),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0x3322D3EE)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0x3322D3EE)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0x8022D3EE)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    const Divider(color: Color(0x1AFFFFFF)),
                    const SizedBox(height: 16),
                    
                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.image, color: Color(0xFF22D3EE)),
                        ),
                        
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x4D06B6D4),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: newPostController.text.trim().isEmpty 
                              ? null 
                              : _createPost,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Paylaş',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: NavigationMenuPanel(
        activeTab: '', 
        currentPage: 'feed', 
        onTabChange: (id) {
           Navigator.pop(context); // Close drawer
           
           if (['home', 'words', 'sentences', 'practice'].contains(id)) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => MainScreen(initialIndex: 
                  id == 'home' ? 0 : 
                  id == 'words' ? 1 : 
                  id == 'sentences' ? 3 : 4
                )),
                (route) => false,
              );
           }
        },
        onNavigate: (id) {
           Navigator.pop(context); // Close drawer
           
           if (id == 'feed') return;
           
           if (id == 'chat') {
               Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatListPage()));
           } else if (id == 'speaking') {
               Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 4)), 
                (route) => false,
              );
           } else if (id == 'dictionary') {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QuickDictionaryPage()));
           } else if (id == 'repeat') {
               Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReviewPage())); // Using class directly
           } else if (id == 'profile-settings') {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfilePage()));
           } else if (id == 'stats') {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StatsPage()));
           }
        },
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),  // slate-900
              Color(0xFF1E3A8A),  // blue-900
              Color(0xFF0F172A),  // slate-900
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated Background
            _buildAnimatedBackground(),
            
            // Main Content - Added Padding for BottomNav space if not part of scaffold bottomNavigationBar
            // Actually, if we use scaffold's bottomNavigationBar, the body should automatically adjust if we don't use extendBody.
            // But main app uses extendBody: true. Let's do same here for consistency.
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 16, bottom: 96),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      return _buildPostCard(posts[index], index);
                    },
                  ),
                ),
              ],
            ),
            
            // Floating Action Button
            _buildFloatingActionButton(),
            
            // Create Post Modal
            if (showCreatePost) _buildCreatePostModal(),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const GlobalMatchmakingSheet(),
          BottomNav(
            currentIndex: -1, // No tab selected
            onTap: (index) {
              if (index == 2) {
                 _scaffoldKey.currentState?.openDrawer();
              } else {
                 Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => MainScreen(initialIndex: index)),
                    (route) => false,
                 );
              }
            },
          ),
        ],
      ),
    );
  }
}
