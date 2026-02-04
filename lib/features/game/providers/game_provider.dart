import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baby_education/core/models/game_models.dart';
import 'package:baby_education/core/services/audio_service.dart';

final audioServiceProvider = Provider<AudioService>((ref) => AudioService());
final languageProvider = StateProvider<String>((ref) => 'en-US');
final currentCategoryProvider = StateProvider<CardCategoryType>((ref) => CardCategoryType.colors);
final isMutedProvider = StateProvider<bool>((ref) => false);

String _enNumberWord(int n) {
  if (n >= 1000000000) return "One Billion";
  if (n >= 1000000) return "One Million";
  if (n >= 1000) return "One Thousand";
  if (n == 100) return "One Hundred";
  
  const units = ["", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen"];
  const tens = ["", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"];
  if (n < 20) return units[n];
  if (n < 100) return tens[n ~/ 10] + (n % 10 != 0 ? " " + units[n % 10] : "");
  return "";
}

String _plNumberWord(int n) {
  if (n >= 1000000000) return "Miliard";
  if (n >= 1000000) return "Milion";
  if (n >= 1000) return "Tysiąc";
  if (n == 100) return "Sto";
  
  const units = ["", "Jeden", "Dwa", "Trzy", "Cztery", "Pięć", "Sześć", "Siedem", "Osiem", "Dziewięć", "Dziesięć", "Jedenaście", "Dwanaście", "Trzynaście", "Czternaście", "Piętnaście", "Szesnaście", "Siedemnaście", "Osiemnaście", "Dziewiętnaście"];
  const tens = ["", "", "Dwadzieścia", "Trzydzieści", "Czterdzieści", "Pięćdziesiąt", "Sześćdziesiąt", "Siedemdziesiąt", "Osiemdziesiąt", "Dziewięćdziesiąt"];
  if (n < 20) return units[n];
  if (n < 100) return tens[n ~/ 10] + (n % 10 != 0 ? " " + units[n % 10].toLowerCase() : "");
  return "";
}

List<EducationCard> _generateNumbers() {
  final numbers = <EducationCard>[];
  
  // 1-30
  for (int i = 1; i <= 30; i++) {
    numbers.add(EducationCard(
      id: 'num_$i',
      imageUrl: 'assets/images/numbers/$i.png',
      transcriptions: {
        'en-US': _enNumberWord(i),
        'pl-PL': _plNumberWord(i),
      },
    ));
  }
  
  // 40, 50, 60, 70, 80, 90, 100
  for (int i = 40; i <= 100; i += 10) {
    numbers.add(EducationCard(
      id: 'num_$i',
      imageUrl: 'assets/images/numbers/$i.png',
      transcriptions: {
        'en-US': _enNumberWord(i),
        'pl-PL': _plNumberWord(i),
      },
    ));
  }
  
  return numbers;
}

final List<String> _englishAlphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');
final List<String> _polishAlphabet = [
  'A', 'Ą', 'B', 'C', 'Ć', 'D', 'E', 'Ę', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'Ł', 'M', 'N', 'Ń', 'O', 'Ó', 'P', 'R', 'S', 'Ś', 'T', 'U', 'W', 'Y', 'Z', 'Ź', 'Ż'
];

final categoriesProvider = Provider<List<CardCategory>>((ref) {
  final lang = ref.watch(languageProvider);
  final isPolish = lang == 'pl-PL';

  return [
    CardCategory(
      type: CardCategoryType.colors,
      name: isPolish ? 'Kolory' : 'Colors',
      icon: '🎨',
      cards: [
        EducationCard(id: 'red', hexColor: '0xFFFF0000', transcriptions: {'en-US': 'Red', 'pl-PL': 'Czerwony'}),
        EducationCard(id: 'blue', hexColor: '0xFF0000FF', transcriptions: {'en-US': 'Blue', 'pl-PL': 'Niebieski'}),
        EducationCard(id: 'green', hexColor: '0xFF00FF00', transcriptions: {'en-US': 'Green', 'pl-PL': 'Zielony'}),
        EducationCard(id: 'yellow', hexColor: '0xFFFFFF00', transcriptions: {'en-US': 'Yellow', 'pl-PL': 'Żółty'}),
        EducationCard(id: 'orange', hexColor: '0xFFFFA500', transcriptions: {'en-US': 'Orange', 'pl-PL': 'Pomarańczowy'}),
        EducationCard(id: 'purple', hexColor: '0xFF800080', transcriptions: {'en-US': 'Purple', 'pl-PL': 'Fioletowy'}),
        EducationCard(id: 'pink', hexColor: '0xFFFFC0CB', transcriptions: {'en-US': 'Pink', 'pl-PL': 'Różowy'}),
        EducationCard(id: 'brown', hexColor: '0xFF8B4513', transcriptions: {'en-US': 'Brown', 'pl-PL': 'Brązowy'}),
        EducationCard(id: 'black', hexColor: '0xFF000000', transcriptions: {'en-US': 'Black', 'pl-PL': 'Czarny'}),
        EducationCard(id: 'white', hexColor: '0xFFFFFFFF', transcriptions: {'en-US': 'White', 'pl-PL': 'Biały'}),
        EducationCard(id: 'grey', hexColor: '0xFF808080', transcriptions: {'en-US': 'Grey', 'pl-PL': 'Szary'}),
        EducationCard(id: 'light_blue', hexColor: '0xFFADD8E6', transcriptions: {'en-US': 'Light Blue', 'pl-PL': 'Jasnoniebieski'}),
      ],
    ),
    CardCategory(
      type: CardCategoryType.numbers,
      name: isPolish ? 'Liczby' : 'Numbers',
      icon: '🔢',
      cards: _generateNumbers(),
    ),
    CardCategory(
      type: CardCategoryType.letters,
      name: isPolish ? 'Litery' : 'Letters',
      icon: '🔤',
      cards: [], 
    ),
    CardCategory(
      type: CardCategoryType.cars,
      name: isPolish ? 'Samochody' : 'Cars',
      icon: '🚗',
      cards: [
        EducationCard(id: 'fire_truck', imageUrl: 'assets/images/cars/fire_truck.png', transcriptions: {'en-US': 'Fire Truck', 'pl-PL': 'Straż Pożarna'}),
        EducationCard(id: 'police_car', imageUrl: 'assets/images/cars/police_car.png', transcriptions: {'en-US': 'Police Car', 'pl-PL': 'Policja'}),
        EducationCard(id: 'ambulance', imageUrl: 'assets/images/cars/ambulance.png', transcriptions: {'en-US': 'Ambulance', 'pl-PL': 'Ambulans'}),
        EducationCard(id: 'bulldozer', imageUrl: 'assets/images/cars/bulldozer.png', transcriptions: {'en-US': 'Bulldozer', 'pl-PL': 'Buldożer'}),
        EducationCard(id: 'garbage_truck', imageUrl: 'assets/images/cars/garbage_truck.png', transcriptions: {'en-US': 'Garbage Truck', 'pl-PL': 'Śmieciarka'}),
        EducationCard(id: 'excavator', imageUrl: 'assets/images/cars/excavator.png', transcriptions: {'en-US': 'Excavator', 'pl-PL': 'Koparka'}),
        EducationCard(id: 'tractor', imageUrl: 'assets/images/cars/tractor.png', transcriptions: {'en-US': 'Tractor', 'pl-PL': 'Traktor'}),
        EducationCard(id: 'tow_truck', imageUrl: 'assets/images/cars/tow_truck.png', transcriptions: {'en-US': 'Tow Truck', 'pl-PL': 'Pomoc Drogowa'}),
        EducationCard(id: 'cement_mixer', imageUrl: 'assets/images/cars/cement_mixer.png', transcriptions: {'en-US': 'Cement Mixer', 'pl-PL': 'Betoniarka'}),
        EducationCard(id: 'crane', imageUrl: 'assets/images/cars/crane.png', transcriptions: {'en-US': 'Crane', 'pl-PL': 'Dźwig'}),
        EducationCard(id: 'school_bus', imageUrl: 'assets/images/cars/school_bus.png', transcriptions: {'en-US': 'School Bus', 'pl-PL': 'Autobus Szkolny'}),
        EducationCard(id: 'taxi', imageUrl: 'assets/images/cars/taxi.png', transcriptions: {'en-US': 'Taxi', 'pl-PL': 'Taksówka'}),
      ],
    ),
  ];
});

final currentCardsProvider = Provider<List<EducationCard>>((ref) {
  final categoryType = ref.watch(currentCategoryProvider);
  final lang = ref.watch(languageProvider);
  final categories = ref.watch(categoriesProvider);

  if (categoryType == CardCategoryType.letters) {
    final alphabet = lang == 'pl-PL' ? _polishAlphabet : _englishAlphabet;
    return alphabet.map((char) => EducationCard(
      id: 'letter_$char',
      transcriptions: {
        'en-US': char.toLowerCase(), 
        'pl-PL': char.toLowerCase(),
      },
    )).toList();
  }

  return categories.firstWhere((c) => c.type == categoryType).cards;
});
