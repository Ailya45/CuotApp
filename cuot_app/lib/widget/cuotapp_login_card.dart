import 'package:cuot_app/Model/local_auth.dart';
import 'package:cuot_app/core/supabase/supabase_service.dart';
import 'package:cuot_app/ui/pages/dashboard_screen.dart';
import 'package:cuot_app/widget/login_form.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'cuotapp_social_buttons_row.dart';

// Servicio de autenticación biométrica
class BiometricAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!isAvailable || !isDeviceSupported) {
        return false;
      }

      final biometrics = await _localAuth.getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } catch (e) {
      print('Error verificando biometría: $e');
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason:
            'Autentícate para guardar tu huella y acceder más rápido',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      return isAuthenticated;
    } catch (e) {
      print('Error en autenticación: $e');
      return false;
    }
  }

  Future<void> saveBiometricCredentials(String email, String password) async {
    await _storage.write(key: 'biometric_email', value: email);
    await _storage.write(key: 'biometric_password', value: password);
    await _storage.write(key: 'biometric_enabled', value: 'true');
  }

  Future<Map<String, String?>> getBiometricCredentials() async {
    final email = await _storage.read(key: 'biometric_email');
    final password = await _storage.read(key: 'biometric_password');
    final enabled = await _storage.read(key: 'biometric_enabled');

    return {
      'email': email,
      'password': password,
      'enabled': enabled,
    };
  }

  Future<bool> hasBiometricCredentials() async {
    final email = await _storage.read(key: 'biometric_email');
    final password = await _storage.read(key: 'biometric_password');
    final enabled = await _storage.read(key: 'biometric_enabled');

    return email != null && password != null && enabled == 'true';
  }

  Future<void> clearBiometricCredentials() async {
    await _storage.delete(key: 'biometric_email');
    await _storage.delete(key: 'biometric_password');
    await _storage.delete(key: 'biometric_enabled');
  }
}

class CuotAppLoginCard extends StatefulWidget {
  final Color primaryGreen;

  const CuotAppLoginCard({super.key, required this.primaryGreen});

  @override
  State<CuotAppLoginCard> createState() => _CuotAppLoginCardState();
}

class _CuotAppLoginCardState extends State<CuotAppLoginCard> {
  final LoginForm _loginForm = LoginForm();
  final BiometricAuthService _biometricService = BiometricAuthService();

  bool _isLoading = false;
  bool _isBiometricLoading = false;
  bool _showBiometricButton = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkBiometricStatus();
  }

  Future<void> _checkBiometricStatus() async {
    final hasCredentials = await _biometricService.hasBiometricCredentials();
    final isAvailable = await _biometricService.isBiometricAvailable();

    setState(() {
      _showBiometricButton = hasCredentials && isAvailable;
    });

    print('🔍 Estado biometría:');
    print('  - Tiene credenciales: $hasCredentials');
    print('  - Biometría disponible: $isAvailable');
    print('  - Mostrar botón: ${hasCredentials && isAvailable}');
  }

  Future<void> _iniciarSesion({String? email, String? password}) async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final String correo = email ?? _loginForm.obtenerCorreo();
      final String contrasena = password ?? _loginForm.obtenerContrasena();

      if (correo.isEmpty || contrasena.isEmpty) {
        throw Exception('Por favor completa todos los campos');
      }

      print('📧 Intentando login con: $correo');

      final supabaseService = SupabaseService();

      final usuarios = await supabaseService.client
          .schema('Usuarios')
          .from('Credenciales')
          .select()
          .eq('Correo_Electronico', correo)
          .maybeSingle();

      if (usuarios == null) {
        throw Exception('Usuario no encontrado');
      }

      final contrasenaBD = usuarios['Contrasena'] ?? '';

      if (contrasena == contrasenaBD) {
        print('✅ Login exitoso para: $correo');

        final user = await supabaseService.client
            .schema("Usuarios")
            .from("Usuarios")
            .select("Nombre_Completo")
            .eq('Correo_Electronico', correo)
            .maybeSingle();

        final nombreCompleto = (user?['Nombre_Completo'] ?? '')
            .toString()
            .replaceAll('{', '')
            .replaceAll('}', '')
            .trim();
        final nombre = nombreCompleto;

        // Verificar si ya tiene credenciales guardadas
        final hasCredentials =
            await _biometricService.hasBiometricCredentials();

        // Variable para controlar si debemos navegar al dashboard
        bool shouldNavigateToDashboard = true;

        // Si NO tiene credenciales guardadas, preguntar antes de navegar
        if (!hasCredentials && mounted) {
          setState(() {
            _isLoading = false;
          });

          // Mostrar diálogo y esperar resultado
          final result =
              await _showEnableBiometricDialog(context, correo, contrasena);

          // Si el resultado es true, significa que ya autenticó con huella
          // y debemos navegar al dashboard
          shouldNavigateToDashboard = result ?? true;
        }

        // Navegar al Dashboard si es necesario
        if (shouldNavigateToDashboard && mounted) {
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (context) =>
                      DashboardScreen(correo: correo, userName: nombre)),
              (Route<dynamic> route) => false);
        }
      } else {
        throw Exception('Contraseña incorrecta');
      }
    } catch (e) {
      print('❌ Error en login: $e');

      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '');
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${e.toString().replaceAll('Exception:', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Diálogo para habilitar biometría - VERSIÓN CORREGIDA
  Future<bool?> _showEnableBiometricDialog(
      BuildContext context, String email, String password) async {
    // Primero preguntamos si quiere habilitar
    final shouldEnable = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🔐 ¿Habilitar huella dactilar?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                '¿Quieres habilitar la autenticación con huella dactilar '
                'para acceder más rápido en el futuro?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.fingerprint, color: widget.primaryGreen),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Podrás iniciar sesión con tu huella sin necesidad de escribir tu contraseña',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ahora no'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Habilitar'),
          ),
        ],
      ),
    );

    // Si no quiere habilitar, retornamos true para navegar al dashboard
    if (shouldEnable != true) {
      return true;
    }

    // Verificar disponibilidad de biometría
    final isAvailable = await _biometricService.isBiometricAvailable();

    if (!isAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Biometría no disponible en este dispositivo'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return true;
    }

    // Mostrar un mensaje indicando que debe colocar la huella
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('👆 Coloca tu huella en el sensor'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.blue,
        ),
      );
    }

    // Autenticar con biometría
    try {
      final authenticated =
          await _biometricService.authenticateWithBiometrics();

      if (authenticated) {
        await _biometricService.saveBiometricCredentials(email, password);

        // Actualizar estado para mostrar el botón
        setState(() {
          _showBiometricButton = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Huella dactilar habilitada correctamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ No se pudo verificar tu identidad'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error habilitando biometría: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    return true; // Navegar al dashboard
  }

  Future<void> _loginWithBiometrics() async {
    setState(() {
      _isBiometricLoading = true;
      _errorMessage = null;
    });

    try {
      final isAvailable = await _biometricService.isBiometricAvailable();

      if (!isAvailable) {
        _showSnackBar('❌ Biometría no disponible', Colors.orange);
        setState(() {
          _showBiometricButton = false;
        });
        return;
      }

      final credentials = await _biometricService.getBiometricCredentials();

      if (credentials['enabled'] != 'true' ||
          credentials['email'] == null ||
          credentials['password'] == null) {
        _showSnackBar('❌ No hay credenciales guardadas', Colors.orange);
        setState(() {
          _showBiometricButton = false;
        });
        return;
      }

      // Mostrar mensaje para colocar la huella
      _showSnackBar('👆 Coloca tu huella en el sensor', Colors.blue);

      final authenticated =
          await _biometricService.authenticateWithBiometrics();

      if (authenticated) {
        await _iniciarSesion(
          email: credentials['email']!,
          password: credentials['password']!,
        );
      } else {
        _showSnackBar('❌ Autenticación fallida', Colors.red);
      }
    } catch (e) {
      print('Error en login biométrico: $e');
      _showSnackBar('❌ Error: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isBiometricLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Método para eliminar huella (útil para pruebas)
  /*Future<void> _eliminarHuella() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🗑️ Eliminar huella'),
        content: const Text('¿Estás seguro de eliminar la huella guardada?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    )

    if (confirm == true) {
      await _biometricService.clearBiometricCredentials();
      setState(() {
        _showBiometricButton = false;
      });
      _showSnackBar('🧹 Huella eliminada correctamente', Colors.blue);
    }
  }*/

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Inicia sesión',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
          ),
          const SizedBox(height: 16),

          // Email
          TextFormField(
            keyboardType: TextInputType.emailAddress,
            controller: _loginForm.getCorreo(),
            decoration: InputDecoration(
              labelText: 'Correo electrónico',
              prefixIcon: const Icon(Icons.email_outlined),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: widget.primaryGreen, width: 1.6),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Password
          TextFormField(
            obscureText: true,
            controller: _loginForm.getContrasena(),
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: widget.primaryGreen, width: 1.6),
              ),
            ),
          ),
          const SizedBox(height: 8),

          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: widget.primaryGreen,
              ),
              child: const Text('¿Olvidaste tu contraseña?'),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _iniciarSesion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Entrar',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ),
              if (_showBiometricButton) ...[
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  child: FloatingActionButton(
                    onPressed:
                        _isBiometricLoading ? null : _loginWithBiometrics,
                    backgroundColor: widget.primaryGreen.withOpacity(0.1),
                    child: _isBiometricLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                          )
                        : Icon(
                            Icons.fingerprint,
                            color: widget.primaryGreen,
                            size: 28,
                          ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Botón para eliminar huella (solo para pruebas)
          /* if (_showBiometricButton)
            Center(
              child: TextButton.icon(
                onPressed: _eliminarHuella,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Eliminar huella guardada (pruebas)'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey,
                ),
              ),
            ),*/

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(child: Container(height: 1, color: Colors.grey[200])),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('o continúa con', style: TextStyle(fontSize: 12)),
              ),
              Expanded(child: Container(height: 1, color: Colors.grey[200])),
            ],
          ),
          const SizedBox(height: 14),

          const CuotAppSocialButtonsRow(),
        ],
      ),
    );
  }
}
