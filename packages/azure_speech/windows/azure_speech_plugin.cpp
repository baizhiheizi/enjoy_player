#include "azure_pronunciation_assessment_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>
#include <string>

#include <speechapi_cxx.h>

using Microsoft::CognitiveServices::Speech::Audio::AudioConfig;
using Microsoft::CognitiveServices::Speech::CancellationDetails;
using Microsoft::CognitiveServices::Speech::PropertyId;
using Microsoft::CognitiveServices::Speech::PronunciationAssessmentConfig;
using Microsoft::CognitiveServices::Speech::PronunciationAssessmentGranularity;
using Microsoft::CognitiveServices::Speech::PronunciationAssessmentGradingSystem;
using Microsoft::CognitiveServices::Speech::ResultReason;
using Microsoft::CognitiveServices::Speech::SpeechConfig;
using Microsoft::CognitiveServices::Speech::SpeechRecognizer;

namespace azure_pronunciation_assessment {

namespace {

std::string GetString(const flutter::EncodableMap& map, const char* key) {
  auto it = map.find(flutter::EncodableValue(key));
  if (it == map.end()) return {};
  const auto* s = std::get_if<std::string>(&it->second);
  return s ? *s : std::string();
}

bool GetBool(const flutter::EncodableMap& map, const char* key, bool def) {
  auto it = map.find(flutter::EncodableValue(key));
  if (it == map.end()) return def;
  const auto* b = std::get_if<bool>(&it->second);
  return b ? *b : def;
}

int GetInt(const flutter::EncodableMap& map, const char* key, int def) {
  auto it = map.find(flutter::EncodableValue(key));
  if (it == map.end()) return def;
  if (const auto* i = std::get_if<int32_t>(&it->second)) return *i;
  if (const auto* i64 = std::get_if<int64_t>(&it->second)) return static_cast<int>(*i64);
  return def;
}

PronunciationAssessmentGranularity ParseGranularity(const std::string& s) {
  if (s == "Word") return PronunciationAssessmentGranularity::Word;
  if (s == "FullText") return PronunciationAssessmentGranularity::FullText;
  return PronunciationAssessmentGranularity::Phoneme;
}

flutter::EncodableValue RunAssess(const flutter::EncodableMap& args) {
  const std::string audio_path = GetString(args, "audioPath");
  const std::string reference_text = GetString(args, "referenceText");
  const std::string language = GetString(args, "language");
  const std::string token = GetString(args, "token");
  const std::string region = GetString(args, "region");
  const bool enable_prosody = GetBool(args, "enableProsody", true);
  const bool enable_miscue = GetBool(args, "enableMiscue", true);
  const int nbest = GetInt(args, "nbestPhonemeCount", 1);
  std::string phoneme_alphabet = GetString(args, "phonemeAlphabet");
  if (phoneme_alphabet.empty()) phoneme_alphabet = "IPA";
  std::string gran_s = GetString(args, "granularity");
  if (gran_s.empty()) gran_s = "Phoneme";

  auto config = SpeechConfig::FromAuthorizationToken(token, region);
  config->SetSpeechRecognitionLanguage(language);

  auto audio_config = AudioConfig::FromWavFileInput(audio_path);

  auto pronunciation_config = PronunciationAssessmentConfig::Create(
      reference_text, PronunciationAssessmentGradingSystem::HundredMark,
      ParseGranularity(gran_s), enable_miscue);
  if (enable_prosody) {
    pronunciation_config->EnableProsodyAssessment();
  }
  pronunciation_config->SetPhonemeAlphabet(phoneme_alphabet);
  pronunciation_config->SetNBestPhonemeCount(static_cast<uint32_t>(nbest));

  auto recognizer = SpeechRecognizer::FromConfig(config, audio_config);
  pronunciation_config->ApplyTo(recognizer);

  auto speech_result = recognizer->RecognizeOnceAsync().get();

  if (speech_result->Reason == ResultReason::RecognizedSpeech) {
    std::string json = speech_result->Properties.GetProperty(
        PropertyId::SpeechServiceResponse_JsonResult);
    if (json.empty()) {
      return flutter::EncodableValue(flutter::EncodableMap{
          {flutter::EncodableValue("error"),
           flutter::EncodableValue("azure_speech_error")},
          {flutter::EncodableValue("message"),
           flutter::EncodableValue("Empty JsonResult")}});
    }
    return flutter::EncodableValue(json);
  }
  if (speech_result->Reason == ResultReason::NoMatch) {
    return flutter::EncodableValue(flutter::EncodableMap{
        {flutter::EncodableValue("error"), flutter::EncodableValue("no_speech")},
        {flutter::EncodableValue("message"),
         flutter::EncodableValue("No speech detected")}});
  }

  auto cancel = CancellationDetails::FromResult(speech_result);
  std::ostringstream oss;
  oss << static_cast<int>(cancel->Reason) << ": " << cancel->ErrorDetails;
  const std::string msg = oss.str();
  return flutter::EncodableValue(flutter::EncodableMap{
      {flutter::EncodableValue("error"), flutter::EncodableValue("azure_speech_error")},
      {flutter::EncodableValue("message"), flutter::EncodableValue(msg)}});
}

}  // namespace

void AzurePronunciationAssessmentPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto plugin = std::make_unique<AzurePronunciationAssessmentPlugin>();
  plugin->channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), "azure_pronunciation_assessment",
      &flutter::StandardMethodCodec::GetInstance());

  plugin->channel_->SetMethodCallHandler(
      [ptr = plugin.get()](const auto& call, auto result) {
        ptr->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

AzurePronunciationAssessmentPlugin::AzurePronunciationAssessmentPlugin() = default;

AzurePronunciationAssessmentPlugin::~AzurePronunciationAssessmentPlugin() = default;

void AzurePronunciationAssessmentPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name() != "assess") {
    result->NotImplemented();
    return;
  }

  const auto* args = std::get_if<flutter::EncodableMap>(method_call.arguments());
  if (!args) {
    result->Error("bad_args", "Expected map arguments");
    return;
  }

  try {
    flutter::EncodableValue out = RunAssess(*args);
    if (const auto* err_map = std::get_if<flutter::EncodableMap>(&out)) {
      auto e_it = err_map->find(flutter::EncodableValue("error"));
      if (e_it != err_map->end()) {
        const auto* code = std::get_if<std::string>(&e_it->second);
        std::string message;
        auto m_it = err_map->find(flutter::EncodableValue("message"));
        if (m_it != err_map->end()) {
          if (const auto* ms = std::get_if<std::string>(&m_it->second)) {
            message = *ms;
          }
        }
        result->Error(code ? *code : "azure_speech_error", message, flutter::EncodableValue());
        return;
      }
    }
    if (const auto* json = std::get_if<std::string>(&out)) {
      result->Success(flutter::EncodableValue(*json));
      return;
    }
    result->Error("azure_speech_error", "Unexpected native result shape");
  } catch (const std::exception& e) {
    result->Error("azure_speech_error", e.what());
  } catch (...) {
    result->Error("azure_speech_error", "Unknown native error");
  }
}

}  // namespace azure_pronunciation_assessment
