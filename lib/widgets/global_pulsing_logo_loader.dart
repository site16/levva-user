import 'package:flutter/material.dart';

class GlobalPulsingLogoLoader extends StatefulWidget {
  final String imagePath;
  final double size;
  final Color logoColor;

  const GlobalPulsingLogoLoader({
    super.key,
    required this.imagePath,
    this.size = 0,
    this.logoColor = Colors.white,
  });

  @override
  State<GlobalPulsingLogoLoader> createState() =>
      _GlobalPulsingLogoLoaderState();
}

class _GlobalPulsingLogoLoaderState extends State<GlobalPulsingLogoLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.75,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Image.asset(
        widget.imagePath,
        height: widget.size,
        width: widget.size,
        fit: BoxFit.contain,
        color: widget.logoColor,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.sync, color: widget.logoColor, size: widget.size);
        },
      ),
    );
  }
}
