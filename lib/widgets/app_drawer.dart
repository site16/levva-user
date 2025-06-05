import 'package:flutter/material.dart';
import 'package:levva/screens/become_driver/become_driver_screen.dart';
import 'package:levva/screens/discounts/discounts_screen.dart';
import 'package:levva/screens/legal/terms_of_use_screen.dart';
import 'package:levva/screens/levva_pay/levva_pay_screen.dart';
import 'package:levva/screens/referral/referral_screen.dart';
import 'package:levva/screens/ride_history/ride_history_screen.dart';
import 'package:levva/screens/support/support_screen.dart';
import 'package:levva/screens/sos/sos_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/profile/profile_screen.dart';
import '../models/user_model.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Widget _buildListItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color iconColor = Colors.black54,
    Color textColor = Colors.black87,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 24),
      title: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.black38,
        size: 22,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 4.0,
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, AppUser? user) {
    ImageProvider? profileImageProvider;
    if (user?.profileImageUrl != null && user!.profileImageUrl!.isNotEmpty) {
      profileImageProvider = NetworkImage(user.profileImageUrl!);
    }

    // Simulação de dados de avaliação - substitua pela sua lógica real se tiver
    const String userRating = "4.9"; // Exemplo, puxe do seu modelo de usuário

    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        Navigator.of(context).pushNamed(ProfileScreen.routeName);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25.0),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior:
                  Clip.none, // Permite que o widget da avaliação transborde um pouco
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: profileImageProvider,
                  child:
                      (profileImageProvider == null)
                          ? Icon(
                            Icons.person_outline,
                            size: 32,
                            color: Colors.grey.shade600,
                          )
                          : null,
                ),
                if (userRating.isNotEmpty)
                  Positioned(
                    bottom:
                        -5, // Ajuste para posicionar a avaliação "dentro" ou tocando a borda
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(
                          0.75,
                        ), // Fundo escuro para a avaliação
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 13,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            userRating,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                // Adicionado padding para o nome não ficar colado na avaliação
                padding: const EdgeInsets.only(
                  top: 4.0,
                ), // Ajuste o top padding se a avaliação sobrepuser demais
                child: Text(
                  user?.fullName ?? 'Nome do Usuário',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final AppUser? user = authProvider.currentUser;

    final List<Map<String, dynamic>> menuItems = [
      {
        'icon': Icons.account_balance_wallet_outlined,
        'text': 'LevvaPay', // Texto alterado
        'routeName': LevvaPayScreen.routeName,
      },
      {
        'icon': Icons.history_rounded,
        'text': 'Minhas Corridas',
        'routeName': RideHistoryScreen.routeName,
      },
      {
        'icon': Icons.local_offer_outlined,
        'text': 'Descontos',
        'routeName': DiscountsScreen.routeName,
      },
      {
        'icon': Icons.two_wheeler_outlined, // Ícone para "Seja Entregador"
        'text': 'Seja Entregador',
        'routeName': BecomeDriverScreen.routeName,
      },
      {
        'icon': Icons.people_alt_outlined,
        'text': 'Indique e Ganhe',
        'routeName': ReferralScreen.routeName,
      },
      {
        'icon': Icons.article_outlined,
        'text': 'Termos de Uso',
        'routeName': TermsOfUseScreen.routeName,
      },
      {
        'icon': Icons.help_outline_rounded,
        'text': 'Ajuda e Suporte',
        'routeName': SupportScreen.routeName,
      },
    ];

    return Drawer(
      backgroundColor: Colors.grey[100],
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título "Levva" no topo foi removido
            _buildProfileSection(context, user),

            Divider(color: Colors.grey.shade300, height: 1, thickness: 0.5),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 8.0),
                children:
                    menuItems.map((item) {
                      return _buildListItem(
                        icon: item['icon'],
                        text: item['text'],
                        onTap: () {
                          final routeToNavigate = item['routeName'] as String?;
                          Navigator.of(context).pop();
                          if (routeToNavigate != null) {
                            Navigator.of(context).pushNamed(routeToNavigate);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Rota não definida para: ${item['text']}',
                                ),
                              ),
                            );
                          }
                        },
                      );
                    }).toList(),
              ),
            ),

            Divider(color: Colors.grey.shade300, height: 1, thickness: 0.5),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                        size: 20,
                      ), // Ícone de "usuário saindo"
                      label: const Text(
                        'Sair',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade500, // Tom de vermelho
                        padding: const EdgeInsets.symmetric(
                          vertical: 13,
                        ), // Padding ajustado
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            10.0,
                          ), // Bordas um pouco mais arredondadas
                        ),
                        elevation: 2,
                      ),
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        final auth = Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        );

                        if (navigator.canPop()) {
                          navigator.pop();
                        }
                        await Future.delayed(const Duration(milliseconds: 100));
                        try {
                          await auth.signOut(context);
                        } catch (error) {
                          if (navigator.mounted) {
                            ScaffoldMessenger.of(
                              navigator.context,
                            ).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Erro ao sair: ${error.toString()}',
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.black87,
                        size: 20,
                      ), // Ícone de alerta para SOS
                      label: const Text(
                        'SOS',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.amber.shade500, // Tom de amarelo
                        padding: const EdgeInsets.symmetric(
                          vertical: 13,
                        ), // Padding ajustado
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed(SosScreen.routeName);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
