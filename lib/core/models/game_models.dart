enum CardCategoryType {
  colors,
  numbers,
  letters,
  cars,
  farm,
  fruits,
  wildAnimals,
  body,
  clothes,
  vegetables,
  weather,
}

class EducationCard {
  EducationCard({
    required this.id,
    this.imageUrl,
    this.hexColor,
    required this.transcriptions,
  });
  final String id;
  final String? imageUrl;
  final String? hexColor;
  final Map<String, String> transcriptions;
}

class CardCategory {
  CardCategory({
    required this.type,
    required this.name,
    required this.icon,
    required this.cards,
  });
  final CardCategoryType type;
  final String name;
  final String icon;
  final List<EducationCard> cards;
}
