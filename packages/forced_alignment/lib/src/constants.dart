/// Sample rate of every PCM buffer accepted by this package.
const int kAlignmentSampleRate = 16000;

/// Minimum extractable audio duration (whole clip or a single cue).
const double kMinAudioSeconds = 1.0;

/// Whole-clip [align] refuses longer source audio; use [alignSegments].
const double kMaxWholeClipSeconds = 90.0;

/// Allowed overshoot of per-cue word times past the cue window.
const double kCuePadSeconds = 0.050;

const Duration kDefaultWholeClipTimeout = Duration(minutes: 2);

const Duration kDefaultPerCueTimeout = Duration(seconds: 30);

/// Sakoe-Chiba band as a fraction of max(sequence lengths).
const double kSakoeChibaWindowPct = 0.20;

/// Absolute cap on the Sakoe-Chiba band, in seconds of drift from the
/// linear (diagonal) time mapping (issue #827 A2). The band only needs to
/// absorb **nonlinear** drift — the diagonal itself already accounts for
/// linear rate differences between the spoken reference and the source —
/// so capping it keeps band memory linear in the sequence length instead
/// of growing with 20% of the clip. Clips up to 50 s keep the full
/// 20% band (0.2 × 50 s = 10 s); only longer, whole-clip inputs are
/// clamped.
const double kSakoeChibaMaxDriftSeconds = 10.0;
