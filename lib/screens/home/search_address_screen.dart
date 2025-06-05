import 'package:flutter/material.dart';

class SearchAddressScreen extends StatelessWidget {
  static const routeName =
      '/search-address'; // Para navegação nomeada, se desejar

  const SearchAddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Endereço'),
        // A cor do ícone de voltar e do texto será definida pelo AppBarTheme em main.dart
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 80, color: Colors.grey),
              SizedBox(height: 20),
              Text(
                'Tela de Busca de Endereço',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'Aqui você poderá buscar por um endereço de partida e destino.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
