import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para SystemUiOverlayStyle
import 'package:url_launcher/url_launcher.dart';

// A classe EmergencyContact permanece a mesma que você forneceu
class EmergencyContact {
  final String name;
  final String number;
  final String description;
  final IconData icon;

  EmergencyContact({
    required this.name,
    required this.number,
    required this.description,
    required this.icon,
  });
}

class SosScreen extends StatelessWidget {
  static const routeName = '/sos';
  const SosScreen({super.key});

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    // Não é necessário capturar o Navigator aqui, pois o context já deve estar montado
    // se a função for chamada de um widget na árvore.

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      // Verifica se o widget ainda está montado antes de mostrar o SnackBar
      if (ScaffoldMessenger.of(context).mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Não foi possível realizar a ligação para $phoneNumber'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Widget _buildEmergencyContactCard(BuildContext context, EmergencyContact contact) {
    // Cores para os ícones e seus círculos, mantendo uma identidade visual
    Color iconCircleAvatarColor = Theme.of(context).colorScheme.primary.withOpacity(0.1); // Um tom sutil da cor primária
    Color iconColor = Theme.of(context).colorScheme.primary; // Cor primária (preto no seu tema)

    if (contact.name == "Polícia Militar") {
      iconCircleAvatarColor = Colors.blue.shade50;
      iconColor = Colors.blue.shade700;
    } else if (contact.name == "SAMU (Ambulância)") {
      iconCircleAvatarColor = Colors.red.shade50;
      iconColor = Colors.red.shade700;
    } else if (contact.name == "Corpo de Bombeiros") {
      iconCircleAvatarColor = Colors.orange.shade50;
      iconColor = Colors.orange.shade800;
    } else if (contact.name == "Defesa Civil") {
      iconCircleAvatarColor = Colors.green.shade50;
      iconColor = Colors.green.shade700;
    } else if (contact.name == "Central de Atendimento à Mulher") {
      iconCircleAvatarColor = Colors.purple.shade50;
      iconColor = Colors.purple.shade700;
    } else if (contact.name == "Suporte de Emergência Levva") {
      iconCircleAvatarColor = Colors.grey.shade200;
      iconColor = Colors.grey.shade800;
    }

    return Card(
      elevation: 2.0, // Sombra sutil
      margin: const EdgeInsets.symmetric(vertical: 7.0), // Espaçamento vertical entre cards
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: Colors.white, // Fundo branco para o card
      child: InkWell( // Para tornar o card inteiro clicável
        onTap: () => _makePhoneCall(context, contact.number),
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: iconCircleAvatarColor,
                child: Icon(contact.icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contact.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Coluna para o número e o botão "LIGAR"
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    contact.number,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).primaryColor, // Preto
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "LIGAR",
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).primaryColor.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<EmergencyContact> emergencyContacts = [
      EmergencyContact(name: "Polícia Militar", number: "190", description: "Para emergências policiais e segurança pública.", icon: Icons.local_police_outlined),
      EmergencyContact(name: "SAMU (Ambulância)", number: "192", description: "Para emergências médicas e atendimento pré-hospitalar.", icon: Icons.medical_services_outlined),
      EmergencyContact(name: "Corpo de Bombeiros", number: "193", description: "Para incêndios, resgates e salvamentos.", icon: Icons.local_fire_department_outlined),
      EmergencyContact(name: "Defesa Civil", number: "199", description: "Para desastres naturais, enchentes e deslizamentos.", icon: Icons.shield_outlined),
      EmergencyContact(name: "Central de Atendimento à Mulher", number: "180", description: "Para denúncias e apoio em casos de violência contra a mulher.", icon: Icons.support_agent_outlined),
      EmergencyContact(name: "Suporte de Emergência Levva", number: "08000000000", description: "Para problemas urgentes relacionados à sua corrida ou entrega Levva.", icon: Icons.support_outlined),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100], // Fundo cinza claro para a tela, consistente
      appBar: AppBar(
        leading: IconButton( // Botão de voltar padrão
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 22),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Voltar',
        ),
        title: const Text(
          'SOS - Emergência',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white, // Fundo branco para a AppBar
        elevation: 0.8, // Sombra sutil
        scrolledUnderElevation: 1.0,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith( // Ícones da barra de status escuros
          statusBarColor: Colors.transparent,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 12.0), // Padding ajustado
            child: Text(
              'Precisa de ajuda imediata?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87, // Ajustado para preto
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: emergencyContacts.length,
              itemBuilder: (context, index) {
                return _buildEmergencyContactCard(context, emergencyContacts[index]);
              },
            ),
          ),
          // Banner de aviso AMARELO no final
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.amber.shade600, // Amarelo um pouco mais escuro para melhor contraste
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.black.withOpacity(0.75), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Atenção: Use estes números apenas em caso de emergência real. O uso indevido pode ter consequências.',
                    style: TextStyle(color: Colors.black.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}