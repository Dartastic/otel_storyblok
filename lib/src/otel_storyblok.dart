// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_storyblok_suppression.dart';

const _tracerName = 'dartastic_otel_libs_storyblok';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

class StoryblokResult {
  /// Creates a result.
  const StoryblokResult({
    this.itemCount,
    this.total,
    this.cvVersion,
    this.version,
    this.resolveRelations,
    this.resolveLinksMode,
    this.componentTypes,
    this.contentLanguage,
    this.cacheHit,
    this.requestId,
    this.statusCode,
  });

  /// `stories.length` for list endpoints.
  final int? itemCount;

  /// `total` header / response field.
  final int? total;

  /// `cv` (cache version) — bumping this forces fresh CDN reads, so a
  /// surge in span counts at a new cv value is the canonical signal.
  final int? cvVersion;

  /// `published` / `draft` — draft reads bypass the CDN.
  final String? version;

  /// Number of relations expanded via `resolve_relations`. Storyblok
  /// inlines linked stories; high counts blow up response size.
  final int? resolveRelations;

  /// `0` / `1` / `link` / `url` / `story` — how internal links were
  /// resolved.
  final String? resolveLinksMode;

  /// `content_type` filter applied (e.g. `page`, `article`).
  final String? componentTypes;

  final String? contentLanguage;

  /// CDN cache hit.
  final bool? cacheHit;

  /// `X-Request-Id`.
  final String? requestId;

  final int? statusCode;
}

/// What a traced call returned: the value for the caller plus fields
/// recorded on the span.
class StoryblokCallResult<T> {
  /// Creates a call result.
  const StoryblokCallResult({required this.value, this.result});

  /// The value returned to the caller.
  final T value;
  final StoryblokResult? result;
}

/// Wraps a Storyblok API call in a CLIENT span. [operation] is one of
/// `stories.list`, `stories.get`, `stories.create`, `stories.update`,
/// `stories.delete`, `stories.publish`, `links`, `tags`, `datasources`,
/// `assets`, `spaces`, `graphql`.
Future<T> tracedStoryblok<T>({
  required String operation,
  required Future<StoryblokCallResult<T>> Function() invoke,
  String? api,
  String? spaceId,
}) async {
  if (storyblokInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'storyblok',
    'rpc.method': operation,
    'storyblok.operation': operation,
  };
  if (api != null) m['storyblok.api'] = api;
  if (spaceId != null) m['storyblok.space.id'] = spaceId;

  final span = _tracer().startSpan(
    'storyblok $operation',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.itemCount != null) {
        extras.add(OTelAPI.attributeInt(
          'storyblok.item_count',
          r.result!.itemCount!,
        ));
      }
      if (r.result!.total != null) {
        extras.add(OTelAPI.attributeInt(
          'storyblok.total',
          r.result!.total!,
        ));
      }
      if (r.result!.cvVersion != null) {
        extras.add(OTelAPI.attributeInt(
          'storyblok.cv',
          r.result!.cvVersion!,
        ));
      }
      if (r.result!.version != null) {
        extras.add(OTelAPI.attributeString(
          'storyblok.version',
          r.result!.version!,
        ));
      }
      if (r.result!.resolveRelations != null) {
        extras.add(OTelAPI.attributeInt(
          'storyblok.resolve_relations.count',
          r.result!.resolveRelations!,
        ));
      }
      if (r.result!.resolveLinksMode != null) {
        extras.add(OTelAPI.attributeString(
          'storyblok.resolve_links',
          r.result!.resolveLinksMode!,
        ));
      }
      if (r.result!.componentTypes != null) {
        extras.add(OTelAPI.attributeString(
          'storyblok.component_types',
          r.result!.componentTypes!,
        ));
      }
      if (r.result!.contentLanguage != null) {
        extras.add(OTelAPI.attributeString(
          'storyblok.language',
          r.result!.contentLanguage!,
        ));
      }
      if (r.result!.cacheHit != null) {
        extras.add(OTelAPI.attributeBool(
          'storyblok.cache.hit',
          r.result!.cacheHit!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTelAPI.attributeString(
          'storyblok.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTelAPI.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Storyblok HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTelAPI.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
