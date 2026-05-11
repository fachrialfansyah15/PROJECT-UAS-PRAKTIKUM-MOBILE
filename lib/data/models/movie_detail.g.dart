// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movie_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Genre _$GenreFromJson(Map<String, dynamic> json) =>
    Genre(id: (json['id'] as num).toInt(), name: json['name'] as String);

Map<String, dynamic> _$GenreToJson(Genre instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
};

MovieDetail _$MovieDetailFromJson(Map<String, dynamic> json) => MovieDetail(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  posterPath: json['poster_path'] as String?,
  backdropPath: json['backdrop_path'] as String?,
  overview: json['overview'] as String,
  voteAverage: (json['vote_average'] as num).toDouble(),
  releaseDate: json['release_date'] as String,
  runtime: (json['runtime'] as num?)?.toInt(),
  genres: (json['genres'] as List<dynamic>)
      .map((e) => Genre.fromJson(e as Map<String, dynamic>))
      .toList(),
  tagline: json['tagline'] as String?,
  status: json['status'] as String,
);

Map<String, dynamic> _$MovieDetailToJson(MovieDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'poster_path': instance.posterPath,
      'backdrop_path': instance.backdropPath,
      'overview': instance.overview,
      'vote_average': instance.voteAverage,
      'release_date': instance.releaseDate,
      'runtime': instance.runtime,
      'genres': instance.genres,
      'tagline': instance.tagline,
      'status': instance.status,
    };

VideoResult _$VideoResultFromJson(Map<String, dynamic> json) => VideoResult(
  key: json['key'] as String,
  name: json['name'] as String,
  site: json['site'] as String,
  type: json['type'] as String,
);

Map<String, dynamic> _$VideoResultToJson(VideoResult instance) =>
    <String, dynamic>{
      'key': instance.key,
      'name': instance.name,
      'site': instance.site,
      'type': instance.type,
    };

VideoResponse _$VideoResponseFromJson(Map<String, dynamic> json) =>
    VideoResponse(
      results: (json['results'] as List<dynamic>)
          .map((e) => VideoResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$VideoResponseToJson(VideoResponse instance) =>
    <String, dynamic>{'results': instance.results};
