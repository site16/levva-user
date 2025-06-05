import 'dart:async';
import 'package:flutter/material.dart';
import 'package:levva/widgets/delivery_options_bottom_sheet.dart';
import 'dart:ui'; // Para ImageFilter
import 'package:provider/provider.dart';

// Importações Corretas:
import '../../providers/ride_request_provider.dart'; // Importa RideRequestProvider, RideRequestStatus, PlaceDetail
import '../widgets/pulsing_logo_loader.dart'; // Importa o loader personalizado

// AS DEFINIÇÕES DUPLICADAS DE RideRequestStatus, PlaceDetail, e RideRequestProvider FORAM REMOVIDAS DAQUI.

class AddressSearchBottomSheet extends StatefulWidget {
  const AddressSearchBottomSheet({super.key});

  @override
  State<AddressSearchBottomSheet> createState() =>
      _AddressSearchBottomSheetState();
}

class _AddressSearchBottomSheetState extends State<AddressSearchBottomSheet> {
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  List<Map<String, String>> _originAutocompleteResults = [];
  List<Map<String, String>> _destinationAutocompleteResults = [];

  final FocusNode _originFocusNode = FocusNode();
  final FocusNode _destinationFocusNode = FocusNode();

  Timer? _debounceOrigin;
  Timer? _debounceDestination;

  bool _isLoadingOriginSuggestions = false;
  bool _isLoadingDestinationSuggestions = false;
  bool _canProceed = false;

  // Caminho para o logo (ajuste se necessário, ou passe como parâmetro)
  static const String _logoPath =
      'assets/images/levva_icon_transp.png'; // Logo colorido para fundo claro
  // static const String _logoPathWhite = 'assets/images/levva_icon_transp_branco.png'; // Logo branco

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rideRequestProvider = Provider.of<RideRequestProvider>(
        context,
        listen: false,
      );
      print(
        "AddressSearchBottomSheet initState: Verificando provider inicial...",
      );
      if (rideRequestProvider.origin != null) {
        _originController.text = rideRequestProvider.origin!.name;
        print(
          "AddressSearchBottomSheet initState: Origem do provider preenchida: ${rideRequestProvider.origin!.name}",
        );
      } else {
        _originController.text =
            ""; // Garante que esteja vazio se não houver origem
        print(
          "AddressSearchBottomSheet initState: Nenhuma origem no provider.",
        );
      }
      if (rideRequestProvider.destination != null) {
        _destinationController.text = rideRequestProvider.destination!.name;
        print(
          "AddressSearchBottomSheet initState: Destino do provider preenchido: ${rideRequestProvider.destination!.name}",
        );
      } else {
        print(
          "AddressSearchBottomSheet initState: Nenhum destino no provider.",
        );
      }
      _updateCanProceed();
    });

    _originController.addListener(() {
      _updateCanProceed();
      if (_originFocusNode.hasFocus) {
        if (_debounceOrigin?.isActive ?? false) _debounceOrigin!.cancel();
        _debounceOrigin = Timer(const Duration(milliseconds: 400), () {
          if (_originController.text.length > 2) {
            _searchAddress(_originController.text, true);
          } else {
            if (mounted) setState(() => _originAutocompleteResults = []);
          }
        });
      }
    });

    _destinationController.addListener(() {
      _updateCanProceed();
      if (_destinationFocusNode.hasFocus) {
        if (_debounceDestination?.isActive ?? false)
          _debounceDestination!.cancel();
        _debounceDestination = Timer(const Duration(milliseconds: 400), () {
          if (_destinationController.text.length > 2) {
            _searchAddress(_destinationController.text, false);
          } else {
            if (mounted) setState(() => _destinationAutocompleteResults = []);
          }
        });
      }
    });

    _originFocusNode.addListener(() {
      if (!_originFocusNode.hasFocus && mounted) {
        Future.delayed(const Duration(milliseconds: 200), () {
          // Delay para permitir clique na lista
          if (mounted && !_originFocusNode.hasFocus) {
            // Verifica novamente se o foco ainda não voltou
            setState(() => _originAutocompleteResults = []);
          }
        });
      } else if (_originFocusNode.hasFocus &&
          _originController.text.length > 2 &&
          mounted) {
        _searchAddress(
          _originController.text,
          true,
        ); // Busca ao focar se já houver texto
      }
    });

    _destinationFocusNode.addListener(() {
      if (!_destinationFocusNode.hasFocus && mounted) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && !_destinationFocusNode.hasFocus) {
            setState(() => _destinationAutocompleteResults = []);
          }
        });
      } else if (_destinationFocusNode.hasFocus &&
          _destinationController.text.length > 2 &&
          mounted) {
        _searchAddress(_destinationController.text, false);
      }
    });
  }

  void _updateCanProceed() {
    if (!mounted) return;
    final rideProvider = Provider.of<RideRequestProvider>(
      context,
      listen: false,
    );
    final bool originTextNotEmpty = _originController.text.isNotEmpty;
    final bool destinationTextNotEmpty = _destinationController.text.isNotEmpty;
    final bool providerOriginSet = rideProvider.origin != null;
    final bool providerDestinationSet = rideProvider.destination != null;

    // Para prosseguir, ambos os campos de texto devem ter algum conteúdo E
    // ambos (origem e destino) devem ter sido definidos no provider (ou seja, selecionados da lista).
    final bool canProceedNow =
        originTextNotEmpty &&
        destinationTextNotEmpty &&
        providerOriginSet &&
        providerDestinationSet;

    // Debug prints (remover em produção)
    // print("--- _updateCanProceed ---");
    // print("Origin Text: '${_originController.text}', Provider Origin Set: $providerOriginSet (Nome: ${rideProvider.origin?.name})");
    // print("Dest Text: '${_destinationController.text}', Provider Dest Set: $providerDestinationSet (Nome: ${rideProvider.destination?.name})");
    // print("Can Proceed Now: $canProceedNow, Current _canProceed State: $_canProceed");
    // print("-------------------------");

    if (canProceedNow != _canProceed) {
      setState(() {
        _canProceed = canProceedNow;
      });
    }
  }

  Future<void> _searchAddress(String query, bool isOrigin) async {
    if (!mounted) return;
    final rideProvider = Provider.of<RideRequestProvider>(
      context,
      listen: false,
    );

    setState(() {
      if (isOrigin)
        _isLoadingOriginSuggestions = true;
      else
        _isLoadingDestinationSuggestions = true;
    });

    try {
      final results = await rideProvider.getAutocompleteSuggestions(query);
      if (mounted) {
        setState(() {
          if (isOrigin) {
            _originAutocompleteResults = results;
          } else {
            _destinationAutocompleteResults = results;
          }
        });
      }
    } catch (e) {
      print("AddressSearchBottomSheet: Erro ao buscar sugestões: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Erro ao buscar: ${e.toString().substring(0, (e.toString().length > 60) ? 60 : e.toString().length)}...",
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          if (isOrigin)
            _isLoadingOriginSuggestions = false;
          else
            _isLoadingDestinationSuggestions = false;
        });
      }
    }
  }

  Future<void> _selectPlace(
    Map<String, String> placeData,
    bool isOrigin,
  ) async {
    if (!mounted) return;
    final rideProvider = Provider.of<RideRequestProvider>(
      context,
      listen: false,
    );
    final String description = placeData['description']!;
    final String placeId = placeData['place_id']!;

    // Mostra feedback visual que algo está acontecendo
    setState(() {
      if (isOrigin) {
        _isLoadingOriginSuggestions = true; // Reutiliza o loader
        _originController.text = description; // Atualiza o texto imediatamente
        _originAutocompleteResults = [];
      } else {
        _isLoadingDestinationSuggestions = true;
        _destinationController.text = description;
        _destinationAutocompleteResults = [];
      }
    });

    try {
      final PlaceDetail? placeDetail = await rideProvider
          .getPlaceDetailsFromPlaceId(placeId, description);

      if (placeDetail != null) {
        if (isOrigin) {
          await rideProvider.setOrigin(
            placeDetail.location,
            placeDetail.name,
            address: placeDetail.address,
            placeId: placeDetail.placeId,
          );
          // _originController.text já foi atualizado
          if (mounted)
            FocusScope.of(context).requestFocus(_destinationFocusNode);
        } else {
          await rideProvider.setDestination(
            placeDetail.location,
            placeDetail.name,
            address: placeDetail.address,
            placeId: placeDetail.placeId,
          );
          // _destinationController.text já foi atualizado
          if (mounted) FocusScope.of(context).unfocus();
        }
        _updateCanProceed(); // Importante chamar após definir no provider
      } else {
        throw Exception("Detalhes do local não encontrados.");
      }
    } catch (e) {
      print(
        "AddressSearchBottomSheet _selectPlace: Erro ao selecionar local: $e",
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Erro ao obter detalhes: ${e.toString().substring(0, (e.toString().length > 60) ? 60 : e.toString().length)}...",
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        // Reverte o texto se a seleção falhar
        setState(() {
          if (isOrigin)
            _originController.clear();
          else
            _destinationController.clear();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          // Limpa os loaders independentemente do resultado
          _isLoadingOriginSuggestions = false;
          _isLoadingDestinationSuggestions = false;
        });
      }
    }
  }

  void _proceedToDeliveryOptions() {
    if (!mounted) return;
    final rideProvider = Provider.of<RideRequestProvider>(
      context,
      listen: false,
    );

    _updateCanProceed(); // Garante que _canProceed está atualizado antes de verificar

    if (_canProceed) {
      Navigator.of(context).pop(); // Fecha o AddressSearchBottomSheet

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (BuildContext bc) {
          return ChangeNotifierProvider.value(
            value: rideProvider,
            child: const DeliveryOptionsBottomSheet(),
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Selecione uma origem e um destino válidos da lista."),
          backgroundColor: Colors.orangeAccent,
        ),
      );
    }
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _originFocusNode.dispose();
    _destinationFocusNode.dispose();
    _debounceOrigin?.cancel();
    _debounceDestination?.cancel();
    super.dispose();
  }

  Widget _buildAddressTextFieldWidget({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required IconData leadingIcon,
    required bool isOriginField, // Para o ícone do pin
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      style: const TextStyle(fontSize: 16, color: Colors.black87),
      cursorColor: Colors.black,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: Icon(leadingIcon, color: Colors.black87, size: 22),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                onPressed: () {
                  controller.clear();
                  final rideProvider = Provider.of<RideRequestProvider>(
                    context,
                    listen: false,
                  );
                  if (isOriginField) {
                    rideProvider.clearOrigin();
                    if (mounted)
                      setState(() => _originAutocompleteResults = []);
                  } else {
                    rideProvider.clearDestination();
                    if (mounted)
                      setState(() => _destinationAutocompleteResults = []);
                  }
                  _updateCanProceed(); // Atualiza o estado do botão Continuar
                },
              ),
            // O onPinTap foi removido temporariamente conforme seu código anterior.
            // Se precisar dele, descomente e passe a função.
            // if (onPinTap != null)
            //   IconButton(
            //     icon: const Icon(Icons.push_pin_outlined, color: Colors.black87, size: 22),
            //     onPressed: onPinTap,
            //     tooltip: 'Marcar no mapa',
            //   ),
          ],
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Colors.black, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSearchResultsList(
    List<Map<String, String>> results,
    bool isOrigin,
  ) {
    if (results.isEmpty) return const SizedBox.shrink();

    return Material(
      // Adiciona Material para elevação e cor de fundo
      elevation: 3.0, // Sombra sutil
      borderRadius: BorderRadius.circular(8.0),
      color: Colors.white, // Fundo da lista de resultados
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height * 0.25, // Limita a altura
        ),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: results.length,
          itemBuilder: (context, index) {
            final placeData = results[index];
            return ListTile(
              title: Text(
                placeData['description']!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              leading: const Icon(
                Icons.location_on_outlined,
                color: Colors.grey,
              ),
              dense: true,
              onTap: () => _selectPlace(placeData, isOrigin),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    // Ajuste dinâmico da altura do BottomSheet (simplificado)
    double estimatedContentHeight =
        220; // Altura base (campos de texto, botão, etc.)
    if (_originFocusNode.hasFocus && _originAutocompleteResults.isNotEmpty) {
      estimatedContentHeight += (_originAutocompleteResults.length * 48.0)
          .clamp(0, 120.0); // Altura da lista de origem
    }
    if (_destinationFocusNode.hasFocus &&
        _destinationAutocompleteResults.isNotEmpty) {
      estimatedContentHeight += (_destinationAutocompleteResults.length * 48.0)
          .clamp(0, 120.0); // Altura da lista de destino
    }

    final initialSheetHeightFactor = (estimatedContentHeight / screenHeight)
        .clamp(0.35, 0.90); // Clamp entre 35% e 90%

    return DraggableScrollableSheet(
      initialChildSize: initialSheetHeightFactor,
      minChildSize: 0.3, // Mínimo de 30% da tela
      maxChildSize: 0.9, // Máximo de 90% da tela
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return BackdropFilter(
          // Efeito de desfoque no fundo
          filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
          child: Container(
            padding: const EdgeInsets.only(top: 12.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.96), // Leve transparência
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 15.0,
                  spreadRadius: 2.0,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  // "Handle" para indicar que é arrastável
                  width: 50,
                  height: 6,
                  margin: const EdgeInsets.only(bottom: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    children: [
                      _buildAddressTextFieldWidget(
                        controller: _originController,
                        focusNode: _originFocusNode,
                        hintText: 'Ponto de Partida',
                        leadingIcon: Icons.trip_origin_outlined,
                        isOriginField: true,
                        // onPinTap: () { Navigator.of(context).pop(); /* Lógica para marcar no mapa */ },
                      ),
                      // Loader ou Resultados para Origem
                      if (_originFocusNode.hasFocus &&
                          _isLoadingOriginSuggestions)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: PulsingLogoLoader(
                              imagePath: _logoPath,
                              size: 30,
                            ),
                          ),
                        )
                      else if (_originFocusNode.hasFocus &&
                          !_isLoadingOriginSuggestions)
                        _buildSearchResultsList(
                          _originAutocompleteResults,
                          true,
                        ),

                      const SizedBox(height: 10),
                      _buildAddressTextFieldWidget(
                        controller: _destinationController,
                        focusNode: _destinationFocusNode,
                        hintText: 'Para onde vamos?',
                        leadingIcon: Icons.location_on_outlined,
                        isOriginField: false,
                        // onPinTap: () { Navigator.of(context).pop(); /* Lógica para marcar no mapa */ },
                      ),
                      // Loader ou Resultados para Destino
                      if (_destinationFocusNode.hasFocus &&
                          _isLoadingDestinationSuggestions)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: PulsingLogoLoader(
                              imagePath: _logoPath,
                              size: 30,
                            ),
                          ),
                        )
                      else if (_destinationFocusNode.hasFocus &&
                          !_isLoadingDestinationSuggestions)
                        _buildSearchResultsList(
                          _destinationAutocompleteResults,
                          false,
                        ),

                      const SizedBox(height: 24), // Espaço antes do botão
                    ],
                  ),
                ),
                // Botão Continuar
                // Garante que o botão fique visível e no final do BottomSheet
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    bottom: 16.0,
                    top: 8.0,
                  ),
                  child: ElevatedButton(
                    onPressed:
                        _canProceed
                            ? _proceedToDeliveryOptions
                            : null, // Habilita/desabilita
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _canProceed ? Colors.black : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          12.0,
                        ), // Borda mais suave
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ).copyWith(
                      elevation: MaterialStateProperty.all(
                        _canProceed ? 2.0 : 0.0,
                      ), // Elevação condicional
                    ),
                    child: const Text(
                      'Continuar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
