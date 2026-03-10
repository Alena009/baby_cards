import 'package:flutter/material.dart';

class JumpingBallAnimation extends StatefulWidget {
  final String icon;
  final VoidCallback onComplete;

  const JumpingBallAnimation({
    super.key,
    required this.icon,
    required this.onComplete,
  });

  @override
  State<JumpingBallAnimation> createState() => _JumpingBallAnimationState();
}

class _JumpingBallAnimationState extends State<JumpingBallAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _xAnimation;
  late Animation<double> _yAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    // X moves from center slightly left/right then to center-top (now top-right)
    _xAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 0.35), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.35, end: 0.65), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.65, end: 0.8), weight: 50), // End at x=0.8 (right side)
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Y simulates gravity bounce then straight up
    _yAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.5,
          end: 0.2,
        ).chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 12.5,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.2,
          end: 0.5,
        ).chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 12.5,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.5,
          end: 0.3,
        ).chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 12.5,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.3,
          end: 0.5,
        ).chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 12.5,
      ),
      // final jump to top bar (y=0) while getting small
      TweenSequenceItem(
        tween: Tween(
          begin: 0.5,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 50,
      ),
    ]).animate(_controller);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.3), weight: 30),
    ]).animate(_controller);

    _controller.forward().then((_) {
      widget.onComplete();
    });
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
        return Align(
          alignment: FractionalOffset(_xAnimation.value, _yAnimation.value),
          child: Opacity(
            opacity: _controller.value > 0.95
                ? (1.0 - (_controller.value - 0.95) * 20)
                : 1.0,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blueAccent, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withValues(alpha: 0.4),
                      blurRadius: 15,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.icon,
                    style: const TextStyle(fontSize: 50),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
