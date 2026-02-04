import 'dart:async';
import 'package:flutter/material.dart';
import 'package:baby_education/features/game/screens/game_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<String> _letters = 'ABCDE12345FGHIJ67890KLMNO'.split('');
  final List<Color> _colors = [
    Colors.redAccent, Colors.blueAccent, Colors.greenAccent, Colors.orangeAccent,
    Colors.purpleAccent, Colors.pinkAccent, Colors.amberAccent
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Simulate loading duration
    Timer(const Duration(seconds: 4), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const GameScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1F5FE),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Jumping Letters and Numbers
          ...List.generate(15, (index) {
            final letter = _letters[index % _letters.length];
            final color = _colors[index % _colors.length];
            
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final screenWidth = MediaQuery.of(context).size.width;
                final screenHeight = MediaQuery.of(context).size.height;
                final isSmall = screenWidth < 600;

                // Calculate base position in grid
                final column = index % 3;
                final row = index ~/ 3;
                
                // Adaptive spacing
                final spacingX = isSmall ? 100.0 : 130.0;
                final spacingY = isSmall ? 110.0 : 150.0;

                final baseX = (column - 1) * spacingX;
                final baseY = (row - 2) * spacingY;
                
                // Animation progress
                final progress = (_controller.value + (index * 0.15)) % 1.0;
                final jumpHeight = (isSmall ? 60.0 : 80.0) * (progress < 0.5 ? progress * 2 : (1 - progress) * 2);
                
                return Align(
                  alignment: Alignment.center,
                  child: Transform.translate(
                    offset: Offset(baseX, baseY - jumpHeight),
                    child: Transform.rotate(
                      angle: progress * 0.4 - 0.2,
                      child: Container(
                        width: isSmall ? 50 : 60,
                        height: isSmall ? 50 : 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            letter,
                            style: TextStyle(
                              fontSize: isSmall ? 28 : 34,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
          
          // Center Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                // Using the newly generated icon here would be ideal, but for now placeholder or hero
                child: const Center(
                  child: Icon(Icons.face_retouching_natural, size: 100, color: Colors.blueAccent),
                ), 
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(color: Colors.blueAccent),
            ],
          ),
        ],
      ),
    );
  }
}
