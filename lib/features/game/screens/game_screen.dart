import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:baby_education/core/models/game_models.dart';
import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/game_provider.dart';
import '../widgets/flip_card.dart';
import '../widgets/jumping_ball_animation.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  final List<FlipCardController> _cardControllers = List.generate(
    200,
    (_) => FlipCardController(),
  );
  late PageController _pageController;
  late ScrollController _categoryScrollController;
  List<EducationCard> _shuffledCards = [];
  CardCategoryType? _lastCategory;
  bool _isWandActive = false;
  final List<GlobalKey> _categoryKeys = [];
  int? _zoomedCardIndex;
  final Set<String> _tappedCardIds = {};

  // ----- Quiz State -----
  String? _quizTargetCardId;
  late final List<ConfettiController> _confettiControllers = List.generate(
    200,
    (_) => ConfettiController(duration: const Duration(seconds: 2)),
  );
  final AudioPlayer _quizAudioPlayer = AudioPlayer();
  // ----------------------

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
    for (final c in _confettiControllers) {
      c.dispose();
    }
    _quizAudioPlayer.dispose();
    super.dispose();
  }

  void _resetAllCards() {
    _tappedCardIds.clear();
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

  void _startQuiz() async {
    if (_shuffledCards.isEmpty || !mounted) return;

    // 1. Determine active cards on current page
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final int cardsPerPage = (isLandscape ? 3 : 2) * (isLandscape ? 1 : 2);

    int pageIndex = 0;
    if (_pageController.hasClients) {
      pageIndex = _pageController.page?.round() ?? 0;
    }

    final int startIndex = pageIndex * cardsPerPage;
    final int endIndex = math.min(
      startIndex + cardsPerPage,
      _shuffledCards.length,
    );
    final activeCards = _shuffledCards.sublist(startIndex, endIndex);

    if (activeCards.isEmpty) return;

    // Reset currently visible cards to front (image) side
    for (int i = startIndex; i < endIndex; i++) {
      _cardControllers[i].reset();
    }

    // 2. Pick a random target card
    final targetCard = activeCards[math.Random().nextInt(activeCards.length)];
    setState(() {
      _quizTargetCardId = targetCard.id;
    });

    // 3. Play question audio sequence
    final currentLang = ref.read(languageProvider);
    final langPrefix = currentLang.split(
      '-',
    )[0]; // simple code: en, pl, de, fr, uk

    final questionFiles = <String, String>{
      'en': 'find.wav',
      'pl': 'znajdź.wav',
      'de': 'finde.wav',
      'fr': 'trouve.wav',
      'uk': 'знайди.wav',
    };

    final questionFilename = questionFiles[langPrefix] ?? 'find.wav';

    try {
      // Play "Find"
      await _quizAudioPlayer.play(
        AssetSource('audio/$langPrefix/$questionFilename'),
      );

      // Wait for completion, then play the target word
      _quizAudioPlayer.onPlayerComplete.first.then((_) {
        if (!mounted || _quizTargetCardId != targetCard.id) return;
        final word = targetCard.transcriptions[currentLang] ?? '';
        ref.read(audioServiceProvider).speak(word, currentLang);
      });
    } catch (e) {
      debugPrint("Error playing quiz audio: $e");
    }
  }

  void _onCardTapped(
    int globalIndex,
    EducationCard card,
    String word,
    String currentLang,
  ) {
    // Record card tap for completion tracking
    final wasAlreadyTapped = _tappedCardIds.contains(card.id);
    _tappedCardIds.add(card.id);

    // Standard Flip logic
    _cardControllers[globalIndex].flip();

    // Check for category completion
    if (!wasAlreadyTapped && _tappedCardIds.length == _shuffledCards.length) {
      _triggerCategoryCompletion();
    }

    // If not in quiz mode, just read the word
    if (_quizTargetCardId == null) {
      ref.read(audioServiceProvider).speak(word, currentLang);
      return;
    }

    // Quiz mode logic
    if (card.id == _quizTargetCardId) {
      // Correct!
      _quizAudioPlayer.play(AssetSource('audio/correct.mp3'));
      _confettiControllers[globalIndex].play();
      setState(() {
        // Reset target so they can ask again
        _quizTargetCardId = null;
      });
    } else {
      // Wrong!
      _quizAudioPlayer.play(AssetSource('audio/wrong.mp3'));
    }
  }

  void _triggerCategoryCompletion() {
    // 1. Play "ping" sound
    ref
        .read(audioServiceProvider)
        .playEffect('magic'); // TODO: replace with ping

    // 2. Clear tapped state so they can do it again
    _tappedCardIds.clear();

    // 3. Show Jumping Ball Animation
    _showJumpingBallAnimation();
  }

  void _showJumpingBallAnimation() {
    final currentCat = ref.read(currentCategoryProvider);

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: SafeArea(
            child: JumpingBallAnimation(
              icon: '⭐',
              onComplete: () {
                overlayEntry.remove();
                if (!mounted) return;
                // Increment counter
                ref.read(categoryCompletionProvider.notifier).update((state) {
                  final current = state[currentCat] ?? 0;
                  return {...state, currentCat: current + 1};
                });
              },
            ),
          ),
        );
      },
    );

    overlay.insert(overlayEntry);
  }

  void _scrollToCategory(int index) {
    if (index >= 0 && index < _categoryKeys.length) {
      final key = _categoryKeys[index];
      if (key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          alignment: 0.5,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(currentCardsProvider);
    final currentLang = ref.watch(languageProvider);
    final categories = ref.watch(categoriesProvider);
    final currentCat = ref.watch(currentCategoryProvider);
    final isMuted = ref.watch(isMutedProvider);
    final completionCounts = ref.watch(categoryCompletionProvider);

    // Sync audio service state
    ref.read(audioServiceProvider).isMuted = isMuted;

    final isTablet = MediaQuery.of(context).size.shortestSide > 600;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

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
      cardPages.add(
        _shuffledCards.sublist(
          i,
          i + cardsPerPage > _shuffledCards.length
              ? _shuffledCards.length
              : i + cardsPerPage,
        ),
      );
    }

    // Maintain category keys
    if (_categoryKeys.length != categories.length) {
      _categoryKeys.clear();
      _categoryKeys.addAll(
        List.generate(categories.length, (_) => GlobalKey()),
      );
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
          leading: Transform.scale(scale: 1.5, child: _LanguageSelector()),
          actions: [
            if (completionCounts.isNotEmpty)
              Builder(
                builder: (context) {
                  final totalStars = completionCounts.values.fold<int>(0, (sum, count) => sum + count);
                  if (totalStars <= 0) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(top: 18, bottom: 18, right: 32),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blueAccent, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '⭐ $totalStars',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                          height: 1.0,
                        ),
                      ),
                    ),
                  );
                },
              ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0, top: 8.0),
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
              // Category Selector with horizontal fade
              Container(
                height: 70,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white,
                        Colors.transparent,
                        Colors.transparent,
                        Colors.white,
                      ],
                      stops: [0.0, 0.05, 0.95, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstOut,
                  child: SingleChildScrollView(
                    controller: _categoryScrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: List.generate(categories.length, (index) {
                        final cat = categories[index];
                        final isSelected = cat.type == currentCat;
                        return Padding(
                          key: _categoryKeys[index],
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              '${cat.icon} ${cat.name}',
                              style: GoogleFonts.rubikBubbles(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.blueAccent,
                                fontWeight: FontWeight.normal,
                                fontSize: 18,
                                letterSpacing: 0.5,
                                shadows: isSelected
                                    ? []
                                    : [
                                        const Shadow(
                                          color: Colors.white,
                                          offset: Offset(-1, -1),
                                          blurRadius: 2,
                                        ),
                                      ],
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() => _zoomedCardIndex = null);
                              _resetAllCards();
                              _scrollToCategory(index);
                              if (_pageController.hasClients)
                                _pageController.jumpToPage(0);
                              ref.read(currentCategoryProvider.notifier).state =
                                  cat.type;
                            },
                            backgroundColor: Colors.white,
                            selectedColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            showCheckmark: false,
                          ),
                        );
                      }),
                    ),
                  ),
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
                    final totalHorizontalSpacing =
                        spacing * (activeCrossCount + 1);
                    final totalVerticalSpacing = spacing * (activeRowCount + 1);

                    // Calculate item dimensions to fill the space exactly
                    final itemWidth =
                        (constraints.maxWidth - totalHorizontalSpacing) /
                        activeCrossCount;
                    final itemHeight =
                        (constraints.maxHeight - totalVerticalSpacing) /
                        activeRowCount;
                    final calculatedAspectRatio = itemWidth / itemHeight;

                    return PageView.builder(
                      controller: _pageController,
                      itemCount: cardPages.length,
                      itemBuilder: (context, pageIndex) {
                        final pageCards = cardPages[pageIndex];
                        final int firstGlobalIndex = (pageIndex * cardsPerPage)
                            .toInt();
                        final int lastGlobalIndex =
                            firstGlobalIndex + pageCards.length - 1;

                        // Check if the current page contains the zoomed card
                        final bool isCardZoomedOnThisPage =
                            _zoomedCardIndex != null &&
                            _zoomedCardIndex! >= firstGlobalIndex &&
                            _zoomedCardIndex! <= lastGlobalIndex;

                        if (isCardZoomedOnThisPage) {
                          final zoomedIndexInPage =
                              _zoomedCardIndex! - firstGlobalIndex;
                          final card = pageCards[zoomedIndexInPage];
                          final word =
                              card.transcriptions[currentLang] ?? 'Unknown';
                          final cardColor = card.hexColor != null
                              ? Color(int.parse(card.hexColor!))
                              : Colors.white;

                          return Padding(
                            padding: const EdgeInsets.all(spacing),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Positioned.fill(
                                  child: Hero(
                                    tag: 'card_${card.id}_$_zoomedCardIndex',
                                    child: FlipCard(
                                      key: ValueKey(
                                        'flip_card_$_zoomedCardIndex',
                                      ),
                                      controller:
                                          _cardControllers[_zoomedCardIndex!],
                                      onFlip: () {
                                        _onCardTapped(
                                          _zoomedCardIndex!,
                                          card,
                                          word,
                                          currentLang,
                                        );
                                      },
                                      onDoubleTap: () {
                                        setState(() => _zoomedCardIndex = null);
                                      },
                                      front: _CardBody(
                                        color: cardColor,
                                        child: card.imageUrl != null
                                            ? Padding(
                                                padding: const EdgeInsets.all(
                                                  40,
                                                ),
                                                child:
                                                    card.imageUrl!.startsWith(
                                                      'http',
                                                    )
                                                    ? Image.network(
                                                        card.imageUrl!,
                                                        fit: BoxFit.contain,
                                                        errorBuilder:
                                                            (
                                                              context,
                                                              error,
                                                              stackTrace,
                                                            ) =>
                                                                const _ImageFallback(),
                                                      )
                                                    : Image.asset(
                                                        card.imageUrl!,
                                                        fit: BoxFit.contain,
                                                        errorBuilder:
                                                            (
                                                              context,
                                                              error,
                                                              stackTrace,
                                                            ) =>
                                                                const _ImageFallback(),
                                                      ),
                                              )
                                            : (currentCat ==
                                                      CardCategoryType
                                                          .letters ||
                                                  currentCat ==
                                                      CardCategoryType.numbers)
                                            ? Center(
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          16.0,
                                                        ),
                                                    child: Text(
                                                      currentCat ==
                                                              CardCategoryType
                                                                  .letters
                                                          ? word.toUpperCase()
                                                          : card.id
                                                                .replaceFirst(
                                                                  'num_',
                                                                  '',
                                                                ),
                                                      style: const TextStyle(
                                                        fontSize: 400,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Colors.blueAccent,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : const SizedBox.expand(),
                                      ),
                                      back: _CardBody(
                                        color: Colors.blueAccent.withValues(
                                          alpha: 0.1,
                                        ),
                                        child: Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                word.toUpperCase(),
                                                textAlign: TextAlign.center,
                                                style:
                                                    currentCat ==
                                                        CardCategoryType.letters
                                                    ? const TextStyle(
                                                        fontFamily:
                                                            'GreatVibes',
                                                        fontSize: 240,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Colors.blueAccent,
                                                      )
                                                    : const TextStyle(
                                                        fontSize: 160,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Colors.blueAccent,
                                                      ),
                                              ), // Text
                                            ), // FittedBox
                                          ), // Padding
                                        ), // Center
                                      ), // _CardBody
                                    ), // FlipCard
                                  ), // Hero
                                ), // Positioned.fill
                                ConfettiWidget(
                                  confettiController:
                                      _confettiControllers[_zoomedCardIndex!],
                                  blastDirection: -math.pi / 2, // Straight up
                                  maxBlastForce: 20,
                                  minBlastForce: 10,
                                  emissionFrequency: 0.1,
                                  numberOfParticles: 30,
                                  gravity: 0.3,
                                ),
                              ],
                            ),
                          );
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.all(spacing),
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: activeCrossCount,
                                crossAxisSpacing: spacing,
                                mainAxisSpacing: spacing,
                                childAspectRatio: calculatedAspectRatio,
                              ),
                          itemCount: pageCards.length,
                          itemBuilder: (context, index) {
                            final globalIndex =
                                ((pageIndex * cardsPerPage) + index).toInt();
                            final card = pageCards[index];
                            final word =
                                card.transcriptions[currentLang] ?? 'Unkown';
                            final cardColor = card.hexColor != null
                                ? Color(int.parse(card.hexColor!))
                                : Colors.white;

                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                Positioned.fill(
                                  child: Hero(
                                    tag: 'card_${card.id}_$globalIndex',
                                    child: FlipCard(
                                      key: ValueKey('flip_card_$globalIndex'),
                                      controller: _cardControllers[globalIndex],
                                      onFlip: () {
                                        _onCardTapped(
                                          globalIndex,
                                          card,
                                          word,
                                          currentLang,
                                        );
                                      },
                                      onDoubleTap: () {
                                        setState(
                                          () => _zoomedCardIndex = globalIndex,
                                        );
                                      },
                                      front: _CardBody(
                                        color: cardColor,
                                        child: card.imageUrl != null
                                            ? Padding(
                                                padding: const EdgeInsets.all(
                                                  20,
                                                ),
                                                child:
                                                    card.imageUrl!.startsWith(
                                                      'http',
                                                    )
                                                    ? Image.network(
                                                        card.imageUrl!,
                                                        fit: BoxFit.contain,
                                                        errorBuilder:
                                                            (
                                                              context,
                                                              error,
                                                              stackTrace,
                                                            ) =>
                                                                const _ImageFallback(),
                                                      )
                                                    : Image.asset(
                                                        card.imageUrl!,
                                                        fit: BoxFit.contain,
                                                        errorBuilder:
                                                            (
                                                              context,
                                                              error,
                                                              stackTrace,
                                                            ) =>
                                                                const _ImageFallback(),
                                                      ),
                                              )
                                            : (currentCat ==
                                                      CardCategoryType
                                                          .letters ||
                                                  currentCat ==
                                                      CardCategoryType.numbers)
                                            ? Center(
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          8.0,
                                                        ),
                                                    child: Text(
                                                      currentCat ==
                                                              CardCategoryType
                                                                  .letters
                                                          ? word.toUpperCase()
                                                          : card.id
                                                                .replaceFirst(
                                                                  'num_',
                                                                  '',
                                                                ),
                                                      style: const TextStyle(
                                                        fontSize: 240,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Colors.blueAccent,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : const SizedBox.expand(),
                                      ),
                                      back: _CardBody(
                                        color: Colors.blueAccent.withValues(
                                          alpha: 0.1,
                                        ),
                                        child: Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                word.toUpperCase(),
                                                textAlign: TextAlign.center,
                                                style:
                                                    currentCat ==
                                                        CardCategoryType.letters
                                                    ? const TextStyle(
                                                        fontFamily:
                                                            'GreatVibes',
                                                        fontSize: 160,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Colors.blueAccent,
                                                      )
                                                    : const TextStyle(
                                                        fontSize: 100,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Colors.blueAccent,
                                                      ),
                                              ), // Text
                                            ), // FittedBox
                                          ), // Padding
                                        ), // Center
                                      ), // _CardBody
                                    ), // FlipCard
                                  ), // Hero
                                ), // Positioned.fill
                                ConfettiWidget(
                                  confettiController:
                                      _confettiControllers[globalIndex],
                                  blastDirection: -math.pi / 2, // Straight up
                                  maxBlastForce: 20,
                                  minBlastForce: 10,
                                  emissionFrequency: 0.1,
                                  numberOfParticles: 30,
                                  gravity: 0.3,
                                ),
                              ],
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
                  padding: const EdgeInsets.only(
                    bottom: 20,
                    left: 20,
                    right: 20,
                  ),
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
                                color: isCurrent
                                    ? Colors.blueAccent
                                    : Colors.grey.shade300,
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
                  : (currentLang == 'de-DE'
                        ? 'Alles umdrehen'
                        : (currentLang == 'fr-FR'
                              ? 'Tout retourner'
                              : (currentLang == 'uk-UA'
                                    ? 'Перевернути все'
                                    : 'Odwróć wszystkie'))),
              color: Colors.blueAccent, // Matched color
              onPressed: _resetAllCards,
            ),
            // The new Quiz Button
            GestureDetector(
              onTap: _startQuiz,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withValues(alpha: 0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.videogame_asset_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            _BottomBarButton(
              icon: Icons.shuffle_rounded,
              label: currentLang == 'en-US'
                  ? 'Shuffle'
                  : (currentLang == 'de-DE'
                        ? 'Mischen'
                        : (currentLang == 'fr-FR'
                              ? 'Mélanger'
                              : (currentLang == 'uk-UA'
                                    ? 'Перемішати'
                                    : 'Pomieszaj'))),
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
            Icon(
              icon,
              color: color,
              size: 40,
            ), // Increased icon size since label is gone
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
        child: Text(flagFor(currentLang), style: const TextStyle(fontSize: 24)),
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
                Text(
                  'English',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
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
                Text(
                  'Polski',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
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
                Text(
                  'Deutsch',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
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
                Text(
                  'Français',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
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
                Text(
                  'Українська',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
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

class _MagicWandEffectState extends State<_MagicWandEffect>
    with SingleTickerProviderStateMixin {
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
      _particles.add(math.Point(_random.nextDouble(), _random.nextDouble()));
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
      final y =
          p.y * size.height - (progress * 200); // Faster rising for bubbles

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
      canvas.drawCircle(
        Offset(x - bubbleSize * 0.3, y - bubbleSize * 0.3),
        bubbleSize * 0.2,
        highlightPaint,
      );
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
