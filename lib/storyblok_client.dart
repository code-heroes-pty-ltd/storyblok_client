import 'dart:convert';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:http/http.dart' as http;

import 'enums.dart';
import 'filter_query.dart';
import 'resolve_relations.dart';
import 'sort_by.dart';

class StoryblokClient {
  static const _base = 'api.storyblok.com';

  final String _token;
  final bool _autoCacheInvalidation;

  String _cacheVersion;

  StoryblokClient({String token, bool autoCacheInvalidation = false})
      : assert(token != null),
        _token = token,
        _autoCacheInvalidation = autoCacheInvalidation;

  Future<dynamic> _get(
    String path, {
    Map<String, String> parameters,
    bool ignoreCacheVersion = false,
  }) async {
    if (parameters == null) {
      parameters = {'token': _token};
    } else {
      parameters['token'] = _token;
    }

    if (!ignoreCacheVersion) {
      if (_autoCacheInvalidation) await invalidateCacheVersion();

      if (_cacheVersion == null) {
        print(
            // ignore: lines_longer_than_80_chars
            'No cache invalidation version fetched. Consider turning on auto cache invalidation');
      } else {
        parameters['cv'] = _cacheVersion;
      }
    }

    final response =
        await http.get(Uri.https(_base, '/v1/cdn/$path', parameters));
    if (response.statusCode != 200) {
      throw ("Invalid response from Storyblok: ${response.statusCode}");
    }

    return json.decode(response.body);
  }

  Future<void> invalidateCacheVersion() async {
    if (_autoCacheInvalidation) {
      print(
          // ignore: lines_longer_than_80_chars
          "Automatic cache invalidation is configured, avoid calling manually.");
    }

    final data = await _get('spaces/me', ignoreCacheVersion: true);
    _cacheVersion = data['space']['version'].toString();
  }

  Future<Map<String, dynamic>> fetchOne({
    String fullSlug,
    String id,
    String uuid,
    StoryVersion version,
    bool resolveLinks,
    List<ResolveRelations> resolveRelations,
    String fromRelease,
    String language,
    String fallbackLanguage,
  }) async {
    final path = StringBuffer('stories/');
    if (fullSlug != null) path.write(fullSlug);
    if (id != null) path.write(id);
    if (uuid != null) path.write(uuid);

    final parameters = <String, String>{};
    if (uuid != null) parameters['find_by'] = 'uuid';
    if (version != null) parameters['version'] = EnumToString.parse(version);
    if (resolveLinks != null) {
      parameters['resolve_links'] = resolveLinks.toString();
    }
    if (resolveRelations != null) {
      parameters['resolve_relations'] = resolveRelations.fold<String>(
          '',
          (previous, current) =>
              previous += '${current.componentName}.${current.fieldName},');
    }
    if (fromRelease != null) parameters['from_release'] = fromRelease;
    if (language != null) parameters['language'] = language;
    if (fallbackLanguage != null) {
      parameters['fallback_language'] = fallbackLanguage;
    }

    return await _get(path.toString(), parameters: parameters);
  }

  Future<Map<String, dynamic>> fetchMultiple({
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
    final parameters = <String, String>{};
    if (startsWith != null) parameters['starts_with'] = startsWith;
    if (byUuids != null) {
      parameters['by_uuids'] =
          byUuids.reduce((previous, current) => previous += ',$current');
    }
    if (fallbackLang != null) parameters['fallback_lang'] = fallbackLang;
    if (byUuidsOrdered != null) {
      parameters['by_uuids_ordered'] =
          byUuidsOrdered.reduce((previous, current) => previous += ',$current');
    }
    if (excludingIds != null) {
      parameters['excluding_ids'] =
          excludingIds.reduce((previous, current) => previous += ',$current');
    }
    if (excludingFields != null) {
      parameters['excluding_fields'] = excludingFields
          .reduce((previous, current) => previous += ',$current');
    }
    if (version != null) parameters['version'] = EnumToString.parse(version);
    if (resolveLinks != null) {
      parameters['resolve_links'] = resolveLinks.toString();
    }
    if (resolveRelations != null) {
      parameters['resolve_relations'] = resolveRelations.fold<String>(
          '',
          (previous, current) =>
              previous += '${current.componentName}.${current.fieldName},');
    }
    if (fromRelease != null) parameters['from_release'] = fromRelease;
    if (sortBy != null) {
      var sort = sortBy.attributeField != null
          ? sortBy.attributeField
          : 'content.${sortBy.contentField}';
      if (sortBy.order != null) sort += ':${EnumToString.parse(sortBy.order)}';
      if (sortBy.type != null) sort += ':${EnumToString.parse(sortBy.type)}';

      parameters['sort_by'] = sort;
    }
    if (searchTerm != null) parameters['search_term'] = searchTerm;
    if (filterQueries != null) {
      for (final filter in filterQueries) {
        parameters['filter_query[${filter.attribute}][${filter.operation}]'] =
            filter.value.toString();
      }
    }
    if (isStartPage != null) {
      parameters['is_startpage'] = isStartPage ? '1' : '0';
    }
    if (page != null) parameters['page'] = page.toString();
    if (perPage != null) parameters['per_page'] = perPage.toString();

    return await _get('stories', parameters: parameters);
  }
}
