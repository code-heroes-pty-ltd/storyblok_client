// ignore_for_file: public_member_api_docs

import 'package:enum_to_string/enum_to_string.dart';

import 'filter_query.dart';
import 'resolve_relations.dart';
import 'sort_by.dart';
import 'storyblok_client.dart';

abstract class RequestBuilder {
  final _parameters = <String, String>{};

  RequestBuilder._();

  void version(StoryVersion version) {
    _parameters['version'] = EnumToString.parse(version);
  }

  // ignore: avoid_positional_boolean_parameters
  void resolveLinks(bool resolveLinks) {
    _parameters['resolve_links'] = resolveLinks.toString();
  }

  void resolveRelations(List<ResolveRelations> resolveRelations) {
    _parameters['resolve_relations'] = resolveRelations.fold<String>(
      '',
      (
        previous,
        current,
      ) =>
          previous += '${current.componentName}.${current.fieldName},',
    );
  }

  void fromRelease(String fromRelease) {
    _parameters['from_release'] = fromRelease;
  }

  void language(String language) {
    _parameters['language'] = language;
  }

  void fallbackLang(String fallbackLang) {
    _parameters['fallback_lang'] = fallbackLang;
  }

  Map<String, dynamic> get parameters => _parameters;
  String get path => 'stories';
}

class OneRequestBuilder extends RequestBuilder {
  final String _path;

  OneRequestBuilder._(String path, [bool findBy = false])
      : _path = path,
        super._() {
    if (findBy) _findBy();
  }

  factory OneRequestBuilder.fullSlug(String fullSlug) {
    return OneRequestBuilder._(fullSlug);
  }

  factory OneRequestBuilder.id(String id) {
    return OneRequestBuilder._(id);
  }

  factory OneRequestBuilder.uuid(String uuid) {
    return OneRequestBuilder._(uuid, true);
  }

  void _findBy() {
    _parameters['find_by'] = 'uuid';
  }

  @override
  String get path => '${super.path}/$_path';
}

class MultipleRequestBuilder extends RequestBuilder {
  MultipleRequestBuilder() : super._();

  void startsWith(String startsWith) {
    _parameters['starts_with'] = startsWith;
  }

  void byUuids(List<String> byUuids) {
    _parameters['by_uuids'] = byUuids.reduce(
      (previous, current) => previous += ',$current',
    );
  }

  void byUuidsOrdered(List<String> byUuidsOrdered) {
    _parameters['by_uuids_ordered'] = byUuidsOrdered.reduce(
      (previous, current) => previous += ',$current',
    );
  }

  void excludingIds(List<String> excludingIds) {
    _parameters['excluding_ids'] = excludingIds.reduce(
      (previous, current) => previous += ',$current',
    );
  }

  void excludingFields(List<String> excludingFields) {
    parameters['excluding_fields'] = excludingFields.reduce(
      (previous, current) => previous += ',$current',
    );
  }

  void sortBy(SortBy sortBy) {
    String sort;
    if (sortBy.attributeField != null) {
      sort = sortBy.attributeField;
    } else {
      sort = 'content.${sortBy.contentField}';
    }
    if (sortBy.order != null) sort += ':${EnumToString.parse(sortBy.order)}';
    if (sortBy.type != null) sort += ':${EnumToString.parse(sortBy.type)}';

    _parameters['sort_by'] = sort;
  }

  void searchTerm(String searchTerm) {
    _parameters['serach_term'] = searchTerm;
  }

  void filterQueries(List<FilterQuery> filterQueries) {
    for (final filter in filterQueries) {
      final key = 'filter_query[${filter.attribute}][${filter.operation}]';
      _parameters[key] = filter.value.toString();
    }
  }

  // ignore: avoid_positional_boolean_parameters
  void isStartPage(bool isStartPage) {
    _parameters['is_startpage'] = isStartPage ? '1' : '0';
  }

  void withTag(List<String> withTag) {
    _parameters['with_tag'] = withTag.reduce(
      (previous, current) => previous += ',$current',
    );
  }

  void page(int page) {
    _parameters['page'] = page.toString();
  }

  void perPage(int perPage) {
    _parameters['per_page'] = perPage.toString();
  }
}
