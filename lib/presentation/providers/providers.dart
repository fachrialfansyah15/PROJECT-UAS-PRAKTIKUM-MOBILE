import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/movie.dart';
import '../../data/models/movie_detail.dart';
import '../../data/repositories/movie_repository.dart';
import '../../data/repositories/watchlist_repository.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final currentUserProvider = Provider((ref) {
  return Supabase.instance.client.auth.currentUser;
});

final popularMoviesProvider = FutureProvider<List<Movie>>((ref) {
  return ref.watch(movieRepositoryProvider).getPopularMovies();
});

final nowPlayingMoviesProvider = FutureProvider<List<Movie>>((ref) {
  return ref.watch(movieRepositoryProvider).getNowPlayingMovies();
});

final topRatedMoviesProvider = FutureProvider<List<Movie>>((ref) {
  return ref.watch(movieRepositoryProvider).getTopRatedMovies();
});

final movieDetailProvider = FutureProvider.family<MovieDetail, int>((ref, id) {
  return ref.watch(movieRepositoryProvider).getMovieDetail(id);
});

final trailerKeyProvider = FutureProvider.family<String?, int>((ref, id) {
  return ref.watch(movieRepositoryProvider).getTrailerKey(id);
});

// ✅ Ganti StateProvider dengan NotifierProvider
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String query) => state = query;
}

final searchResultsProvider = FutureProvider<List<Movie>>((ref) {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return Future.value([]);
  return ref.watch(movieRepositoryProvider).searchMovies(query);
});

final watchlistProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(watchlistRepositoryProvider).getWatchlist();
});

final isInWatchlistProvider = FutureProvider.family<bool, int>((ref, movieId) {
  return ref.watch(watchlistRepositoryProvider).isInWatchlist(movieId);
});

class WatchlistNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> toggle(Movie movie) async {
    final repo = ref.read(watchlistRepositoryProvider);
    final isIn = await repo.isInWatchlist(movie.id);
    if (isIn) {
      await repo.removeFromWatchlist(movie.id);
    } else {
      await repo.addToWatchlist(movie);
    }
    ref.invalidate(watchlistProvider);
    ref.invalidate(isInWatchlistProvider(movie.id));
  }
}

final watchlistNotifierProvider =
    AsyncNotifierProvider<WatchlistNotifier, void>(WatchlistNotifier.new);
