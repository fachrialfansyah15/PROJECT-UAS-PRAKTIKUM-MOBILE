import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/movie.dart';

class WatchlistRepository {
  final SupabaseClient _client;

  WatchlistRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  Future<List<Map<String, dynamic>>> getWatchlist() async {
    final res = await _client
        .from('watchlist')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> addToWatchlist(Movie movie) async {
    await _client.from('watchlist').insert({
      'user_id': _userId,
      'movie_id': movie.id,
      'title': movie.title,
      'poster_path': movie.posterPath,
      'overview': movie.overview,
      'vote_average': movie.voteAverage,
    });
  }

  Future<void> removeFromWatchlist(int movieId) async {
    await _client
        .from('watchlist')
        .delete()
        .eq('user_id', _userId)
        .eq('movie_id', movieId);
  }

  Future<bool> isInWatchlist(int movieId) async {
    final res = await _client
        .from('watchlist')
        .select('id')
        .eq('user_id', _userId)
        .eq('movie_id', movieId);
    return (res as List).isNotEmpty;
  }
}

final watchlistRepositoryProvider = Provider<WatchlistRepository>((ref) {
  return WatchlistRepository(Supabase.instance.client);
});
