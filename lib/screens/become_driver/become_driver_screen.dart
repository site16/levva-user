// lib/screens/become_driver/become_driver_screen.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para SystemUiOverlayStyle
import 'package:levva/screens/become_driver/pre_registration_type_screen.dart';
import 'package:url_launcher/url_launcher.dart'; 

// Definição do Clipper (ReferenceWaveClipper)
// Certifique-se que esta classe está definida aqui ou importada corretamente.
class ReferenceWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height * 0.70); // Linha lateral esquerda, desce 70%

    var firstControlPoint = Offset(size.width * 0.25, size.height * 0.95); // Puxa para baixo
    var firstEndPoint = Offset(size.width * 0.55, size.height * 0.75);   // Meio da curva
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width * 0.85, size.height * 0.55); // Puxa para cima
    var secondEndPoint = Offset(size.width, size.height * 0.70); // Termina na direita, na mesma altura do início
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);
    
    path.lineTo(size.width, 0); // Linha para o topo direito
    path.close(); // Fecha o caminho no canto superior esquerdo
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}


class BecomeDriverScreen extends StatelessWidget {
  static const routeName = '/become-driver';
  const BecomeDriverScreen({super.key});

  Future<void> _launchURL(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Não foi possível abrir $urlString')),
        );
      }
      print('Não foi possível abrir $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); 
    final screenHeight = MediaQuery.of(context).size.height;
    final EdgeInsets systemPadding = MediaQuery.of(context).padding;

    final double topWhiteSectionHeight = screenHeight * 0.55; 
    final double driverImageHeight = screenHeight * 0.35; 

    return Scaffold(
      backgroundColor: Colors.black, 
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith( 
          statusBarColor: Colors.transparent, 
          statusBarIconBrightness: Brightness.dark, 
        ),
        child: Stack(
          children: <Widget>[
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: screenHeight * 0.60, 
                color: Colors.black,
              ),
            ),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipPath(
                clipper: ReferenceWaveClipper(), 
                child: Container(
                  height: topWhiteSectionHeight, 
                  width: double.infinity,
                  color: Colors.white, 
                  child: SafeArea( 
                    bottom: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start, 
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: EdgeInsets.only(left: 10.0, top: systemPadding.top > 0 ? systemPadding.top - 5 : 10.0), 
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black), 
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ),
                        // Reduzindo o SizedBox para mover a imagem para cima
                        const SizedBox(height: 8.0), // <<< ALTERADO AQUI (era screenHeight * 0.02)
                        Image.asset(
                          'assets/images/Entregador acenando.png', 
                          height: driverImageHeight,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.delivery_dining_outlined,
                              size: driverImageHeight * 0.8,
                              color: Colors.grey.shade400, 
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: screenHeight * 0.55, 
                width: double.infinity,
                child: SafeArea(
                  top: false, 
                  bottom: true,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        28.0, 
                        screenHeight * 0.10, 
                        28.0, 
                        20.0 
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center, 
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            'Transforme seu tempo em renda extra!',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white, 
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          Text(
                            'Com a Levva, você tem flexibilidade para fazer suas entregas quando quiser, usando sua moto ou bike. Junte-se à nossa comunidade e aumente seus ganhos.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontSize: 15,
                              color: Colors.grey.shade300, 
                              height: 1.5,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.06), 
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white, 
                              foregroundColor: Colors.black, 
                              minimumSize: const Size(double.infinity, 52),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                side: BorderSide(color: Colors.grey.shade300) 
                              ),
                              elevation: 2, 
                            ),
                            onPressed: () {
                              Navigator.of(context).pushNamed(PreRegistrationTypeScreen.routeName);
                            },
                            child: const Text('QUERO SER ENTREGADOR'),
                          ),
                          const SizedBox(height: 20.0),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade500, 
                                  height: 1.4,
                                ),
                                children: <TextSpan>[
                                  const TextSpan(text: 'Ao continuar, você declara que leu e concorda com nossos '),
                                  TextSpan(
                                    text: 'Termos de Uso do Entregador',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8), 
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Colors.white.withOpacity(0.8),
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        _launchURL(context, 'https://seusite.com/termos-entregador'); 
                                      },
                                  ),
                                  const TextSpan(text: '.'),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.03),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
