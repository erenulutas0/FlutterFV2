import 'dart:convert';

/// Piper TTS Konuşmacı Modeli
class VoiceModel {
  final String id;
  final String name;
  final String gender; // 'female' or 'male'
  final String accent; // 'American', 'British', 'Australian', 'Canadian'
  final String locale; // 'en_US', 'en_GB', etc.
  final String piperVoice; // Piper TTS voice name (e.g., 'amy', 'lessac')
  final String avatarUrl;
  final String sampleText;

  const VoiceModel({
    required this.id,
    required this.name,
    required this.gender,
    required this.accent,
    required this.locale,
    required this.piperVoice,
    required this.avatarUrl,
    required this.sampleText,
  });

  /// Cinsiyet emojisi
  String get genderEmoji => gender == 'female' ? '👩' : '👨';

  /// Cinsiyet Türkçe
  String get genderText => gender == 'female' ? 'Kadın' : 'Erkek';

  /// JSON'a dönüştür
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'accent': accent,
      'locale': locale,
      'piperVoice': piperVoice,
      'avatarUrl': avatarUrl,
      'sampleText': sampleText,
    };
  }

  /// JSON'dan oluştur
  factory VoiceModel.fromJson(Map<String, dynamic> json) {
    return VoiceModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      gender: json['gender'] ?? 'female',
      accent: json['accent'] ?? 'American',
      locale: json['locale'] ?? 'en_US',
      piperVoice: json['piperVoice'] ?? 'amy',
      avatarUrl: json['avatarUrl'] ?? '',
      sampleText: json['sampleText'] ?? '',
    );
  }

  /// JSON String'e dönüştür
  String toJsonString() => jsonEncode(toJson());

  /// JSON String'den oluştur
  factory VoiceModel.fromJsonString(String jsonString) {
    return VoiceModel.fromJson(jsonDecode(jsonString));
  }

  /// Varsayılan konuşmacıliar listesi (Piper TTS sesleri ile)
  static List<VoiceModel> get availableVoices => [
    const VoiceModel(
      id: 'amy',
      name: 'Amy',
      gender: 'female',
      accent: 'American',
      locale: 'en_US',
      piperVoice: 'amy',
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&h=400&fit=crop',
      sampleText: "Hi! I'm Amy, and I'm here to help you practice English. Let's have a great conversation!",
    ),
    const VoiceModel(
      id: 'ryan',
      name: 'Ryan',
      gender: 'male',
      accent: 'American',
      locale: 'en_US',
      piperVoice: 'ryan',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop',
      sampleText: "Hello there! I'm Ryan, ready to assist you with your English learning journey.",
    ),
    const VoiceModel(
      id: 'lessac',
      name: 'Emma',
      gender: 'female',
      accent: 'American',
      locale: 'en_US',
      piperVoice: 'lessac',
      avatarUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&h=400&fit=crop',
      sampleText: "Hey! I'm Emma. I'm excited to practice English with you and make learning fun!",
    ),
    const VoiceModel(
      id: 'alan',
      name: 'Alan',
      gender: 'male',
      accent: 'British',
      locale: 'en_GB',
      piperVoice: 'alan',
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&h=400&fit=crop',
      sampleText: "Hi! I'm Alan from the UK. Let's improve your English skills together, shall we?",
    ),
    const VoiceModel(
      id: 'jenny',
      name: 'Jenny',
      gender: 'female',
      accent: 'British',
      locale: 'en_GB',
      piperVoice: 'jenny_dioco',
      avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&h=400&fit=crop',
      sampleText: "Hello! I'm Jenny from Britain. I'm here to help you become more confident in English!",
    ),
    const VoiceModel(
      id: 'cori',
      name: 'Cori',
      gender: 'female',
      accent: 'British',
      locale: 'en_GB',
      piperVoice: 'cori',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&h=400&fit=crop',
      sampleText: "G'day! I'm Cori. Let's make your English practice enjoyable and effective!",
    ),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoiceModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
