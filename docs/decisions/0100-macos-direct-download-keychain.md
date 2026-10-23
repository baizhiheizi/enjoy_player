# ADR-0100: macOS secure storage on the Developer ID direct-download channel

## Status

Accepted

## Context

Issue #1044 reported that the macOS **direct-download** build fails secure
storage with `-34018` (`errSecMissingEntitlement`):

```
secureTokenStore: secure storage delete failed for "enjoy_player.cached_profile_json"
PlatformException(-34018, A required entitlement is not present.)
```

The issue's premise was that a sandboxed macOS app needs a
`keychain-access-groups` entitlement for *any* keychain access, and it
proposed baking a literal, expanded access group into the signed
entitlements at release-signing time. Both halves of that premise are
wrong, and the proposed fix breaks the channel it targets.

### The direct channel cannot carry a keychain access group

`macos/Runner/ReleaseDirect.entitlements` is what
[`notarize_release.sh`](../../macos/scripts/notarize_release.sh) signs the
Developer ID build with. It carries the App Sandbox and network
entitlements but **no** `keychain-access-groups` key, because a Developer ID
signature has no provisioning profile for the keychain groups to match
against.

Measured on macOS 26.5.2 (arm64) with the release Developer ID certificate
(`Developer ID Application: An Li (46X685R747)`), signing a probe bundle
with `--options runtime`:

| Signed entitlements | Result |
|---|---|
| shipping (`ReleaseDirect.entitlements`, no group) | launches; legacy keychain add/copy `0`; data-protection keychain `-34018` |
| `keychain-access-groups` = `46X685R747.ai.enjoy.player` | **killed at launch**, `SIGKILL` / exit 137 |
| `keychain-access-groups` = `ai.enjoy.player` | **killed at launch**, `SIGKILL` / exit 137 |
| `keychain-access-groups` = `[]` | **killed at launch**, `SIGKILL` / exit 137 |
| `com.apple.security.application-groups` | launches; data-protection keychain still `-34018` |

The kill is AMFI rejecting the entitlements, identically with and without a
secure timestamp:

```
amfid: Restricted entitlements not validated, bailing out.
        Error Domain=AppleMobileFileIntegrityError Code=-413 "No matching profile found"
amfid: .../probe.app/Contents/MacOS/probe not valid: Code=-413 "No matching profile found"
```

This is the "launch error 163" the release script's own header warns about,
so the entitlement the issue asks for would trade a recoverable
keychain error for an app that does not start at all.

### The legacy keychain works without any entitlement

The `-34018` comes from the **data-protection** keychain
(`kSecUseDataProtectionKeychain`), which is gated on a keychain access
group. The legacy keychain is not: on the shipping entitlements, add, copy
and delete of a generic-password item all return `0`.

`flutter_secure_storage` picks the data-protection keychain whenever
`MacOsOptions.usesDataProtectionKeychain` is `true` — which is the
`MacOsOptions.defaultOptions` value. `SecureTokenStore` has overridden it
with `false` since `0bd28bc3` (v0.4.0); `ByokSecretStore` never did, so
**every** BYOK read, write, and delete failed with `-34018` on the direct
channel.

### The delete error is a false alarm

`flutter_secure_storage_darwin` 0.3.2 deletes an item by probing the
synchronizable domain first and the non-synchronizable domain second, and
only reports success when one of them returns `errSecSuccess` or both
return `errSecItemNotFound`. On the direct channel the synchronizable probe
returns `-34018`, so the verdict becomes `-34018` whenever the item was
**already absent** — which is exactly the cold-start case
(`loadInitialAuthState` → `clearCachedProfile()` with no access token).
Measured against the shipping entitlements:

```
SecItemAdd                                    : 0
plugin delete [item PRESENT]                 : sync=-34018 nonSync=0     verdict=0
plugin delete [item ABSENT]                  : sync=-34018 nonSync=-25300 verdict=-34018
```

A `-34018` from a delete therefore means "already gone", not "secret still
on disk" — but the app logged it as a failure on every cold start.

## Decision

1. **The direct channel keeps no keychain access group.** `ReleaseDirect.entitlements`
   stays as it is. Any future attempt to add `keychain-access-groups` to it
   must be rejected unless it is shown not to trip AMFI `-413`.

2. **One shared secure-storage backend.** `secureStorageBackend`
   ([`lib/data/api/secure_storage_options.dart`](../../lib/data/api/secure_storage_options.dart))
   is the single `FlutterSecureStorage` instance every store uses. Its macOS
   options set `usesDataProtectionKeychain: false`, so **all** macOS secrets
   live in the legacy keychain on every macOS build — local Xcode builds
   included, where the data-protection keychain would also have worked. One
   store can no longer drift from the others.

3. **Deletes treat a missing entitlement as "already absent".**
   `deleteSecureStorageKey` ([`lib/data/api/secure_storage_delete.dart`](../../lib/data/api/secure_storage_delete.dart))
   swallows `-34018` and lets every other status through. `SecureTokenStore`
   and `ByokSecretStore` both delete through it, so the misleading
   "secure storage delete failed" warning is gone from the direct channel
   while a genuinely broken keyring still surfaces.

4. **The stale documentation is corrected.** `docs/packaging.md` and
   `docs/features/auth.md` claimed the direct build ships an app keychain
   group. They now describe what the channel actually signs.

## Consequences

* **BYOK works on the direct channel.** A macOS direct-download user can
  save, read, and delete their own provider API keys; before this change
  every one of those operations failed with `-34018`.
* **The cold-start `-34018` warning is gone.** Deleting an already-absent
  key is no longer reported as a failure.
* **A BYOK key saved by a local macOS build has to be re-entered.** Local
  builds stored BYOK keys in the data-protection keychain; they now live in
  the legacy keychain like everything else. Auth tokens are unaffected —
  they have used the legacy keychain since v0.4.0.
* **Signing out is unchanged on the other platforms.** `-34018` is a macOS
  keychain status; iOS, Android, Windows, and Linux never produce it.
* **The direct channel is now the only macOS configuration** that matters
  for keychain access, because every macOS build uses the same legacy
  keychain. `DebugProfile.entitlements` and `Release.entitlements` keep
  their `keychain-access-groups` entry for Xcode runs; it is not what makes
  secure storage work there.
* **The issue's proposal (a) is rejected** on the evidence above, and its
  proposal (b) — moving macOS off `flutter_secure_storage` to a file-based
  store — is not needed: the legacy keychain is a real, OS-managed keyring.

## References

* Issue #1044 — the report this ADR answers.
* Issue #1033 — the macOS report whose side note surfaced the `-34018`.
* [`docs/features/auth.md`](../features/auth.md) — secure-storage
  configuration.
* [`docs/packaging.md`](../packaging.md) — Apple signing and notarization.
* `0bd28bc3` — "fix(macos): restore keychain access and resilient auth
  cold-start", which first pinned `usesDataProtectionKeychain: false` on the
  token store.
* `5a45c3de` — "fix(macos): unblock Developer ID direct download launch on
  macOS 26", which introduced `ReleaseDirect.entitlements`.
