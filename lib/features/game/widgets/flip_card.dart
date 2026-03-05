import 'dart:math';
import 'package:flutter/material.dart';

class FlipCardController {
  _FlipCardState? _state;
  
  void flip() => _state?._onTap();
  void reset() => _state?._reset();
}

class FlipCard extends StatefulWidget {
  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    this.onFlip,
    this.onDoubleTap,
    this.controller,
  });
  final Widget front;
  final Widget back;
  final VoidCallback? onFlip;
  final VoidCallback? onDoubleTap;
  final FlipCardController? controller;

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _wobbleController;
  late AnimationController _scaleController;
  late AnimationController _glowController;
  
  late Animation<double> _animation;
  late Animation<double> _wobbleAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    
    // Main flip animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );

    // Wobble animation (tilting)
    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _wobbleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.06).chain(CurveTween(curve: Curves.easeOut)), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.06, end: -0.06).chain(CurveTween(curve: Curves.easeInOut)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: -0.06, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 25),
    ]).animate(_wobbleController);

    // Scale animation (bounce)
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.1).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 50),
    ]).animate(_scaleController);

    // Glow animation
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 2.0, end: 15.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?._state = null;
      widget.controller?._state = this;
    }
  }

  @override
  void dispose() {
    if (widget.controller?._state == this) {
      widget.controller?._state = null;
    }
    _controller.dispose();
    _wobbleController.dispose();
    _scaleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _onTap() async {
    if (_controller.isAnimating || _wobbleController.isAnimating) return;
    
    // Start wobble and scale first
    _wobbleController.forward(from: 0);
    _scaleController.forward(from: 0);

    // Delay flip slightly
    await Future.delayed(const Duration(milliseconds: 150));
    
    if (_isFront) {
      _controller.forward();
      widget.onFlip?.call();
    } else {
      _controller.reverse();
    }
    setState(() => _isFront = !_isFront);
  }

  void _reset() {
    if (!mounted) return;
    if (!_isFront) {
      _controller.reverse();
      setState(() => _isFront = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      onDoubleTap: widget.onDoubleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_animation, _wobbleAnimation, _scaleAnimation, _glowAnimation]),
        builder: (context, child) {
          final angle = _animation.value * pi;
          final wobble = _wobbleAnimation.value;
          final scale = _scaleAnimation.value;
          final glowRadius = _glowAnimation.value;
          final isBackVisible = angle >= pi / 2;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // Perspective
              ..scale(scale)
              ..rotateY(angle)
              ..rotateZ(wobble),
            alignment: Alignment.center,
            child: isBackVisible
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: widget.back,
                  )
                : Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.3),
                          blurRadius: glowRadius,
                          spreadRadius: glowRadius / 2,
                        ),
                      ],
                    ),
                    child: widget.front,
                  ),
          );
        },
      ),
    );
  }
}
