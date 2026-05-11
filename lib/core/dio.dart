import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/tmdb_service.dart';

final tmdbApiKeyProvider = Provider<String>((ref) {
  return dotenv.env['TMDB_API_KEY'] ?? '';
});

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  dio.options.connectTimeout = const Duration(seconds: 10);
  dio.options.receiveTimeout = const Duration(seconds: 10);
  return dio;
});

final tmdbServiceProvider = Provider<TmdbService>((ref) {
  final dio = ref.watch(dioProvider);
  return TmdbService(dio);
});
