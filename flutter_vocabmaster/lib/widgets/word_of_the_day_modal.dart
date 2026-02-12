import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../widgets/modern_card.dart';
import '../widgets/modern_background.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../models/word.dart';

class WordOfTheDayModal extends StatefulWidget {
  final Map<String, dynamic> wordData;
  final VoidCallback onClose;
  final bool enableAnimations;
  final bool enableTts;
  final int initialStep;

  const WordOfTheDayModal({
    Key? key,
    required this.wordData,
    required this.onClose,
    this.enableAnimations = true,
    this.enableTts = true,
    this.initialStep = 0,
  }) : super(key: key);

  @override
  State<WordOfTheDayModal> createState() => _WordOfTheDayModalState();
}

class _WordOfTheDayModalState extends State<WordOfTheDayModal> with TickerProviderStateMixin {
  int _currentStep = 0;
  final int _totalSteps = 6;
  late FlutterTts _flutterTts;
  
  // Animation Controllers
  late AnimationController _pulseController;
  
  // Quiz state
  String? _quizSelectedAnswer;
  bool _quizAnswered = false;
  late List<String> _quizOptions;
  
  // Utils
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep.clamp(0, _totalSteps - 1);
    if (widget.enableTts) {
      _initTts();
    }
    _prepareQuiz();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    if (widget.enableAnimations) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    if (widget.enableTts) {
      _flutterTts.stop();
    }
    super.dispose();
  }

  void _initTts() {
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage("en-US");
    _flutterTts.setPitch(1.0);
    _flutterTts.setSpeechRate(0.5);
  }

  void _prepareQuiz() {
    final correct = widget.wordData['translation'] as String;
    final dummies = [
      "Mutlu, neşeli",
      "Hızlı, çabuk",
      "Sessiz, sakin"
    ]; // In real app, these should be better
    _quizOptions = [...dummies, correct]..shuffle();
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> _addToWords({required bool withSentence, required bool wordAdded, required bool sentenceAdded}) async {
    if (_isAdding) return;
    if (wordAdded && (!withSentence || sentenceAdded)) return;

    setState(() => _isAdding = true);

    try {
      final appState = context.read<AppStateProvider>();
      final addedDate = DateTime.now();
      final wordText = (widget.wordData['word'] ?? '').toString();
      final sentenceText = (widget.wordData['exampleSentence'] ?? '').toString();
      final translationText = (widget.wordData['exampleTranslation'] ?? '').toString();

      Word? word = appState.findWordByEnglish(wordText);

      if (!wordAdded) {
        word = await appState.addWord(
          english: wordText,
          turkish: "⭐ ${widget.wordData['translation']}",
          addedDate: addedDate,
          difficulty: (widget.wordData['difficulty'] as String? ?? 'Medium').toLowerCase(),
          source: 'daily_word',
        );
      }

      if (withSentence && word != null && !sentenceAdded) {
        await appState.addSentenceToWord(
          wordId: word.id,
          sentence: sentenceText,
          translation: translationText,
          difficulty: 'medium',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      widget.onClose();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 400,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF0C1445), // blue-950
              Color(0xFF581C87), // purple-900
              Color(0xFF0C1445), // blue-950
            ],
            stops: [0.0, 0.5, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  final offsetAnimation = Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOut,
                  ));
                  return SlideTransition(position: offsetAnimation, child: child);
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      key: ValueKey<int>(_currentStep),
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: IntrinsicHeight(
                          child: _buildStepContent(),
                        ),
                      ),
                    );
                  }
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02), // subtle overlay
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 32), // spacer for centering title
              const Text(
                'Günün Kelimesi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Segmented Progress Bar
          Row(
            children: List.generate(_totalSteps, (index) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index == _totalSteps - 1 ? 0 : 4),
                  decoration: BoxDecoration(
                    gradient: index <= _currentStep 
                      ? const LinearGradient(colors: [Color(0xFF22D3EE), Color(0xFF3B82F6)]) // Cyan to Blue
                      : null,
                    color: index <= _currentStep ? null : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            _getStepTitle(_currentStep),
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0: return 'Kelime (1/6)';
      case 1: return 'Anlam (2/6)';
      case 2: return 'Örnek Cümle (3/6)';
      case 3: return 'Telaffuz (4/6)';
      case 4: return 'Quiz (5/6)';
      case 5: return 'Tamamlandı (6/6)';
      default: return '';
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0: return _buildStep1_Word();
      case 1: return _buildStep2_Meaning();
      case 2: return _buildStep3_Example();
      case 3: return _buildStep4_Pronunciation();
      case 4: return _buildStep5_Quiz();
      case 5: return _buildStep6_Summary();
      default: return const SizedBox();
    }
  }

  // --- Step 1 ---
  Widget _buildStep1_Word() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFA855F7).withOpacity(0.2), // Purple-500/20
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFC084FC).withOpacity(0.3)),
            ),
            child: Text(
              (widget.wordData['partOfSpeech'] ?? 'Unknown').toString().toUpperCase(),
              style: const TextStyle(color: Color(0xFFD8B4FE), fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 32),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.05),
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF22D3EE), Color(0xFF3B82F6)],
                  ).createShader(bounds),
                  child: Text(
                    widget.wordData['word'] ?? '',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            widget.wordData['pronunciation'] ?? '',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 48),
          GestureDetector(
            onTap: () => _speak(widget.wordData['word'] ?? ''),
            child: ModernCard(
              variant: BackgroundVariant.accent,
              borderRadius: BorderRadius.circular(30),
              showGlow: true,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.volume_up, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Dinle', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 2 ---
  Widget _buildStep2_Meaning() {
    final synonyms = List<String>.from(widget.wordData['synonyms'] ?? []);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Text(
            widget.wordData['word'] ?? '',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
             widget.wordData['pronunciation'] ?? '',
             style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5)),
          ),
           const SizedBox(height: 24),
           
           Container(
             width: double.infinity,
             padding: const EdgeInsets.all(20),
             decoration: BoxDecoration(
               gradient: LinearGradient(
                 colors: [const Color(0xFF22D3EE).withOpacity(0.15), const Color(0xFF3B82F6).withOpacity(0.15)],
                 begin: Alignment.topLeft,
                 end: Alignment.bottomRight,
               ),
               borderRadius: BorderRadius.circular(16),
               border: Border.all(color: const Color(0xFF22D3EE).withOpacity(0.3)),
             ),
             child: Column(
               children: [
                 const Icon(Icons.lightbulb_outline, color: Color(0xFFFACC15), size: 28),
                 const SizedBox(height: 8),
                 Text(
                   'Türkçe Anlamı',
                   style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w600),
                 ),
                 const SizedBox(height: 8),
                 Text(
                   widget.wordData['translation'] ?? '',
                   textAlign: TextAlign.center,
                   style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                 ),
               ],
             ),
           ),
           
           const SizedBox(height: 16),
           
           Container(
             width: double.infinity,
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(
               color: Colors.white.withOpacity(0.05),
               borderRadius: BorderRadius.circular(16),
               border: Border.all(color: Colors.white.withOpacity(0.1)),
             ),
             child: Text(
               widget.wordData['definition'] ?? '',
               textAlign: TextAlign.center,
               style: TextStyle(color: Colors.white.withOpacity(0.7), fontStyle: FontStyle.italic),
             ),
           ),
           
           const SizedBox(height: 20),
           
            if (synonyms.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('Eş Anlamlılar: ', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: synonyms.map((s) => Chip(
                          label: Text(s),
                          backgroundColor: Colors.white.withOpacity(0.1),
                          labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        )).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }

  // --- Step 3 ---
  Widget _buildStep3_Example() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
             width: double.infinity,
             padding: const EdgeInsets.all(24),
             decoration: BoxDecoration(
               gradient: LinearGradient(
                 colors: [const Color(0xFFA855F7).withOpacity(0.15), const Color(0xFF22D3EE).withOpacity(0.15)],
                 begin: Alignment.topLeft,
                 end: Alignment.bottomRight,
               ),
               borderRadius: BorderRadius.circular(20),
               border: Border.all(color: const Color(0xFFA855F7).withOpacity(0.3)),
             ),
             child: Column(
               children: [
                 const Icon(Icons.menu_book_rounded, color: Colors.white, size: 32),
                 const SizedBox(height: 16),
                 Text(
                   '"${widget.wordData['exampleSentence']}"',
                   textAlign: TextAlign.center,
                   style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                 ),
                 const SizedBox(height: 12),
                 Text(
                   widget.wordData['exampleTranslation'] ?? '',
                   textAlign: TextAlign.center,
                   style: TextStyle(color: Colors.white.withOpacity(0.6), fontStyle: FontStyle.italic),
                 ),
               ],
             ),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () => _speak(widget.wordData['exampleSentence'] ?? ''),
            icon: const Icon(Icons.volume_up),
            label: const Text('Cümleyi Dinle'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 4 ---
  Widget _buildStep4_Pronunciation() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Telaffuz Pratiği',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 40),
        
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
             return Transform.scale(
               scale: 1.0 + (_pulseController.value * 0.08),
               child: child,
             );
          },
          child: Text(
            widget.wordData['word'] ?? '',
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        
        const SizedBox(height: 12),
        Text(
          widget.wordData['pronunciation'] ?? '',
          style: const TextStyle(fontSize: 24, color: Color(0xFF22D3EE), fontWeight: FontWeight.w500),
        ),
        
        const SizedBox(height: 48),
        
        GestureDetector(
          onTap: () => _speak(widget.wordData['word'] ?? ''),
          child: ModernCard(
            variant: BackgroundVariant.accent,
            borderRadius: BorderRadius.circular(16),
            showGlow: true,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.volume_up, size: 28, color: Colors.white),
                SizedBox(width: 12),
                Text('Tekrar Dinle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 32),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'İpucu: Sesi dinleyip tekrar ederek öğrenme hızınızı artırabilirsiniz!',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Step 5 ---
  Widget _buildStep5_Quiz() {
    final word = widget.wordData['word'] as String;
    final correctAns = widget.wordData['translation'] as String;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Mini Quiz', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
            '"$word" kelimesinin anlamı nedir?',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, color: Colors.white70),
          ),
          const SizedBox(height: 24),
          
          ..._quizOptions.map((option) {
             final isSelected = _quizSelectedAnswer == option;
             final isCorrect = option == correctAns;
             
             Color borderColor = Colors.white.withOpacity(0.2);
             Color bgColor = Colors.white.withOpacity(0.05);
             Widget? icon;
             
             if (_quizAnswered) {
               if (option == correctAns) {
                 borderColor = const Color(0xFF4ADE80); // Green
                 bgColor = const Color(0xFF4ADE80).withOpacity(0.2);
                 icon = const Icon(Icons.check_circle, color: Color(0xFF4ADE80));
               } else if (isSelected) {
                 borderColor = const Color(0xFFF87171); // Red
                 bgColor = const Color(0xFFF87171).withOpacity(0.2);
                 icon = const Icon(Icons.cancel, color: Color(0xFFF87171));
               } else {
                 borderColor = Colors.transparent;
                 bgColor = Colors.transparent;
               }
             } else if (isSelected) {
               borderColor = const Color(0xFF22D3EE);
               bgColor = const Color(0xFF22D3EE).withOpacity(0.2);
             }
             
             return Padding(
               padding: const EdgeInsets.only(bottom: 12),
               child: GestureDetector(
                 onTap: _quizAnswered ? null : () {
                   setState(() {
                     _quizSelectedAnswer = option;
                   });
                 },
                 child: AnimatedContainer(
                   duration: const Duration(milliseconds: 200),
                   padding: const EdgeInsets.all(16),
                   decoration: BoxDecoration(
                     color: bgColor,
                     border: Border.all(color: borderColor, width: 2),
                     borderRadius: BorderRadius.circular(12),
                   ),
                   child: Row(
                     children: [
                       Expanded(
                         child: Text(
                           option,
                           style: TextStyle(
                             color: _quizAnswered && !isCorrect && !isSelected 
                               ? Colors.white.withOpacity(0.3) 
                               : Colors.white,
                             fontWeight: FontWeight.w500,
                             fontSize: 16,
                           ),
                         ),
                       ),
                       if (icon != null) icon,
                     ],
                   ),
                 ),
               ),
             );
          }).toList(),
          
          const SizedBox(height: 20),
          
          // Check Answer Button

          
          // Feedback
          if (_quizAnswered)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _quizSelectedAnswer == correctAns 
                  ? const Color(0xFF4ADE80).withOpacity(0.1) 
                  : const Color(0xFFF87171).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _quizSelectedAnswer == correctAns ? Icons.check_circle : Icons.cancel,
                    color: _quizSelectedAnswer == correctAns ? const Color(0xFF4ADE80) : const Color(0xFFF87171)
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _quizSelectedAnswer == correctAns 
                        ? "Doğru cevap!" 
                        : "Yanlış cevap: $correctAns",
                      style: TextStyle(
                        color: _quizSelectedAnswer == correctAns ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
                        fontWeight: FontWeight.bold
                      )
                    )
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // --- Step 6 ---
  Widget _buildStep6_Summary() {
    final appState = context.watch<AppStateProvider>();
    final wordText = (widget.wordData['word'] ?? '').toString();
    final sentenceText = (widget.wordData['exampleSentence'] ?? '').toString();
    final existingWord = appState.findWordByEnglish(wordText);
    final wordAdded = existingWord != null;
    final sentenceAdded = wordAdded && appState.hasSentenceForWord(existingWord!, sentenceText);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF4ADE80), size: 80),
          const SizedBox(height: 24),
          const Text(
            'Harika İş!',
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            '"${widget.wordData['word']}" kelimesini öğrendiniz.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
          ),
          const SizedBox(height: 48),

          if (!wordAdded) ...[
            // "Kelimeyi Cümlesiyle Ekle" Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isAdding ? null : () => _addToWords(withSentence: true, wordAdded: wordAdded, sentenceAdded: sentenceAdded),
                icon: const Icon(Icons.playlist_add, color: Colors.white),
                label: const Text('Kelimeyi Cümlesiyle Ekle', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981), // Emerald-500
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // "Sadece Kelimeyi Ekle" Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isAdding ? null : () => _addToWords(withSentence: false, wordAdded: wordAdded, sentenceAdded: sentenceAdded),
                icon: const Icon(Icons.add, color: Colors.white70),
                label: const Text('Sadece Kelimeyi Ekle', style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ] else if (wordAdded && !sentenceAdded) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF10B981)),
                  SizedBox(width: 8),
                  Text('Kelime ekli', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isAdding ? null : () => _addToWords(withSentence: true, wordAdded: wordAdded, sentenceAdded: sentenceAdded),
                icon: const Icon(Icons.playlist_add, color: Colors.white),
                label: const Text('Cümlesini de ekle', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF10B981)),
                  SizedBox(width: 8),
                  Text('Kelime ve cümle ekli', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                ],
              ),
            )
        ],
      ),
    );
  }

  Widget _buildFooter() {
    // Buttons layout: Back (left), Next (right, expanded)
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
           if (_currentStep > 0)
             Padding(
               padding: const EdgeInsets.only(right: 12.0),
               child: OutlinedButton(
                 onPressed: _prevStep,
                 style: OutlinedButton.styleFrom(
                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                   side: BorderSide(color: Colors.white.withOpacity(0.2)),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                   foregroundColor: Colors.white,
                 ),
                 child: const Icon(Icons.arrow_back),
               ),
             ),
             
           Expanded(
             child: GestureDetector(
               onTap: () {
                 if (_currentStep == 4 && !_quizAnswered) {
                   if (_quizSelectedAnswer != null) {
                     setState(() => _quizAnswered = true);
                   }
                 } else {
                   _nextStep();
                 }
               },
               child: ModernCard(
                 variant: BackgroundVariant.accent,
                 borderRadius: BorderRadius.circular(16),
                 padding: const EdgeInsets.symmetric(vertical: 16),
                 showGlow: true,
                 child: Center(
                   child: Text(
                     (_currentStep == 4 && !_quizAnswered) ? 'Kontrol Et' :
                     (_currentStep < 5 ? 'İleri' : 'Çıkış'),
                     style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                   ),
                 ),
               ),
             ),
           ),
        ],
      ),
    );
  }
}
