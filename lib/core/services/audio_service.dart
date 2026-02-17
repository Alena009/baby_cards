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
          _updateBestVoice('en-US', name, locale, isNatural, isPremium, voice['gender']?.toString().toLowerCase() == 'female');
        } else if (locale.startsWith('pl')) {
          _updateBestVoice('pl-PL', name, locale, isNatural, isPremium, voice['gender']?.toString().toLowerCase() == 'female');
        } else if (locale.startsWith('de')) {
          _updateBestVoice('de-DE', name, locale, isNatural, isPremium, voice['gender']?.toString().toLowerCase() == 'female');
        } else if (locale.startsWith('fr')) {
          _updateBestVoice('fr-FR', name, locale, isNatural, isPremium, voice['gender']?.toString().toLowerCase() == 'female');
        } else if (locale.startsWith('uk')) {
          _updateBestVoice('uk-UA', name, locale, isNatural, isPremium, voice['gender']?.toString().toLowerCase() == 'female');
        }
      }
    } catch (e) {
      print("TTS: Error: $e");
    }
  }

  void _updateBestVoice(String lang, String name, String locale, bool natural, bool premium, bool isFemale) {
    final current = _bestVoices[lang];
    
    // Check for female names for prioritization
    final String lowerName = name.toLowerCase();
    bool priorityFemaleName = false;
    if (lang.startsWith('en')) {
      priorityFemaleName = lowerName.contains('samantha') || 
                          lowerName.contains('nicky') || 
                          lowerName.contains('flo') || 
                          lowerName.contains('victoria') ||
                          lowerName.contains('karen') ||
                          lowerName.contains('moira');
    } else if (lang.startsWith('pl')) {
      priorityFemaleName = lowerName.contains('paulina') || 
                          lowerName.contains('maja') || 
                          lowerName.contains('zosia') ||
                          lowerName.contains('agnieszka') ||
                          lowerName.contains('ewa');
    } else if (lang.startsWith('de')) {
      priorityFemaleName = lowerName.contains('marlene') || 
                          lowerName.contains('vicki') || 
                          lowerName.contains('gaby') ||
                          lowerName.contains('katrin') ||
                          lowerName.contains('anna');
    } else if (lang.startsWith('fr')) {
      priorityFemaleName = lowerName.contains('amelie') || 
                          lowerName.contains('celine') || 
                          lowerName.contains('lea') ||
                          lowerName.contains('chloe') ||
                          lowerName.contains('manon') ||
                          lowerName.contains('audrey') ||
                          lowerName.contains('aurelie') ||
                          lowerName.contains('marie') ||
                          lowerName.contains('julie') ||
                          lowerName.contains('alice');
    } else if (lang.startsWith('uk')) {
      priorityFemaleName = lowerName.contains('hanna') || 
                          lowerName.contains('viktoria') || 
                          lowerName.contains('mariya') ||
                          lowerName.contains('olena') ||
                          lowerName.contains('natalia') ||
                          lowerName.contains('lesya');
    }

    if (current == null) {
      _bestVoices[lang] = {"name": name, "locale": locale, "isFemale": isFemale.toString(), "priorityFemaleName": priorityFemaleName.toString()};
      return;
    }

    final String currentName = current["name"]!.toLowerCase();
    bool curNatural = currentName.contains('siri') || currentName.contains('natural');
    bool curFemale = current["isFemale"] == "true" || current["priorityFemaleName"] == "true";

    // Scoring system: Female/Priority > Natural > Premium > Default
    bool shouldReplace = false;

    // If current is NOT female but new one IS female or has priority name -> Replace
    if (!curFemale && (isFemale || priorityFemaleName)) {
      shouldReplace = true;
    } 
    // If both are female (or both not), use natural/premium quality logic
    else if (curFemale == (isFemale || priorityFemaleName)) {
      if (natural && !curNatural) {
        shouldReplace = true;
      } else if (premium && !curNatural && !currentName.contains('premium')) {
        shouldReplace = true;
      }
    }

    if (shouldReplace) {
      _bestVoices[lang] = {
        "name": name, 
        "locale": locale, 
        "isFemale": isFemale.toString(), 
        "priorityFemaleName": priorityFemaleName.toString()
      };
    }
  }

  Future<void> speak(String text, String languageCode) async {
    if (isMuted) return;

    // Try playing local audio file first
    try {
      // 1. Sanitize text for filename
      // Remove accents/diacritics for normalization if needed, but simple replacement is safer for now
      // We will strip special chars but keep standard letters/numbers
      
      String normalized = text.toLowerCase().trim();
      
      // Manual mapping for common Polish/Ukrainian chars if they were used in filename
      normalized = normalized
          .replaceAll('ą', 'a')
          .replaceAll('ć', 'c')
          .replaceAll('ę', 'e')
          .replaceAll('ł', 'l')
          .replaceAll('ń', 'n')
          .replaceAll('ó', 'o')
          .replaceAll('ś', 's')
          .replaceAll('ź', 'z')
          .replaceAll('ż', 'z')
          .replaceAll('є', 'ye')
          .replaceAll('і', 'i')
          .replaceAll('ї', 'yi')
          .replaceAll('ґ', 'g');
          
      final String filename = normalized
          .replaceAll(' ', '_')
          .replaceAll(RegExp(r'[^\w\s_]'), ''); 
      
      final String langDir = languageCode.split('-')[0]; // en, pl, or uk
      final String path = 'audio/$langDir/$filename.wav';

      print('AudioService: Looking for file at assets/$path');
      
      await _effectPlayer.play(AssetSource(path));
      print('AudioService: Playing custom file: $path');
      return; 
    } catch (e) {
      print("AudioService: Error playing local file (fallback to TTS): $e");
    }

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
