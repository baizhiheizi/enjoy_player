#include "azure_speech_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <chrono>
#include <memory>
#include <sstream>
#include <string>
#include <thread>
#include <vector>

#include <speechapi_cxx.h>

using Microsoft::CognitiveServices::Speech::Audio::AudioConfig;
using Microsoft::CognitiveServices::Speech::Audio::AudioOutputStream;
using Microsoft::CognitiveServices::Speech::CancellationDetails;
using Microsoft::CognitiveServices::Speech::PropertyId;
using Microsoft::CognitiveServices::Speech::PronunciationAssessmentConfig;
using Microsoft::CognitiveServices::Speech::PronunciationAssessmentGranularity;
using Microsoft::CognitiveServices::Speech::PronunciationAssessmentGradingSystem;
using Microsoft::CognitiveServices::Speech::ResultReason;
using Microsoft::CognitiveServices::Speech::SpeechConfig;
using Microsoft::CognitiveServices::Speech::SpeechRecognizer;
using Microsoft::CognitiveServices::Speech::SpeechSynthesizer;
using Microsoft::CognitiveServices::Speech::SpeechSynthesisCancellationDetails;

namespace azure_speech {

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

std::string Base64Encode(const std::vector<uint8_t>& data) {
  static const char kTable[] =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  std::string out;
  out.reserve(((data.size() + 2) / 3) * 4);
  size_t i = 0;
  while (i + 2 < data.size()) {
    const uint32_t n = (static_cast<uint32_t>(data[i]) << 16) |
                       (static_cast<uint32_t>(data[i + 1]) << 8) |
                       static_cast<uint32_t>(data[i + 2]);
    out.push_back(kTable[(n >> 18) & 63]);
    out.push_back(kTable[(n >> 12) & 63]);
    out.push_back(kTable[(n >> 6) & 63]);
    out.push_back(kTable[n & 63]);
    i += 3;
  }
  if (i < data.size()) {
    const uint32_t n = static_cast<uint32_t>(data[i]) << 16;
    out.push_back(kTable[(n >> 18) & 63]);
    if (i + 1 < data.size()) {
      const uint32_t n2 = n | (static_cast<uint32_t>(data[i + 1]) << 8);
      out.push_back(kTable[(n2 >> 12) & 63]);
      out.push_back(kTable[(n2 >> 6) & 63]);
      out.push_back('=');
    } else {
      out.push_back(kTable[(n >> 12) & 63]);
      out.push_back('=');
      out.push_back('=');
    }
  }
  return out;
}

flutter::EncodableValue ErrorValue(const std::string& code,
                                   const std::string& message) {
  return flutter::EncodableValue(flutter::EncodableMap{
      {flutter::EncodableValue("error"), flutter::EncodableValue(code)},
      {flutter::EncodableValue("message"), flutter::EncodableValue(message)}});
}

flutter::EncodableValue RunSynthesize(const flutter::EncodableMap& args) {
  const std::string text = GetString(args, "text");
  const std::string language = GetString(args, "language");
  const std::string token = GetString(args, "token");
  const std::string subscription_key = GetString(args, "subscriptionKey");
  const std::string region = GetString(args, "region");
  const std::string voice = GetString(args, "voice");

  std::shared_ptr<SpeechConfig> config;
  if (!subscription_key.empty()) {
    config = SpeechConfig::FromSubscription(subscription_key, region);
  } else {
    config = SpeechConfig::FromAuthorizationToken(token, region);
  }
  config->SetSpeechSynthesisLanguage(language);
  if (!voice.empty()) {
    config->SetSpeechSynthesisVoiceName(voice);
  }

  // Disable auto-playback by routing synthesis to a memory-backed audio
  // output stream instead of the default speakers. The SDK writes the
  // synthesized audio into this in-memory pull stream; we retrieve it via
  // result.GetAudioData() (which reads from the same stream). Without
  // this, the SDK auto-plays through device speakers.
  auto audio_output_stream = AudioOutputStream::CreatePullStream();
  auto audio_config = AudioConfig::FromStreamOutput(audio_output_stream);
  auto synthesizer = SpeechSynthesizer::FromConfig(config, audio_config);

  // Collect word boundary events for transcript timing.
  // MSVC has trouble parsing nested template lambdas with `const T&`
  // capture lists. Move the boundary handler to a free function.
  struct WordBoundaryInfo {
    std::string text;
    int64_t audioOffset;
    int64_t duration;
  };
  std::vector<WordBoundaryInfo> word_boundaries;

  auto boundary_sink =
      [&word_boundaries](
          const Microsoft::CognitiveServices::Speech::
              SpeechSynthesisWordBoundaryEventArgs& args) {
        // AudioOffset is in 100-nanosecond ticks (uint64_t).
        // Duration is std::chrono::milliseconds; convert to ticks for
        // consistency with the Dart-side JSON parser (1 ms = 10000 ticks).
        const auto duration_ms =
            std::chrono::duration_cast<std::chrono::milliseconds>(
                args.Duration);
        word_boundaries.push_back(
            {args.Text,
             static_cast<int64_t>(args.AudioOffset),
             duration_ms.count() * 10000});
      };
  synthesizer->WordBoundary.Connect(boundary_sink);

  auto speech_result = synthesizer->SpeakTextAsync(text).get();

  if (speech_result->Reason == ResultReason::SynthesizingAudioCompleted) {
    const auto audio = speech_result->GetAudioData();
    if (!audio || audio->empty()) {
      return ErrorValue("azure_speech_error", "Empty synthesis audio");
    }
    // Build JSON manually: {"audio":"<base64>","wordBoundaries":[...]}
    std::string json = "{\"audio\":\"";
    json += Base64Encode(*audio);
    json += "\",\"wordBoundaries\":[";
    for (size_t i = 0; i < word_boundaries.size(); i++) {
      if (i > 0) json += ",";
      json += "{\"text\":\"";
      // Simple escape for quotes/backslashes in text.
      for (char c : word_boundaries[i].text) {
        if (c == '"' || c == '\\') json += '\\';
        json += c;
      }
      json += "\",\"audioOffset\":";
      json += std::to_string(word_boundaries[i].audioOffset);
      json += ",\"duration\":";
      json += std::to_string(word_boundaries[i].duration);
      json += "}";
    }
    json += "]}";
    return flutter::EncodableValue(json);
  }

  auto cancel = SpeechSynthesisCancellationDetails::FromResult(speech_result);
  std::ostringstream oss;
  oss << static_cast<int>(cancel->Reason) << ": " << cancel->ErrorDetails;
  return ErrorValue("azure_speech_error", oss.str());
}

flutter::EncodableValue RunAssess(const flutter::EncodableMap& args) {
  const std::string audio_path = GetString(args, "audioPath");
  const std::string reference_text = GetString(args, "referenceText");
  const std::string language = GetString(args, "language");
  const std::string token = GetString(args, "token");
  const std::string subscription_key = GetString(args, "subscriptionKey");
  const std::string region = GetString(args, "region");
  const bool enable_prosody = GetBool(args, "enableProsody", true);
  const bool enable_miscue = GetBool(args, "enableMiscue", true);
  const int nbest = GetInt(args, "nbestPhonemeCount", 1);
  std::string phoneme_alphabet = GetString(args, "phonemeAlphabet");
  if (phoneme_alphabet.empty()) phoneme_alphabet = "IPA";
  std::string gran_s = GetString(args, "granularity");
  if (gran_s.empty()) gran_s = "Phoneme";

  auto config = !subscription_key.empty()
                    ? SpeechConfig::FromSubscription(subscription_key, region)
                    : SpeechConfig::FromAuthorizationToken(token, region);
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
      return ErrorValue("azure_speech_error", "Empty JsonResult");
    }
    return flutter::EncodableValue(json);
  }
  if (speech_result->Reason == ResultReason::NoMatch) {
    return ErrorValue("no_speech", "No speech detected");
  }

  auto cancel = CancellationDetails::FromResult(speech_result);
  std::ostringstream oss;
  oss << static_cast<int>(cancel->Reason) << ": " << cancel->ErrorDetails;
  return ErrorValue("azure_speech_error", oss.str());
}

flutter::EncodableValue RunTranscribe(const flutter::EncodableMap& args) {
  const std::string audio_path = GetString(args, "audioPath");
  const std::string language = GetString(args, "language");
  const std::string subscription_key = GetString(args, "subscriptionKey");
  const std::string region = GetString(args, "region");

  auto config = SpeechConfig::FromSubscription(subscription_key, region);
  config->SetSpeechRecognitionLanguage(language);

  auto audio_config = AudioConfig::FromWavFileInput(audio_path);
  auto recognizer = SpeechRecognizer::FromConfig(config, audio_config);
  auto speech_result = recognizer->RecognizeOnceAsync().get();

  if (speech_result->Reason == ResultReason::RecognizedSpeech) {
    return flutter::EncodableValue(speech_result->Text);
  }
  if (speech_result->Reason == ResultReason::NoMatch) {
    return ErrorValue("no_speech", "No speech detected");
  }

  auto cancel = CancellationDetails::FromResult(speech_result);
  std::ostringstream oss;
  oss << static_cast<int>(cancel->Reason) << ": " << cancel->ErrorDetails;
  return ErrorValue("azure_speech_error", oss.str());
}

void DispatchResult(
    const std::shared_ptr<flutter::MethodResult<flutter::EncodableValue>>&
        result,
    flutter::EncodableValue out) {
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
      result->Error(code ? *code : "azure_speech_error", message,
                    flutter::EncodableValue());
      return;
    }
  }
  if (const auto* text = std::get_if<std::string>(&out)) {
    result->Success(flutter::EncodableValue(*text));
    return;
  }
  result->Error("azure_speech_error", "Unexpected native result shape");
}

}  // namespace

void AzureSpeechPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto plugin = std::make_unique<AzureSpeechPlugin>();
  plugin->channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), "azure_speech",
      &flutter::StandardMethodCodec::GetInstance());

  plugin->channel_->SetMethodCallHandler(
      [ptr = plugin.get()](const auto& call, auto result) {
        ptr->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

AzureSpeechPlugin::AzureSpeechPlugin() = default;

AzureSpeechPlugin::~AzureSpeechPlugin() = default;

void AzureSpeechPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto* args = std::get_if<flutter::EncodableMap>(method_call.arguments());
  if (!args) {
    result->Error("bad_args", "Expected map arguments");
    return;
  }

  const std::string method = method_call.method_name();
  if (method != "assess" && method != "transcribe" && method != "synthesize") {
    result->NotImplemented();
    return;
  }

  // Run SDK work off the platform thread so RecognizeOnce / SpeakText do not
  // freeze the Flutter embedder. FlutterDesktopMessengerSend is thread-safe.
  auto shared_result =
      std::shared_ptr<flutter::MethodResult<flutter::EncodableValue>>(
          std::move(result));
  auto args_copy = *args;

  std::thread([method, args_copy, shared_result]() {
    try {
      flutter::EncodableValue out;
      if (method == "assess") {
        out = RunAssess(args_copy);
      } else if (method == "transcribe") {
        out = RunTranscribe(args_copy);
      } else {
        out = RunSynthesize(args_copy);
      }
      DispatchResult(shared_result, std::move(out));
    } catch (const std::exception& e) {
      shared_result->Error("azure_speech_error", e.what());
    } catch (...) {
      shared_result->Error("azure_speech_error", "Unknown native error");
    }
  }).detach();
}

}  // namespace azure_speech
