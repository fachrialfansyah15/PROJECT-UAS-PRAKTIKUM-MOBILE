import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../../../data/models/movie.dart';
import '../../providers/providers.dart';
import '../../widgets/movie_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchCtrl = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nowPlaying = ref.watch(nowPlayingMoviesProvider);
    final popular = ref.watch(popularMoviesProvider);
    final topRated = ref.watch(topRatedMoviesProvider);
    final searchResults = ref.watch(searchResultsProvider);
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Cari film...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppTheme.textSecondary),
                ),
                onChanged: (v) => ref.read(searchQueryProvider.notifier).set(v),
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.movie_filter_rounded,
                    color: AppTheme.primary,
                    size: 28,
                  ),
                  SizedBox(width: 8),
                  Text('CineMate'),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() => _isSearching = !_isSearching);
              if (!_isSearching) {
                _searchCtrl.clear();
                ref.read(searchQueryProvider.notifier).set('');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_outlined),
            onPressed: () => context.push('/watchlist'),
          ),
          PopupMenuButton(
            color: AppTheme.card,
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primary,
              child: Text(
                (user?.email?.substring(0, 1) ?? 'U').toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            itemBuilder: (context) => <PopupMenuEntry<dynamic>>[
              PopupMenuItem(
                enabled: false,
                child: Text(
                  user?.email ?? '',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                onTap: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (!context.mounted) return;
                  context.go('/login');
                },
                child: const Row(
                  children: [
                    Icon(Icons.logout, color: AppTheme.primary, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Keluar',
                      style: TextStyle(color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isSearching && _searchCtrl.text.isNotEmpty
          ? _buildSearchResults(searchResults)
          : _buildHome(nowPlaying, popular, topRated),
    );
  }

  Widget _buildHome(
    AsyncValue<List<Movie>> nowPlaying,
    AsyncValue<List<Movie>> popular,
    AsyncValue<List<Movie>> topRated,
  ) {
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () async {
        ref.invalidate(nowPlayingMoviesProvider);
        ref.invalidate(popularMoviesProvider);
        ref.invalidate(topRatedMoviesProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            nowPlaying.when(
              data: (m) => m.isNotEmpty
                  ? _BannerSection(movie: m.first)
                  : const SizedBox(),
              loading: () => Container(
                height: 220,
                color: AppTheme.surface,
                child: const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              ),
              error: (e, _) => const SizedBox(),
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Tayang Sekarang'),
            nowPlaying.when(
              data: (m) => _HorizontalList(movies: m),
              loading: () => const _LoadingList(),
              error: (e, _) => _ErrWidget(message: e.toString()),
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Populer'),
            popular.when(
              data: (m) => _HorizontalList(movies: m),
              loading: () => const _LoadingList(),
              error: (e, _) => _ErrWidget(message: e.toString()),
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Rating Tertinggi'),
            topRated.when(
              data: (m) => _HorizontalList(movies: m),
              loading: () => const _LoadingList(),
              error: (e, _) => _ErrWidget(message: e.toString()),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(AsyncValue<List<Movie>> results) {
    return results.when(
      data: (movies) => movies.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    color: AppTheme.textSecondary,
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Film tidak ditemukan',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.55,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: movies.length,
              itemBuilder: (_, i) => MovieCard(movie: movies[i]),
            ),
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }
}

class _BannerSection extends StatelessWidget {
  final Movie movie;
  const _BannerSection({required this.movie});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/detail/${movie.id}'),
      child: Stack(
        children: [
          CachedNetworkImage(
            imageUrl: movie.backdropUrl,
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppTheme.background],
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'TAYANG SEKARANG',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  movie.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppTheme.gold,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      movie.voteAverage.toStringAsFixed(1),
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _HorizontalList extends StatelessWidget {
  final List<Movie> movies;
  const _HorizontalList({required this.movies});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: movies.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: MovieCard(movie: movies[i]),
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 255,
      child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
    );
  }
}

class _ErrWidget extends StatelessWidget {
  final String message;
  const _ErrWidget({required this.message});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Center(
        child: Text(
          'Error: $message',
          style: const TextStyle(color: AppTheme.primary),
        ),
      ),
    );
  }
}
