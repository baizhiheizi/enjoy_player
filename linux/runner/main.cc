#include "my_application.h"

constexpr char kSystemFontconfigFile[] = "/etc/fonts/fonts.conf";
constexpr char kApplicationDataDir[] = "ai.enjoy.player.enjoy_player";
constexpr char kSoftwareGlMarkerFile[] = "webview_software_gl";

// Points fontconfig at the bundled data/fontconfig/fonts.conf, which includes
// the system configuration and keeps CJK glyph fallback on sans faces at every
// weight (ADR-0095). A FONTCONFIG_FILE the user already set always wins.
static void use_bundled_fontconfig() {
  if (g_getenv("FONTCONFIG_FILE") != nullptr ||
      !g_file_test(kSystemFontconfigFile, G_FILE_TEST_EXISTS)) {
    return;
  }
  g_autofree gchar* exe = g_file_read_link("/proc/self/exe", nullptr);
  if (exe == nullptr) {
    return;
  }
  g_autofree gchar* dir = g_path_get_dirname(exe);
  g_autofree gchar* conf =
      g_build_filename(dir, "data", "fontconfig", "fonts.conf", nullptr);
  if (g_file_test(conf, G_FILE_TEST_EXISTS)) {
    g_setenv("FONTCONFIG_FILE", conf, TRUE);
  }
}

// The YouTube frame watchdog (ADR-0092, ADR-0096) persists this marker when
// the WPE hardware frame export stalls. LIBGL_ALWAYS_SOFTWARE is consulted by
// Mesa only at GL context creation, so it must be set here — before the
// engine and the WPE WebKit runtime create any context — for the whole
// process tree; arming it inside the running app cannot repair the stall.
// A value the user already set always wins.
static void arm_software_gl_marker() {
  if (g_getenv("LIBGL_ALWAYS_SOFTWARE") != nullptr) {
    return;
  }
  g_autofree gchar* marker = g_build_filename(g_get_user_data_dir(),
                                              kApplicationDataDir,
                                              kSoftwareGlMarkerFile, nullptr);
  if (g_file_test(marker, G_FILE_TEST_IS_REGULAR)) {
    g_setenv("LIBGL_ALWAYS_SOFTWARE", "1", TRUE);
  }
}

int main(int argc, char** argv) {
  arm_software_gl_marker();
  use_bundled_fontconfig();
  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
