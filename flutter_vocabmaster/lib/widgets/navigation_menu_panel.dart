import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';

class MenuItemData {
  final String id;
  final String label;
  final IconData icon;
  
  MenuItemData({
    required this.id,
    required this.label,
    required this.icon,
  });
}

class NavigationMenuPanel extends StatefulWidget {
  final String activeTab;
  final String currentPage;
  final Function(String) onTabChange;
  final Function(String) onNavigate;

  const NavigationMenuPanel({
    required this.activeTab,
    required this.currentPage,
    required this.onTabChange,
    required this.onNavigate,
    Key? key,
  }) : super(key: key);

  @override
  _NavigationMenuPanelState createState() => _NavigationMenuPanelState();
}

class _NavigationMenuPanelState extends State<NavigationMenuPanel> 
    with TickerProviderStateMixin {
  late List<AnimationController> _orbControllers;
  late List<AnimationController> _rainControllers;
  late List<AnimationController> _sparkleControllers;

  final List<MenuItemData> mainPages = [
    MenuItemData(id: 'profile-settings', label: 'Profil', icon: Icons.person),
    MenuItemData(id: 'home', label: 'Ana Sayfa', icon: Icons.home),
    MenuItemData(id: 'words', label: 'Kelimeler', icon: Icons.book),
    MenuItemData(id: 'sentences', label: 'Cümleler', icon: Icons.description),
    MenuItemData(id: 'practice', label: 'Pratik', icon: Icons.school),
    // MVP: Social features disabled for v1.0
    // MenuItemData(id: 'chat', label: 'Sohbet', icon: Icons.chat_bubble),
    // MenuItemData(id: 'feed', label: 'Social Feed', icon: Icons.rss_feed),
    // MenuItemData(id: 'notifications', label: 'Bildirimler', icon: Icons.notifications),
    MenuItemData(id: 'stats', label: 'İstatistikler', icon: Icons.bar_chart),
  ];

  final List<MenuItemData> specialPages = [
    MenuItemData(id: 'speaking', label: 'Konuşma', icon: Icons.chat_bubble_outline),
    MenuItemData(id: 'repeat', label: 'Tekrar', icon: Icons.replay),
    MenuItemData(id: 'dictionary', label: 'Sözlük', icon: Icons.book),
    MenuItemData(id: 'xp-history', label: 'XP Geçmişi', icon: Icons.history),
  ];

  @override
  void initState() {
    super.initState();
    _initAnimationControllers();
  }

  void _initAnimationControllers() {
    // Orb controllers
    _orbControllers = List.generate(3, (i) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(seconds: 10 + i * 2),
      );
      controller.repeat();
      return controller;
    });

    // Rain controllers
    _rainControllers = List.generate(20, (i) {
      final duration = 2.0 + Random().nextDouble() * 2;
      final delay = Random().nextDouble() * 3;
      
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: (duration * 1000).toInt()),
      );
      
      Future.delayed(Duration(milliseconds: (delay * 1000).toInt()), () {
        if (mounted) controller.repeat();
      });
      
      return controller;
    });

    // Sparkle controllers
    _sparkleControllers = List.generate(10, (i) {
      final duration = 2.0 + Random().nextDouble() * 2;
      final delay = Random().nextDouble() * 3;
      
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

  @override
  void dispose() {
    for (var controller in _orbControllers) {
      controller.dispose();
    }
    for (var controller in _rainControllers) {
      controller.dispose();
    }
    for (var controller in _sparkleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleNavigation(String pageId) {
    // Determine if it's a tab change or navigation
    // Based on user logic:
    // Tabs: home (0), words (1), sentences (3), practice (4)
    // Navigations: profile-settings, chat, stats, speaking, repeat, dictionary
    
    // We pass the ID back to the parent to handle
    if (['home', 'words', 'sentences', 'practice'].contains(pageId)) {
        widget.onTabChange(pageId);
    } else {
        widget.onNavigate(pageId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer( // Wrapped in Drawer to work with Scaffold.drawer
      backgroundColor: Colors.transparent,
      elevation: 0,
      width: 320, // As per prompt container width
      child: Container(
        width: 320,
        height: double.infinity,
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
            // Layer 2: Animated effects
            _buildAnimatedEffects(),
            
            // Layer 3: Content
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    children: [
                      // Main Pages
                      _buildSectionHeader(
                        'Ana Sayfalar',
                        const Color(0xFF67E8F9),  // cyan-300
                        const Color(0xFF3B82F6),  // blue-500
                      ),
                      const SizedBox(height: 6),
                      ...mainPages.map((page) => _buildMenuItemWrapper(page)).toList(),
                      
                      const SizedBox(height: 24),
                      
                      // Special Pages
                      _buildSectionHeader(
                        'Özel Sayfalar',
                        const Color(0xFFC084FC),  // purple-300
                        const Color(0xFFEC4899),  // pink-500
                      ),
                      const SizedBox(height: 6),
                      ...specialPages.map((page) => _buildMenuItemWrapper(page)).toList(),
                    ],
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItemWrapper(MenuItemData page) {
      // Determine if active
      bool isActive = false;
      if (['home', 'words', 'sentences', 'practice'].contains(page.id)) {
          isActive = widget.activeTab == page.id;
      } else {
          isActive = widget.currentPage == page.id;
      }
      
      // Colors based on section
      final bool isSpecial = specialPages.contains(page);
      
      return _buildMenuItem(
        item: page,
        isActive: isActive,
        onTap: () => _handleNavigation(page.id),
        activeStartColor: isSpecial ? const Color(0xFFA855F7) : const Color(0xFF06B6D4),
        activeEndColor: isSpecial ? const Color(0xFFEC4899) : const Color(0xFF3B82F6),
        iconColor: isSpecial ? const Color(0xFFC084FC) : const Color(0xFF67E8F9),
        shadowColor: isSpecial ? const Color(0x4DA855F7) : const Color(0x4D06B6D4),
      );
  }

  Widget _buildAnimatedEffects() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            ...List.generate(3, (i) => _buildGlowingOrb(i)),
            ...List.generate(20, (i) => _buildRainDrop(i)),
            ...List.generate(10, (i) => _buildSparkle(i)),
          ],
        ),
      ),
    );
  }

  Widget _buildGlowingOrb(int index) {
    return AnimatedBuilder(
      animation: _orbControllers[index],
      builder: (context, child) {
        final value = _orbControllers[index].value;
        final scale = 1.0 + 0.3 * sin(value * 2 * pi);
        final opacity = 0.3 + 0.3 * sin(value * 2 * pi);
        final offsetX = 20 * sin(value * 2 * pi);
        final offsetY = -30 * cos(value * 2 * pi);
        
        return Positioned(
          left: index * 30.0 * 3.2 + offsetX,
          top: index * 40.0 * 6 + offsetY,
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: 256,
                height: 256,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      index % 2 == 0
                        ? const Color(0x1A06B6D4)
                        : const Color(0x1A3B82F6),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRainDrop(int index) {
    final size = 2.0 + Random().nextDouble() * 3;
    final initialX = Random().nextDouble() * 320;
    
    return AnimatedBuilder(
      animation: _rainControllers[index],
      builder: (context, child) {
        final value = _rainControllers[index].value;
        final yPos = -20 + (800 * value);
        final opacity = value < 0.2 
          ? value / 0.2 
          : value > 0.8 
            ? (1 - value) / 0.2 
            : 1.0;
        
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
                    Color(0x8006B6D4),
                    Color(0x3306B6D4),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(size),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x4D06B6D4),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSparkle(int index) {
    final left = Random().nextDouble() * 320;
    final top = Random().nextDouble() * 800;
    
    return AnimatedBuilder(
      animation: _sparkleControllers[index],
      builder: (context, child) {
        final value = _sparkleControllers[index].value;
        final scale = value < 0.5 ? value * 3 : (1 - value) * 3;
        final opacity = value < 0.5 ? value * 2 : (1 - value) * 2;
        
        return Positioned(
          left: left,
          top: top,
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFF22D3EE),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x8022D3EE),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: const BoxDecoration(
        color: Color(0x0DFFFFFF),
        border: Border(
          bottom: BorderSide(
            color: Color(0x3322D3EE),
            width: 1,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF06B6D4),
                      Color(0xFF3B82F6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x4D06B6D4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFF67E8F9),
                          Color(0xFF3B82F6),
                        ],
                      ).createShader(bounds),
                      child: const Text(
                        'VocabMaster',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: Color(0xB367E8F9),
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Navigasyon',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xB367E8F9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Color(0xB3FFFFFF), size: 20),
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
    );
  }

  Widget _buildSectionHeader(String title, Color startColor, Color endColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [startColor, endColor],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: startColor.withOpacity(0.8),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required MenuItemData item,
    required bool isActive,
    required VoidCallback onTap,
    required Color activeStartColor,
    required Color activeEndColor,
    required Color iconColor,
    required Color shadowColor,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(-20 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            // Wrapping Material to ensure ink splash works over container
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(12),
                  splashColor: activeStartColor.withOpacity(0.2),
                  highlightColor: activeStartColor.withOpacity(0.1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isActive
                        ? LinearGradient(
                            colors: [activeStartColor, activeEndColor],
                          )
                        : null,
                      color: isActive ? null : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: shadowColor,
                              blurRadius: 16,
                              spreadRadius: 0,
                            ),
                          ]
                        : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          size: 20,
                          color: isActive ? Colors.white : iconColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: isActive ? Colors.white : const Color(0xCCFFFFFF),
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                        if (isActive) _buildPulsingDot(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: const SizedBox.shrink(), // Not used, builder is used
    );
  }

  Widget _buildPulsingDot() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(seconds: 2),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeInOut,
      onEnd: () {
        if (mounted) setState(() {});
      },
      builder: (context, value, child) {
        final scale = 1.0 + 0.2 * sin(value * 2 * pi);
        final opacity = 0.7 + 0.3 * sin(value * 2 * pi);
        
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x80FFFFFF),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0x1A06B6D4),
            Color(0x1A3B82F6),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: Color(0x3322D3EE),
            width: 1,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Column(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFF67E8F9),
                    Color(0xFF3B82F6),
                  ],
                ).createShader(bounds),
                child: const Text(
                  'VocabMaster v1.0',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '© 2026 Tüm hakları saklıdır',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0x8067E8F9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
