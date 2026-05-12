#include "include/azure_pronunciation_assessment/azure_pronunciation_assessment_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "azure_pronunciation_assessment_plugin.h"

void AzurePronunciationAssessmentPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  azure_pronunciation_assessment::AzurePronunciationAssessmentPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
