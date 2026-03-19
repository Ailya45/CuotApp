import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // Verificar si está inicializado
  bool get isInitialized => SupabaseConfig.isInitialized;

  // Obtener cliente (lanzará error si no está inicializado)
  SupabaseClient get client => SupabaseConfig.client;

  // 📁 STORAGE: Subir archivos al bucket 'Documentos'
  Future<String> uploadFile({
    required String folder,
    required String fileName,
    required File file,
  }) async {
    _checkInitialized();
    try {
      final String path = '$folder/$fileName';
      
      await client.storage.from('Documentos').upload(
        path,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      // Obtener la URL pública
      return client.storage.from('Documentos').getPublicUrl(path);
    } catch (e) {
      print('❌ Error al subir archivo a Storage: $e');
      rethrow;
    }
  }

  // 📁 STORAGE: Eliminar archivos del bucket 'Documentos'
  Future<void> deleteFile(String path) async {
    _checkInitialized();
    try {
      await client.storage.from('Documentos').remove([path]);
    } catch (e) {
      print('❌ Error al eliminar archivo de Storage: $e');
    }
  }

  // 📊 DB: Métodos con soporte de esquemas
  Future<List<Map<String, dynamic>>> fetchAll(String table, {String schema = 'Financiamientos'}) async {
    _checkInitialized();
    try {
      return await client.schema(schema).from(table).select();
    } catch (e) {
      print('❌ Error en fetchAll ($schema.$table): $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> fetchById(String table, String id, {String schema = 'Financiamientos'}) async {
    _checkInitialized();
    try {
      return await client
          .schema(schema)
          .from(table)
          .select()
          .eq('id', id)
          .maybeSingle();
    } catch (e) {
      print('❌ Error en fetchById ($schema.$table): $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> insert(String table, Map<String, dynamic> data, {String schema = 'Financiamientos'}) async {
    _checkInitialized();
    try {
      return await client
          .schema(schema)
          .from(table)
          .insert(data)
          .select()
          .single();
    } catch (e) {
      print('❌ Error en insert ($schema.$table): $e');
      rethrow;
    }
  }

  Future<void> update(String table, String id, Map<String, dynamic> data, {String schema = 'Financiamientos'}) async {
    _checkInitialized();
    try {
      await client
          .schema(schema)
          .from(table)
          .update(data)
          .eq('id', id);
    } catch (e) {
      print('❌ Error en update ($schema.$table): $e');
      rethrow;
    }
  }

  void _checkInitialized() {
    if (!isInitialized) {
      throw Exception('SupabaseService no inicializado');
    }
  }
}

// Singleton global
final supabaseService = SupabaseService();