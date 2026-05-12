#ifndef FLUTTER_PLUGIN_AZURE_SPEECH_PLUGIN_H_
#define FLUTTER_PLUGIN_AZURE_SPEECH_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace azure_speech {

class AzureSpeechPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  AzureSpeechPlugin();

  virtual ~AzureSpeechPlugin();

 private:
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;

  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace azure_speech

#endif  // FLUTTER_PLUGIN_AZURE_SPEECH_PLUGIN_H_
