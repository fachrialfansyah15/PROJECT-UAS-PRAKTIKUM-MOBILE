import 'package:json_annotation/json_annotation.dart';

part 'movie_detail.g.dart';

@JsonSerializable()
class Genre {
  final int id;
  final String name;

  const Genre({required this.id, required this.name});

  factory Genre.fromJson(Map<String, dynamic> json) => _$GenreFromJson(json);
  Map<String, dynamic> toJson() => _$GenreToJson(this);
}

@JsonSerializable()
class MovieDetail {
  final int id;
  final String title;
  @JsonKey(name: 'poster_path')
  final String? posterPath;
  @JsonKey(name: 'backdrop_path')
  final String? backdropPath;
  final String overview;
  @JsonKey(name: 'vote_average')
  final double voteAverage;
  @JsonKey(name: 'release_date')
  final String releaseDate;
  final int? runtime;
  final List<Genre> genres;
  final String? tagline;
  final String status;

  const MovieDetail({
    required this.id,
    required this.title,
    this.posterPath,
    this.backdropPath,
    required this.overview,
    required this.voteAverage,
    required this.releaseDate,
    this.runtime,
    required this.genres,
    this.tagline,
    required this.status,
  });

  String get posterUrl =>
      posterPath != null ? 'https://image.tmdb.org/t/p/w500$posterPath' : '';

  String get backdropUrl => backdropPath != null
      ? 'https://image.tmdb.org/t/p/w780$backdropPath'
      : '';

  String get genreNames => genres.map((g) => g.name).join(', ');

  String get runtimeFormatted {
    if (runtime == null) return '-';
    final h = runtime! ~/ 60;
    final m = runtime! % 60;
    return h > 0 ? '${h}j ${m}m' : '${m}m';
  }

  factory MovieDetail.fromJson(Map<String, dynamic> json) =>
      _$MovieDetailFromJson(json);
  Map<String, dynamic> toJson() => _$MovieDetailToJson(this);
}

@JsonSerializable()
class VideoResult {
  final String key;
  final String name;
  final String site;
  final String type;

  const VideoResult({
    required this.key,
    required this.name,
    required this.site,
    required this.type,
  });

  factory VideoResult.fromJson(Map<String, dynamic> json) =>
      _$VideoResultFromJson(json);
  Map<String, dynamic> toJson() => _$VideoResultToJson(this);
}

@JsonSerializable()
class VideoResponse {
  final List<VideoResult> results;

  const VideoResponse({required this.results});

  factory VideoResponse.fromJson(Map<String, dynamic> json) =>
      _$VideoResponseFromJson(json);
  Map<String, dynamic> toJson() => _$VideoResponseToJson(this);
}
