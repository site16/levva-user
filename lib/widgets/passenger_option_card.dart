import 'package:flutter/material.dart';

class PassengerOptionCard extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const PassengerOptionCard({
    Key? key,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = isSelected ? Colors.black : Colors.white;
    final Color contentColor = isSelected ? Colors.white : Colors.black87;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isSelected ? 0.15 : 0.08),
                spreadRadius: 1,
                blurRadius: isSelected ? 4 : 2,
                offset: Offset(0, isSelected ? 2 : 1),
              ),
            ],
            border: Border.all(
              color: isSelected ? Colors.black : Colors.grey.shade300,
              width: isSelected ? 1.5 : 0.8,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.two_wheeler_outlined, color: contentColor, size: 26),
              const SizedBox(height: 8),
              Text(
                "Passageiro",
                style: TextStyle(
                  color: contentColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}