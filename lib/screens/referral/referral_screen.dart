// lib/screens/referral/referral_screen.dart
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para Clipboard e SystemUiOverlayStyle
import 'package:share_plus/share_plus.dart';
// import 'package:provider/provider.dart';
// import '../../providers/auth_provider.dart';

class ReferralScreen extends StatelessWidget {
  static const routeName = '/referral';
  const ReferralScreen({super.key});

  final String playStoreUrl = "https://play.google.com/store/apps/details?id=com.seucompany.levva";
  final String appStoreUrl = "https://apps.apple.com/app/idSEU_APP_ID";
  final String genericAppUrl = "https://www.levva.com.br/app";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    const String userReferralCode = "LEVVAAMIGO123";

    // Cores para o gradiente VERMELHO (mesmas da LevvaPayScreen para consistência)
    const Color primaryRedGradient = Color(0xFFE53935); // Vermelho vibrante
    const Color secondaryRedGradient = Color(0xFFC62828); // Vermelho profundo

    // Gradiente para o card do código de convite
    const LinearGradient referralCardGradient = LinearGradient(
      colors: [primaryRedGradient, secondaryRedGradient],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: [0.0, 0.9], // Ajuste os stops para controlar a transição do gradiente
    );

    String getAppShareLink() {
      if (Platform.isIOS) {
        return appStoreUrl;
      } else if (Platform.isAndroid) {
        return playStoreUrl;
      }
      return genericAppUrl;
    }

    void shareReferral() {
      final String appLink = getAppShareLink();
      final String shareMessage =
          "Ei! Estou usando o Levva para minhas entregas e viagens e adorei! 🛵💨\n"
          "Baixe o app e experimente: $appLink\n\n"
          "Use meu código de convite *${userReferralCode}* para ganhar um bônus especial na sua primeira corrida! 😉";

      Share.share(shareMessage, subject: 'Convite para o Levva App!');
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 22),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Voltar',
        ),
        title: Text(
          'Indique e Ganhe',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.8,
        scrolledUnderElevation: 1.0,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: 16.0),
            Icon(
              Icons.card_giftcard_rounded,
              size: 72,
              color: theme.colorScheme.primary, // Preto
            ),
            const SizedBox(height: 24.0),
            Text(
              'Convide Amigos, Ganhe Recompensas!',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              'Compartilhe seu código de convite com amigos. Quando eles usarem o Levva, vocês dois ganham!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 15,
                color: theme.colorScheme.onBackground.withOpacity(0.75),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32.0),

            // Card do Código de Convite com GRADIENTE VERMELHO
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
              decoration: BoxDecoration(
                gradient: referralCardGradient, // Aplicando o gradiente vermelho
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: secondaryRedGradient.withOpacity(0.3), // Sombra baseada na cor do gradiente
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Seu Código de Convite:',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9), // Texto branco sobre o gradiente
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  SelectableText(
                    userReferralCode,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Código em branco
                      letterSpacing: 2.5,
                      fontSize: 26,
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  TextButton.icon(
                    icon: Icon(Icons.copy_all_outlined, size: 20, color: Colors.white.withOpacity(0.85)),
                    label: Text(
                      'Copiar Código',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600) // Texto branco
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        side: BorderSide(color: Colors.white.withOpacity(0.4)) // Borda sutil branca
                      )
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: userReferralCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Código de convite copiado!'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32.0),

            ElevatedButton.icon(
              icon: const Icon(Icons.share_outlined, color: Colors.white),
              label: const Text('CONVIDAR AMIGOS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, // Botão principal de compartilhar continua preto
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0))
              ),
              onPressed: shareReferral,
            ),
            const SizedBox(height: 24.0),
            Text(
              'Ao compartilhar, você ajuda a Levva a crescer e oferecer um serviço cada vez melhor para nossa comunidade.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }
}