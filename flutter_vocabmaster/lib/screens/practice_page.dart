import 'package:flutter/material.dart';
import 'dart:ui';
import '../widgets/animated_background.dart';
import '../widgets/info_dialog.dart';
import '../services/api_service.dart';
import '../models/word.dart';
import '../widgets/matching_animation.dart';
import '../services/global_state.dart';
import 'ai_bot_chat_page.dart';
import 'exam_selection_page.dart';
import 'translation_practice_page.dart';
import 'reading_practice_page.dart';
import 'writing_practice_page.dart';
import 'video_call_page.dart';
import '../services/matchmaking_service.dart';
import '../widgets/animated_ai_chat_card.dart';
import 'package:provider/provider.dart';
import 'chat_list_page.dart';
import '../widgets/animated_ai_chat_card.dart';
import '../widgets/animated_ai_chat_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/modern_card.dart';
import '../widgets/modern_background.dart';
import '../widgets/modern_card_background.dart';
import '../widgets/level_and_length_section.dart';


class PracticePage extends StatefulWidget {
  final String? initialMode;
  const PracticePage({Key? key, this.initialMode}) : super(key: key);

  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  String _selectedMode = 'Çevirme'; // Çevirme, Okuma, Konuşma
  String _selectedSubMode = 'Seç'; // Seç, Manuel, Karışık
  String _selectedLevel = 'B1';
  String _selectedLength = 'Orta (9-15 kelime)';

  // Word Selection State
  List<Word> _allWords = [];
  List<Word> _filteredWords = [];
  final Set<int> _selectedWordIds = {};
  final TextEditingController _searchController = TextEditingController();
  bool _isLoadingWords = true;
  
  bool get _isMatching => GlobalState.isMatching.value;
  void _updateMatchingState() {
    if (mounted) setState(() {});
  }

  // Animation State
  late AnimationController _avatarAnimationController;
  late Animation<double> _avatarAnimation;

  final List<String> _avatarUrls = [
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&h=100&fit=crop',  // Sarah
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop',  // James
    'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100&h=100&fit=crop',  // Emma
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&h=100&fit=crop',  // Michael
    'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100&h=100&fit=crop',  // Olivia
    'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=100&h=100&fit=crop',  // David
  ];

  @override
  void initState() {
    super.initState();
    _loadWords();
    _searchController.addListener(_onSearchChanged);
    _searchController.addListener(_onSearchChanged);
    GlobalState.isMatching.addListener(_updateMatchingState);
    GlobalState.matchmakingService.addListener(_onMatchmakingUpdate);
    if (widget.initialMode != null) {
      _selectedMode = widget.initialMode!;
    }

    _avatarAnimationController = AnimationController(
       duration: const Duration(seconds: 20),
       vsync: this,
     )..repeat();
     
     _avatarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
       CurvedAnimation(
         parent: _avatarAnimationController,
         curve: Curves.linear,
       ),
     );
  }

  @override
  void didUpdateWidget(PracticePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialMode != null && widget.initialMode != oldWidget.initialMode) {
      // Only switch if the incoming mode is different and relevant
      setState(() {
        _selectedMode = widget.initialMode!;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _avatarAnimationController.dispose();
    GlobalState.isMatching.removeListener(_updateMatchingState);
    GlobalState.matchmakingService.removeListener(_onMatchmakingUpdate);
    super.dispose();
  }

  Future<void> _loadWords() async {
    try {
      final words = await _apiService.getAllWords();
      words.sort((a, b) => b.learnedDate.compareTo(a.learnedDate));
      
      if (mounted) {
        setState(() {
          _allWords = words;
          _filteredWords = words;
          _isLoadingWords = false;
        });
      }
    } catch (e) {
      print('Error loading words: $e');
      if (mounted) setState(() => _isLoadingWords = false);
    }
  }

  void _onMatchmakingUpdate() {
    final service = GlobalState.matchmakingService;
    if (service.status == MatchStatus.matched && service.matchInfo != null) {
      // Bekleme modunu kapat
      GlobalState.isMatching.value = false;
      
      // Video Call sayfasına git
      // Double navigation önlemek için kontrol
      if (ModalRoute.of(context)?.isCurrent == true) {
         Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoCallPage(
              socket: service.socket!,
              roomId: service.matchInfo!.roomId,
              matchedUserId: service.matchInfo!.matchedUserId,
              currentUserId: service.userId!,
              role: service.matchInfo!.role,
            ),
          ),
        ).then((_) {
           // Geri dönüldüğünde çağrıyı sonlandır
           service.leftCall(); // Bunu servise eklememiz lazım veya disconnect
        });
        
        // Servis durumunu güncelle ki tekrar tetiklenmesin
        service.setInCall(); // Bunu eklemeliyiz
      }
    } else if (service.status == MatchStatus.error) {
      GlobalState.isMatching.value = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(service.errorMessage ?? 'Hata oluştu')),
        );
      }
    }
  }

  void _startMatchmaking() {
    GlobalState.isMatching.value = true;
    GlobalState.matchmakingService.connect().then((_) {
        GlobalState.matchmakingService.joinQueue();
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredWords = _allWords.where((w) {
        return w.englishWord.toLowerCase().contains(query) ||
               w.turkishMeaning.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _toggleWordSelection(int id) {
    setState(() {
      if (_selectedWordIds.contains(id)) {
        _selectedWordIds.remove(id);
      } else {
        _selectedWordIds.add(id);
      }
    });
  }

  Future<void> _showWordDetailsDialog(Word word) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ModernCard(
              variant: BackgroundVariant.primary,
              borderRadius: BorderRadius.circular(20),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                        Expanded(
                          child: Text(
                            word.englishWord,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                       IconButton(
                         icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                         onPressed: () => Navigator.pop(context),
                         padding: EdgeInsets.zero,
                         constraints: const BoxConstraints(),
                       )
                     ],
                   ),
                   const SizedBox(height: 8),
                   Text(
                     word.turkishMeaning,
                     style: const TextStyle(color: Color(0xFF22D3EE), fontSize: 18, fontWeight: FontWeight.w500),
                   ),
                   const SizedBox(height: 16),
                   
                   // Details Grid wrapped in container with glass effect
                   Container(
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: Colors.white.withOpacity(0.05),
                       borderRadius: BorderRadius.circular(12),
                     ),
                     child: Column(
                       children: [
                         _buildDetailRow('Seviye', word.difficulty.toUpperCase()),
                         const Divider(color: Colors.white10, height: 16),
                         _buildDetailRow('Eklendiği Tarih', word.learnedDate.toIso8601String().split('T')[0]),
                          if (word.notes != null && word.notes!.isNotEmpty) ...[
                           const Divider(color: Colors.white10, height: 16),
                           _buildDetailRow('Notlar', word.notes!),
                         ],
                       ],
                     ),
                   ),
                   const SizedBox(height: 20),
                   
                   // Close Button
                   GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: ModernCard(
                      variant: BackgroundVariant.accent,
                      borderRadius: BorderRadius.circular(12),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      showGlow: true,
                      child: const Center(
                        child: Text('Kapat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                   ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(isDark: true),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  // Header with Info button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF06b6d4), Color(0xFF3b82f6)], // Neon Blue Gradient
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF06b6d4).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.school, color: Colors.white, size: 28),
                              SizedBox(width: 12),
                              Text(
                                'Pratik Yap',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () {
                              InfoDialog.show(
                                context,
                                title: 'Pratik Modları',
                                steps: [
                                  'Farklı pratik modları (Çevirme, Okuma, Yazma, Konuşma) arasından ihtiyacınıza uygun olanı seçin.',
                                  'Okuma bölümünde seviyenize (A1-C2) uygun metinleri analiz edin.',
                                  'Konuşma pratiğinde yapay zeka asistanı ile canlı diyaloglar kurun.',
                                  'Yazma bölümünde kompozisyonlar oluşturup yapay zekadan anlık geri bildirim alın.',
                                  'Düzenli pratik yaparak dil becerilerinizi bütüncül olarak geliştirin.',
                                ],
                              );
                            },
                            icon: const Icon(Icons.info_outline, color: Colors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Top Tabs
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: ModernCard(
                      borderRadius: BorderRadius.circular(16),
                      padding: const EdgeInsets.all(4),
                      variant: BackgroundVariant.secondary,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTopTab('Çevirme'),
                          _buildTopTab('Okuma'),
                          _buildTopTab('Yazma'),
                          _buildTopTab('Konuşma'),
                        ],
                      ),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildContent(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_selectedMode == 'Okuma') {
      return _buildReadingTab();
    } else if (_selectedMode == 'Konuşma') {
      return _buildSpeakingTab();
    } else if (_selectedMode == 'Yazma') {
      return _buildWritingTab();
    } else {
      return _buildTranslationTab();
    }
  }

  Widget _buildReadingTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
         // Header
         Row(
           children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF22D3EE), // Cyan
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF22D3EE).withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.menu_book, color: Colors.white, size: 24),
            ),
             const SizedBox(width: 16),
             const Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(
                   'Okuma & Anlama',
                   style: TextStyle(
                     color: Colors.white,
                     fontSize: 18,
                     fontWeight: FontWeight.bold,
                   ),
                 ),
                 Text(
                   'Metinleri okuyun ve anlayın',
                   style: TextStyle(
                     color: Colors.white70,
                     fontSize: 12,
                   ),
                 ),
               ],
             )
           ],
         ),
         const SizedBox(height: 24),
         
        // Level and Length Card
        ModernCard(showGlow: true, borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Seviye ve Uzunluk', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              const Text('Seviye:', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'].map((l) => _buildLevelChip(l)).toList(),
              ),
              const SizedBox(height: 24),
              const Text('Metin Uzunluğu:', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 12),
              _buildLengthButton('Kısa (100-200 kelime)'),
              const SizedBox(height: 8),
              _buildLengthButton('Orta (200-400 kelime)'),
              const SizedBox(height: 8),
              _buildLengthButton('Uzun (400+ kelime)'),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Start Button
        ModernCard(
          width: double.infinity,
          variant: BackgroundVariant.accent,
          showGlow: true,
          borderRadius: BorderRadius.circular(16),
          padding: EdgeInsets.zero,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReadingPracticePage(
                    level: _selectedLevel,
                    length: _selectedLength.contains('Kısa') ? 'short' : (_selectedLength.contains('Orta') ? 'medium' : 'long'),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Okumaya Başla',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: Colors.white),
              ],
            ),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

    Widget _buildWritingTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF22D3EE), // Cyan
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF22D3EE).withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yazma Pratiği',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'AI destekli yazma ve değerlendirme',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            )
          ],
        ),
        const SizedBox(height: 24),

        // Info Card - Glassmorphism
        ModernCard(showGlow: true, borderRadius: BorderRadius.circular(20),
          child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22D3EE).withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF22D3EE).withOpacity(0.5),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF22D3EE).withOpacity(0.2),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.auto_awesome, color: Color(0xFF22D3EE), size: 32),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Yazma Becerilerini Geliştir',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Seviyene uygun konularda yazılar yaz, yapay zeka anında değerlendirsin ve geri bildirim versin.',
                      style: TextStyle(
                        color: Colors.white70, // Slightly improved readability
                        fontSize: 14,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ModernCard(
                        variant: BackgroundVariant.accent,
                        showGlow: true,
                        borderRadius: BorderRadius.circular(16),
                        padding: EdgeInsets.zero,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const WritingPracticePage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Başla', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ),
                    ),
                   ],
                 ),
               ),
        const SizedBox(height: 80),
      ],
    );
  }
  Widget _buildSpeakingTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
           Padding(
             padding: const EdgeInsets.only(bottom: 24),
             child: ModernCard(showGlow: true, borderRadius: BorderRadius.circular(20),
               padding: const EdgeInsets.all(20),
               child: Row(
                     children: [
                       Container(
                         padding: const EdgeInsets.all(12),
                         decoration: BoxDecoration(
                           color: Colors.white.withOpacity(0.1),
                           shape: BoxShape.circle,
                         ),
                         child: const Icon(Icons.mic, color: Colors.white, size: 24),
                       ),
                       const SizedBox(width: 16),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Row(
                               children: [
                                  Flexible(
                                      child: const Text(
                                      'VocabMaster ile Konuşma',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF4ade80), // Green dot
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                             ),
                             const SizedBox(height: 4),
                             const Text(
                               'İngilizce konuşma pratiği için hazır!',
                               style: TextStyle(
                                 color: Colors.white,
                                 fontSize: 12,
                               ),
                               maxLines: 2,
                             ),
                           ],
                         ),
                       ),
 
                     ],
                   ),
                 ),
               ),
          const SizedBox(height: 24),

         // 2. Sohbet (Chat) Card
          ModernCard(showGlow: true, borderRadius: BorderRadius.circular(20),
            child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Row(
                 children: [
                   const Icon(Icons.chat_bubble_outline, color: Color(0xFF0ea5e9), size: 28),
                   const SizedBox(width: 12),
                   const Text(
                     'Sohbet',
                     style: TextStyle(
                       color: Colors.white,
                       fontSize: 20,
                       fontWeight: FontWeight.bold,
                       ),
                   ),
                 ],
               ),
               const SizedBox(height: 16),
               const Text(
                 'İngilizce pratik yap',
                 style: TextStyle(color: Colors.white70, fontSize: 14),
               ),
               const SizedBox(height: 24),
               
                if (_isMatching)
                  GestureDetector(
                    onTap: () {
                       GlobalState.matchmakingService.leaveQueue();
                       GlobalState.isMatching.value = false;
                    },
                    child: ModernCard(
                    width: double.infinity,
                    variant: BackgroundVariant.secondary,
                    showGlow: true,
                    borderRadius: BorderRadius.circular(12),
                    showBorder: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  )
                else ...[
                  // Eşleş Button
                  ModernCard(
                    width: double.infinity,
                    variant: BackgroundVariant.accent,
                    showGlow: true,
                    borderRadius: BorderRadius.circular(16),
                    padding: EdgeInsets.zero,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _startMatchmaking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Center(
                          child: Text(
                            'Eşleş',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Sohbete Git Button
                  ModernCard(
                    width: double.infinity,
                    variant: BackgroundVariant.accent,
                    showGlow: true,
                    borderRadius: BorderRadius.circular(16),
                    padding: EdgeInsets.zero,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ChatListPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Center(
                          child: Text(
                            'Sohbete Git',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
             ],
           ),
         ),

         const SizedBox(height: 20),

         // 3. AI Asistanları Animasyonlu Kart
         const AnimatedAIChatCard(),
         
         const SizedBox(height: 20),

         // 4. Kendini Sınavlara Hazırla Card
          ModernCard(showGlow: true, borderRadius: BorderRadius.circular(20),
            padding: const EdgeInsets.all(20),
            child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Row(
                 children: [
                   Container(
                     padding: const EdgeInsets.all(10),
                     decoration: BoxDecoration(
                       color: Colors.white.withOpacity(0.1),
                       shape: BoxShape.circle,
                     ),
                     child: const Icon(Icons.mic_none_outlined, color: Colors.white70, size: 22),
                   ),
                   const SizedBox(width: 14),
                   const Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         'Kendini Sınavlara Hazırla!',
                         style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                       ),
                       Text(
                         'IELTS & TOEFL konuşma pratiği yap',
                         style: TextStyle(color: Colors.white54, fontSize: 13),
                       ),
                     ],
                   ),
                 ],
               ),
               const SizedBox(height: 20),
               SizedBox(
                                   width: double.infinity,
                  child: ModernCard(
                    variant: BackgroundVariant.accent,
                    showGlow: true,
                    borderRadius: BorderRadius.circular(16),
                    padding: EdgeInsets.zero,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ExamSelectionPage()),
                          );
                        },
                        icon: const Icon(Icons.menu_book_rounded, size: 18, color: Colors.white),
                        label: const Text('Sınava Hazırlan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
                        ),
                      ),
                    ),
                  ),
               ),
             ],
           ),
         ),
         
         const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildTranslationTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
          // Header (Logo + Title)
          Row(
            children: [
              Container(
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(
                   color: Colors.white.withOpacity(0.1),
                   shape: BoxShape.circle,
                   border: Border.all(
                     color: const Color(0xFF22D3EE),
                     width: 2,
                   ),
                   boxShadow: [
                     BoxShadow(
                       color: const Color(0xFF22D3EE).withOpacity(0.3),
                       blurRadius: 12,
                       spreadRadius: 2,
                     ),
                   ],
                 ),
                 child: const Icon(Icons.translate, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Çevirme', // 1. sırada
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Pratik Modu', // 2. sırada
                     style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(child: _buildModeButton('Seç')),
              const SizedBox(width: 8),
              Expanded(child: _buildModeButton('Manuel')),
              const SizedBox(width: 8),
              Expanded(child: _buildModeButton('Karışık')),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Banner (Owen)
          // Owen Banner Removed
          
          const SizedBox(height: 24),

          if (_selectedSubMode == 'Manuel') ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Cümle içinde kullanılacak kelimeyi girin...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.edit_outlined, color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Level and Length
          LevelAndLengthSection(
            selectedLevel: _selectedLevel,
            selectedLength: _selectedLength,
            onLevelChanged: (val) => setState(() => _selectedLevel = val),
            onLengthChanged: (val) => setState(() => _selectedLength = val),
          ),
          
          // Word Selection Section (Only in 'Seç' mode)
          // Word Selection Section (Only in 'Seç' mode)
          if (_selectedSubMode == 'Seç') ...[
            const SizedBox(height: 24),
            ModernCard(
              padding: const EdgeInsets.all(20),
              borderRadius: BorderRadius.circular(20),
              variant: BackgroundVariant.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kelime Seçimi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Kelime Ara:', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  
                  // Search Box
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        icon: Icon(Icons.search, color: Colors.white54),
                        hintText: 'Kelime veya çeviriyi girin',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Kelime Listesi:', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      Text(
                        '${_selectedWordIds.length} seçili', 
                        style: const TextStyle(color: Color(0xFF06b6d4), fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Word List
                  SizedBox(
                    height: 300, // Fixed height for scrollable list within the page
                    child: _isLoadingWords 
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: _filteredWords.length,
                          itemBuilder: (context, index) {
                            final word = _filteredWords[index];
                            final isSelected = _selectedWordIds.contains(word.id);
                            final bool hasStar = word.turkishMeaning.contains('★') || word.turkishMeaning.contains('⭐');
                            final String displayMeaning = word.turkishMeaning.replaceAll('★', '').replaceAll('⭐', '').trim();
                            
                            return GestureDetector(
                              onTap: () => _toggleWordSelection(word.id),
                              child: ModernCard(
                                padding: const EdgeInsets.all(12),
                                borderRadius: BorderRadius.circular(16),
                                variant: isSelected ? BackgroundVariant.accent : BackgroundVariant.secondary,
                                showGlow: isSelected,
                                showBorder: isSelected,
                                child: Row(
                                  children: [
                                    // Checkbox circle
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected ? const Color(0xFF06b6d4) : Colors.transparent,
                                        border: Border.all(
                                          color: isSelected ? const Color(0xFF06b6d4) : Colors.white54,
                                          width: 2,
                                        ),
                                      ),
                                      child: isSelected 
                                        ? const Icon(Icons.check, size: 16, color: Colors.white) 
                                        : null,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              if (hasStar) ...[
                                                const Icon(Icons.star, color: Color(0xFFFACC15), size: 16), // Yellow
                                                const SizedBox(width: 4),
                                              ],
                                              Flexible(
                                                child: Text(
                                                  word.englishWord,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              // Type Tag
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF06b6d4).withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  "Word",
                                                  style: TextStyle(
                                                    color: Color(0xFF06b6d4),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            displayMeaning,
                                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    const SizedBox(width: 8),

                                    // Right side actions
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        // Difficulty Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            word.difficulty.toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Info Button
                                        GestureDetector(
                                          onTap: () => _showWordDetailsDialog(word),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0ea5e9).withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: const Color(0xFF0ea5e9).withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.info_outline,
                                              color: Color(0xFF0ea5e9),
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Start Button
          ModernCard(
            width: double.infinity,
            variant: BackgroundVariant.accent,
            showGlow: true,
            borderRadius: BorderRadius.circular(16),
            padding: EdgeInsets.zero,
            child: ElevatedButton(
              onPressed: () {
                // Seçili kelimeleri al
                final selectedWords = _allWords.where((w) => _selectedWordIds.contains(w.id)).toList();
                final firstWord = selectedWords.isNotEmpty ? selectedWords.first : null;
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TranslationPracticePage(
                      selectedWord: firstWord,
                      selectedLevels: [_selectedLevel],
                      selectedLengths: [_selectedLength == 'Kısa (5-8 kelime)' ? 'short' : (_selectedLength == 'Orta (9-15 kelime)' ? 'medium' : 'long')],
                      subMode: _selectedSubMode == 'Seç' ? 'select' : (_selectedSubMode == 'Manuel' ? 'manual' : 'random'),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Başla',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: Colors.white),
                ],
              ),
            ),
          ),
          const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildTopTab(String text) {
    final isSelected = _selectedMode == text;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMode = text),
      child: ModernCard(
        padding: const EdgeInsets.symmetric(vertical: 12),
        borderRadius: BorderRadius.circular(12),
        variant: isSelected ? BackgroundVariant.accent : BackgroundVariant.secondary,
        showGlow: isSelected,
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildModeButton(String text) {
    final isSelected = _selectedSubMode == text;
    return GestureDetector(
      onTap: () => setState(() => _selectedSubMode = text),
      child: ModernCard(
        padding: const EdgeInsets.symmetric(vertical: 16),
        borderRadius: BorderRadius.circular(16),
        variant: isSelected ? BackgroundVariant.accent : BackgroundVariant.secondary,
        showGlow: isSelected,
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelChip(String level) {
    final isSelected = _selectedLevel == level;
    return GestureDetector(
      onTap: () => setState(() => _selectedLevel = level),
      child: ModernCard(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        borderRadius: BorderRadius.circular(12),
        variant: isSelected ? BackgroundVariant.accent : BackgroundVariant.secondary,
        showGlow: isSelected,
        child: Center(
          child: Text(
            level,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
  Widget _buildLengthButton(String text) {
     final isSelected = _selectedLength == text;
     return GestureDetector(
       onTap: () => setState(() => _selectedLength = text),
       child: ModernCard(
         width: double.infinity,
         padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
         borderRadius: BorderRadius.circular(12),
         variant: isSelected ? BackgroundVariant.accent : BackgroundVariant.secondary,
         showGlow: isSelected,
         child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) const Icon(Icons.check, color: Colors.white, size: 20),
            if (isSelected) const SizedBox(width: 8),
            Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
       ),
     );
  }
}
