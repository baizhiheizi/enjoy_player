/// Sign-in, profile fetch, and session lifecycle.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/features/auth/data/auth_repository.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/update_profile_request.dart';

part 'auth_controller.g.dart';

final Logger _log = logNamed('auth');

@Riverpod(keepAlive: true)
class AuthCtrl extends _$AuthCtrl {
  Timer? _pollTimer;
  int _pollGeneration = 0;

  @override
  Future<AuthState> build() async {
    ref.onDispose(() {
      _pollTimer?.cancel();
      _pollTimer = null;
    });
    final sw = Stopwatch()..start();
    _log.info('auth: loadInitialAuthState start');
    try {
      final state = await ref.read(authRepositoryProvider).loadInitialAuthState();
      _log.info(
        'auth: loadInitialAuthState done in ${sw.elapsedMilliseconds}ms '
        '(${state.runtimeType})',
      );
      return state;
    } catch (e, st) {
      _log.warning(
        'auth: loadInitialAuthState failed after ${sw.elapsedMilliseconds}ms',
        e,
        st,
      );
      rethrow;
    }
  }

  Future<void> startSignIn() async {
    final repo = ref.read(authRepositoryProvider);
    _pollTimer?.cancel();
    _log.info('auth: calling start_auth');
    final start = await repo.startAuth();
    final gen = ++_pollGeneration;
    state = AsyncData(
      AuthSigningIn(
        requestId: start.requestId,
        verificationUrl: start.verificationUrl,
        startedAt: DateTime.now(),
      ),
    );
    final uri = Uri.parse(start.verificationUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      _pollTimer?.cancel();
      state = const AsyncData(AuthSignedOut());
      _log.warning('launchUrl failed for $uri');
      return;
    }

    // [Timer.periodic] waits one full period before the first tick — run an
    // immediate poll so HTTP logs and approval appear without a 2s gap.
    Future<void> pollTick() async {
      if (gen != _pollGeneration) return;
      final s = state.valueOrNull;
      if (s is! AuthSigningIn) {
        _pollTimer?.cancel();
        return;
      }
      if (DateTime.now().difference(s.startedAt) > const Duration(minutes: 5)) {
        _pollTimer?.cancel();
        state = const AsyncData(AuthSignedOut());
        return;
      }
      try {
        final outcome = await repo.pollAuth(s.requestId);
        if (gen != _pollGeneration) return;
        if (outcome is PollAuthOutcomeApproved) {
          _pollTimer?.cancel();
          await repo.persistAccessToken(outcome.accessToken);
          final profile = await repo.fetchProfile();
          if (gen != _pollGeneration) return;
          state = AsyncData(AuthSignedIn(profile: profile));
          await ref
              .read(appPreferencesCtrlProvider.notifier)
              .applyFromUserProfile(profile);
        }
      } catch (e, st) {
        _log.warning('poll auth failed', e, st);
      }
    }

    _log.info('auth: polling until approved (every 2s, first tick now)');
    unawaited(pollTick());
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      unawaited(pollTick());
    });
  }

  void cancelSignIn() {
    _pollGeneration++;
    _pollTimer?.cancel();
    _pollTimer = null;
    final current = state.valueOrNull;
    if (current is AuthSigningIn) {
      state = const AsyncData(AuthSignedOut());
    }
  }

  Future<void> signOut() async {
    _pollGeneration++;
    _pollTimer?.cancel();
    _pollTimer = null;
    await ref.read(authRepositoryProvider).clearSession();
    state = const AsyncData(AuthSignedOut());
  }

  Future<void> refreshProfile() async {
    final cur = state.valueOrNull;
    if (cur is! AuthSignedIn) return;
    final profile = await ref.read(authRepositoryProvider).fetchProfile();
    state = AsyncData(AuthSignedIn(profile: profile));
    await ref
        .read(appPreferencesCtrlProvider.notifier)
        .applyFromUserProfile(profile);
  }

  Future<void> updateProfile(UpdateProfileRequest request) async {
    final cur = state.valueOrNull;
    if (cur is! AuthSignedIn) return;
    final profile =
        await ref.read(authRepositoryProvider).updateProfile(request);
    state = AsyncData(AuthSignedIn(profile: profile));
    await ref
        .read(appPreferencesCtrlProvider.notifier)
        .applyFromUserProfile(profile);
  }

  /// When the user changes UI locale while signed in, keep server profile in sync.
  Future<void> syncLocaleToServerIfSignedIn(Locale? locale) async {
    final cur = state.valueOrNull;
    if (cur is! AuthSignedIn) return;
    final tag = locale?.toLanguageTag();
    if (tag == null) return;
    await updateProfile(UpdateProfileRequest(locale: tag));
  }
}
