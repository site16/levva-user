// lib/widgets/custom_loading_screen.dart
import 'package:flutter/material.dart';
import 'global_pulsing_logo_loader.dart'; // Certifique-se que este caminho está correto

class CustomLoadingScreen extends StatelessWidget {
  final String? logoAssetPath; // Opcional, para flexibilidade
  final Color? backgroundColor; // Opcional
  final Color? customLogoColor; // Opcional

  const CustomLoadingScreen({
    super.key,
    this.logoAssetPath, // = 'assets/images/levva_icon_transp_branco.png', // Manteve o branco como padrão
    this.backgroundColor,
    this.customLogoColor,
  });

  @override
  Widget build(BuildContext context) {
    // Define os padrões se nenhum valor for passado
    final String effectiveLogoPath =
        logoAssetPath ?? 'assets/images/levva_icon_transp_branco.png';
    final Color effectiveBackgroundColor =
        backgroundColor ?? Colors.black; // Fundo preto é o padrão
    final Color effectiveLogoColor =
        customLogoColor ??
        Colors.black; // <<-- LOGO PRETA AQUI por padrão se não especificado

    return Scaffold(
      backgroundColor: effectiveBackgroundColor, // Fundo preto
      body: Center(
        child: GlobalPulsingLogoLoader(
          imagePath:
              effectiveLogoPath, // Use a logo que pode ser tingida (ex: a branca)
          size: 100.0,
          logoColor: effectiveLogoColor, // Cor da logo preta
        ),
      ),
    );
  }
}
