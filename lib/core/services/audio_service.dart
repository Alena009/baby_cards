import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  AudioService() {
    _initTts();
  }
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _effectPlayer = AudioPlayer();
  final Map<String, Map<String, String>> _bestVoices = {};
  bool isMuted = false;

  Future<void> _initTts() async {
    await _flutterTts.setVolume(1.0);
    // Reverted to natural, standard pitch
    await _flutterTts.setPitch(1.0); 
    await _flutterTts.setSpeechRate(0.5);
    
    if (Platform.isIOS) {
      await _flutterTts.setSharedInstance(true);
      await _flutterTts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        IosTextToSpeechAudioCategoryOptions.mixWithOthers,
      ]);
      _findBestVoices();
      Future.delayed(const Duration(seconds: 1), _findBestVoices);
    }
  }

  Future<void> _findBestVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      if (voices == null || voices is! List) return;

      for (var voice in voices) {
        if (voice is! Map) continue;
        final String name = voice['name']?.toString() ?? '';
        final String locale = voice['locale']?.toString().toLowerCase() ?? '';
        final String lowerName = name.toLowerCase();
        
        bool isNatural = lowerName.contains('natural') || (lowerName.contains('siri') && !lowerName.contains('compact'));
        bool isPremium = lowerName.contains('premium') || lowerName.contains('enhanced');
        
        if (locale.startsWith('en')) {
          _updateBestVoice('en-US', name, locale, isNatural, isPremium);
        } else if (locale.startsWith('pl')) {
          _updateBestVoice('pl-PL', name, locale, isNatural, isPremium);
        }
      }
    } catch (e) {
      print("TTS: Error: $e");
    }
  }

  void _updateBestVoice(String lang, String name, String locale, bool natural, bool premium) {
    final current = _bestVoices[lang];
    if (current == null) {
      _bestVoices[lang] = {"name": name, "locale": locale};
      return;
    }

    final String currentName = current["name"]!.toLowerCase();
    bool curNatural = currentName.contains('siri') || currentName.contains('natural');

    // Natural/Siri > Premium > Default
    if (natural && !curNatural) {
      _bestVoices[lang] = {"name": name, "locale": locale};
    } else if (premium && !curNatural && !currentName.contains('premium')) {
      _bestVoices[lang] = {"name": name, "locale": locale};
    }
  }

  Future<void> speak(String text, String languageCode) async {
    if (isMuted) return;
    if (_bestVoices[languageCode] == null) await _findBestVoices();

    await _flutterTts.setLanguage(languageCode);
    await _flutterTts.setPitch(1.0); // Reset to standard

    if (Platform.isIOS && _bestVoices.containsKey(languageCode)) {
      final voice = _bestVoices[languageCode]!;
      await _flutterTts.setVoice({
        "name": voice["name"]!, 
        "locale": voice["locale"]!
      });
    }

    await _flutterTts.speak(text);
  }

  Future<void> playEffect(String effect) async {
    if (isMuted) return;
    String url = '';
    if (effect == 'whoosh') {
      // Alternative whoosh sound
      url = 'https://assets.mixkit.co/active_storage/sfx/2568/2568-preview.mp3';
    } else if (effect == 'magic') {
      // Softer bubbles/pop sound
      url = 'https://assets.mixkit.co/active_storage/sfx/2043/2043-preview.mp3';
    }
    
    if (url.isNotEmpty) {
      try {
        await _effectPlayer.play(UrlSource(url));
      } catch (e) {
        print("Audio: Error playing effect: $e");
      }
    }
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
