// lib/screens/auth/login_screen.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:levva/models/enums.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/pulsing_logo_loader.dart';
// Importe o clipper se estiver em um arquivo separado:
// import '../../widgets/reference_wave_clipper.dart'; 

// Se o clipper estiver no mesmo arquivo, não precisa do import acima.
// Cole a definição da classe ReferenceWaveClipper aqui se não estiver em arquivo separado.

// NOVO CLIPPER PARA A CURVA DA IMAGEM DE REFERÊNCIA
class ReferenceWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height * 0.50); // Início da descida na esquerda (ajuste esta altura)

    // Curva de "S" ou onda - Ponto inicial (0, size.height * 0.50)
    var controlPoint1 = Offset(size.width * 0.2, size.height * 0.85); // Puxa para baixo
    var endPoint1 = Offset(size.width * 0.5, size.height * 0.65);    // Ponto médio da curva, um pouco acima da base
    path.quadraticBezierTo(controlPoint1.dx, controlPoint1.dy, endPoint1.dx, endPoint1.dy);

    var controlPoint2 = Offset(size.width * 0.8, size.height * 0.45); // Puxa para cima
    var endPoint2 = Offset(size.width, size.height * 0.75);          // Termina na direita
    path.quadraticBezierTo(controlPoint2.dx, controlPoint2.dy, endPoint2.dx, endPoint2.dy);

    path.lineTo(size.width, 0); // Linha para o topo direito
    path.close(); // Fecha o caminho no canto superior esquerdo
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}


class LoginScreen extends StatefulWidget {
  static const routeName = '/login';
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ... (métodos _signInWithGoogle, _signInWithApple, _launchURL INALTERADOS da última versão) ...
  Future<void> _signInWithGoogle() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.signInWithGoogle(context);
    } catch (e) {
      print("Erro UI ao tentar login com Google: $e");
      if (mounted && (e.toString().contains("network_error") || e.toString().contains("SocketException"))){
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sem conexão com a internet. Verifique sua rede e tente novamente.'), backgroundColor: Colors.orangeAccent),
        );
      } else if (mounted && e.toString().contains("sign_in_canceled")){
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login com Google cancelado.')),
        );
      }
    }
  }

  void _signInWithApple() {
    print("Login Apple não implementado.");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login com Apple não disponível no momento.')),
      );
    }
  }

  void _launchURL(String urlKey) {
    String urlToLaunch = "https://seusite.com/$urlKey"; 
    print("Tentando abrir URL: $urlToLaunch");
    if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Abrindo link para: $urlKey (simulado)')));
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final bool isLoading = authProvider.authStatus == AuthStatus.authenticating;
    final screenHeight = MediaQuery.of(context).size.height;
    
    const String logoPathBlack = 'assets/images/levva_icon_transp.png'; 
    const String logoPathWhite = 'assets/images/levva_icon_transp_branco.png';

    // Altura da seção superior branca. Ajuste este valor para controlar o quanto da tela ela ocupa.
    // A curva será desenhada dentro desta altura.
    final double topSectionHeight = screenHeight * 0.55; 

    return Scaffold(
      body: Stack(
        children: <Widget>[
          // --- Seção Inferior (Preta) - Fica atrás como base ---
          Positioned.fill(
            child: Container(
              color: Colors.black,
            ),
          ),

          // --- Seção Superior (Branca com a Curva da Imagem de Referência) ---
          ClipPath(
            clipper: ReferenceWaveClipper(), // <<< USANDO O NOVO CLIPPER
            child: Container(
              height: topSectionHeight, // Altura da seção branca
              width: double.infinity,
              color: Colors.white,
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // Tenta centralizar o logo na parte branca
                  children: [
                    // Espaçamento para o logo não ficar muito colado na status bar ou na curva
                    SizedBox(height: topSectionHeight * 0.15), 
                    if (!isLoading)
                      Image.asset(
                        logoPathBlack, 
                        height: topSectionHeight * 0.25, // Tamanho do logo proporcional à seção
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, s) => Icon(
                          Icons.business_center, // Um ícone placeholder diferente
                          color: Colors.grey.shade400,
                          size: topSectionHeight * 0.25,
                        ),
                      ),
                    if (isLoading) 
                      SizedBox(height: topSectionHeight * 0.25), // Mantém o espaço
                    const Spacer(), 
                  ],
                ),
              ),
            ),
          ),

          // --- Conteúdo da Seção Inferior (Textos, Botões, etc.) ---
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              // A altura desta seção deve ser suficiente para o conteúdo + o "mergulho" da curva.
              // (1 - 0.50 (altura da parte branca antes da curva mais baixa) + 0.15 (aprofundamento da curva)) * screenHeight
              // Ou simplesmente uma proporção que funcione visualmente.
              height: screenHeight * 0.65, // Pode precisar de ajuste fino
              width: double.infinity,
              child: SafeArea(
                top: false,
                child: Padding(
                  // O padding superior aqui precisa ser suficiente para que o texto
                  // comece abaixo da parte mais baixa da curva branca.
                  padding: EdgeInsets.fromLTRB(30.0, screenHeight * 0.18, 30.0, 20.0), // <<< AJUSTE ESTE PADDING SUPERIOR
                  child: Column(
                    // mainAxisAlignment: MainAxisAlignment.center, // Removido para permitir que o Spacer funcione melhor
                    children: <Widget>[
                      // O Spacer acima foi removido, o padding superior agora controla o início do texto
                      const Text(
                        "Bem-vindo(a) ao Levva!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Conecte-se para começar a usar nossos serviços de forma rápida e segura.", // Texto mais elaborado
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade400,
                          height: 1.4
                        ),
                      ),
                      const SizedBox(height: 35),

                      if (isLoading)
                        Expanded( // Para o loader ocupar o espaço dos botões
                          child: Center(
                            child: PulsingLogoLoader(
                              imagePath: logoPathWhite, 
                              size: 60.0,
                              color: Colors.white,
                            ),
                          ),
                        )
                      else ...[
                        ElevatedButton.icon(
                          // ... (estilo do botão Google inalterado) ...
                          icon: Text('G', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                          label: const Text('Continuar com Google'),
                          onPressed: _signInWithGoogle,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black, backgroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 52),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Inter'),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextButton.icon(
                          // ... (estilo do botão Apple inalterado) ...
                          icon: const Icon(Icons.apple, color: Colors.white, size: 26),
                          label: const Text('Continuar com Apple'),
                          onPressed: _signInWithApple,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 52),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Inter'),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              side: const BorderSide(color: Colors.white54, width: 1.5),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ],
                      const Spacer(), // Empurra os termos para baixo

                      if (!isLoading)
                        RichText(
                          // ... (RichText dos Termos inalterado) ...
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5, height: 1.5),
                            children: <TextSpan>[
                              const TextSpan(text: 'Ao continuar, você concorda com nossa\n'),
                              TextSpan(
                                text: 'Política de Privacidade',
                                style: const TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.w500, color: Colors.white70),
                                recognizer: TapGestureRecognizer()..onTap = () => _launchURL('URL_DA_POLITICA_DE_PRIVACIDADE'),
                              ),
                              const TextSpan(text: ' e '),
                              TextSpan(
                                text: 'Termos de Uso',
                                style: const TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.w500, color: Colors.white70),
                                recognizer: TapGestureRecognizer()..onTap = () => _launchURL('URL_DOS_TERMOS_E_CONDICOES'),
                              ),
                            ],
                          ),
                        ),
                      if (authProvider.authStatus == AuthStatus.error &&
                          authProvider.errorMessage != null &&
                          !isLoading)
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Text(
                            authProvider.errorMessage!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Adicione a classe ReferenceWaveClipper aqui se não a colocou em um arquivo separado.