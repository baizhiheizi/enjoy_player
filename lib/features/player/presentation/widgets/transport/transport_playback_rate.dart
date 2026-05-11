/// Presets and labels for transport playback speed menu.
library;

const kPlaybackRatePresets = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

const playbackRateEpsilon = 0.01;

bool playbackRatesEqual(double a, double b) =>
    (a - b).abs() < playbackRateEpsilon;
