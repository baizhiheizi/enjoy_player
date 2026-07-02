# REST service layer (`RestApi` + `JsonMap`)

Reference for the thin REST service wrappers under
[`lib/data/api/services/`](../../lib/data/api/services/). Every `*Api` class in
that folder follows the same shape: it extends `RestApi`, owns no HTTP state of
its own, and returns `JsonMap` / `List<JsonMap>` instead of `Map<String,
dynamic>` / `List<Map<String, dynamic>>`.

This page is the canonical "how do I add a new REST endpoint?" reference. The
rationale for the pattern lives in commit
`218c3fc refactor(api): extract RestApi base and shared JsonMap typedef (#170)`
(closes #161).

## The two building blocks

### `RestApi` (abstract base)

Defined in [`lib/data/api/rest_api.dart`](../../lib/data/api/rest_api.dart):

```dart
abstract class RestApi {
  const RestApi(this.client);

  @protected
  final ApiClient client;
}
```

- One constructor parameter: the shared [`ApiClient`](../../lib/data/api/api_client.dart).
- `client` is `@protected` rather than private. Dart's `_` privacy is
  per-library, and each service lives in its own file/library — a private field
  declared here would not be visible to subclasses declared elsewhere. The
  analyzer-enforced `@protected` annotation keeps it package-internal.
- Subclasses pass the client through with `super.client` (or `super(args)` when
  the subclass takes more).

### `JsonMap` (shared typedef)

Defined in [`lib/data/api/api_client.dart`](../../lib/data/api/api_client.dart):

```dart
/// Shared alias for decoded JSON objects; import from here instead of
/// redeclaring per service file.
typedef JsonMap = Map<String, dynamic>;
```

- Import `JsonMap` from `api_client.dart`, **do not** redeclare a per-file
  typedef. (Eight files used to repeat `typedef JsonMap = Map<String, dynamic>;`
  verbatim before the refactor.)
- `List<JsonMap>` is the canonical response shape for collection endpoints.

## Adding a new REST service

1. Create `lib/data/api/services/<area>/<name>_api.dart`.
2. Extend `RestApi` and forward the client to `super`:

   ```dart
   /// Short, plain-English summary of the endpoints covered.
   library;

   import 'package:enjoy_player/data/api/api_client.dart';
   import 'package:enjoy_player/data/api/rest_api.dart';

   class FooApi extends RestApi {
     FooApi(super.client);

     static const _path = '/api/v1/foo';

     Future<JsonMap> getFoo(String id) => client.getJson('$_path/$id');

     Future<List<JsonMap>> listFoo() => client.getJsonList(_path);
   }
   ```

3. Expose it through a Riverpod provider next to the other `*ApiProvider`s
   (e.g. under `services/<area>/<name>_api_provider.dart`) using
   `@Riverpod(keepAlive: true)` and the right `*ApiClientProvider` — see
   [`api_client_provider.dart`](../../lib/data/api/api_client_provider.dart) for
   the three clients in play (`authApiClient`, `apiClient`, `aiApiClient`).
4. Add or update the feature doc under `docs/features/` in the same PR,
   following [docs/README.md](../README.md#how-to-update-a-feature-spec).

## Choosing an `ApiClient`

`ApiClient` instances are wired in
[`api_client_provider.dart`](../../lib/data/api/api_client_provider.dart). Pick
the one whose base URL and auth posture matches your endpoint:

| Provider | Base URL | Auth | Use for |
|----------|----------|------|---------|
| `authApiClientProvider` | `apiBaseUrlProvider` | sends access token, no refresh hook | Pre-session calls and any service that should never trigger a refresh |
| `apiClientProvider` | `apiBaseUrlProvider` | sends access token; on 401, calls `authRepository.refreshSession()` once, then retries | Default for signed-in app traffic (profile, library, sync, recordings, subscription, stats, …) |
| `aiApiClientProvider` | `aiApiBaseUrlProvider` | sends access token, no refresh hook | Worker routes (chat, ASR, translation, YouTube transcripts, Azure token, credits) — these hit a separate origin so they must not inherit the Rails API base |

## What `ApiClient` gives you for free

`RestApi` only owns the client field — every HTTP concern is delegated to
[`ApiClient`](../../lib/data/api/api_client.dart). You should rarely need to
touch HTTP manually inside a service:

- `getJson` / `postJson` / `patchJson` / `deleteJson` — JSON-only requests with
  the right verb and bearer header.
- `getJsonList` — typed list helper.
- `postMultipartJson` — `multipart/form-data` for Whisper-style uploads
  (added in [ADR-0014](../decisions/0014-ai-capabilities-layer.md)).
- Automatic `camelCase` ↔ `snake_case` conversion via
  [`case_conversion.dart`](../../lib/data/api/case_conversion.dart).
- Trace logging under the `api` logger ([`logNamed('api')`](../../lib/data/api/api_client.dart)).

## Anti-patterns

- **Do not** declare a per-file `typedef JsonMap`. Import it from
  `api_client.dart`.
- **Do not** add your own `http.Client` field. Use the one already on
  `ApiClient`.
- **Do not** instantiate `ApiClient` directly in a service. Always go through
  one of the three Riverpod providers above so base URL, token refresh, and
  disposal stay wired correctly.
- **Do not** construct services in widgets. Expose them as Riverpod providers
  in `services/<area>/` and let feature code depend on the provider type, not
  the service class.

## Examples in tree

Reference services that already follow this pattern (each is a thin
`RestApi` subclass returning `JsonMap`):

- [`auth_api.dart`](../../lib/data/api/services/auth_api.dart) — sign-in, OTP,
  PKCE, refresh, profile.
- [`audio_api.dart`](../../lib/data/api/services/audio_api.dart) —
  `/api/v1/mine/audios` CRUD.
- [`video_api.dart`](../../lib/data/api/services/video_api.dart) — both the
  `mine/videos` and the public `videos` listing endpoints.
- [`subscription_api.dart`](../../lib/data/api/services/subscription_api.dart)
  — Pro status and purchase.
- [`services/ai/`](../../lib/data/api/services/ai/) — `AsrApi`, `ChatApi`,
  `TranslationApi`, `DictionaryApi`, `AzureTokenApi`, `CreditsApi`,
  `YoutubeTranscriptsApi`.

## Related references

- [architecture.md § *Optional Enjoy account (auth)*](../architecture.md#optional-enjoy-account-auth)
- [decisions/0014-ai-capabilities-layer.md](../decisions/0014-ai-capabilities-layer.md)
- [decisions/0027-native-auth-v2.md](../decisions/0027-native-auth-v2.md)
- [features/auth.md](../features/auth.md)
- [features/ai.md](../features/ai.md)