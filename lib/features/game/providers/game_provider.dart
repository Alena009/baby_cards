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

String _deNumberWord(int n) {
  if (n == 100) return "Hundert";
  if (n == 0) return "Null";
  
  const units = ["", "eins", "zwei", "drei", "vier", "fünf", "sechs", "sieben", "acht", "neun", "zehn", "elf", "zwölf", "dreizehn", "vierzehn", "fünfzehn", "sechzehn", "siebzehn", "achtzehn", "neunzehn"];
  const tens = ["", "", "zwanzig", "dreißig", "vierzig", "fünfzig", "sechzig", "siebzig", "achtzig", "neunzig"];
  
  if (n < 20) return units[n][0].toUpperCase() + units[n].substring(1);
  
  if (n % 10 == 0) return tens[n ~/ 10][0].toUpperCase() + tens[n ~/ 10].substring(1);
  
  String unitPart = n % 10 == 1 ? "ein" : units[n % 10];
  String combined = unitPart + "und" + tens[n ~/ 10];
  return combined[0].toUpperCase() + combined.substring(1);
}

String _frNumberWord(int n) {
  if (n == 0) return "Zéro";
  if (n == 100) return "Cent";
  
  const units = ["", "un", "deux", "trois", "quatre", "cinq", "six", "sept", "huit", "neuf", "dix", "onze", "douze", "treize", "quatorze", "quinze", "seize", "dix-sept", "dix-huit", "dix-neuf"];
  const tens = ["", "", "vingt", "trente", "quarante", "cinquante", "soixante", "soixante", "quatre-vingt", "quatre-vingt"];

  if (n < 20) return units[n][0].toUpperCase() + units[n].substring(1);
  
  if (n < 70) {
    if (n % 10 == 0) return tens[n ~/ 10][0].toUpperCase() + tens[n ~/ 10].substring(1);
    String sep = (n % 10 == 1) ? "-et-" : "-";
    String res = tens[n ~/ 10] + sep + units[n % 10];
    return res[0].toUpperCase() + res.substring(1);
  }
  
  if (n < 80) {
    if (n == 71) return "Soixante-et-onze";
    String res = "soixante-" + units[n - 60];
    return res[0].toUpperCase() + res.substring(1);
  }
  
  if (n < 90) {
    if (n % 10 == 0) return "Quatre-vingts";
    String res = "quatre-vingt-" + units[n % 10];
    return res[0].toUpperCase() + res.substring(1);
  }
  
  if (n < 100) {
    String res = "quatre-vingt-" + units[n - 80];
    return res[0].toUpperCase() + res.substring(1);
  }
  
  return "";
}

String _ukNumberWord(int n) {
  if (n == 0) return "Нуль";
  if (n == 100) return "Сто";
  
  const units = ["", "Один", "Два", "Три", "Чотири", "П'ять", "Шість", "Сім", "Вісім", "Дев'ять", "Десять", "Одинадцять", "Дванадцять", "Тринадцять", "Чотирнадцять", "П'ятнадцять", "Шістнадцять", "Сімнадцять", "Вісімнадцять", "Дев'ятнадцять"];
  const tens = ["", "", "Двадцять", "Тридцять", "Сорок", "П'ятдесят", "Шістдесят", "Сімдесят", "Вісімдесят", "Дев'яносто"];
  
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
      transcriptions: {
        'en-US': _enNumberWord(i),
        'pl-PL': _plNumberWord(i),
        'de-DE': _deNumberWord(i),
        'fr-FR': _frNumberWord(i),
        'uk-UA': _ukNumberWord(i),
      },
    ));
  }
  
  // 40, 50, 60, 70, 80, 90, 100
  for (int i = 40; i <= 100; i += 10) {
    numbers.add(EducationCard(
      id: 'num_$i',
      transcriptions: {
        'en-US': _enNumberWord(i),
        'pl-PL': _plNumberWord(i),
        'de-DE': _deNumberWord(i),
        'fr-FR': _frNumberWord(i),
        'uk-UA': _ukNumberWord(i),
      },
    ));
  }
  
  return numbers;
}

final List<String> _englishAlphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');
final List<String> _polishAlphabet = [
  'A', 'Ą', 'B', 'C', 'Ć', 'D', 'E', 'Ę', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'Ł', 'M', 'N', 'Ń', 'O', 'Ó', 'P', 'R', 'S', 'Ś', 'T', 'U', 'W', 'Y', 'Z', 'Ź', 'Ż'
];
final List<String> _ukrainianAlphabet = [
  'А', 'Б', 'В', 'Г', 'Ґ', 'Д', 'Е', 'Є', 'Ж', 'З', 'И', 'І', 'Ї', 'Й', 'К', 'Л', 'М', 'Н', 'О', 'П', 'Р', 'С', 'Т', 'У', 'Ф', 'Х', 'Ц', 'Ч', 'Ш', 'Щ', 'Ь', 'Ю', 'Я'
];

final categoriesProvider = Provider<List<CardCategory>>((ref) {
  final lang = ref.watch(languageProvider);
  final isPolish = lang == 'pl-PL';
  final isGerman = lang == 'de-DE';
  final isFrench = lang == 'fr-FR';
  final isUkrainian = lang == 'uk-UA';

  return [
    CardCategory(
      type: CardCategoryType.colors,
      name: isUkrainian ? 'Кольори' : (isFrench ? 'Couleurs' : (isGerman ? 'Farben' : (isPolish ? 'Kolory' : 'Colors'))),
      icon: '🎨',
      cards: [
        EducationCard(id: 'red', hexColor: '0xFFFF0000', transcriptions: {'en-US': 'Red', 'pl-PL': 'Czerwony', 'de-DE': 'Rot', 'fr-FR': 'Rouge', 'uk-UA': 'Червоний'}),
        EducationCard(id: 'blue', hexColor: '0xFF0000FF', transcriptions: {'en-US': 'Blue', 'pl-PL': 'Granatowy', 'de-DE': 'Blau', 'fr-FR': 'Bleu', 'uk-UA': 'Синій'}),
        EducationCard(id: 'green', hexColor: '0xFF00FF00', transcriptions: {'en-US': 'Green', 'pl-PL': 'Zielony', 'de-DE': 'Grün', 'fr-FR': 'Vert', 'uk-UA': 'Зелений'}),
        EducationCard(id: 'yellow', hexColor: '0xFFFFFF00', transcriptions: {'en-US': 'Yellow', 'pl-PL': 'Żółty', 'de-DE': 'Gelb', 'fr-FR': 'Jaune', 'uk-UA': 'Жовтий'}),
        EducationCard(id: 'orange', hexColor: '0xFFFFA500', transcriptions: {'en-US': 'Orange', 'pl-PL': 'Pomarańczowy', 'de-DE': 'Orange', 'fr-FR': 'Orange', 'uk-UA': 'Помаранчевий'}),
        EducationCard(id: 'purple', hexColor: '0xFF800080', transcriptions: {'en-US': 'Purple', 'pl-PL': 'Fioletowy', 'de-DE': 'Lila', 'fr-FR': 'Violet', 'uk-UA': 'Фіолетовий'}),
        EducationCard(id: 'pink', hexColor: '0xFFFFC0CB', transcriptions: {'en-US': 'Pink', 'pl-PL': 'Różowy', 'de-DE': 'Rosa', 'fr-FR': 'Rose', 'uk-UA': 'Рожевий'}),
        EducationCard(id: 'brown', hexColor: '0xFF8B4513', transcriptions: {'en-US': 'Brown', 'pl-PL': 'Brązowy', 'de-DE': 'Braun', 'fr-FR': 'Marron', 'uk-UA': 'Коричневий'}),
        EducationCard(id: 'black', hexColor: '0xFF000000', transcriptions: {'en-US': 'Black', 'pl-PL': 'Czarny', 'de-DE': 'Schwarz', 'fr-FR': 'Noir', 'uk-UA': 'Чорний'}),
        EducationCard(id: 'white', hexColor: '0xFFFFFFFF', transcriptions: {'en-US': 'White', 'pl-PL': 'Biały', 'de-DE': 'Weiß', 'fr-FR': 'Blanc', 'uk-UA': 'Білий'}),
        EducationCard(id: 'grey', hexColor: '0xFF808080', transcriptions: {'en-US': 'Grey', 'pl-PL': 'Szary', 'de-DE': 'Grau', 'fr-FR': 'Gris', 'uk-UA': 'Сірий'}),
        EducationCard(id: 'light_blue', hexColor: '0xFFADD8E6', transcriptions: {'en-US': 'Light Blue', 'pl-PL': 'Niebieski', 'de-DE': 'Hellblau', 'fr-FR': 'Bleu ciel', 'uk-UA': 'Блакитний'}),
      ],
    ),
    CardCategory(
      type: CardCategoryType.numbers,
      name: isUkrainian ? 'Цифри' : (isFrench ? 'Nombres' : (isGerman ? 'Zahlen' : (isPolish ? 'Liczby' : 'Numbers'))),
      icon: '🔢',
      cards: _generateNumbers(),
    ),
    CardCategory(
      type: CardCategoryType.letters,
      name: isUkrainian ? 'Абетка' : (isFrench ? 'Lettres' : (isGerman ? 'Buchstaben' : (isPolish ? 'Litery' : 'Letters'))),
      icon: '🔤',
      cards: [], 
    ),
    CardCategory(
      type: CardCategoryType.cars,
      name: isUkrainian ? 'Машини' : (isFrench ? 'Voitures' : (isGerman ? 'Autos' : (isPolish ? 'Samochody' : 'Cars'))),
      icon: '🚗',
      cards: [
        EducationCard(id: 'fire_truck', imageUrl: 'assets/images/cars/fire_truck.png', transcriptions: {'en-US': 'Fire Truck', 'pl-PL': 'Straż Pożarna', 'de-DE': 'Feuerwehrauto', 'fr-FR': 'Camion de pompiers', 'uk-UA': 'Пожежна машина'}),
        EducationCard(id: 'police_car', imageUrl: 'assets/images/cars/police_car.png', transcriptions: {'en-US': 'Police Car', 'pl-PL': 'Policja', 'de-DE': 'Polizeiauto', 'fr-FR': 'Voiture de police', 'uk-UA': 'Поліцейська машина'}),
        EducationCard(id: 'ambulance', imageUrl: 'assets/images/cars/ambulance.png', transcriptions: {'en-US': 'Ambulance', 'pl-PL': 'Ambulans', 'de-DE': 'Krankenwagen', 'fr-FR': 'Ambulance', 'uk-UA': 'Швидка допомога'}),
        EducationCard(id: 'bulldozer', imageUrl: 'assets/images/cars/bulldozer.png', transcriptions: {'en-US': 'Bulldozer', 'pl-PL': 'Buldożer', 'de-DE': 'Planierraupe', 'fr-FR': 'Bulldozer', 'uk-UA': 'Бульдозер'}),
        EducationCard(id: 'garbage_truck', imageUrl: 'assets/images/cars/garbage_truck.png', transcriptions: {'en-US': 'Garbage Truck', 'pl-PL': 'Śmieciarka', 'de-DE': 'Müllwagen', 'fr-FR': 'Camion poubelle', 'uk-UA': 'Сміттєвоз'}),
        EducationCard(id: 'excavator', imageUrl: 'assets/images/cars/excavator.png', transcriptions: {'en-US': 'Excavator', 'pl-PL': 'Koparka', 'de-DE': 'Bagger', 'fr-FR': 'Pelle mécanique', 'uk-UA': 'Екскаватор'}),
        EducationCard(id: 'tractor', imageUrl: 'assets/images/cars/tractor.png', transcriptions: {'en-US': 'Tractor', 'pl-PL': 'Traktor', 'de-DE': 'Traktor', 'fr-FR': 'Tracteur', 'uk-UA': 'Трактор'}),
        EducationCard(id: 'tow_truck', imageUrl: 'assets/images/cars/tow_truck.png', transcriptions: {'en-US': 'Tow Truck', 'pl-PL': 'Pomoc Drogowa', 'de-DE': 'Abschleppwagen', 'fr-FR': 'Dépanneuse', 'uk-UA': 'Евакуатор'}),
        EducationCard(id: 'cement_mixer', imageUrl: 'assets/images/cars/cement_mixer.png', transcriptions: {'en-US': 'Cement Mixer', 'pl-PL': 'Betoniarka', 'de-DE': 'Betonmischer', 'fr-FR': 'Bétonnière', 'uk-UA': 'Бетонозмішувач'}),
        EducationCard(id: 'crane', imageUrl: 'assets/images/cars/crane.png', transcriptions: {'en-US': 'Crane', 'pl-PL': 'Dźwig', 'de-DE': 'Kran', 'fr-FR': 'Grue', 'uk-UA': 'Підйомний кран'}),
        EducationCard(id: 'school_bus', imageUrl: 'assets/images/cars/school_bus.png', transcriptions: {'en-US': 'School Bus', 'pl-PL': 'Autobus Szkolny', 'de-DE': 'Schulbus', 'fr-FR': 'Bus scolaire', 'uk-UA': 'Шкільний автобус'}),
        EducationCard(id: 'taxi', imageUrl: 'assets/images/cars/taxi.png', transcriptions: {'en-US': 'Taxi', 'pl-PL': 'Taksówka', 'de-DE': 'Taxi', 'fr-FR': 'Taxi', 'uk-UA': 'Таксі'}),
      ],
    ),
    CardCategory(
      type: CardCategoryType.farm,
      name: isUkrainian ? 'Тварини' : (isFrench ? 'Ferme' : (isGerman ? 'Tiere' : (isPolish ? 'Zwierzęta' : 'Farm Animals'))),
      icon: '🐮',
      cards: [
        EducationCard(id: 'dog', imageUrl: 'assets/images/farm/dog.png', transcriptions: {'en-US': 'Dog', 'pl-PL': 'Pies', 'de-DE': 'Hund', 'fr-FR': 'Chien', 'uk-UA': 'Собака'}),
        EducationCard(id: 'cat', imageUrl: 'assets/images/farm/cat.png', transcriptions: {'en-US': 'Cat', 'pl-PL': 'Kot', 'de-DE': 'Katze', 'fr-FR': 'Chat', 'uk-UA': 'Кіт'}),
        EducationCard(id: 'chicken', imageUrl: 'assets/images/farm/chicken.png', transcriptions: {'en-US': 'Chicken', 'pl-PL': 'Kura', 'de-DE': 'Huhn', 'fr-FR': 'Poule', 'uk-UA': 'Курка'}),
        EducationCard(id: 'cow', imageUrl: 'assets/images/farm/cow.png', transcriptions: {'en-US': 'Cow', 'pl-PL': 'Krowa', 'de-DE': 'Kuh', 'fr-FR': 'Vache', 'uk-UA': 'Корова'}),
        EducationCard(id: 'goat', imageUrl: 'assets/images/farm/goat.png', transcriptions: {'en-US': 'Goat', 'pl-PL': 'Koza', 'de-DE': 'Ziege', 'fr-FR': 'Chèvre', 'uk-UA': 'Коза'}),
        EducationCard(id: 'pig', imageUrl: 'assets/images/farm/pig.png', transcriptions: {'en-US': 'Pig', 'pl-PL': 'Świnia', 'de-DE': 'Schwein', 'fr-FR': 'Cochon', 'uk-UA': 'Свиня'}),
        EducationCard(id: 'goose', imageUrl: 'assets/images/farm/goose.png', transcriptions: {'en-US': 'Goose', 'pl-PL': 'Gęś', 'de-DE': 'Gans', 'fr-FR': 'Oie', 'uk-UA': 'Гуска'}),
        EducationCard(id: 'horse', imageUrl: 'assets/images/farm/horse.png', transcriptions: {'en-US': 'Horse', 'pl-PL': 'Koń', 'de-DE': 'Pferd', 'fr-FR': 'Cheval', 'uk-UA': 'Кінь'}),
        EducationCard(id: 'duck', imageUrl: 'assets/images/farm/duck.png', transcriptions: {'en-US': 'Duck', 'pl-PL': 'Kaczka', 'de-DE': 'Ente', 'fr-FR': 'Canard', 'uk-UA': 'Качка'}),
        EducationCard(id: 'rabbit', imageUrl: 'assets/images/farm/rabbit.png', transcriptions: {'en-US': 'Rabbit', 'pl-PL': 'Królik', 'de-DE': 'Hase', 'fr-FR': 'Lapin', 'uk-UA': 'Кролик'}),
        EducationCard(id: 'turkey', imageUrl: 'assets/images/farm/turkey.png', transcriptions: {'en-US': 'Turkey', 'pl-PL': 'Indyk', 'de-DE': 'Pute', 'fr-FR': 'Dindon', 'uk-UA': 'Індик'}),
        EducationCard(id: 'donkey', imageUrl: 'assets/images/farm/donkey.png', transcriptions: {'en-US': 'Donkey', 'pl-PL': 'Osioł', 'de-DE': 'Esel', 'fr-FR': 'Âne', 'uk-UA': 'Осел'}),
      ],
    ),
    CardCategory(
      type: CardCategoryType.fruits,
      name: isUkrainian ? 'Фрукти' : (isFrench ? 'Fruits' : (isGerman ? 'Früchte' : (isPolish ? 'Owoce' : 'Fruits'))),
      icon: '🍎',
      cards: [
        EducationCard(id: 'apple', imageUrl: 'assets/images/fruits/apple.png', transcriptions: {'en-US': 'Apple', 'pl-PL': 'Jabłko', 'de-DE': 'Apfel', 'fr-FR': 'Pomme', 'uk-UA': 'Яблуко'}),
        EducationCard(id: 'pear', imageUrl: 'assets/images/fruits/pear.png', transcriptions: {'en-US': 'Pear', 'pl-PL': 'Gruszka', 'de-DE': 'Birne', 'fr-FR': 'Poire', 'uk-UA': 'Груша'}),
        EducationCard(id: 'orange', imageUrl: 'assets/images/fruits/orange.png', transcriptions: {'en-US': 'Orange', 'pl-PL': 'Pomarańcza', 'de-DE': 'Orange', 'fr-FR': 'Orange', 'uk-UA': 'Апельсин'}),
        EducationCard(id: 'banana', imageUrl: 'assets/images/fruits/banan.png', transcriptions: {'en-US': 'Banana', 'pl-PL': 'Banan', 'de-DE': 'Banane', 'fr-FR': 'Banane', 'uk-UA': 'Банан'}),
        EducationCard(id: 'pineapple', imageUrl: 'assets/images/fruits/ananas.png', transcriptions: {'en-US': 'Pineapple', 'pl-PL': 'Ananas', 'de-DE': 'Ananas', 'fr-FR': 'Ananas', 'uk-UA': 'Ананас'}),
        EducationCard(id: 'plum', imageUrl: 'assets/images/fruits/plum.png', transcriptions: {'en-US': 'Plum', 'pl-PL': 'Śliwka', 'de-DE': 'Pflaume', 'fr-FR': 'Prune', 'uk-UA': 'Слива'}),
        EducationCard(id: 'kiwi', imageUrl: 'assets/images/fruits/kiwi.png', transcriptions: {'en-US': 'Kiwi', 'pl-PL': 'Kiwi', 'de-DE': 'Kiwi', 'fr-FR': 'Kiwi', 'uk-UA': 'Ківі'}),
        EducationCard(id: 'lemon', imageUrl: 'assets/images/fruits/lemon.png', transcriptions: {'en-US': 'Lemon', 'pl-PL': 'Cytryna', 'de-DE': 'Zitrone', 'fr-FR': 'Citron', 'uk-UA': 'Лимон'}),
        EducationCard(id: 'apricot', imageUrl: 'assets/images/fruits/apricot.png', transcriptions: {'en-US': 'Apricot', 'pl-PL': 'Morela', 'de-DE': 'Aprikose', 'fr-FR': 'Abricot', 'uk-UA': 'Абрикос'}),
        EducationCard(id: 'cherry', imageUrl: 'assets/images/fruits/cherry.png', transcriptions: {'en-US': 'Cherry', 'pl-PL': 'Wiśnia', 'de-DE': 'Kirsche', 'fr-FR': 'Cerise', 'uk-UA': 'Вишня'}),
        EducationCard(id: 'mango', imageUrl: 'assets/images/fruits/mango.png', transcriptions: {'en-US': 'Mango', 'pl-PL': 'Mango', 'de-DE': 'Mango', 'fr-FR': 'Mangue', 'uk-UA': 'Манго'}),
        EducationCard(id: 'tangerine', imageUrl: 'assets/images/fruits/mandarin.png', transcriptions: {'en-US': 'Tangerine', 'pl-PL': 'Mandarynka', 'de-DE': 'Mandarine', 'fr-FR': 'Mandarine', 'uk-UA': 'Мандарин'}),
      ],
    ),
  ];
});

final currentCardsProvider = Provider<List<EducationCard>>((ref) {
  final categoryType = ref.watch(currentCategoryProvider);
  final lang = ref.watch(languageProvider);
  final categories = ref.watch(categoriesProvider);

  if (categoryType == CardCategoryType.letters) {
    final alphabet = lang == 'uk-UA' ? _ukrainianAlphabet : (lang == 'pl-PL' ? _polishAlphabet : _englishAlphabet);
    return alphabet.map((char) => EducationCard(
      id: 'letter_$char',
      transcriptions: {
        'en-US': char.toLowerCase(), 
        'pl-PL': char.toLowerCase(),
        'de-DE': char.toLowerCase(),
        'fr-FR': char.toLowerCase(),
        'uk-UA': char.toLowerCase(),
      },
    )).toList();
  }

  return categories.firstWhere((c) => c.type == categoryType).cards;
});
