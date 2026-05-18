// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_storyblok/otel_storyblok.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_storyblok-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('stories.list records cv + resolve_relations + cache', () async {
    await tracedStoryblok<String>(
      operation: 'stories.list',
      api: 'cdn',
      invoke: () async => const StoryblokCallResult(
        value: 'ok',
        result: StoryblokResult(
          itemCount: 25,
          total: 312,
          cvVersion: 1700000000,
          version: 'published',
          resolveRelations: 6,
          resolveLinksMode: 'story',
          componentTypes: 'page',
          contentLanguage: 'en',
          cacheHit: true,
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('storyblok stories.list')!);
    expect(a['storyblok.api'], 'cdn');
    expect(a['storyblok.version'], 'published');
    expect(a['storyblok.cv'], 1700000000);
    expect(a['storyblok.resolve_relations.count'], 6);
    expect(a['storyblok.cache.hit'], true);
  });

  test('suppression skips spans', () async {
    await runWithoutStoryblokInstrumentationAsync(() async {
      await tracedStoryblok<String>(
        operation: 'stories.list',
        invoke: () async => const StoryblokCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('storyblok '), isEmpty);
  });
}
