// lib/widgets/option_selection_card.dart
import 'package:flutter/material.dart';
import 'package:levva/models/enums.dart';

// T é o tipo das opções (ex: DeliveryType, VehicleType, PaymentType)
class OptionSelectionCard<T> extends StatelessWidget {
  final String title; // Título da seção de opções
  final IconData? sectionIcon; // Ícone opcional para a seção
  final List<T> options; // Lista das opções disponíveis
  final T groupValue; // O valor atualmente selecionado
  final ValueChanged<T?> onChanged; // Callback quando uma opção é selecionada
  final String Function(T option)
  getOptionLabel; // Função para obter o rótulo da opção
  final IconData? Function(T option)?
  getOptionIcon; // Função opcional para obter o ícone da opção

  const OptionSelectionCard({
    super.key,
    required this.title,
    this.sectionIcon,
    required this.options,
    required this.groupValue,
    required this.onChanged,
    required this.getOptionLabel,
    this.getOptionIcon,
    VehicleType? value,
    required void Function(dynamic type) onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (sectionIcon != null) ...[
              Icon(
                sectionIcon,
                color: theme.textTheme.titleMedium?.color,
                size: 20,
              ),
              const SizedBox(width: 8),
            ],
            Text(title, style: theme.textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8.0, // Espaço horizontal entre os chips
          runSpacing: 8.0, // Espaço vertical entre as linhas de chips
          children:
              options.map((option) {
                final bool isSelected = option == groupValue;
                final IconData? optionIconData =
                    getOptionIcon != null ? getOptionIcon!(option) : null;
                return ChoiceChip(
                  label: Text(getOptionLabel(option)),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    if (selected) {
                      onChanged(option);
                    }
                    // Se você quiser permitir desmarcar, precisaria de uma lógica adicional
                    // ou um tipo de chip diferente, pois ChoiceChip geralmente não desmarca
                    // por si só quando parte de um grupo.
                  },
                  avatar:
                      optionIconData != null
                          ? Icon(
                            optionIconData,
                            color:
                                isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface.withOpacity(
                                      0.7,
                                    ),
                            size: 18,
                          )
                          : null,
                  selectedColor: theme.primaryColor,
                  labelStyle: TextStyle(
                    color:
                        isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(
                    0.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    side: BorderSide(
                      color:
                          isSelected
                              ? theme.primaryColor
                              : const Color.fromARGB(255, 7, 5, 5),
                      width: 1.2,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8.0,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}
