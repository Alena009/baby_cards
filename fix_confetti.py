import re

with open("lib/features/game/screens/game_screen.dart", "r") as f:
    code = f.read()

# 1. State array
code = code.replace(
    '''  String? _quizTargetCardId;\n  late ConfettiController _confettiController;''',
    '''  String? _quizTargetCardId;\n  final List<ConfettiController> _confettiControllers = List.generate(200, (_) => ConfettiController(duration: const Duration(seconds: 1)));'''
)

# 2. InitState
code = code.replace(
    '''_confettiController = ConfettiController(duration: const Duration(seconds: 2));''',
    ''''''
)

# 3. Dispose
code = code.replace(
    '''_confettiController.dispose();''',
    '''for (var c in _confettiControllers) c.dispose();'''
)

# 4. _onCardTapped
code = code.replace(
    '''_confettiController.play();''',
    '''_confettiControllers[globalIndex].play();'''
)

# 5. Remove overlay
overlay_str = """          // Confetti Overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: math.pi / 2, // Straight down
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
            ),
          ),"""
code = code.replace(overlay_str, "")

# 6. Zoomed Card
code = code.replace(
    '''                            child: Hero(\n                              tag: 'card_${card.id}_$_zoomedCardIndex',''',
    '''                            child: Stack(\n                              alignment: Alignment.center,\n                              children: [\n                                Hero(\n                                  tag: 'card_${card.id}_$_zoomedCardIndex','''
)
code = code.replace(
    '''                                ),\n                              ),\n                            ),\n                          );\n                        }''',
    '''                                ),\n                              ),\n                            ),\n                            ConfettiWidget(\n                              confettiController: _confettiControllers[_zoomedCardIndex!],\n                              blastDirection: -math.pi / 2,\n                              maxBlastForce: 20,\n                              minBlastForce: 10,\n                              emissionFrequency: 0.1,\n                              numberOfParticles: 30,\n                              gravity: 0.3,\n                            ),\n                          ],\n                        ),\n                      );\n                    }'''
)

# 7. GridView Card
code = code.replace(
    '''                            return Hero(\n                              tag: 'card_${card.id}_$globalIndex',''',
    '''                            return Stack(\n                              alignment: Alignment.center,\n                              children: [\n                                Hero(\n                                  tag: 'card_${card.id}_$globalIndex','''
)

code = code.replace(
    '''                                    ),\n                                  ),\n                                ),\n                              ),\n                            );\n                          },\n                        );''',
    '''                                    ),\n                                  ),\n                                ),\n                              ),\n                              ConfettiWidget(\n                                confettiController: _confettiControllers[globalIndex],\n                                blastDirection: -math.pi / 2,\n                                maxBlastForce: 20,\n                                minBlastForce: 10,\n                                emissionFrequency: 0.1,\n                                numberOfParticles: 30,\n                                gravity: 0.3,\n                              ),\n                            ]);\n                          },\n                        );'''
)

with open("lib/features/game/screens/game_screen.dart", "w") as f:
    f.write(code)
print("done")
