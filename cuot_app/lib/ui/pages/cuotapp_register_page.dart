import 'package:cuot_app/core/supabase/supabase_service.dart';
import 'package:cuot_app/ui/pages/cuotapp_login_page.dart';
import 'package:cuot_app/widget/register/step_basic_info.dart';
import 'package:cuot_app/widget/register/step_documents.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class CuotAppRegisterPage extends StatefulWidget {
  const CuotAppRegisterPage({super.key});

  @override
  State<CuotAppRegisterPage> createState() => _CuotAppRegisterPageState();
}

class _CuotAppRegisterPageState extends State<CuotAppRegisterPage> {
  static const Color kLightGreen = Color(0xFFB9F6CA);
  static const Color kPrimaryGreen = Color(0xFF00C853);

  int _currentStep = 0;
  bool _isRegistering = false;

  final formStep1Key = GlobalKey<FormState>();

  final TextEditingController nombreCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController telefonoCtrl = TextEditingController();
  final TextEditingController cedulaCtrl = TextEditingController();
  final TextEditingController contrasenaCtrl = TextEditingController();
  final TextEditingController contrasenaVerificaCtrl = TextEditingController();

  File? cedulaFile;

  @override
  void dispose() {
    nombreCtrl.dispose();
    emailCtrl.dispose();
    telefonoCtrl.dispose();
    cedulaCtrl.dispose();
    contrasenaCtrl.dispose();
    contrasenaVerificaCtrl.dispose();
    super.dispose();
  }

  bool isEmpty() => 
      nombreCtrl.text.isEmpty || 
      emailCtrl.text.isEmpty || 
      telefonoCtrl.text.isEmpty || 
      contrasenaCtrl.text.isEmpty;

  bool isContrasenaValid() => 
      contrasenaCtrl.text == contrasenaVerificaCtrl.text;

  Future<void> _continuar() async {
    final bool isLastStep = _currentStep == _steps.length - 1;

    if (_currentStep == 0) {
      if (formStep1Key.currentState?.validate() != true) return;
    }

    if (!isContrasenaValid()) {
      _showSnackBar('Las contraseñas no coinciden.', Colors.redAccent);
      return;
    }

    if (isEmpty()) {
      _showSnackBar('Por favor, rellena todos los campos.', Colors.redAccent);
      return;
    }

    if (isLastStep) {
      await _registrarUsuario();
    } else {
      setState(() => _currentStep += 1);
    }
  }

  Future<void> _registrarUsuario() async {
    setState(() => _isRegistering = true);
    final supabaseService = SupabaseService();
    String? cedulaPath;

    try {
      String? cedulaUrl;
      if (cedulaFile != null) {
        cedulaPath = 'cedulas/cedula_${cedulaCtrl.text}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        cedulaUrl = await supabaseService.uploadFile(
          folder: 'cedulas',
          fileName: 'cedula_${cedulaCtrl.text}_${DateTime.now().millisecondsSinceEpoch}.jpg',
          file: cedulaFile!,
        );
      }

      await supabaseService.client.schema("Usuarios").from("Usuarios").insert({
        "Nombre_Completo": nombreCtrl.text,
        "Correo_Electronico": emailCtrl.text,
        "Telefono": telefonoCtrl.text,
        "Cedula": cedulaCtrl.text,
        "Contrasena": contrasenaCtrl.text,
        "cedula_url": cedulaUrl,
      });

      if (mounted) {
        _showSnackBar('¡Registro completado!', Colors.green);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CuotAppLoginPage()),
        );
      }
    } catch (e) {
      if (cedulaPath != null) {
        await supabaseService.deleteFile(cedulaPath);
      }
      if (mounted) {
        _showSnackBar('Error al registrar: $e', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  void _atras() {
    if (_currentStep == 0) return;
    setState(() => _currentStep -= 1);
  }

  List<Step> get _steps => [
        Step(
          state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          isActive: _currentStep >= 0,
          title: const Text('Información Básica', style: TextStyle(fontWeight: FontWeight.bold)),
          content: StepBasicInfo(
            formKey: formStep1Key,
            nombreCtrl: nombreCtrl,
            emailCtrl: emailCtrl,
            telefonoCtrl: telefonoCtrl,
            cedulaCtrl: cedulaCtrl,
            primaryGreen: kPrimaryGreen,
            contrasenaCtrl: contrasenaCtrl,
            contrasenaVerificaCtrl: contrasenaVerificaCtrl,
          ),
        ),
        Step(
          state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          isActive: _currentStep >= 1,
          title: const Text('Documentos de Identidad', style: TextStyle(fontWeight: FontWeight.bold)),
          content: StepDocuments(
            cedulaFile: cedulaFile,
            onCedulaPicked: (file) => setState(() => cedulaFile = file),
          ),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black12,
        iconTheme: const IconThemeData(color: kPrimaryGreen),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: kLightGreen.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person_add, size: 20, color: kPrimaryGreen),
            ),
            const SizedBox(width: 10),
            const Text(
              'Crea tu Cuenta',
              style: TextStyle(color: kPrimaryGreen, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF1F8E9), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: kPrimaryGreen),
          ),
          child: Stepper(
            type: StepperType.vertical,
            currentStep: _currentStep,
            onStepContinue: _continuar,
            onStepCancel: _atras,
            onStepTapped: (step) => setState(() => _currentStep = step),
            elevation: 0,
            physics: const BouncingScrollPhysics(),
            controlsBuilder: (context, details) {
              final bool isLast = _currentStep == _steps.length - 1;
              return Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isRegistering ? null : details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isRegistering 
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                isLast ? 'FINALIZAR REGISTRO' : 'CONTINUAR',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                maxLines: 1,
                              ),
                            ),
                      ),
                    ),
                    if (_currentStep != 0) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isRegistering ? null : details.onStepCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey.shade300, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'VOLVER',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
            steps: _steps,
          ),
        ),
      ),
    );
  }
}
