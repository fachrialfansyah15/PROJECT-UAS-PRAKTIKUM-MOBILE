import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../providers/providers.dart';
import '../../../data/repositories/watchlist_repository.dart';

class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlist = ref.watch(watchlistProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Watchlist Saya')),
      body: watchlist.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: AppTheme.primary),
          ),
        ),
        data: (items) => items.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bookmark_border,
                      size: 80,
                      color: AppTheme.textSecondary,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Belum ada film di watchlist',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tambahkan film favorit kamu!',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                color: AppTheme.primary,
                onRefresh: () async => ref.invalidate(watchlistProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final posterPath = item['poster_path'] as String?;
                    final posterUrl = posterPath != null
                        ? 'https://image.tmdb.org/t/p/w200$posterPath'
                        : '';
                    return Dismissible(
                      key: Key(item['movie_id'].toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) async {
                        await ref
                            .read(watchlistRepositoryProvider)
                            .removeFromWatchlist(item['movie_id'] as int);
                        ref.invalidate(watchlistProvider);
                      },
                      child: GestureDetector(
                        onTap: () =>
                            context.push('/detail/${item['movie_id']}'),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.card,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: posterUrl,
                                  width: 70,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  placeholder: (_, _) => Container(
                                    color: AppTheme.surface,
                                    child: const Icon(
                                      Icons.movie,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  errorWidget: (_, _, _) => Container(
                                    color: AppTheme.surface,
                                    child: const Icon(
                                      Icons.broken_image,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'] ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          color: AppTheme.gold,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          (item['vote_average'] as num?)
                                                  ?.toStringAsFixed(1) ??
                                              '-',
                                          style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item['overview'] ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: AppTheme.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
