#include "include/azure_speech/azure_speech_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "azure_speech_plugin.h"

void AzureSpeechPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  azure_speech::AzureSpeechPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
