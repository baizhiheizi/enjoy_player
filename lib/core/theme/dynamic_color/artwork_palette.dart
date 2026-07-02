/// Artwork color extraction via palette_generator.
/// Results are cached in-process by thumbnail-path + size + mtime so a
/// regenerated artwork file (re-thumbnailed, re-encoded, etc.) invalidates
/// the previously cached palette instead of being masked by it.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

/// Composite key for the in-process artwork palette cache. Records have
/// structural equality, so map lookups by `(path, size, mtime)` value work
/// without an explicit `==` / `hashCode` override.
typedef CacheKey = ({String path, int size, int mtime});

/// Builds a [CacheKey] from a file path + [FileStat]. Exposed for tests.
@visibleForTesting
CacheKey artworkPaletteCacheKey(String path, FileStat stat) =>
    (path: path, size: stat.size, mtime: stat.modified.millisecondsSinceEpoch);

/// Extracted colors from a piece of media artwork.
class ArtworkPalette {
  const ArtworkPalette({
    required this.dominant,
    required this.accent,
    required this.onAccent,
    required this.vibrant,
  });

  /// Dominant (most common) color — used for backdrop tint.
  final Color dominant;

  /// Vibrant accent — used for ring glow and active-line rail.
  final Color accent;

  /// High-contrast text color readable on [accent].
  final Color onAccent;

  /// Raw vibrant swatch (may equal accent).
  final Color vibrant;

  static ArtworkPalette fromScheme(ColorScheme scheme) => ArtworkPalette(
    dominant: scheme.primaryContainer,
    accent: scheme.primary,
    onAccent: scheme.onPrimary,
    vibrant: scheme.primary,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtworkPalette &&
          other.dominant == dominant &&
          other.accent == accent &&
          other.onAccent == onAccent &&
          other.vibrant == vibrant;

  @override
  int get hashCode => Object.hash(dominant, accent, onAccent, vibrant);
}

/// LRU-bounded in-process cache keyed on (path, size, mtime). Records have
/// structural equality so no custom comparator is required. LRU order is
/// tracked in a plain growable list where the last element is the most
/// recently used.
final _cache = <CacheKey, ArtworkPalette>{};
final _cacheOrder = <CacheKey>[];
const _kCacheMax = 32;

/// Reads-then-evicts: drops any cached entry for [path] whose recorded
/// `(size, mtime)` no longer matches the file's current stat. Returns the
/// matching live entry, or null when the cache has nothing current for it.
ArtworkPalette? _lookupFresh(String path, FileStat stat) {
  final current = artworkPaletteCacheKey(path, stat);
  final staleIndices = <int>[];
  ArtworkPalette? hit;
  for (var i = 0; i < _cacheOrder.length; i++) {
    final key = _cacheOrder[i];
    if (key.path != path) continue;
    if (key == current) {
      hit = _cache[key];
      // Move to end to mark it as most-recently-used.
      _cacheOrder.removeAt(i);
      _cacheOrder.add(key);
      break;
    }
    staleIndices.add(i);
  }
  for (final i in staleIndices.reversed) {
    final key = _cacheOrder.removeAt(i);
    _cache.remove(key);
  }
  return hit;
}

/// Records [palette] under [key], evicting the LRU tail once we hit the cap.
void _store(CacheKey key, ArtworkPalette palette) {
  if (_cache.length >= _kCacheMax && !_cache.containsKey(key)) {
    final oldest = _cacheOrder.removeAt(0);
    _cache.remove(oldest);
  }
  _cache[key] = palette;
  _cacheOrder.remove(key);
  _cacheOrder.add(key);
}

/// Test seams for the cache.
@visibleForTesting
void debugResetArtworkPaletteCache() {
  _cache.clear();
  _cacheOrder.clear();
}

@visibleForTesting
int debugArtworkPaletteCacheSize() => _cache.length;

@visibleForTesting
bool debugArtworkPaletteCacheContainsPath(String path) =>
    _cacheOrder.any((k) => k.path == path);

@visibleForTesting
ArtworkPalette? debugLookupArtworkPalette(String path, FileStat stat) =>
    _lookupFresh(path, stat);

@visibleForTesting
void debugPutArtworkPalette(
  String path,
  FileStat stat,
  ArtworkPalette palette,
) {
  _store(artworkPaletteCacheKey(path, stat), palette);
}

/// Extracts [ArtworkPalette] from a local file path.
/// Returns null if the file is absent or extraction fails.
Future<ArtworkPalette?> extractArtworkPalette(String? thumbnailPath) async {
  if (thumbnailPath == null || thumbnailPath.isEmpty) return null;

  final file = File(thumbnailPath);
  if (!await file.exists()) return null;

  final stat = await file.stat();

  // Cache hit: re-use the previous palette only if the file is byte-identical
  // (same `size` and `mtime`) to the entry we computed for.
  final hit = _lookupFresh(thumbnailPath, stat);
  if (hit != null) return hit;

  try {
    final generator = await PaletteGenerator.fromImageProvider(
      FileImage(file),
      size: const Size(200, 200),
      maximumColorCount: 16,
    );

    final dominant =
        generator.dominantColor?.color ??
        generator.mutedColor?.color ??
        const Color(0xFF1A1A22);

    final vibrant =
        generator.vibrantColor?.color ??
        generator.lightVibrantColor?.color ??
        generator.dominantColor?.color ??
        dominant;

    // Compute a readable on-color for the accent.
    final luminance = vibrant.computeLuminance();
    final onAccent = luminance > 0.4 ? const Color(0xFF0B0B10) : Colors.white;

    final palette = ArtworkPalette(
      dominant: dominant,
      accent: vibrant,
      onAccent: onAccent,
      vibrant: vibrant,
    );

    _store(artworkPaletteCacheKey(thumbnailPath, stat), palette);
    return palette;
  } catch (_) {
    return null;
  }
}
