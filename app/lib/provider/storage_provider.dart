import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/storage_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  final supabase = Supabase.instance.client;
  return StorageService(supabase: supabase);
});