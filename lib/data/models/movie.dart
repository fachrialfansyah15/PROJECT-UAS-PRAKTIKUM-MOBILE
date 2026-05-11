import 'package:json_annotation/json_annotation.dart';

part 'movie.g.dart';

@JsonSerializable()
class Movie {
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
  @JsonKey(name: 'genre_ids')
  final List<int>? genreIds;

  const Movie({
    required this.id,
    required this.title,
    this.posterPath,
    this.backdropPath,
    required this.overview,
    required this.voteAverage,
    required this.releaseDate,
    this.genreIds,
  });

  String get posterUrl =>
      posterPath != null ? 'https://image.tmdb.org/t/p/w500$posterPath' : '';

  String get backdropUrl => backdropPath != null
      ? 'https://image.tmdb.org/t/p/w780$backdropPath'
      : '';

  factory Movie.fromJson(Map<String, dynamic> json) => _$MovieFromJson(json);
  Map<String, dynamic> toJson() => _$MovieToJson(this);
}

@JsonSerializable()
class MovieResponse {
  final int page;
  final List<Movie> results;
  @JsonKey(name: 'total_pages')
  final int totalPages;

  const MovieResponse({
    required this.page,
    required this.results,
    required this.totalPages,
  });

  factory MovieResponse.fromJson(Map<String, dynamic> json) =>
      _$MovieResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MovieResponseToJson(this);
}
