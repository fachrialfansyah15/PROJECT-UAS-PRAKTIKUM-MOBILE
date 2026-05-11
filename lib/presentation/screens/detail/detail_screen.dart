import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../core/theme.dart';
import '../../../data/models/movie.dart';
import '../../../data/models/movie_detail.dart';
import '../../providers/providers.dart';

class DetailScreen extends ConsumerStatefulWidget {
  final int movieId;
  const DetailScreen({super.key, required this.movieId});
  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  YoutubePlayerController? _ytController;
  bool _showTrailer = false;

  @override
  void dispose() {
    _ytController?.dispose();
    super.dispose();
  }

  void _openTrailer(String key) {
    setState(() {
      _showTrailer = true;
      _ytController = YoutubePlayerController(
        initialVideoId: key,
        flags: const YoutubePlayerFlags(autoPlay: true),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(movieDetailProvider(widget.movieId));
    final trailer = ref.watch(trailerKeyProvider(widget.movieId));
    final isInWatchlist = ref.watch(isInWatchlistProvider(widget.movieId));

    return Scaffold(
      body: detail.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (e, _) => Center(
          child: Text(
            'Gagal memuat: $e',
            style: const TextStyle(color: AppTheme.primary),
          ),
        ),
        data: (movie) => _buildContent(movie, trailer, isInWatchlist),
      ),
    );
  }

  Widget _buildContent(
    MovieDetail movie,
    AsyncValue<String?> trailer,
    AsyncValue<bool> isInWatchlist,
  ) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: AppTheme.background,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            isInWatchlist.when(
              data: (isIn) => IconButton(
                icon: Icon(
                  isIn ? Icons.bookmark : Icons.bookmark_border,
                  color: isIn ? AppTheme.primary : Colors.white,
                ),
                onPressed: () async {
                  final m = Movie(
                    id: movie.id,
                    title: movie.title,
                    posterPath: movie.posterPath,
                    backdropPath: movie.backdropPath,
                    overview: movie.overview,
                    voteAverage: movie.voteAverage,
                    releaseDate: movie.releaseDate,
                  );
                  await ref.read(watchlistNotifierProvider.notifier).toggle(m);
                },
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              error: (_, _) => const SizedBox(),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _showTrailer && _ytController != null
                ? YoutubePlayer(
                    controller: _ytController!,
                    showVideoProgressIndicator: true,
                    progressIndicatorColor: AppTheme.primary,
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: movie.backdropUrl,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, AppTheme.background],
                          ),
                        ),
                      ),
                      trailer.when(
                        data: (key) => key != null
                            ? Center(
                                child: GestureDetector(
                                  onTap: () => _openTrailer(key),
                                  child: Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withValues(
                                        alpha: 0.5,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox(),
                        loading: () => const SizedBox(),
                        error: (_, _) => const SizedBox(),
                      ),
                    ],
                  ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (movie.tagline != null && movie.tagline!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '"${movie.tagline}"',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: Icons.star_rounded,
                      label: movie.voteAverage.toStringAsFixed(1),
                      color: AppTheme.gold,
                    ),
                    _InfoChip(
                      icon: Icons.calendar_today,
                      label: movie.releaseDate.isNotEmpty
                          ? movie.releaseDate.substring(0, 4)
                          : '-',
                    ),
                    _InfoChip(
                      icon: Icons.timer_outlined,
                      label: movie.runtimeFormatted,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: movie.genres
                      .map(
                        (g) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.primary),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            g.name,
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                if (!_showTrailer)
                  trailer.when(
                    data: (key) => key != null
                        ? ElevatedButton.icon(
                            onPressed: () => _openTrailer(key),
                            icon: const Icon(Icons.play_circle_outline),
                            label: const Text('Tonton Trailer'),
                          )
                        : const SizedBox(),
                    loading: () => const SizedBox(),
                    error: (_, _) => const SizedBox(),
                  ),
                const SizedBox(height: 24),
                const Text(
                  'Sinopsis',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  movie.overview.isEmpty
                      ? 'Sinopsis tidak tersedia.'
                      : movie.overview,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    height: 1.6,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color ?? AppTheme.textSecondary, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color ?? AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
