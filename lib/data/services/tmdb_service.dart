import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/movie.dart';
import '../models/movie_detail.dart';

part 'tmdb_service.g.dart';

@RestApi(baseUrl: 'https://api.themoviedb.org/3')
abstract class TmdbService {
  factory TmdbService(Dio dio, {String baseUrl}) = _TmdbService;

  @GET('/movie/popular')
  Future<MovieResponse> getPopularMovies(
    @Query('api_key') String apiKey, {
    @Query('page') int page = 1,
    @Query('language') String language = 'id-ID',
  });

  @GET('/movie/now_playing')
  Future<MovieResponse> getNowPlayingMovies(
    @Query('api_key') String apiKey, {
    @Query('page') int page = 1,
    @Query('language') String language = 'id-ID',
  });

  @GET('/movie/top_rated')
  Future<MovieResponse> getTopRatedMovies(
    @Query('api_key') String apiKey, {
    @Query('page') int page = 1,
    @Query('language') String language = 'id-ID',
  });

  @GET('/movie/{id}')
  Future<MovieDetail> getMovieDetail(
    @Path('id') int id,
    @Query('api_key') String apiKey, {
    @Query('language') String language = 'id-ID',
  });

  @GET('/movie/{id}/videos')
  Future<VideoResponse> getMovieVideos(
    @Path('id') int id,
    @Query('api_key') String apiKey,
  );

  @GET('/search/movie')
  Future<MovieResponse> searchMovies(
    @Query('api_key') String apiKey,
    @Query('query') String query, {
    @Query('page') int page = 1,
    @Query('language') String language = 'id-ID',
  });
}
