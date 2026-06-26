import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:monitor/core/widgets/industrial_feedback.dart';
import '../../../../core/widgets/connectivity_indicator.dart';
import '../../../../features/settings/providers/connectivity_preferences_provider.dart';
import '../../../../core/theme_config.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _rememberMe = true;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final connectivityAsync = ref.watch(connectivityStatusProvider);

    if (authState.isChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.response != null && previous?.response == null) {
        IndustrialFeedback.showSuccess(
          context,
          message: 'LOGIN EXITOSO: CREDENCIALES VERIFICADAS',
        );

        // 3. Navegación
        context.go('/home');
      }

      if (next.error != null && next.error != previous?.error) {
        IndustrialFeedback.showError(
          context,
          message: next.error!,
        );
      }
    });

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/png/auth_background.png',
            fit: BoxFit.fitHeight,
          ),

          Container(color: Colors.black.withOpacity(0.3)),

          // Indicador de conexión (solo visual)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0, right: 16.0),
              child: Align(
                alignment: Alignment.topRight,
                child: connectivityAsync.when(
                  data: (isOnline) => ConnectivityIndicator(
                    mode: ConnectivityDisplayMode.iconOnly,
                    showWhenOnline: null,
                    isOnline: isOnline,
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (error, stack) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),

          // Formulario
          Center(
            child: _SignInForm(
              formKey: _formKey,
              emailController: _emailController,
              passwordController: _passwordController,
              rememberMe: _rememberMe,
              onRememberMeChanged: (value) {
                setState(() {
                  _rememberMe = value ?? false;
                });
              },
              onLoginPressed: _login,
              isLoading: authState.isLoading,
              error: authState.error,
              isPasswordVisible: _isPasswordVisible,
              onTogglePasswordVisibility: _togglePasswordVisibility,
              connectivityAsync: connectivityAsync,
            ),
          ),
        ],
      ),
    );
  }

  void _login() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      ref
          .read(authProvider.notifier)
          .login(_emailController.text, _passwordController.text);
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }
}

class _SignInForm extends StatefulWidget {
  const _SignInForm({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.rememberMe,
    required this.onRememberMeChanged,
    required this.onLoginPressed,
    required this.isLoading,
    this.error,
    required this.isPasswordVisible,
    required this.onTogglePasswordVisibility,
    required this.connectivityAsync,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool rememberMe;
  final ValueChanged<bool?> onRememberMeChanged;
  final VoidCallback onLoginPressed;
  final bool isLoading;
  final String? error;
  final bool isPasswordVisible;
  final VoidCallback onTogglePasswordVisibility;
  final AsyncValue<bool> connectivityAsync;

  @override
  State<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<_SignInForm> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      color: AppTheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Container(
        padding: const EdgeInsets.all(32.0),
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Form(
            key: widget.formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset('assets/images/svg/logo.svg', height: 100),
                const SizedBox(height: 6),
                Text(
                  'Ingrese sus credenciales',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF1A1A1A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Campo correo
                TextFormField(
                  controller: widget.emailController,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF1A1A1A),
                  ),
                  cursorColor: const Color(0xFF2d9292),
                  decoration: InputDecoration(
                    labelText: 'Correo Electrónico',
                    labelStyle: const TextStyle(color: Color(0xFF4A4A4A)),
                    floatingLabelStyle: const TextStyle(
                      color: Color(0xFF2d9292),
                    ),
                    hintText: 'ejemplo@correo.com',
                    hintStyle: const TextStyle(color: Color(0xFF9B9B9B)),
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Color(0xFF4A4A4A),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFD1D1D1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF2d9292),
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFDC2626)),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFFDC2626),
                        width: 2,
                      ),
                    ),
                    errorStyle: const TextStyle(color: Color(0xFFDC2626)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Campo contraseña
                TextFormField(
                  controller: widget.passwordController,
                  obscureText: !widget.isPasswordVisible,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF1A1A1A),
                  ),
                  cursorColor: const Color(0xFF2d9292),
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    labelStyle: const TextStyle(color: Color(0xFF4A4A4A)),
                    floatingLabelStyle: const TextStyle(
                      color: Color(0xFF2d9292),
                    ),
                    hintStyle: const TextStyle(color: Color(0xFF9B9B9B)),
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: Color(0xFF4A4A4A),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFD1D1D1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF2d9292),
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFDC2626)),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFFDC2626),
                        width: 2,
                      ),
                    ),
                    errorStyle: const TextStyle(color: Color(0xFFDC2626)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        widget.isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: const Color(0xFF4A4A4A),
                      ),
                      onPressed: widget.onTogglePasswordVisibility,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su contraseña';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Checkbox
                Theme(
                  data: Theme.of(context).copyWith(
                    checkboxTheme: CheckboxThemeData(
                      fillColor: WidgetStateProperty.resolveWith<Color?>((
                        states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return const Color(0xFF2d9292);
                        }
                        return const Color(0xFFD1D1D1);
                      }),
                      checkColor: WidgetStateProperty.all(Colors.white),
                    ),
                  ),
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: widget.rememberMe,
                    onChanged: widget.onRememberMeChanged,
                    title: const Text(
                      'Recordarme',
                      style: TextStyle(color: Color(0xFF4A4A4A)),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 32,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: widget.isLoading ? null : widget.onLoginPressed,
                  child: widget.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Ingresar',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
