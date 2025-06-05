// lib/screens/notifications/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para SystemUiOverlayStyle
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart'; // Importa NotificationModel
import '../../widgets/pulsing_logo_loader.dart';

class NotificationsScreen extends StatefulWidget {
  static const routeName = '/notifications';
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      // Lógica corrigida para buscar notificações:
      // Busca se a lista estiver vazia, não estiver carregando e não houver erro.
      if (provider.notifications.isEmpty &&
          !provider.isLoading &&
          provider.errorMessage == null) {
        provider.fetchNotifications();
      }
    });
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.promocao:
        return Icons.local_offer_outlined;
      case NotificationType.corrida:
        return Icons.directions_car_filled_outlined;
      case NotificationType.sistema:
        return Icons.info_outline_rounded;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  void _handleNotificationTap(
    BuildContext context,
    NotificationModel notification,
  ) {
    final provider = Provider.of<NotificationProvider>(context, listen: false);

    if (!notification.isRead) {
      provider.markNotificationAsRead(notification.id);
    }

    if (notification.type == NotificationType.promocao &&
        (notification.discountCode != null ||
            notification.discountId != null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Abrindo detalhes da promoção: ${notification.title}'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      print('Promoção tocada: ${notification.title}');
    } else if (notification.rideId != null && notification.rideId!.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Abrindo detalhes da corrida: ${notification.rideId}'),
        ),
      );
      print('Navegar para detalhes da corrida: ${notification.rideId}');
    } else {
      print(
        'Notificação "${notification.title}" tocada. Sem ação específica definida.',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notificação: ${notification.title}')),
      );
    }
  }

  Widget _buildBody(
    BuildContext context,
    NotificationProvider provider,
    ThemeData theme,
  ) {
    const String logoPathForLightBg = 'assets/images/levva_icon_transp.png';

    if (provider.isLoading && provider.notifications.isEmpty) {
      return Center(
        child: PulsingLogoLoader(
          imagePath: logoPathForLightBg,
          size: 70.0,
          color: theme.colorScheme.primary,
        ),
      );
    }
    if (provider.errorMessage != null && provider.notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                color: Colors.grey.shade500,
                size: 64,
              ),
              const SizedBox(height: 20),
              Text(
                "Ops! Algo deu errado",
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                icon: Icon(
                  Icons.refresh_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                label: Text(
                  'Tentar Novamente',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () => provider.fetchNotifications(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (provider.notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_none_outlined,
                size: 70,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 20),
              Text(
                "Nenhuma notificação por aqui!",
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Suas atualizações e alertas importantes aparecerão aqui.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                icon: Icon(
                  Icons.refresh_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                label: Text(
                  'Atualizar',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () => provider.fetchNotifications(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 16.0),
      itemCount: provider.notifications.length,
      itemBuilder: (context, index) {
        final NotificationModel notification = provider.notifications[index];
        final bool isUnread = !notification.isRead;
        final String formattedDate = DateFormat(
          'dd/MM/yy \'às\' HH:mm',
          'pt_BR',
        ).format(notification.timestamp.toDate());

        final Color iconBackgroundColor =
            isUnread
                ? theme.colorScheme.primary.withOpacity(0.1)
                : Colors.grey.shade200;
        final Color iconFgColor =
            isUnread ? theme.colorScheme.primary : Colors.grey.shade700;
        final Color titleColor =
            isUnread
                ? theme.colorScheme.onBackground
                : theme.colorScheme.onBackground.withOpacity(0.7);
        final Color messageColor =
            isUnread
                ? theme.colorScheme.onBackground.withOpacity(0.85)
                : theme.colorScheme.onBackground.withOpacity(0.6);

        return Dismissible(
          key: Key(notification.id),
          direction: DismissDirection.endToStart,
          onDismissed: (d) {
            provider.clearNotification(notification.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("'${notification.title}' removida."),
                backgroundColor: Colors.orange.shade800,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          background: Container(
            color: Colors.red.shade600,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerRight,
            child: const Icon(
              Icons.delete_sweep_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          child: Card(
            elevation: 1.5,
            margin: const EdgeInsets.symmetric(vertical: 5.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: iconBackgroundColor,
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: iconFgColor,
                  size: 22,
                ),
              ),
              title: Text(
                notification.title,
                style: TextStyle(
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                  color: titleColor,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 3.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: messageColor,
                        fontSize: 13.5,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              trailing:
                  isUnread
                      ? Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      )
                      : null,
              onTap: () => _handleNotificationTap(context, notification),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 12.0,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
            size: 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Voltar',
        ),
        title: Text(
          "Notificações",
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
        actions: [
          if (notificationProvider.notifications.isNotEmpty &&
              notificationProvider.unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.mark_chat_read_outlined),
              tooltip: 'Marcar todas como lidas',
              onPressed:
                  () => notificationProvider.markAllNotificationsAsRead(),
              color: Colors.black87,
            ),
          if (notificationProvider.notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Limpar todas as notificações',
              color: Colors.black87,
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder:
                      (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        title: const Text('Limpar Notificações?'),
                        content: const Text(
                          'Tem certeza que deseja apagar todas as suas notificações? Esta ação não pode ser desfeita.',
                        ),
                        actions: [
                          TextButton(
                            child: const Text('Cancelar'),
                            onPressed: () => Navigator.of(ctx).pop(false),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                            ),
                            child: const Text('Limpar Todas'),
                            onPressed: () => Navigator.of(ctx).pop(true),
                          ),
                        ],
                      ),
                );
                if (confirm == true) {
                  notificationProvider.clearAllNotifications();
                }
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => notificationProvider.fetchNotifications(),
        color: theme.colorScheme.primary,
        backgroundColor: Colors.white,
        child: _buildBody(context, notificationProvider, theme),
      ),
    );
  }
}
