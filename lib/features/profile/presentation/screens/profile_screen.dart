import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharedPreferences = ref.watch(sharedPreferencesProvider);
    final theme = Theme.of(context);

    final userName = sharedPreferences.getString('user_name') ?? 'Usuario';
    final userEmail =
        sharedPreferences.getString('user_email') ?? 'email@ejemplo.com';
    final employeeFirstName =
        sharedPreferences.getString('employee_first_name') ?? '';
    final employeeLastName =
        sharedPreferences.getString('employee_last_name') ?? '';
    final employeePosition =
        sharedPreferences.getString('employee_position') ?? 'Posición';
    final employeeDocumentNumber =
        sharedPreferences.getString('employee_document_number') ?? 'Documento';

    final fullName = '$employeeFirstName $employeeLastName'.trim();
    final displayName = fullName.isNotEmpty ? fullName : userName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PERFIL'),
        elevation: 0, // REGLA: Sombras eliminadas
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      // CAMBIO CLAVE: Usar SingleChildScrollView para hacer la pantalla scrollable
      body: SingleChildScrollView(
        child: Column(
          children: [
            // El TopPortion necesita una altura fija ahora, ya que el padre ya no es un Column con Expanded
            const SizedBox(
              height: 250, // Altura fija para la porción superior (ajustable)
              child: _TopPortion(),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    displayName.toUpperCase(),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    employeePosition,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //_ActionButton(
                      //  onPressed: () {
                      //    // Acción para editar perfil
                      //  },
                      //  label: "EDITAR",
                      //  icon: Icons.edit,
                      //  color: theme.colorScheme.primary,
                      //),
                      const SizedBox(width: 16.0),
                      _ActionButton(
                        onPressed: () {
                          ref.read(authProvider.notifier).logout();
                        },
                        label: "CERRAR SESIÓN",
                        icon: Icons.logout,
                        color: theme.colorScheme.error,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white10), // REGLA: Separadores
                  const SizedBox(height: 16),
                  _ProfileInfoCard(
                    title: 'INFORMACIÓN PERSONAL',
                    items: [
                      _InfoItem(label: 'Email', value: userEmail),
                      _InfoItem(
                        label: 'Documento',
                        value: employeeDocumentNumber,
                      ),
                    ],
                  ),
                  // Agrega más elementos aquí si fuera necesario
                  const SizedBox(height: 16),
                  _ProfileInfoCard(
                    title: 'OTROS DATOS',
                    items: [
                      _InfoItem(label: 'Nombre de usuario', value: userName),
                      //_InfoItem(label: 'ID Empleado', value: '12345'),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Las clases _ActionButton, _ProfileInfoCard, _InfoItem y _TopPortion permanecen sin cambios
// a excepción de la eliminación de los Expanded en la clase principal.

class _ActionButton extends StatelessWidget {
  // ... código de _ActionButton sin cambios ...
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final Color color;

  const _ActionButton({
    required this.onPressed,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4), // REGLA: Bordes rectos
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: color,
            width: 1,
          ), // REGLA: Siempre con Border.all
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  final String title;
  final List<_InfoItem> items;

  const _ProfileInfoCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        border: Border.all(
          color: theme.colorScheme.outline,
          width: 1,
        ), // REGLA: Bordes con Border.all
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          ...items,
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$label:'.toUpperCase(),
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                letterSpacing: 0.5,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopPortion extends StatelessWidget {
  const _TopPortion();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 50),
          decoration: BoxDecoration(
            color: theme
                .colorScheme
                .surface, // Usar color del tema en lugar de gradiente
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(4), // REGLA: Bordes rectos
              bottomRight: Radius.circular(4),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: 120,
            height: 120,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.outline,
                  width: 2,
                ), // REGLA: Bordes
              ),
              child: Icon(
                Icons.person,
                size: 60,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}