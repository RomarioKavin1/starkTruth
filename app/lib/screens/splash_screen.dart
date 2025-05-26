import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeStark;
  late Animation<double> _fadeFake;
  late Animation<double> _strikeFake;
  late Animation<double> _fadeOutFake;
  late Animation<double> _fadeTruth;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    _fadeStark = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
      ),
    );

    _fadeFake = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.3, curve: Curves.easeIn),
      ),
    );

    _strikeFake = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.4, curve: Curves.easeInOut),
      ),
    );

    _fadeOutFake = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.5, curve: Curves.easeIn),
      ),
    );

    _fadeTruth = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.6, curve: Curves.easeIn),
      ),
    );

    _controller.forward().then((_) {
      Future.delayed(const Duration(seconds: 0), () {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildFakeWithStrike() {
    const textStyle = TextStyle(
      fontSize: 48,
      fontWeight: FontWeight.w900,
      letterSpacing: -1,
      color: Colors.red,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final text = TextPainter(
          text: const TextSpan(text: 'Fake', style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout();

        final lineWidth = text.width;

        return Opacity(
          opacity: _fadeOutFake.value,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: _fadeFake.value,
                child: Text('Fake', style: textStyle),
              ),
              Positioned(
                top: text.height / 2,
                left: 0,
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: _strikeFake.value,
                    child: Container(
                      width: lineWidth,
                      height: 2,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // STARK
            FadeTransition(
              opacity: _fadeStark,
              child: const Text(
                'Stark',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  color: Colors.black,
                ),
              ),
            ),

            // FAKE <-> TRUTH
            Stack(
              alignment: Alignment.center,
              children: [
                _buildFakeWithStrike(),
                FadeTransition(
                  opacity: _fadeTruth,
                  child: const Text(
                    'Truth',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      color: Color(0xFF004AAD),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
