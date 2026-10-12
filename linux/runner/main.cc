#include "my_application.h"

constexpr char kSystemFontconfigFile[] = "/etc/fonts/fonts.conf";

// Points fontconfig at the bundled data/fontconfig/fonts.conf, which includes
// the system configuration and keeps CJK glyph fallback on sans faces
// (ADR-0095). A FONTCONFIG_FILE the user already set always wins.
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

int main(int argc, char** argv) {
  use_bundled_fontconfig();
  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
