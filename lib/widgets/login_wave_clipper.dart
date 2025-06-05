// Adicione esta classe ao seu arquivo login_screen.dart ou em um arquivo de clippers
import 'package:flutter/material.dart'; // Necessário para Path e Size
// Para usar PI, se necessário para arcos

class ReferenceWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    // Começa no topo esquerdo
    path.lineTo(0, size.height * 0.55); // Desce um pouco na esquerda

    // Primeira parte da curva (descendo e indo para a direita)
    // Ponto de controle 1, ponto de controle 2, ponto final
    path.cubicTo(
      size.width * 0.20, size.height * 0.80, // Controle 1: puxa para baixo e para a direita
      size.width * 0.35, size.height * 0.40, // Controle 2: puxa para cima e mais para a direita (cria a "crista" da onda)
      size.width * 0.65, size.height * 0.65  // Ponto final da primeira grande curva (um pouco depois do meio, abaixo do centro)
    );

    // Segunda parte da curva (subindo e indo para a borda direita)
    path.cubicTo(
      size.width * 0.85, size.height * 0.80, // Controle 1: puxa para baixo e mais para a direita
      size.width * 0.95, size.height * 0.55, // Controle 2: puxa para cima perto da borda
      size.width,        size.height * 0.60  // Ponto final na borda direita
    );
    
    path.lineTo(size.width, 0); // Linha para o topo direito
    path.close(); // Fecha o caminho no canto superior esquerdo
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}