import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Para ouvir o RideRequestProvider
import '../providers/ride_request_provider.dart'; // Importa o RideRequestProvider
import 'global_pulsing_logo_loader.dart'; // Importa o loader

class SearchingDriverDialog extends StatefulWidget {
  final String logoPath;
  // Os callbacks onCancelDialog e onRetrySearch são chamados quando os botões são pressionados.
  // A lógica principal de mudança de estado da busca é feita através do RideRequestProvider.
  final VoidCallback onCancelDialog;
  final VoidCallback onRetrySearch;

  const SearchingDriverDialog({
    super.key,
    required this.logoPath,
    required this.onCancelDialog,
    required this.onRetrySearch,
  });

  @override
  State<SearchingDriverDialog> createState() => _SearchingDriverDialogState();
}

class _SearchingDriverDialogState extends State<SearchingDriverDialog>
    with TickerProviderStateMixin {
  Timer? _timer;
  int _countdown = 90; // Duração do temporizador em segundos
  bool _canRetryButtonBeActive =
      false; // Controla se o botão "De Novo" está ativo

  // Controladores de Animação para o efeito "Entregador Encontrado"
  late AnimationController _foundAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Listener para o provider
  VoidCallback? _providerListener;

  @override
  void initState() {
    super.initState();
    _foundAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _foundAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _foundAnimationController, curve: Curves.easeIn),
    );

    // Acede ao provider e configura o listener e o estado inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final rideProvider = Provider.of<RideRequestProvider>(
        context,
        listen: false,
      );
      _handleProviderStatusChange(
        rideProvider.status,
      ); // Lida com o estado inicial

      // Adiciona um listener para futuras mudanças de estado do provider
      _providerListener = () {
        if (!mounted) return;
        _handleProviderStatusChange(rideProvider.status);
      };
      rideProvider.addListener(_providerListener!);
    });
  }

  // Lida com as mudanças de estado vindas do RideRequestProvider
  void _handleProviderStatusChange(RideRequestStatus status) {
    if (!mounted) return;
    print(
      "SearchingDriverDialog: Provider status mudou para $status. Countdown: $_countdown",
    );

    if (status == RideRequestStatus.driverFound) {
      _timer?.cancel();
      _canRetryButtonBeActive = false;
      if (mounted)
        setState(() {}); // Garante que o botão "De Novo" atualize o estado
      _foundAnimationController.forward();
      Future.delayed(const Duration(seconds: 2), () {
        // Tempo para o utilizador ver a mensagem
        if (mounted) {
          Navigator.of(context).pop(true); // Retorna true indicando sucesso
        }
      });
    } else if (status == RideRequestStatus.notFound) {
      _timer?.cancel(); // Para o timer se o provider indicar que não encontrou
      if (mounted) {
        setState(() {
          _canRetryButtonBeActive = true; // Permite tentar de novo
        });
      }
    } else if (status == RideRequestStatus.searchingDriver) {
      // Se o estado voltar para searching (ex: após um retry), reinicia o timer
      if (!(_timer?.isActive ?? false)) {
        _startTimer();
      }
    } else if (status == RideRequestStatus.error ||
        status == RideRequestStatus.none) {
      // Se houver erro ou o estado for resetado (ex: cancelado pelo provider), fecha o diálogo
      _timer?.cancel();
      if (mounted && Navigator.canPop(context)) {
        // Verifica se pode dar pop
        Navigator.of(
          context,
        ).pop(false); // Retorna false indicando falha/cancelamento
      }
    }
  }

  void _startTimer() {
    print("SearchingDriverDialog: Iniciando timer de 90 segundos.");
    if (mounted) {
      setState(() {
        _canRetryButtonBeActive = false;
        _countdown = 90; // Reseta o contador
      });
    }
    _timer?.cancel(); // Cancela qualquer timer anterior
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final rideProvider = Provider.of<RideRequestProvider>(
        context,
        listen: false,
      );
      if (mounted) {
        setState(() {
          if (_countdown > 0) {
            _countdown--;
          } else {
            timer.cancel();
            _canRetryButtonBeActive = true;
            // Se o tempo esgotou e o provider ainda está a procurar,
            // o provider DEVE mudar o seu próprio estado para notFound.
            // Este diálogo apenas reage ao estado do provider.
            if (rideProvider.status == RideRequestStatus.searchingDriver) {
              print(
                "SearchingDriverDialog: Timer esgotado, provider ainda em searchingDriver. O provider deve mudar para notFound.",
              );
              // Opcional: Forçar o provider a mudar para notFound se ele não o fizer sozinho
              // rideProvider.searchTimeout(); // Método a ser criado no provider
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _foundAnimationController.dispose();
    // Remove o listener ao sair
    if (_providerListener != null) {
      Provider.of<RideRequestProvider>(
        context,
        listen: false,
      ).removeListener(_providerListener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ouve o RideRequestProvider para o estado atual da busca
    // Não precisamos de um Consumer aqui se já temos um listener no initState/didChangeDependencies
    // que chama setState. Mas para consistência e para garantir que a UI sempre reflete
    // o estado mais recente do provider, um Consumer é uma boa prática.
    // No entanto, como _handleProviderStatusChange já chama setState,
    // podemos apenas ler o provider aqui.
    final rideProvider = Provider.of<RideRequestProvider>(context);
    Widget content;
    final currentStatus = rideProvider.status;

    // Define o conteúdo do diálogo com base no estado do provider
    if (currentStatus == RideRequestStatus.searchingDriver) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlobalPulsingLogoLoader(
            imagePath: widget.logoPath,
            size: 70,
            logoColor: Colors.white,
          ),
          const SizedBox(height: 24),
          const Text(
            "Procurando entregador...",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            "$_countdown s",
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    } else if (currentStatus == RideRequestStatus.notFound) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sentiment_dissatisfied_outlined,
            color: Colors.orangeAccent,
            size: 70,
          ),
          const SizedBox(height: 20),
          Text(
            rideProvider.errorMessage ?? "Nenhum entregador encontrado.",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            "Tente novamente ou cancele.",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
        ],
      );
    } else if (currentStatus == RideRequestStatus.driverFound) {
      content = ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.greenAccent.shade400,
                size: 70,
              ),
              const SizedBox(height: 16),
              Text(
                "Entregador Encontrado!",
                style: TextStyle(
                  color: Colors.greenAccent.shade400,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "A sua Levva está a caminho.",
                style: TextStyle(color: Colors.white70, fontSize: 15),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } else {
      // Estados como error, none, etc.
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 70,
          ),
          const SizedBox(height: 20),
          Text(
            rideProvider.errorMessage ?? "Ocorreu um problema na busca.",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Dialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            content,
            const SizedBox(height: 30),
            // Botões só aparecem se não encontrou ou ainda está procurando
            // e se o entregador ainda não foi encontrado.
            if (currentStatus == RideRequestStatus.searchingDriver ||
                currentStatus == RideRequestStatus.notFound)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _timer?.cancel(); // Para o timer local
                        widget
                            .onCancelDialog(); // Chama o callback original passado ao widget
                        // rideProvider.cancelSearch(); // O provider já deve ser notificado pelo onCancelDialog
                        // ou o onCancelDialog pode chamar rideProvider.cancelSearch()
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white, // Cor do texto
                        side: const BorderSide(color: Colors.white, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        "Cancelar",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      // Habilita o botão "De Novo" se _canRetryButtonBeActive for true E o status for notFound
                      onPressed:
                          _canRetryButtonBeActive &&
                                  currentStatus == RideRequestStatus.notFound
                              ? () {
                                widget
                                    .onRetrySearch(); // Chama o callback original
                                // rideProvider.searchForDriver(); // O onRetrySearch deve chamar isso
                              }
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _canRetryButtonBeActive &&
                                    currentStatus == RideRequestStatus.notFound
                                ? Colors.white
                                : Colors.grey.shade700,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        // Texto do botão "De Novo" ou o contador
                        _canRetryButtonBeActive &&
                                currentStatus == RideRequestStatus.notFound
                            ? "De Novo"
                            : (_countdown > 0 &&
                                    currentStatus ==
                                        RideRequestStatus.searchingDriver
                                ? "$_countdown s"
                                : "Aguarde..."),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
