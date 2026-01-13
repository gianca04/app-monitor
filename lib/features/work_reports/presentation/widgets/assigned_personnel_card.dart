import 'package:flutter/material.dart';
import '../../../../core/theme_config.dart'; // Tu archivo de tema
import '../../domain/models/personnel.dart'; // Tu modelo

class AssignedPersonnelCard extends StatelessWidget {
  final PersonnelItem person;
  final VoidCallback onEdit;

  const AssignedPersonnelCard({
    super.key,
    required this.person,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(
          0xFF151B22,
        ), // Fondo oscuro tipo tarjeta (Ajustar a tu AppTheme)
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER: ICONO + INFO + BADGE ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono circular verde con check
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2421), // Verde oscuro fondo
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                ),
                child: const Icon(
                  Icons.check,
                  color: AppTheme.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Datos del empleado
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fila ID y Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (person.employeeId != null)
                          Text(
                            "ID: ${person.employeeId}",
                            style: const TextStyle(
                              color:
                                  Colors.blueAccent, // Color cyan/azul del ID
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        // Badge de REGISTERED
                        if (!person.isNotRegistered)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF0D2421,
                              ), // Fondo verde oscuro
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppTheme.success.withOpacity(0.3),
                              ),
                            ),
                            child: const Text(
                              "REGISTERED",
                              style: TextStyle(
                                color: AppTheme.success,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Nombre
                    Text(
                      person.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // Cargo (Role)
                    Text(
                      person.positionName,
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                  ],
                ),
              ),
              // Menú de opciones (3 puntitos)
              IconButton(
                icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),

          // --- FOOTER: MAN-HOURS ---
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "MAN-HOURS (DAILY/ASSIGNED)", // Ajustado a tu contexto
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: person.hh.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(
                      text: " HRS",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
