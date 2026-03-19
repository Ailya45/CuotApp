import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String bucketName = 'Documentos';

  // 🔧 LÓGICA: Subir factura a Supabase Storage
  Future<String?> subirFactura(File archivo, String nombreArchivo) async {
    try {
      final filePath = 'facturas/$nombreArchivo';
      
      // Subir archivo
      await _supabase.storage
          .from(bucketName)
          .upload(filePath, archivo);

      // Obtener URL pública
      final publicUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('Error subiendo factura: $e');
      return null;
    }
  }

  // 🔧 LÓGICA: Descargar factura
  Future<File?> descargarFactura(String url, String nombreArchivo) async {
    try {
      final response = await _supabase.storage
          .from(bucketName)
          .download(url);

      // Guardar archivo temporal
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/$nombreArchivo');
      await file.writeAsBytes(response);

      return file;
    } catch (e) {
      print('Error descargando factura: $e');
      return null;
    }
  }
}