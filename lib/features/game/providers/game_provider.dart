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
        EducationCard(id: 'ambulance', imageUrl: 'assets/images/cars/ambulance.png', transcriptions: {'en-US': 'Ambulance', 'pl-PL': 'Karetka', 'de-DE': 'Krankenwagen', 'fr-FR': 'Ambulance', 'uk-UA': 'Швидка допомога'}),
        EducationCard(id: 'bulldozer', imageUrl: 'assets/images/cars/bulldozer.png', transcriptions: {'en-US': 'Bulldozer', 'pl-PL': 'Spycharka', 'de-DE': 'Planierraupe', 'fr-FR': 'Bulldozer', 'uk-UA': 'Бульдозер'}),
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
      type: CardCategoryType.wildAnimals,
      name: isUkrainian ? 'Дикі тварини' : (isFrench ? 'Animaux sauvages' : (isGerman ? 'Wildtiere' : (isPolish ? 'Dzikie zwierzęta' : 'Wild Animals'))),
      icon: '🦊',
      cards: [
        EducationCard(id: 'fox', imageUrl: 'assets/images/wild/fox.png', transcriptions: {'en-US': 'Fox', 'pl-PL': 'Lis', 'de-DE': 'Fuchs', 'fr-FR': 'Renard', 'uk-UA': 'Лисиця'}),
        EducationCard(id: 'wolf', imageUrl: 'assets/images/wild/wolf.png', transcriptions: {'en-US': 'Wolf', 'pl-PL': 'Wilk', 'de-DE': 'Wolf', 'fr-FR': 'Loup', 'uk-UA': 'Вовк'}),
        EducationCard(id: 'raccoon', imageUrl: 'assets/images/wild/raccoon.png', transcriptions: {'en-US': 'Raccoon', 'pl-PL': 'Szop', 'de-DE': 'Waschbär', 'fr-FR': 'Raton laveur', 'uk-UA': 'Єнот'}),
        EducationCard(id: 'badger', imageUrl: 'assets/images/wild/badger.png', transcriptions: {'en-US': 'Badger', 'pl-PL': 'Borsuk', 'de-DE': 'Dachs', 'fr-FR': 'Blaireau', 'uk-UA': 'Борсук'}),
        EducationCard(id: 'owl', imageUrl: 'assets/images/wild/owl.png', transcriptions: {'en-US': 'Owl', 'pl-PL': 'Sowa', 'de-DE': 'Eule', 'fr-FR': 'Hibou', 'uk-UA': 'Сова'}),
        EducationCard(id: 'deer', imageUrl: 'assets/images/wild/deer.png', transcriptions: {'en-US': 'Deer', 'pl-PL': 'Jeleń', 'de-DE': 'Hirsch', 'fr-FR': 'Cerf', 'uk-UA': 'Олень'}),
        EducationCard(id: 'moose', imageUrl: 'assets/images/wild/moose.png', transcriptions: {'en-US': 'Moose', 'pl-PL': 'Łoś', 'de-DE': 'Elch', 'fr-FR': 'Élan', 'uk-UA': 'Лось'}),
        EducationCard(id: 'beaver', imageUrl: 'assets/images/wild/beaver.png', transcriptions: {'en-US': 'Beaver', 'pl-PL': 'Bóbr', 'de-DE': 'Biber', 'fr-FR': 'Castor', 'uk-UA': 'Бобер'}),
        EducationCard(id: 'hedgehog', imageUrl: 'assets/images/wild/hedgehog.png', transcriptions: {'en-US': 'Hedgehog', 'pl-PL': 'Jeż', 'de-DE': 'Igel', 'fr-FR': 'Hérisson', 'uk-UA': 'Їжак'}),
        EducationCard(id: 'hare', imageUrl: 'assets/images/wild/hare.png', transcriptions: {'en-US': 'Hare', 'pl-PL': 'Zając', 'de-DE': 'Hase', 'fr-FR': 'Lièvre', 'uk-UA': 'Заєць'}),
        EducationCard(id: 'mole', imageUrl: 'assets/images/wild/mole.png', transcriptions: {'en-US': 'Mole', 'pl-PL': 'Kret', 'de-DE': 'Maulwurf', 'fr-FR': 'Taupe', 'uk-UA': 'Кріт'}),
        EducationCard(id: 'boar', imageUrl: 'assets/images/wild/boar.png', transcriptions: {'en-US': 'Boar', 'pl-PL': 'Dzik', 'de-DE': 'Wildschwein', 'fr-FR': 'Sanglier', 'uk-UA': 'Кабан'}),
      ],
    ),

    CardCategory(
      type: CardCategoryType.vegetables,
      name: isUkrainian ? 'Овочі' : (isFrench ? 'Légumes' : (isGerman ? 'Gemüse' : (isPolish ? 'Warzywa' : 'Vegetables'))),
      icon: '🥦',
      cards: [
        EducationCard(id: 'carrot', imageUrl: 'assets/images/vegetables/carrot.png', transcriptions: {'en-US': 'Carrot', 'pl-PL': 'Marchewka', 'de-DE': 'Karotte', 'fr-FR': 'Carotte', 'uk-UA': 'Морква'}),
        EducationCard(id: 'potato', imageUrl: 'assets/images/vegetables/potato.png', transcriptions: {'en-US': 'Potato', 'pl-PL': 'Ziemniak', 'de-DE': 'Kartoffel', 'fr-FR': 'Pomme de terre', 'uk-UA': 'Картопля'}),
        EducationCard(id: 'beetroot', imageUrl: 'assets/images/vegetables/beetroot.png', transcriptions: {'en-US': 'Beetroot', 'pl-PL': 'Burak', 'de-DE': 'Rote Bete', 'fr-FR': 'Betterave', 'uk-UA': 'Буряк'}),
        EducationCard(id: 'cabbage', imageUrl: 'assets/images/vegetables/cabbage.png', transcriptions: {'en-US': 'Cabbage', 'pl-PL': 'Kapusta', 'de-DE': 'Kohl', 'fr-FR': 'Chou', 'uk-UA': 'Капуста'}),
        EducationCard(id: 'onion', imageUrl: 'assets/images/vegetables/onion.png', transcriptions: {'en-US': 'Onion', 'pl-PL': 'Cebula', 'de-DE': 'Zwiebel', 'fr-FR': 'Oignon', 'uk-UA': 'Цибуля'}),
        EducationCard(id: 'tomato', imageUrl: 'assets/images/vegetables/tomato.png', transcriptions: {'en-US': 'Tomato', 'pl-PL': 'Pomidor', 'de-DE': 'Tomate', 'fr-FR': 'Tomate', 'uk-UA': 'Помідор'}),
        EducationCard(id: 'cucumber', imageUrl: 'assets/images/vegetables/cucumber.png', transcriptions: {'en-US': 'Cucumber', 'pl-PL': 'Ogórek', 'de-DE': 'Gurke', 'fr-FR': 'Concombre', 'uk-UA': 'Огірок'}),
        EducationCard(id: 'eggplant', imageUrl: 'assets/images/vegetables/eggplant.png', transcriptions: {'en-US': 'Eggplant', 'pl-PL': 'Bakłażan', 'de-DE': 'Aubergine', 'fr-FR': 'Aubergine', 'uk-UA': 'Баклажан'}),
        EducationCard(id: 'zucchini', imageUrl: 'assets/images/vegetables/zucchini.png', transcriptions: {'en-US': 'Zucchini', 'pl-PL': 'Cukinia', 'de-DE': 'Zucchini', 'fr-FR': 'Courgette', 'uk-UA': 'Цукіні'}),
        EducationCard(id: 'garlic', imageUrl: 'assets/images/vegetables/garlic.png', transcriptions: {'en-US': 'Garlic', 'pl-PL': 'Czosnek', 'de-DE': 'Knoblauch', 'fr-FR': 'Ail', 'uk-UA': 'Часник'}),
        EducationCard(id: 'celery', imageUrl: 'assets/images/vegetables/celery.png', transcriptions: {'en-US': 'Celery', 'pl-PL': 'Seler', 'de-DE': 'Sellerie', 'fr-FR': 'Céleri', 'uk-UA': 'Селера'}),
        EducationCard(id: 'parsley_root', imageUrl: 'assets/images/vegetables/parsley_root.png', transcriptions: {'en-US': 'Parsley root', 'pl-PL': 'Korzeń pietruszki', 'de-DE': 'Petersilienwurzel', 'fr-FR': 'Racine de persil', 'uk-UA': 'Корінь петрушки'}),
      ],
    ),
    CardCategory(
      type: CardCategoryType.body,
      name: isUkrainian ? 'Тіло' : (isFrench ? 'Corps' : (isGerman ? 'Körper' : (isPolish ? 'Ciało' : 'Body'))),
      icon: '🧍',
      cards: [
        EducationCard(id: 'hair', imageUrl: 'assets/images/body/hair.png', transcriptions: {'en-US': 'Hair', 'pl-PL': 'Włosy', 'de-DE': 'Haare', 'fr-FR': 'Cheveux', 'uk-UA': 'Волосся'}),
        EducationCard(id: 'nose', imageUrl: 'assets/images/body/nose.png', transcriptions: {'en-US': 'Nose', 'pl-PL': 'Nos', 'de-DE': 'Nase', 'fr-FR': 'Nez', 'uk-UA': 'Ніс'}),
        EducationCard(id: 'ears', imageUrl: 'assets/images/body/ears.png', transcriptions: {'en-US': 'Ears', 'pl-PL': 'Uszy', 'de-DE': 'Ohren', 'fr-FR': 'Oreilles', 'uk-UA': 'Вуха'}),
        EducationCard(id: 'stomach', imageUrl: 'assets/images/body/stomach.png', transcriptions: {'en-US': 'Stomach', 'pl-PL': 'Brzuch', 'de-DE': 'Bauch', 'fr-FR': 'Ventre', 'uk-UA': 'Живіт'}),
        EducationCard(id: 'feet', imageUrl: 'assets/images/body/feet.png', transcriptions: {'en-US': 'Feet', 'pl-PL': 'Stopy', 'de-DE': 'Füße', 'fr-FR': 'Pieds', 'uk-UA': 'Ступні'}),
        EducationCard(id: 'palms', imageUrl: 'assets/images/body/palms.png', transcriptions: {'en-US': 'Palms', 'pl-PL': 'Dłonie', 'de-DE': 'Handflächen', 'fr-FR': 'Paumes', 'uk-UA': 'Долоньки'}),
        EducationCard(id: 'eyes', imageUrl: 'assets/images/body/eyes.png', transcriptions: {'en-US': 'Eyes', 'pl-PL': 'Oczy', 'de-DE': 'Augen', 'fr-FR': 'Yeux', 'uk-UA': 'Очі'}),
        EducationCard(id: 'eyebrows', imageUrl: 'assets/images/body/eyebrows.png', transcriptions: {'en-US': 'Eyebrows', 'pl-PL': 'Brwi', 'de-DE': 'Augenbrauen', 'fr-FR': 'Sourcils', 'uk-UA': 'Брови'}),
        EducationCard(id: 'cheeks', imageUrl: 'assets/images/body/cheeks.png', transcriptions: {'en-US': 'Cheeks', 'pl-PL': 'Policzki', 'de-DE': 'Wangen', 'fr-FR': 'Joues', 'uk-UA': 'Щоки'}),
        EducationCard(id: 'teeth', imageUrl: 'assets/images/body/teeth.png', transcriptions: {'en-US': 'Teeth', 'pl-PL': 'Zęby', 'de-DE': 'Zähne', 'fr-FR': 'Dents', 'uk-UA': 'Зуби'}),
        EducationCard(id: 'mouth', imageUrl: 'assets/images/body/mouth.png', transcriptions: {'en-US': 'Mouth', 'pl-PL': 'Usta', 'de-DE': 'Mund', 'fr-FR': 'Bouche', 'uk-UA': 'Рот'}),
        EducationCard(id: 'chin', imageUrl: 'assets/images/body/chin.png', transcriptions: {'en-US': 'Chin', 'pl-PL': 'Broda', 'de-DE': 'Kinn', 'fr-FR': 'Menton', 'uk-UA': 'Підборіддя'}),
      ],
    ),
    CardCategory(
      type: CardCategoryType.clothes,
      name: isUkrainian ? 'Одяг' : (isFrench ? 'Vêtements' : (isGerman ? 'Kleidung' : (isPolish ? 'Ubrania' : 'Clothes'))),
      icon: '👕',
      cards: [
        EducationCard(id: 'shoes', imageUrl: 'assets/images/clothes/shoes.png', transcriptions: {'en-US': 'Shoes', 'pl-PL': 'Buty', 'de-DE': 'Schuhe', 'fr-FR': 'Chaussures', 'uk-UA': 'Ботинки'}),
        EducationCard(id: 'pants', imageUrl: 'assets/images/clothes/pants.png', transcriptions: {'en-US': 'Pants', 'pl-PL': 'Spodnie', 'de-DE': 'Hose', 'fr-FR': 'Pantalon', 'uk-UA': 'Штани'}),
        EducationCard(id: 'sweater', imageUrl: 'assets/images/clothes/sweater.png', transcriptions: {'en-US': 'Sweater', 'pl-PL': 'Sweter', 'de-DE': 'Pullover', 'fr-FR': 'Pull-over', 'uk-UA': 'Светр'}),
        EducationCard(id: 'tshirt', imageUrl: 'assets/images/clothes/tshirt.png', transcriptions: {'en-US': 'T-shirt', 'pl-PL': 'Koszulka', 'de-DE': 'T-Shirt', 'fr-FR': 'T-shirt', 'uk-UA': 'Футболка'}),
        EducationCard(id: 'jacket', imageUrl: 'assets/images/clothes/jacket.png', transcriptions: {'en-US': 'Jacket', 'pl-PL': 'Kurtka', 'de-DE': 'Jacke', 'fr-FR': 'Veste', 'uk-UA': 'Куртка'}),
        EducationCard(id: 'hat', imageUrl: 'assets/images/clothes/hat.png', transcriptions: {'en-US': 'Hat', 'pl-PL': 'Czapka', 'de-DE': 'Mütze', 'fr-FR': 'Bonnet', 'uk-UA': 'Шапка'}),
        EducationCard(id: 'mittens', imageUrl: 'assets/images/clothes/mittens.png', transcriptions: {'en-US': 'Mittens', 'pl-PL': 'Rękawiczki', 'de-DE': 'Handschuhe', 'fr-FR': 'Moufles', 'uk-UA': 'Рукавички'}),
        EducationCard(id: 'winter_boots', imageUrl: 'assets/images/clothes/winter_boots.png', transcriptions: {'en-US': 'Boots', 'pl-PL': 'Kozaki', 'de-DE': 'Stiefel', 'fr-FR': 'Bottes', 'uk-UA': 'Сапоги'}),
        EducationCard(id: 'dress', imageUrl: 'assets/images/clothes/dress.png', transcriptions: {'en-US': 'Dress', 'pl-PL': 'Sukienka', 'de-DE': 'Kleid', 'fr-FR': 'Robe', 'uk-UA': 'Плаття'}),
        EducationCard(id: 'cap', imageUrl: 'assets/images/clothes/cap.png', transcriptions: {'en-US': 'Cap', 'pl-PL': 'Czapka z daszkiem', 'de-DE': 'Kappe', 'fr-FR': 'Casquette', 'uk-UA': 'Кепка'}),
        EducationCard(id: 'slippers', imageUrl: 'assets/images/clothes/slippers.png', transcriptions: {'en-US': 'Slippers', 'pl-PL': 'Kapcie', 'de-DE': 'Hausschuhe', 'fr-FR': 'Pantoufles', 'uk-UA': 'Тапочки'}),
        EducationCard(id: 'shirt', imageUrl: 'assets/images/clothes/shirt.png', transcriptions: {'en-US': 'Shirt', 'pl-PL': 'Koszula', 'de-DE': 'Hemd', 'fr-FR': 'Chemise', 'uk-UA': 'Рубашка'}),
      ],
    ),
    CardCategory(
      type: CardCategoryType.weather,
      name: isUkrainian ? 'Погода' : (isFrench ? 'Météo' : (isGerman ? 'Wetter' : (isPolish ? 'Pogoda' : 'Weather'))),
      icon: '☁️',
      cards: [
        EducationCard(id: 'rain', imageUrl: 'assets/images/weather/rain.png', transcriptions: {'en-US': 'Rain', 'pl-PL': 'Deszcz', 'de-DE': 'Regen', 'fr-FR': 'Pluie', 'uk-UA': 'Дождь'}),
        EducationCard(id: 'snow', imageUrl: 'assets/images/weather/snow.png', transcriptions: {'en-US': 'Snow', 'pl-PL': 'Śnieg', 'de-DE': 'Schnee', 'fr-FR': 'Neige', 'uk-UA': 'Сніг'}),
        EducationCard(id: 'thunderstorm', imageUrl: 'assets/images/weather/thunderstorm.png', transcriptions: {'en-US': 'Thunderstorm', 'pl-PL': 'Burza', 'de-DE': 'Gewitter', 'fr-FR': 'Orage', 'uk-UA': 'Гроза'}),
        EducationCard(id: 'hurricane', imageUrl: 'assets/images/weather/hurricane.png', transcriptions: {'en-US': 'Hurricane', 'pl-PL': 'Huragan', 'de-DE': 'Hurrikan', 'fr-FR': 'Ouragan', 'uk-UA': 'Ураган'}),
        EducationCard(id: 'cloudy', imageUrl: 'assets/images/weather/cloudy.png', transcriptions: {'en-US': 'Cloudy', 'pl-PL': 'Pochmurno', 'de-DE': 'Bewölkt', 'fr-FR': 'Nuageux', 'uk-UA': 'Хмарно'}),
        EducationCard(id: 'sunny', imageUrl: 'assets/images/weather/sunny.png', transcriptions: {'en-US': 'Sunny', 'pl-PL': 'Słonecznie', 'de-DE': 'Sonnig', 'fr-FR': 'Ensoleillé', 'uk-UA': 'Сонячно'}),
        EducationCard(id: 'wind', imageUrl: 'assets/images/weather/wind.png', transcriptions: {'en-US': 'Wind', 'pl-PL': 'Wiatr', 'de-DE': 'Wind', 'fr-FR': 'Vent', 'uk-UA': 'Вітер'}),
        EducationCard(id: 'rainbow', imageUrl: 'assets/images/weather/rainbow.png', transcriptions: {'en-US': 'Rainbow', 'pl-PL': 'Tęcza', 'de-DE': 'Regenbogen', 'fr-FR': 'Arc-en-ciel', 'uk-UA': 'Веселка'}),
        EducationCard(id: 'northern_lights', imageUrl: 'assets/images/weather/northern_lights.png', transcriptions: {'en-US': 'Northern Lights', 'pl-PL': 'Zorza polarna', 'de-DE': 'Polarlichter', 'fr-FR': 'Aurore boréale', 'uk-UA': 'Північне сяйво'}),
        EducationCard(id: 'partly_cloudy', imageUrl: 'assets/images/weather/partly_cloudy.png', transcriptions: {'en-US': 'Partly Cloudy', 'pl-PL': 'Częściowe zachmurzenie', 'de-DE': 'Teilweise bewölkt', 'fr-FR': 'Partiellement nuageux', 'uk-UA': 'Мінлива хмарність'}),
        EducationCard(id: 'hail', imageUrl: 'assets/images/weather/hail.png', transcriptions: {'en-US': 'Hail', 'pl-PL': 'Grad', 'de-DE': 'Hagel', 'fr-FR': 'Grêle', 'uk-UA': 'Град'}),
        EducationCard(id: 'frost', imageUrl: 'assets/images/weather/frost.png', transcriptions: {'en-US': 'Frost', 'pl-PL': 'Mróz', 'de-DE': 'Frost', 'fr-FR': 'Gel', 'uk-UA': 'Мороз'}),
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
