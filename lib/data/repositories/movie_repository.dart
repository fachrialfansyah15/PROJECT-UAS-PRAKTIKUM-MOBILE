import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/movie.dart';
import '../models/movie_detail.dart';
import '../services/tmdb_service.dart';
import '../../core/dio.dart';

class MovieRepository {
  final TmdbService _service;
  final String _apiKey;

  MovieRepository(this._service, this._apiKey);

  Future<List<Movie>> getPopularMovies({int page = 1}) async {
    final res = await _service.getPopularMovies(_apiKey, page: page);
    return res.results;
  }

  Future<List<Movie>> getNowPlayingMovies({int page = 1}) async {
    final res = await _service.getNowPlayingMovies(_apiKey, page: page);
    return res.results;
  }

  Future<List<Movie>> getTopRatedMovies({int page = 1}) async {
    final res = await _service.getTopRatedMovies(_apiKey, page: page);
    return res.results;
  }

  Future<MovieDetail> getMovieDetail(int id) async {
    return await _service.getMovieDetail(id, _apiKey);
  }

  Future<String?> getTrailerKey(int id) async {
    final res = await _service.getMovieVideos(id, _apiKey);
    try {
      final trailer = res.results.firstWhere(
        (v) => v.type == 'Trailer' && v.site == 'YouTube',
      );
      return trailer.key;
    } catch (_) {
      return res.results.isNotEmpty ? res.results.first.key : null;
    }
  }

  Future<List<Movie>> searchMovies(String query) async {
    final res = await _service.searchMovies(_apiKey, query);
    return res.results;
  }
}

final movieRepositoryProvider = Provider<MovieRepository>((ref) {
  final service = ref.watch(tmdbServiceProvider);
  final apiKey = ref.watch(tmdbApiKeyProvider);
  return MovieRepository(service, apiKey);
});
