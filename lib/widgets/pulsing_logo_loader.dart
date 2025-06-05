import 'package:flutter/material.dart';

class PulsingLogoLoader extends StatefulWidget {
  final String imagePath;
  final double size;
  final Color? color; // Permite personalizar a cor do logo, se necessário

  const PulsingLogoLoader({
    super.key,
    required this.imagePath,
    this.size =
        50.0, // Tamanho padrão um pouco maior para telas de carregamento
    this.color,
  });

  @override
  State<PulsingLogoLoader> createState() => _PulsingLogoLoaderState();
}

class _PulsingLogoLoaderState extends State<PulsingLogoLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800), // Duração da pulsação
      vsync: this,
    )..repeat(reverse: true); // Repete a animação (pulsa)

    _animation = Tween<double>(
      begin: 0.85,
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
      child: ScaleTransition(
        // Adiciona um leve efeito de escala também
        scale: _animation,
        child: Image.asset(
          widget.imagePath,
          height: widget.size,
          width: widget.size,
          fit: BoxFit.contain,
          color: widget.color, // Aplica a cor se fornecida
          // Fallback caso a imagem não carregue
          errorBuilder:
              (context, error, stackTrace) => Icon(
                Icons.sync_problem, // Um ícone de erro diferente
                color: widget.color ?? Theme.of(context).primaryColor,
                size: widget.size,
              ),
        ),
      ),
    );
  }
}
