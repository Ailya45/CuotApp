import 'package:cuot_app/widget/dashboard/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsScreen extends StatefulWidget {
  final String? nombreUsuario; // Callback para navegación segura
  
  const SettingsScreen({
    super.key,
    required this.nombreUsuario
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isBiometricEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkBiometricStatus();
  }

  Future<void> _checkBiometricStatus() async {
    final enabled = await _storage.read(key: 'biometric_enabled');
    setState(() {
      _isBiometricEnabled = enabled == 'true';
      _isLoading = false;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    setState(() {
      _isLoading = true;
    });

    if (value == false) {
      // Desactivar biometría
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('🗑️ Desactivar huella'),
          content: const Text(
            '¿Estás seguro de desactivar la huella dactilar?\n'
            'Tendrás que iniciar sesión con tu correo y contraseña.'
          ),
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
              child: const Text('Desactivar'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await _storage.delete(key: 'biometric_email');
        await _storage.delete(key: 'biometric_password');
        await _storage.delete(key: 'biometric_enabled');
        
        if (mounted) {
          setState(() {
            _isBiometricEnabled = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Huella desactivada'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } else {
      // Aquí iría la lógica para activar biometría
      // (similar a cuando preguntas después del login)
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    
      drawer: CustomDrawer(nombre_usuario: widget.nombreUsuario ?? "Usuario", ventanaActiva: "Configuración"),
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: const Text('Inicio con huella dactilar'),
                  subtitle: const Text(
                    'Inicia sesión rápidamente usando tu huella'
                  ),
                  value: _isBiometricEnabled,
                  secondary: Icon(
                    Icons.fingerprint,
                    color: _isBiometricEnabled ? Colors.blue : Colors.grey,
                  ),
                  onChanged: _toggleBiometric,
                ),
              ],
            ),
    );
  }
}