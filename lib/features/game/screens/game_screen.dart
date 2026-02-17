import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:baby_education/core/models/game_models.dart';
import 'dart:math' as math;
import '../providers/game_provider.dart';
import '../widgets/flip_card.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  final List<FlipCardController> _cardControllers = List.generate(200, (_) => FlipCardController());
  late PageController _pageController;
  late ScrollController _categoryScrollController;
  List<EducationCard> _shuffledCards = [];
  CardCategoryType? _lastCategory;
  bool _isWandActive = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _categoryScrollController = ScrollController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  void _resetAllCards() {
    if (!_isWandActive) {
      ref.read(audioServiceProvider).playEffect('whoosh');
    }
    for (var controller in _cardControllers) {
      controller.reset();
    }
  }

  void _shuffleCards() {
    setState(() {
      _shuffledCards.shuffle();
      _isWandActive = true;
    });
    
    ref.read(audioServiceProvider).playEffect('magic');
    _resetAllCards();
    
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _isWandActive = false);
    });
  }

  void _scrollToCategory(int index) {
    if (_categoryScrollController.hasClients) {
      const itemWidth = 110.0;
      final viewportWidth = _categoryScrollController.position.viewportDimension;
      
      // Center the item in the list to reveal items on both sides if they exist
      final targetOffset = (index * itemWidth) - (viewportWidth / 2) + (itemWidth / 2);
      
      _categoryScrollController.animateTo(
        targetOffset.clamp(0.0, _categoryScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(currentCardsProvider);
    final currentLang = ref.watch(languageProvider);
    final categories = ref.watch(categoriesProvider);
    final currentCat = ref.watch(currentCategoryProvider);
    final isMuted = ref.watch(isMutedProvider);
    
    // Sync audio service state
    ref.read(audioServiceProvider).isMuted = isMuted;

    final isTablet = MediaQuery.of(context).size.shortestSide > 600;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    
    // Unified logic for all devices:
    // Vertical (Portrait): 4 cards total (2x2)
    // Horizontal (Landscape): 3 cards total (3x1)
    final int crossCount;
    final int rowCount;
    
    if (isLandscape) {
      crossCount = 3;
      rowCount = 1;
    } else {
      crossCount = 2;
      rowCount = 2;
    }
    
    final int cardsPerPage = crossCount * rowCount;
    
    // Sync shuffled cards with provider cards
    if (_lastCategory != currentCat || _shuffledCards.length != cards.length) {
      _shuffledCards = List.from(cards);
      _lastCategory = currentCat;
    }

    final List<List<EducationCard>> cardPages = [];
    for (var i = 0; i < _shuffledCards.length; i += cardsPerPage) {
      cardPages.add(_shuffledCards.sublist(i, i + cardsPerPage > _shuffledCards.length ? _shuffledCards.length : i + cardsPerPage));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE1F5FE),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Colors.white.withValues(alpha: 0.8),
          elevation: 0,
          centerTitle: true,
          toolbarHeight: 80,
          title: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Image.asset(
              'assets/images/branding/logo.png',
              height: 60,
              fit: BoxFit.contain,
            ),
          ),
          leading: Transform.scale(
            scale: 1.5,
            child: _LanguageSelector(),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0, top: 8.0),
              child: _MuteButton(),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          _isWandActive ? _MagicWandEffect() : const SizedBox.shrink(),
          Column(
            children: [
          // Category Selector
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListView.builder(
              controller: _categoryScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = cat.type == currentCat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${cat.icon} ${cat.name}', 
                      style: GoogleFonts.rubikBubbles(
                        color: isSelected ? Colors.white : Colors.blueAccent,
                        fontWeight: FontWeight.normal,
                        fontSize: 18,
                        letterSpacing: 0.5,
                        shadows: isSelected ? [] : [
                          const Shadow(color: Colors.white, offset: Offset(-1, -1), blurRadius: 2),
                        ],
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      _resetAllCards();
                      _scrollToCategory(index);
                      if (_pageController.hasClients) _pageController.jumpToPage(0);
                      ref.read(currentCategoryProvider.notifier).state = cat.type;
                    },
                    backgroundColor: Colors.white,
                    selectedColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    showCheckmark: false,
                  ),
                );
              },
            ),
          ),
          
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Use the counts calculated above at the build level
                final activeCrossCount = crossCount;
                final activeRowCount = rowCount;
                
                // Calculate spacing
                const spacing = 12.0;
                final totalHorizontalSpacing = spacing * (activeCrossCount + 1);
                final totalVerticalSpacing = spacing * (activeRowCount + 1);
                
                // Calculate item dimensions to fill the space exactly
                final itemWidth = (constraints.maxWidth - totalHorizontalSpacing) / activeCrossCount;
                final itemHeight = (constraints.maxHeight - totalVerticalSpacing) / activeRowCount;
                final calculatedAspectRatio = itemWidth / itemHeight;

                return PageView.builder(
                  controller: _pageController,
                  itemCount: cardPages.length,
                  itemBuilder: (context, pageIndex) {
                    final pageCards = cardPages[pageIndex];
                    
                    return GridView.builder(
                      padding: const EdgeInsets.all(spacing),
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: activeCrossCount,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        childAspectRatio: calculatedAspectRatio,
                      ),
                      itemCount: pageCards.length,
                      itemBuilder: (context, index) {
                        final globalIndex = ((pageIndex * cardsPerPage) + index).toInt();
                        final card = pageCards[index];
                        final word = card.transcriptions[currentLang] ?? 'Unkown';
                        final cardColor = card.hexColor != null 
                            ? Color(int.parse(card.hexColor!)) 
                            : Colors.white;

                        return FlipCard(
                          controller: _cardControllers[globalIndex],
                          onFlip: () {
                            ref.read(audioServiceProvider).speak(word, currentLang);
                          },
                          front: _CardBody(
                            color: cardColor,
                            child: card.imageUrl != null 
                              ? Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: card.imageUrl!.startsWith('http')
                                      ? Image.network(
                                          card.imageUrl!, 
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) => const _ImageFallback(),
                                        )
                                      : Image.asset(
                                          card.imageUrl!, 
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) => const _ImageFallback(),
                                        ),
                                )
                              : (currentCat == CardCategoryType.letters || currentCat == CardCategoryType.numbers)
                                ? Center(child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        currentCat == CardCategoryType.letters 
                                          ? word.toUpperCase()
                                          : card.id.replaceFirst('num_', ''), 
                                        style: const TextStyle(fontSize: 120, fontWeight: FontWeight.bold, color: Colors.blueAccent)
                                      ),
                                    ),
                                  ))
                                : const SizedBox.expand(),
                          ),
                          back: _CardBody(
                            color: Colors.blueAccent.withValues(alpha: 0.1),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    word.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: currentCat == CardCategoryType.letters
                                        ? const TextStyle(
                                            fontFamily: 'GreatVibes',
                                            fontSize: 80,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueAccent,
                                          )
                                        : const TextStyle(
                                            fontSize: 40,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueAccent,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          
          if (cardPages.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(cardPages.length, (index) {
                    return AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                        double selected = 0;
                        if (_pageController.hasClients) {
                          selected = (_pageController.page ?? 0);
                        }
                        final isCurrent = index == selected.round();
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isCurrent ? 12 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isCurrent ? Colors.blueAccent : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _BottomBarButton(
              icon: Icons.refresh_rounded,
              label: currentLang == 'en-US' 
                ? 'Flip All' 
                : (currentLang == 'de-DE' ? 'Alles umdrehen' : (currentLang == 'fr-FR' ? 'Tout retourner' : (currentLang == 'uk-UA' ? 'Перевернути все' : 'Odwróć wszystkie'))),
              color: Colors.blueAccent, // Matched color
              onPressed: _resetAllCards,
            ),
            _BottomBarButton(
              icon: Icons.shuffle_rounded,
              label: currentLang == 'en-US' 
                ? 'Shuffle' 
                : (currentLang == 'de-DE' ? 'Mischen' : (currentLang == 'fr-FR' ? 'Mélanger' : (currentLang == 'uk-UA' ? 'Перемішати' : 'Pomieszaj'))),
              color: Colors.blueAccent,
              onPressed: _shuffleCards,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBarButton extends StatelessWidget {
  const _BottomBarButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 40), // Increased icon size since label is gone
          ],
        ),
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({required this.color, required this.child});
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        border: color == Colors.white || color == const Color(0xFFFFFFFF)
          ? Border.all(color: Colors.black.withValues(alpha: 0.1))
          : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LanguageSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(languageProvider);

    String flagFor(String lang) {
      if (lang == 'en-US') return '🇬🇧';
      if (lang == 'pl-PL') return '🇵🇱';
      if (lang == 'de-DE') return '🇩🇪';
      if (lang == 'fr-FR') return '🇫🇷';
      if (lang == 'uk-UA') return '🇺🇦';
      return '🌍';
    }

    return PopupMenuButton<String>(
      initialValue: currentLang,
      onSelected: (val) => ref.read(languageProvider.notifier).state = val,
      child: Center(
        child: Text(
          flagFor(currentLang),
          style: const TextStyle(fontSize: 24),
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'en-US',
          child: SizedBox(
            width: 150,
            child: Row(
              children: [
                Text('🇬🇧', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Text('English', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const PopupMenuItem(
          value: 'pl-PL',
          child: SizedBox(
            width: 150,
            child: Row(
              children: [
                Text('🇵🇱', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Text('Polski', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const PopupMenuItem(
          value: 'de-DE',
          child: SizedBox(
            width: 150,
            child: Row(
              children: [
                Text('🇩🇪', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Text('Deutsch', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const PopupMenuItem(
          value: 'fr-FR',
          child: SizedBox(
            width: 150,
            child: Row(
              children: [
                Text('🇫🇷', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Text('Français', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const PopupMenuItem(
          value: 'uk-UA',
          child: SizedBox(
            width: 150,
            child: Row(
              children: [
                Text('🇺🇦', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Text('Українська', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_not_supported_rounded, size: 64, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            'Coming Soon',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
class _MagicWandEffect extends StatefulWidget {
  @override
  State<_MagicWandEffect> createState() => _MagicWandEffectState();
}

class _MagicWandEffectState extends State<_MagicWandEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<math.Point> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    // Generate random star particles
    for (int i = 0; i < 40; i++) {
      _particles.add(math.Point(
        _random.nextDouble(),
        _random.nextDouble(),
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _MagicPainter(
            progress: _controller.value,
            particles: _particles,
          ),
        );
      },
    );
  }
}

class _MagicPainter extends CustomPainter {
  _MagicPainter({required this.progress, required this.particles});
  final double progress;
  final List<math.Point> particles;

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final x = p.x * size.width;
      final y = p.y * size.height - (progress * 200); // Faster rising for bubbles
      
      final bubbleSize = (math.sin(progress * 8 + p.x * 12) + 1.2) * 8 + 4;
      final opacity = (1 - progress).clamp(0.0, 1.0);

      // Main bubble body
      final paint = Paint()
        ..color = Colors.blueAccent.withValues(alpha: opacity * 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), bubbleSize, paint);

      // Bubble border
      final borderPaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(x, y), bubbleSize, borderPaint);
      
      // Bubble highlight
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.6)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x - bubbleSize * 0.3, y - bubbleSize * 0.3), bubbleSize * 0.2, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _MuteButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMuted = ref.watch(isMutedProvider);
    return IconButton(
      icon: Icon(
        isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
        color: Colors.blueAccent,
        size: 32,
      ),
      onPressed: () => ref.read(isMutedProvider.notifier).state = !isMuted,
    );
  }
}
