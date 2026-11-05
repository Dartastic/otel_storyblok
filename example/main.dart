// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_storyblok/otel_storyblok.dart';

/// Traces Storyblok calls with OpenTelemetry.
///
/// `otel_storyblok` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Storyblok call in
/// [tracedStoryblok]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'storyblok-example');

  // Wraps a Storyblok API call in a CLIENT span.
  final storyblokId = await tracedStoryblok<String>(
    operation: 'stories.create',
    api: 'example',
    spaceId: 'space_8f3a2c',
    invoke: () async {
      // Make the Storyblok call here, then report what it returned.
      const id = 'storyblok_8f3a2c';
      return const StoryblokCallResult(
          value: id,
          result: StoryblokResult(
              itemCount: 3,
              total: 1,
              cvVersion: 1,
              version: 'published',
              resolveRelations: 1,
              resolveLinksMode: '0',
              componentTypes: 'content_type',
              contentLanguage: 'en',
              cacheHit: true,
              requestId: 'request_8f3a2c',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedStoryblok stories.create returned $storyblokId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutStoryblokInstrumentationAsync.
  await runWithoutStoryblokInstrumentationAsync(
    () => tracedStoryblok<String>(
      operation: 'stories.create',
      api: 'example',
      spaceId: 'space_8f3a2c',
      invoke: () async {
        const id = 'storyblok_8f3a2c';
        return const StoryblokCallResult(
            value: id,
            result: StoryblokResult(
                itemCount: 3,
                total: 1,
                cvVersion: 1,
                version: 'published',
                resolveRelations: 1,
                resolveLinksMode: '0',
                componentTypes: 'content_type',
                contentLanguage: 'en',
                cacheHit: true,
                requestId: 'request_8f3a2c',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
