import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'filter_query.dart';
import 'request_builder.dart';
import 'resolve_relations.dart';
import 'sort_by.dart';
import 'story_model.dart';
import 'storyblok_response.dart';

/// The Story version to fetch.
enum StoryVersion {
  /// Published stories.
  published,

  /// Non published stories, ie. drafted stories.
  draft,
}

/// The main class for fetching Storyblok content.
class StoryblokClient {
  static const _base = 'api.storyblok.com';

  final String _token;
  final bool _autoCacheInvalidation;

  String _cacheVersion;

  /// Construct a new client for accessing Storyblok.
  ///
  /// When [autoCacheInvalidation] is set to `false` will the cache version not
  /// be auto invalidated before each request. To invalidate the cache version
  /// manually at appropriate stages in the project, use the
  /// [StoryblokClient.invalidateCacheVersion] method.
  StoryblokClient({
    @required String token,
    bool autoCacheInvalidation = false,
  })  : assert(token != null),
        _token = token,
        _autoCacheInvalidation = autoCacheInvalidation;

  Future<http.Response> _get(
    String path, {
    Map<String, String> parameters,
    bool ignoreCacheVersion = false,
  }) async {
    if (parameters == null) {
      parameters = {
        'token': _token,
      };
    } else {
      parameters['token'] = _token;
    }

    if (!ignoreCacheVersion) {
      if (_autoCacheInvalidation) {
        await invalidateCacheVersion();
      }

      if (_cacheVersion == null) {
        print(
          // ignore: lines_longer_than_80_chars
          'No cache invalidation version fetched. Consider turning on auto cache invalidation',
        );
      } else {
        parameters['cv'] = _cacheVersion;
      }
    }

    final uri = Uri.https(_base, '/v1/cdn/$path', parameters);
    http.Response response;

    try {
      response = await http.get(uri);
    } on Exception catch (e) {
      print(e);
      throw Exception(
        'Cannot perform http request to Storyblok. Check error logs above.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Invalid http response code from Storyblok: ${response.statusCode}',
      );
    }

    return response;
  }

  /// Fetches the latest cache version from Storyblok. The fetched cache version
  /// will then be used in subsequent calls.
  Future<void> invalidateCacheVersion() async {
    final response = await _get('spaces/me', ignoreCacheVersion: true);
    final body = json.decode(response.body);

    _cacheVersion = body['space']['version'].toString();
  }

  Future<StoryblokResponse> _fetchStories(
    RequestBuilder builder, [
    bool multiple = false,
  ]) async {
    final response = await _get(builder.path, parameters: builder.parameters);
    final body = json.decode(response.body);
    List<Story> stories;

    if (multiple) {
      final data = List<Map<String, dynamic>>.from(body['stories']);
      stories = data.map((json) => Story.fromJson(json)).toList();
    } else {
      final story = Story.fromJson(body['story'] as Map<String, dynamic>);
      stories = <Story>[]..add(story);
    }

    return StoryblokResponse(response, stories);
  }

  /// Fetches a single Story.
  ///
  /// See https://www.storyblok.com/docs/api/content-delivery#core-resources/stories/retrieve-one-story
  /// for more details.
  Future<StoryblokResponse> fetchOne({
    String fullSlug,
    String id,
    String uuid,
    StoryVersion version,
    bool resolveLinks,
    List<ResolveRelations> resolveRelations,
    String fromRelease,
    String language,
    String fallbackLang,
  }) async {
    OneRequestBuilder builder;
    if (fullSlug != null) {
      assert(id == null && uuid == null);
      builder = OneRequestBuilder.fullSlug(fullSlug);
    } else if (id != null) {
      assert(fullSlug == null && uuid == null);
      builder = OneRequestBuilder.id(id);
    } else if (uuid != null) {
      assert(fullSlug == null && id == null);
      builder = OneRequestBuilder.uuid(uuid);
    } else {
      throw Exception('No path provided with either fullSlug, id or uuid.');
    }

    if (version != null) builder.version(version);
    if (resolveLinks != null) builder.resolveLinks(resolveLinks);
    if (resolveRelations != null) builder.resolveRelations(resolveRelations);
    if (fromRelease != null) builder.fromRelease(fromRelease);
    if (language != null) builder.language(language);
    if (fallbackLang != null) builder.fallbackLang(fallbackLang);

    return _fetchStories(builder);
  }

  /// Fetches multiple stories.
  ///
  /// See https://www.storyblok.com/docs/api/content-delivery#core-resources/stories/retrieve-multiple-stories
  /// for more details.
  Future<StoryblokResponse> fetchMultiple({
    String startsWith,
    List<String> byUuids,
    String fallbackLang,
    List<String> byUuidsOrdered,
    List<String> excludingIds,
    List<String> excludingFields,
    StoryVersion version,
    bool resolveLinks,
    List<ResolveRelations> resolveRelations,
    String fromRelease,
    SortBy sortBy,
    String searchTerm,
    List<FilterQuery> filterQueries,
    bool isStartPage,
    List<String> withTag,
    int page,
    int perPage,
  }) async {
    final builder = MultipleRequestBuilder();

    if (startsWith != null) builder.startsWith(startsWith);
    if (byUuids != null) builder.byUuids(byUuids);
    if (fallbackLang != null) builder.fallbackLang(fallbackLang);
    if (byUuidsOrdered != null) builder.byUuidsOrdered(byUuidsOrdered);
    if (excludingIds != null) builder.excludingIds(excludingIds);
    if (excludingFields != null) builder.excludingFields(excludingFields);
    if (version != null) builder.version(version);
    if (resolveLinks != null) builder.resolveLinks(resolveLinks);
    if (resolveRelations != null) builder.resolveRelations(resolveRelations);
    if (fromRelease != null) builder.fromRelease(fromRelease);
    if (sortBy != null) builder.sortBy(sortBy);
    if (searchTerm != null) builder.searchTerm(searchTerm);
    if (filterQueries != null) builder.filterQueries(filterQueries);
    if (isStartPage != null) builder.isStartPage(isStartPage);
    if (page != null) builder.page(page);
    if (perPage != null) builder.perPage(perPage);

    return _fetchStories(builder, true);
  }
}
