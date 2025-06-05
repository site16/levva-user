// lib/widgets/promotional_carousel_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';
// Ajuste o caminho se o seu modelo estiver em outro lugar
import '../models/carousel_item_data.dart';

class PromotionalCarouselWidget extends StatefulWidget {
  final List<CarouselItemData> items;
  final double height;
  final bool autoPlay;
  final Duration autoPlayDuration;

  const PromotionalCarouselWidget({
    super.key,
    required this.items,
    this.height = 130.0,
    this.autoPlay = true,
    this.autoPlayDuration = const Duration(seconds: 5),
  });

  @override
  State<PromotionalCarouselWidget> createState() => _PromotionalCarouselWidgetState();
}

class _PromotionalCarouselWidgetState extends State<PromotionalCarouselWidget> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage, viewportFraction: 0.9); // Para ver um pouco dos cards vizinhos
    if (widget.autoPlay && widget.items.length > 1) {
      _timer = Timer.periodic(widget.autoPlayDuration, (Timer timer) {
        if (_currentPage < widget.items.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeIn,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return SizedBox(height: widget.height); // Retorna vazio se não houver itens
    }

    return SizedBox(
      height: widget.height,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.items.length,
        onPageChanged: (int page) {
          setState(() {
            _currentPage = page;
          });
        },
        itemBuilder: (context, index) {
          final item = widget.items[index];
          // Efeito de escala para o item central (opcional)
          // double scale = (_currentPage == index) ? 1.0 : 0.95;
          // Matrix4 matrix = Matrix4.identity()..scale(scale, scale);

          return //Transform.value(
            //matrix: matrix,
            //alignment: Alignment.center,
            //child: 
            InkWell(
              onTap: item.onTap,
              child: Card(
                elevation: 2.0,
                margin: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0), // Margem entre os cards
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                color: item.backgroundColor,
                clipBehavior: Clip.antiAlias, // Para a imagem respeitar as bordas
                child: Stack(
                  children: [
                    if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                      Positioned.fill(
                        child: Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          color: Colors.black.withOpacity(0.2), // Leve escurecida para o texto destacar
                          colorBlendMode: BlendMode.darken,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: item.imageUrl != null ? Colors.white : Colors.black.withOpacity(0.7),
                               shadows: item.imageUrl != null ? [const Shadow(blurRadius: 2, color: Colors.black54)] : [],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: item.imageUrl != null ? Colors.white.withOpacity(0.9) : Colors.black.withOpacity(0.6),
                              shadows: item.imageUrl != null ? [const Shadow(blurRadius: 1, color: Colors.black45)] : [],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            //),
          );
        },
      ),
    );
  }
}