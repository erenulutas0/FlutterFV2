import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:typed_data';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../widgets/animated_background.dart';
import '../widgets/voice_selection_modal.dart';
import '../services/chatbot_service.dart';
import '../services/piper_tts_service.dart';
import '../models/voice_model.dart';

class AIBotChatPage extends StatefulWidget {
  const AIBotChatPage({Key? key}) : super(key: key);

  @override
  State<AIBotChatPage> createState() => _AIBotChatPageState();
}

class _AIBotChatPageState extends State<AIBotChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final ChatbotService _chatbotService = ChatbotService();
  final PiperTtsService _ttsService = PiperTtsService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts(); // Fallback TTS
  
  bool _isTyping = false;
  bool _isSpeaking = false;
  bool _ttsEnabled = true;
  bool _ttsAvailable = false;
  
  // STT
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _continuousListening = false; // Persistent session state
  
  // Seçili konuşmacı
  VoiceModel? _selectedVoice;
  bool _isFirstVisit = true;
  
  // Floating particles animation
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    _checkTtsAvailability();
    _initFlutterTts(); // Fallback TTS hazırla
    _loadSelectedVoice();
  }

  Future<void> _initFlutterTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.awaitSpeakCompletion(true); // Konuşma bitmesini bekle
  }

  /// Kaydedilmiş konuşmacıyı yükle
  Future<void> _loadSelectedVoice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final voiceJson = prefs.getString('selected_voice');
      final hasVisited = prefs.getBool('voice_modal_shown') ?? false;
      
      if (voiceJson != null) {
        setState(() {
          _selectedVoice = VoiceModel.fromJsonString(voiceJson);
          _isFirstVisit = false;
        });
      } else {
        _isFirstVisit = !hasVisited;
        
    // İlk ziyarette modal göster
        if (_isFirstVisit && mounted) {
          Future.delayed(const Duration(milliseconds: 800), _showVoiceSelectionModal);
        } else {
           // Zaten seçiliyse standart hoşgeldin mesajı
           if (_messages.isEmpty) {
             _addBotMessage(
              'Tekrar merhaba! Ben ${_selectedVoice?.name ?? 'AI Bot'}. İngilizce pratiğine kaldığımız yerden devam edelim mi? 👋',
             );
           }
        }
      }
    } catch (e) {
      debugPrint('Load voice error: $e');
    }
  }

  /// Konuşmacı seçim modalını göster
  Future<void> _showVoiceSelectionModal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voice_modal_shown', true);
    
    if (!mounted) return;
    
    final voice = await VoiceSelectionModal.show(
      context,
      currentVoice: _selectedVoice,
    );
    
    if (!mounted) return;

    if (voice != null) {
      // Ses değiştiyse sohbeti sıfırla
      if (_selectedVoice?.id != voice.id) {
         setState(() {
           _selectedVoice = voice;
           _messages.clear(); // Sohbeti temizle
         });
         
         // Yeni karakterin hoşgeldin mesajı
         _addBotMessage(
           'Selam! Ben ${voice.name}. Seninle ${voice.accent} aksanıyla konuşacağım için çok heyecanlıyım! Hadi başlayalım. 🚀',
           speak: true,
         );
      }
    } else {
      // Seçim yapmadan kapattıysa
      if (_selectedVoice == null) {
        // Eğer hiç ses seçili değilse sayfadan at (Zorunlu seçim)
        Navigator.pop(context); 
      }
    }
  }

  Future<void> _checkTtsAvailability() async {
    final available = await _ttsService.isAvailable();
    if (mounted) {
      setState(() => _ttsAvailable = available);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _particleController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _addBotMessage(String text, {bool speak = false}) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isBot: true,
        time: _getCurrentTime(),
      ));
    });
    _scrollToBottom();
    
    // TTS ile seslendir
    if (speak && _ttsEnabled) {
      _speakText(text);
    }
  }

  Future<void> _speakText(String text) async {
    if (_isSpeaking) {
       // Önceki konuşmayı durdur
       await _audioPlayer.stop();
       await _flutterTts.stop();
    }
    
    // TTS başlamadan önce mikrofonu kesin olarak kapat
    if (_isListening) {
      await _speech.stop();
      if (mounted) {
        setState(() => _isListening = false);
      }
    }
    
    setState(() => _isSpeaking = true);
    
    try {
      // Seçili konuşmacının sesini kullan
      final voiceName = _selectedVoice?.piperVoice ?? 'amy';
      
      // 1. Önce Piper TTS dene
      Uint8List? audioData;
      
      // Sadece Piper available ise API çağrısı yap, yoksa direkt fallback'e geç
      if (_ttsAvailable) {
        try {
           audioData = await _ttsService.synthesize(text, voice: voiceName);
        } catch (e) {
          debugPrint('Piper synthesize error: $e');
        }
      }

      if (audioData != null && mounted) {
        // Uint8List'i AudioSource'a çevir
        // File playback (Daha güvenli)
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/chat_response.wav');
        await tempFile.writeAsBytes(audioData);
        
        await _audioPlayer.setFilePath(tempFile.path);
        await _audioPlayer.play();
        
        // Bitmesini bekle
        await _audioPlayer.playerStateStream.firstWhere(
          (state) => state.processingState == ProcessingState.completed
        );
        
      } else {
        // 2. Fallback: Flutter TTS (System)
        debugPrint('Main Chat: Piper başarısız, System TTS kullanılıyor.');
        if (_selectedVoice != null) {
           String locale = _selectedVoice!.locale.replaceAll('_', '-');
           await _flutterTts.setLanguage(locale);
           // Pitch ayarı
           if (_selectedVoice!.gender == 'female') {
              await _flutterTts.setPitch(1.1);
           } else {
              await _flutterTts.setPitch(0.9);
           }
        }
        await _flutterTts.speak(text);
        // awaitSpeakCompletion(true) olduğu için burada bekler
      }
      
    } catch (e) {
      debugPrint('TTS error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSpeaking = false);
        // Continue loop if session is active
        if (_continuousListening && !_isListening) {
          // Short delay to avoid clipping
          Future.delayed(const Duration(milliseconds: 500), _startListening);
        }
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) {
        setState(() => _isListening = false);
      }
    }

    if (_messageController.text.trim().isEmpty) return;
    
    final userMessage = _messageController.text.trim();
    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isBot: false,
        time: _getCurrentTime(),
      ));
      _isTyping = true;
    });
    _messageController.clear();
    _scrollToBottom();
    
    try {
      // Backend'den gerçek AI yanıtı al
      final response = await _chatbotService.chat(userMessage);
      
      if (mounted) {
        setState(() => _isTyping = false);
        _addBotMessage(response, speak: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTyping = false);
        _addBotMessage('Üzgünüm, bir hata oluştu: ${e.toString()}');
      }
    }
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          const AnimatedBackground(isDark: true),
          
          // Floating particles
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlesPainter(_particleController.value),
                size: Size.infinite,
              );
            },
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // App Bar
                _buildAppBar(),
                
                // Messages List
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isTyping) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageBubble(_messages[index], index);
                    },
                  ),
                ),
                
                // Input Area
                _buildInputArea(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startListening() async {
    // Request permission first
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mikrofon izni gerekli.')));
      return;
    }

    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
             // If stopped automatically (silence or timeout), send message
             if (mounted && _isListening) {
               _stopAndSend(manual: false);
             }
          }
        },
        onError: (val) => debugPrint('STT Error: $val'),
      );
      if (available) {
        if(mounted) setState(() {
          _isListening = true;
          // Only set true, don't reset to false here unless manual stop?
          // Actually, if we start, we assume continuous unless told otherwise?
          // Let's set it true here to ensure loop starts/continues.
          _continuousListening = true; 
        });
        _speech.listen(
          onResult: (val) {
            setState(() {
              _messageController.text = val.recognizedWords;
            });
          },
          listenFor: const Duration(seconds: 60),
          pauseFor: const Duration(seconds: 5), // Wait 5 seconds of silence
          localeId: 'en_US',
        );
      } else {
        if(mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ses algılama başlatılamadı.')),
           );
        }
      }
    }
  }

  void _stopAndSend({bool manual = false}) {
    if (_isListening) {
      _speech.stop();
      if(mounted) {
        setState(() {
          _isListening = false;
          if (manual) _continuousListening = false;
        });
        // Delay slightly to ensure final result is captured
        Future.delayed(const Duration(milliseconds: 500), () {
           if (_messageController.text.trim().isNotEmpty) {
             _sendMessage();
           }
        });
      }
    }
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          
          // Bot Avatar - Eğer konuşmacı seçiliyse avatarını göster
          if (_selectedVoice != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: _selectedVoice!.avatarUrl,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0ea5e9), Color(0xFF06b6d4)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _selectedVoice!.name[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0ea5e9), Color(0xFF06b6d4)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _selectedVoice!.name[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0ea5e9), Color(0xFF06b6d4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0ea5e9).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
          const SizedBox(width: 12),
          
          // Bot Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedVoice?.name ?? 'AI Bot',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22c55e),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _selectedVoice != null
                            ? '${_selectedVoice!.accent} • Sohbete hazır'
                            : (_ttsAvailable ? 'Online - Sesli cevap aktif' : 'Online - Ready to chat'),
                        style: const TextStyle(
                          color: Color(0xFF0ea5e9),
                          fontSize: 12,
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
          
          // Settings Button - Konuşmacı değiştir
          IconButton(
            onPressed: _showVoiceSelectionModal,
            icon: const Icon(
              Icons.settings,
              color: Colors.white54,
            ),
            tooltip: 'Konuşmacı Değiştir',
          ),
          
          // Sound Toggle
          IconButton(
            onPressed: () => setState(() => _ttsEnabled = !_ttsEnabled),
            icon: Icon(
              _ttsEnabled ? Icons.volume_up : Icons.volume_off,
              color: _ttsEnabled ? const Color(0xFF0ea5e9) : Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: message.isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          if (message.isBot)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedVoice != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImage(
                        imageUrl: _selectedVoice!.avatarUrl,
                        width: 24,
                        height: 24,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0ea5e9), Color(0xFF06b6d4)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 14),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0ea5e9), Color(0xFF06b6d4)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.smart_toy_outlined,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedVoice?.name ?? 'AI Bot',
                    style: const TextStyle(
                      color: Color(0xFF0ea5e9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // Speak button for bot messages
                  if (_ttsAvailable) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _speakText(message.text),
                      child: Icon(
                        _isSpeaking ? Icons.stop_circle_outlined : Icons.volume_up,
                        color: const Color(0xFF0ea5e9),
                        size: 18,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: message.isBot
                  ? const LinearGradient(
                      colors: [Color(0xFF1e3a5f), Color(0xFF1e3a8a)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF0ea5e9), Color(0xFF0284c7)],
                    ),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(message.isBot ? 4 : 20),
                bottomRight: Radius.circular(message.isBot ? 20 : 4),
              ),
              border: message.isBot
                  ? Border.all(color: const Color(0xFF0ea5e9).withOpacity(0.2))
                  : null,
              boxShadow: [
                BoxShadow(
                  color: (message.isBot ? const Color(0xFF1e3a8a) : const Color(0xFF0ea5e9))
                      .withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message.time,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1e3a8a).withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF0ea5e9).withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFF0ea5e9).withOpacity(0.6 + (value * 0.4)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0f172a).withOpacity(0.8),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Mic Button (Voice Input)
              GestureDetector(
                  onTap: () {
                    if (_isListening) {
                      _stopAndSend(manual: true);
                    } else {
                      _startListening();
                    }
                  },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _isListening ? const Color(0xFFef4444) : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _isListening ? [
                      BoxShadow(
                        color: const Color(0xFFef4444).withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ) 
                    ] : [],
                  ),
                  child: Icon(
                    _isListening ? Icons.stop : Icons.mic, 
                    color: Colors.white, 
                    size: 22
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Text Input
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1e293b).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Type your message in English...',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Send Button
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0ea5e9), Color(0xFF0284c7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0ea5e9).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _isTyping ? null : _sendMessage,
                  icon: const Icon(Icons.send, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Bottom Hint
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _ttsAvailable 
                    ? 'Sesli cevap için hoparlör açık' 
                    : 'Practice your English with AI Bot',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0ea5e9), Color(0xFF06b6d4)],
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Icon(
                  Icons.smart_toy_outlined,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isBot;
  final String time;

  ChatMessage({
    required this.text,
    required this.isBot,
    required this.time,
  });
}

// Custom audio source for just_audio
class MyCustomSource extends StreamAudioSource {
  final Uint8List _buffer;
  
  MyCustomSource(this._buffer);
  
  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _buffer.length;
    return StreamAudioResponse(
      sourceLength: _buffer.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_buffer.sublist(start, end)),
      contentType: 'audio/wav',
    );
  }
}

// Particles Painter for floating animation
class ParticlesPainter extends CustomPainter {
  final double animationValue;
  
  ParticlesPainter(this.animationValue);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0ea5e9).withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    // Draw floating particles
    for (int i = 0; i < 20; i++) {
      final x = (size.width * (0.1 + (i * 0.05) + animationValue * 0.1)) % size.width;
      final y = (size.height * (0.1 + (i * 0.04) + animationValue * 0.2)) % size.height;
      final radius = 1.0 + (i % 3);
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant ParticlesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
