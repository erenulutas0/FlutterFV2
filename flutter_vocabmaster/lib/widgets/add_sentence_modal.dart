import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word.dart';
import '../providers/app_state_provider.dart';

class AddSentenceModal extends StatefulWidget {
  final Word word;
  final VoidCallback onSentencesAdded;

  const AddSentenceModal({
    required this.word,
    required this.onSentencesAdded,
    Key? key,
  }) : super(key: key);

  @override
  _AddSentenceModalState createState() => _AddSentenceModalState();
}

class SentenceData {
  TextEditingController englishController = TextEditingController();
  TextEditingController turkishController = TextEditingController();
  String difficulty = 'easy';
  
  void dispose() {
    englishController.dispose();
    turkishController.dispose();
  }

  bool get isValid => 
    englishController.text.trim().isNotEmpty && 
    turkishController.text.trim().isNotEmpty;
}

class _AddSentenceModalState extends State<AddSentenceModal> 
    with TickerProviderStateMixin {
  late List<AnimationController> _orbControllers;
  late List<AnimationController> _sparkleControllers;
  List<Offset>? _sparklePositions;
  
  List<SentenceData> sentences = [SentenceData()];
  // OfflineSyncService kaldırıldı - AppStateProvider kullanılıyor
  bool _isSavePressed = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    
    // Orb controllers
    _orbControllers = List.generate(3, (i) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(seconds: 8 + i * 2),
      );
      controller.repeat();
      return controller;
    });
    
    // Sparkle controllers
    _sparkleControllers = List.generate(15, (i) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 2000 + (Random().nextDouble() * 2000).toInt()),
      );
      Future.delayed(Duration(milliseconds: (Random().nextDouble() * 3000).toInt()), () {
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
    for (var controller in _sparkleControllers) {
      controller.dispose();
    }
    for (var sentence in sentences) {
      sentence.dispose();
    }
    super.dispose();
  }

  Future<void> _saveSentences() async {
    // Validate
    final validSentences = sentences.where((s) => s.isValid).toList();
    
    if (validSentences.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen en az bir cümle ve çevirisini girin.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final appState = context.read<AppStateProvider>();
      
      for (var s in validSentences) {
        // AppStateProvider ile ekle (XP ve refresh otomatik)
        await appState.addSentenceToWord(
          wordId: widget.word.id,
          sentence: s.englishController.text.trim(),
          translation: s.turkishController.text.trim(),
          difficulty: s.difficulty,
        );
      }
      
      if (mounted) {
        Navigator.pop(context);
        widget.onSentencesAdded();
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('${validSentences.length} cümle başarıyla eklendi! (+${validSentences.length * 5} XP)'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Hata oluştu: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_sparklePositions == null) {
       final size = MediaQuery.of(context).size;
       _sparklePositions = List.generate(15, (_) => Offset(
         Random().nextDouble() * size.width,
         Random().nextDouble() * size.height,
       ));
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),  // slate-900
            Color(0xFF1E3A8A),  // blue-900
            Color(0xFF0F172A),  // slate-900
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border.all(
          color: const Color(0x4D22D3EE),  // cyan-400 with 30% opacity
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // 1. Animated background effects
          _buildAnimatedBackground(),
          
          Column(
            children: [
              // 2. Header
              _buildHeader(),
              
              // 3. Scrollable content
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sentences.length + 1,  // +1 for "Add NewButton"
                  itemBuilder: (context, index) {
                    if (index == sentences.length) {
                      return _buildAddNewButton();
                    }
                    return _buildSentenceCard(index);
                  },
                ),
              ),

              // 4. Footer
              _buildFooter(),
            ],
          ),
          
          if (_isSaving)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // GLOWING ORBS (3 pieces)
            ...List.generate(3, (i) {
              return AnimatedBuilder(
                animation: _orbControllers[i],
                builder: (context, child) {
                  double value = _orbControllers[i].value;
                  return Positioned(
                    left: MediaQuery.of(context).size.width * (i * 0.4),
                    top: MediaQuery.of(context).size.height * (i * 0.3),
                    child: Transform.translate(
                      offset: Offset(
                        30 * sin(value * 2 * pi),
                        -20 * cos(value * 2 * pi),
                      ),
                      child: Container(
                        width: 256,
                        height: 256,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              i % 2 == 0 
                                ? const Color(0x2606B6D4)  // cyan-500 15% opacity
                                : const Color(0x263B82F6), // blue-500 15% opacity
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.7],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

            // SPARKLES (15 pieces)
            ...List.generate(15, (i) {
               final pos = _sparklePositions![i];
               
               return AnimatedBuilder(
                animation: _sparkleControllers[i],
                builder: (context, child) {
                  double value = _sparkleControllers[i].value;
                  double opacity = value < 0.5 ? value * 2 : (1 - value) * 2;
                  double scale = value < 0.5 ? value * 3 : (1 - value) * 3;
                  
                  return Positioned(
                    left: pos.dx, 
                    top: pos.dy,
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22D3EE),  // cyan-400
                            shape: BoxShape.circle,
                            boxShadow: const [
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
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0x0DFFFFFF),  // white with 5% opacity
        border: Border(
          bottom: BorderSide(
            color: Color(0x3322D3EE),  // cyan-400 with 20% opacity
            width: 1,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Icon Container with Gradient
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF06B6D4),  // cyan-500
                        Color(0xFF3B82F6),  // blue-600
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x4D06B6D4),  // cyan-500 30% opacity
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.bookmark_add,  // BookmarkPlus equivalent
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cümle Ekle',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,  // Sparkles equivalent
                            color: Color(0xFF67E8F9),  // cyan-300
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${widget.word.englishWord} kelimesi için cümleler',
                              style: const TextStyle(
                                color: Color(0xFF67E8F9),  // cyan-300
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Close Button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xB3FFFFFF), size: 24),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0x1AFFFFFF),  // white 10% opacity
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
    );
  }

  Widget _buildSentenceCard(int index) {
    final sentence = sentences[index];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),  // white 5% opacity
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0x3322D3EE),  // cyan-400 20% opacity
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3306B6D4),  // cyan-500 20% opacity
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER: Number Badge + Delete Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Number Badge with Gradient
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF06B6D4),  // cyan-500
                                Color(0xFF3B82F6),  // blue-600
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x4D06B6D4),  // cyan-500 30% opacity
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Cümle',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    
                    // Delete Button (visible if more than 1 sentence)
                    if (sentences.length > 1)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            sentences.removeAt(index);
                          });
                        },
                        icon: const Icon(Icons.delete_outline, size: 20),
                        style: IconButton.styleFrom(
                          foregroundColor: const Color(0xFFF87171),  // red-400
                          backgroundColor: const Color(0x33EF4444),  // red-500 20% opacity
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // ENGLISH SENTENCE INPUT
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     const Text(
                      'İngilizce Cümle',
                      style: TextStyle(
                        color: Color(0xFF67E8F9),  // cyan-300
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: sentence.englishController,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      maxLines: null,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        hintText: 'Enter an example sentence...',
                        hintStyle: const TextStyle(
                          color: Color(0x66FFFFFF),  // white 40% opacity
                          fontSize: 15,
                        ),
                        filled: true,
                        fillColor: const Color(0x1AFFFFFF),  // white 10% opacity
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0x4D22D3EE),  // cyan-400 30% opacity
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0x4D22D3EE),  // cyan-400 30% opacity
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF22D3EE),  // cyan-400 full
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // TURKISH TRANSLATION INPUT
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     const Text(
                      'Türkçe Anlamı',
                      style: TextStyle(
                        color: Color(0xFF67E8F9),  // cyan-300
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                       controller: sentence.turkishController,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Cümlenin Türkçe çevirisi...',
                        hintStyle: const TextStyle(
                          color: Color(0x66FFFFFF),  // white 40% opacity
                          fontSize: 15,
                        ),
                        filled: true,
                        fillColor: const Color(0x1AFFFFFF),  // white 10% opacity
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0x4D22D3EE),  // cyan-400 30% opacity
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0x4D22D3EE),  // cyan-400 30% opacity
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF22D3EE),  // cyan-400 full
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // DIFFICULTY SELECTOR
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Zorluk Seviyesi',
                      style: TextStyle(
                        color: Color(0xFF67E8F9),  // cyan-300
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0x1AFFFFFF),  // white 10% opacity
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0x4D22D3EE),  // cyan-400 30% opacity
                          width: 1,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: sentence.difficulty,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF1E3A8A),  // blue-900
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                          icon: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _getDifficultyColor(sentence.difficulty),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getDifficultyColor(sentence.difficulty).withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_drop_down, color: Color(0xFF67E8F9)),
                            ],
                          ),
                          onChanged: (value) {
                            setState(() {
                              sentence.difficulty = value!;
                            });
                          },
                          items: const [
                            DropdownMenuItem(
                              value: 'easy',
                              child: Text('🟢 Kolay'),
                            ),
                            DropdownMenuItem(
                              value: 'medium',
                              child: Text('🟡 Orta'),
                            ),
                            DropdownMenuItem(
                              value: 'hard',
                              child: Text('🔴 Zor'),
                            ),
                          ],
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
    );
  }

  Widget _buildAddNewButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: const Color(0x4D22D3EE),
          strokeWidth: 2,
          dashWidth: 8,
          dashSpace: 4,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                sentences.add(SentenceData());
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0x1A06B6D4),  // cyan-500 10% opacity
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add,
                    color: Color(0xFF67E8F9),  // cyan-300
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Yeni Cümle Ekle',
                    style: TextStyle(
                      color: Color(0xFF67E8F9),  // cyan-300
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
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

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0x1A06B6D4),  // cyan-500 10% opacity
            Color(0x1A3B82F6),  // blue-500 10% opacity
          ],
        ),
        border: Border(
          top: BorderSide(
            color: Color(0x6622D3EE),  // cyan-400 40% opacity
            width: 2,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Row(
            children: [
              // İptal Button
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0x0DFFFFFF),  // white 5% opacity
                    side: const BorderSide(
                      color: Color(0x4D22D3EE),  // cyan-400 30% opacity
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'İptal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Kaydet Button with Gradient & Shine
              Expanded(
                child: Listener(
                  onPointerDown: (_) => setState(() => _isSavePressed = true),
                  onPointerUp: (_) => setState(() => _isSavePressed = false),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF06B6D4),  // cyan-500
                              Color(0xFF3B82F6),  // blue-600
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x8006B6D4),  // cyan-500 50% opacity
                              blurRadius: 16,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _saveSentences,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: const Center(
                                child: Text(
                                  'Kaydet',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Shine Effect (Optional - on press/hover)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedOpacity(
                            opacity: _isSavePressed ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.transparent,
                                    Color(0x33FFFFFF),  // white 20% opacity
                                    Colors.transparent,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return const Color(0xFF22C55E);  // green-500
      case 'medium':
        return const Color(0xFFEAB308);  // yellow-500
      case 'hard':
        return const Color(0xFFEF4444);  // red-500
      default:
        return const Color(0xFF6B7280);  // gray-500
    }
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(12),
      ));

    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final dashPath = Path();
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final start = distance;
        final end = distance + dashWidth;
        dashPath.addPath(
          metric.extractPath(start, end.clamp(0, metric.length)),
          Offset.zero,
        );
        distance = end + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
