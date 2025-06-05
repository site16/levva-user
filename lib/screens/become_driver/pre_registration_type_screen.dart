// lib/screens/become_driver/pre_registration_type_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para SystemUiOverlayStyle
import 'package:levva/models/enums.dart'; 
import 'package:levva/screens/become_driver/driver_registration_form_screen.dart';

// Clipper para a forma da onda do header (mesmo da LoginScreen)
class ReferenceWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height * 0.70); 

    var firstControlPoint = Offset(size.width * 0.25, size.height * 0.95);
    var firstEndPoint = Offset(size.width * 0.55, size.height * 0.75);   
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width * 0.85, size.height * 0.55); 
    var secondEndPoint = Offset(size.width, size.height * 0.70);          
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);
    
    path.lineTo(size.width, 0); 
    path.close(); 
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}


class PreRegistrationTypeScreen extends StatelessWidget {
  static const routeName = '/pre-registration-type';
  const PreRegistrationTypeScreen({super.key});

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String imagePath, // Alterado de IconData para String imagePath
    required VehicleType vehicleType,
    // cardColor e iconColor não são mais necessários aqui, pois o card será branco
    // e o ícone é uma imagem.
  }) {
    final theme = Theme.of(context);
    return Card(
      // O estilo do Card virá do CardTheme global (fundo branco, borda sutil)
      // elevation: 2.0, // Já definido no CardTheme
      // margin: const EdgeInsets.symmetric(vertical: 12.0), // Já definido no CardTheme
      // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)), // Já definido no CardTheme
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            DriverRegistrationFormScreen.routeName,
            arguments: vehicleType,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0), // Padding ajustado
          child: Row( // Usando Row para imagem ao lado do texto
            children: [
              Image.asset( // Usando Image.asset
                imagePath,
                height: 70, // Ajuste o tamanho da imagem
                width: 70,  // Ajuste o tamanho da imagem
                fit: BoxFit.contain, // Ou BoxFit.cover, dependendo da imagem
                errorBuilder: (context, error, stackTrace) {
                  // Fallback caso a imagem não carregue
                  return Icon(
                    vehicleType == VehicleType.moto ? Icons.motorcycle : Icons.directions_bike,
                    size: 50,
                    color: theme.colorScheme.onSurface.withOpacity(0.5), // Cinza
                  );
                },
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.left,
                      style: theme.textTheme.titleLarge?.copyWith( // Usando titleLarge
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface, // Texto preto/cinza escuro
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      textAlign: TextAlign.left,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7), // Texto cinza
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: theme.colorScheme.onSurface.withOpacity(0.6), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Tema global (fundo branco, primária preta)
    final screenHeight = MediaQuery.of(context).size.height;
    final EdgeInsets systemPadding = MediaQuery.of(context).padding;

    // Altura da seção preta superior (onde a curva termina na base)
    // Ajuste esta altura para controlar o quanto da tela a seção preta ocupa
    final double topBlackSectionHeight = screenHeight * 0.30; // Ex: 30% da tela

    return Scaffold(
      backgroundColor: Colors.white, // Fundo da parte inferior da tela
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light, // Ícones da status bar BRANCOS (sobre fundo preto)
        child: Stack(
          children: <Widget>[
            // --- Seção Superior (Preta com Curva na Base) ---
            ClipPath(
              clipper: ReferenceWaveClipper(), // Clipper para a forma da onda
              child: Container(
                height: topBlackSectionHeight, 
                width: double.infinity,
                color: Colors.black, // Fundo preto para esta seção
                child: SafeArea( // Para o título e botão de voltar não ficarem sob a status bar
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: systemPadding.top + 10, // Espaço para o botão de voltar
                      left: 60, // Espaço se houver botão de voltar
                      right: 20,
                      bottom: 40, // Espaço antes da curva começar a afetar o texto
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft, // Alinha o título à esquerda
                      child: Text(
                        'Escolha seu Veículo',
                        style: theme.textTheme.headlineSmall?.copyWith( // Usando headlineSmall para o título
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // --- Botão de Voltar ---
            Positioned(
              top: systemPadding.top + 5, // Ajustado para o padding do sistema
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), // Ícone BRANCO
                onPressed: () => Navigator.of(context).pop(),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              ),
            ),

            // --- Conteúdo Inferior (Branco, com a pergunta e os cards) ---
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: screenHeight - (topBlackSectionHeight * 0.75), // Altura para o conteúdo branco
                width: double.infinity,
                padding: EdgeInsets.only(top: topBlackSectionHeight * 0.15), // Padding para desviar da curva preta
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start, 
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        'Com qual tipo de veículo você fará as entregas?',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 18, 
                          color: theme.colorScheme.onBackground, // Texto preto
                          fontWeight: FontWeight.w600
                        ),
                      ),
                      const SizedBox(height: 24), // Espaço aumentado
                      _buildOptionCard(
                        context,
                        title: 'Moto', // Título simplificado
                        subtitle: 'Para entregas rápidas e ágeis pela cidade.',
                        imagePath: 'assets/images/motoka.png', // Caminho da imagem
                        vehicleType: VehicleType.moto,
                      ),
                      _buildOptionCard(
                        context,
                        title: 'Bike', // Título simplificado
                        subtitle: 'Para entregas ecológicas e saudáveis.',
                        imagePath: 'assets/images/bike_woman.png', // Caminho da imagem
                        vehicleType: VehicleType.bike,
                      ),
                      SizedBox(height: screenHeight * 0.05), // Espaço na base
                    ],
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
