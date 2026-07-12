/// Discriminator for the [AiResultCache] hierarchy.
///
/// Every entry persisted in the Drift `ai_cache` table or held in L1 is
/// tagged with one of these values so cross-modality collisions are
/// impossible at the SQL PK layer and at the fingerprint layer.
library;

enum AiKind {
  translation('translation'),
  dictionary('dictionary'),
  contextualTranslation('contextual_translation'),
  autoTranslateLine('auto_translate_line');

  const AiKind(this.wire);

  /// Stable string used in SQL rows, fingerprints, and logs.
  final String wire;
}
