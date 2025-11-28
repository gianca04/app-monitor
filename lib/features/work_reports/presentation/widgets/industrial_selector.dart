import 'package:flutter/material.dart';

// --- CONSTANTES DE DISEÑO INDUSTRIAL ---
const Color kIndBg = Color(0xFF1F1F1F);
const Color kIndSurface = Color(0xFF121212);
const Color kIndBorder = Colors.white24;
const Color kIndAccent = Colors.amber;
const double kIndRadius = 4.0;

class IndustrialSelector extends StatelessWidget {
  final String label;
  final String? value;
  final String? subValue;
  final IconData icon;
  final VoidCallback onTap;

  const IndustrialSelector({
    required this.label,
    required this.value,
    this.subValue,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: kIndSurface,
          border: Border.all(color: hasValue ? kIndAccent : kIndBorder),
          borderRadius: BorderRadius.circular(kIndRadius),
        ),
        child: Row(
          children: [
            Icon(icon, color: hasValue ? kIndAccent : Colors.grey),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value ?? 'SELECCIONAR',
                    style: TextStyle(
                      color: hasValue ? Colors.white : Colors.white30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subValue != null)
                    Text(
                      subValue!,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
