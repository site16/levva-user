import 'dart:async';
import 'package:flutter/material.dart';
import 'package:levva/models/enums.dart';
import 'package:provider/provider.dart';
import '../providers/ride_request_provider.dart';
import 'global_pulsing_logo_loader.dart';

class SearchingDriverDialog extends StatefulWidget {
  final String logoPath;
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
  int _countdown = 90;
  bool _canRetryButtonBeActive = false;

  late AnimationController _foundAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  VoidCallback? _providerListener;
  RideRequestProvider? _rideProvider;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final rideProvider = Provider.of<RideRequestProvider>(
        context,
        listen: false,
      );
      _rideProvider = rideProvider;
      _handleProviderStatusChange(rideProvider.status);

      _providerListener = () {
        if (!mounted) return;
        _handleProviderStatusChange(rideProvider.status);
      };
      rideProvider.addListener(_providerListener!);
    });
  }

  void _handleProviderStatusChange(RideRequestStatus status) {
    if (!mounted) return;

    if (status == RideRequestStatus.driverFound) {
      _timer?.cancel();
      _canRetryButtonBeActive = false;
      setState(() {});
      _foundAnimationController.forward();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      });
    } else if (status == RideRequestStatus.notFound) {
      _timer?.cancel();
      setState(() {
        _canRetryButtonBeActive = true;
      });
    } else if (status == RideRequestStatus.searchingDriver) {
      if (!(_timer?.isActive ?? false)) {
        _startTimer();
      }
    } else if (status == RideRequestStatus.error ||
        status == RideRequestStatus.none) {
      _timer?.cancel();
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop(false);
      }
    }
  }

  void _startTimer() {
    if (mounted) {
      setState(() {
        _canRetryButtonBeActive = false;
        _countdown = 90;
      });
    }
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          timer.cancel();
          _canRetryButtonBeActive = true;
          if (_rideProvider?.status == RideRequestStatus.searchingDriver) {
            // O provider deve mudar para notFound; se quiser, pode forçar aqui.
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _foundAnimationController.dispose();
    // Remover o listener sem usar Provider.of(context)
    if (_providerListener != null && _rideProvider != null) {
      _rideProvider!.removeListener(_providerListener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rideProvider = Provider.of<RideRequestProvider>(context);
    final currentStatus = rideProvider.status;
    Widget content;

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
          const Icon(
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
            if (currentStatus == RideRequestStatus.searchingDriver ||
                currentStatus == RideRequestStatus.notFound)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _timer?.cancel();
                        widget.onCancelDialog();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
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
                      onPressed: _canRetryButtonBeActive &&
                              currentStatus == RideRequestStatus.notFound
                          ? () {
                              widget.onRetrySearch();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _canRetryButtonBeActive &&
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