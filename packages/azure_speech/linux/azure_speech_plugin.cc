#include "include/azure_speech/azure_speech_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

#include <chrono>
#include <cstdint>
#include <cstdio>
#include <exception>
#include <memory>
#include <sstream>
#include <string>
#include <thread>
#include <vector>

#include <speechapi_cxx.h>

using Microsoft::CognitiveServices::Speech::CancellationDetails;
using Microsoft::CognitiveServices::Speech::PronunciationAssessmentConfig;
using Microsoft::CognitiveServices::Speech::PronunciationAssessmentGradingSystem;
using Microsoft::CognitiveServices::Speech::PronunciationAssessmentGranularity;
using Microsoft::CognitiveServices::Speech::PropertyId;
using Microsoft::CognitiveServices::Speech::ResultReason;
using Microsoft::CognitiveServices::Speech::SpeechConfig;
using Microsoft::CognitiveServices::Speech::SpeechRecognizer;
using Microsoft::CognitiveServices::Speech::SpeechSynthesisCancellationDetails;
using Microsoft::CognitiveServices::Speech::SpeechSynthesisWordBoundaryEventArgs;
using Microsoft::CognitiveServices::Speech::SpeechSynthesizer;
using Microsoft::CognitiveServices::Speech::Audio::AudioConfig;
using Microsoft::CognitiveServices::Speech::Audio::AudioOutputStream;

#define AZURE_SPEECH_PLUGIN(obj)                                     \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), azure_speech_plugin_get_type(), \
                              AzureSpeechPlugin))

struct _AzureSpeechPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(AzureSpeechPlugin, azure_speech_plugin, g_object_get_type())

namespace {

struct Outcome {
  bool ok = false;
  std::string payload;
  std::string code;
  std::string message;
};

Outcome Success(std::string payload) {
  Outcome out;
  out.ok = true;
  out.payload = std::move(payload);
  return out;
}

Outcome Failure(std::string code, std::string message) {
  Outcome out;
  out.code = std::move(code);
  out.message = std::move(message);
  return out;
}

struct Args {
  FlValue* map;

  std::string String(const char* key) const {
    FlValue* v = fl_value_lookup_string(map, key);
    if (v == nullptr || fl_value_get_type(v) != FL_VALUE_TYPE_STRING) {
      return {};
    }
    return fl_value_get_string(v);
  }

  bool Bool(const char* key, bool def) const {
    FlValue* v = fl_value_lookup_string(map, key);
    if (v == nullptr || fl_value_get_type(v) != FL_VALUE_TYPE_BOOL) {
      return def;
    }
    return fl_value_get_bool(v);
  }

  int Int(const char* key, int def) const {
    FlValue* v = fl_value_lookup_string(map, key);
    if (v == nullptr || fl_value_get_type(v) != FL_VALUE_TYPE_INT) {
      return def;
    }
    return static_cast<int>(fl_value_get_int(v));
  }
};

std::shared_ptr<SpeechConfig> MakeConfig(const std::string& subscription_key,
                                         const std::string& token,
                                         const std::string& region) {
  return !subscription_key.empty()
             ? SpeechConfig::FromSubscription(subscription_key, region)
             : SpeechConfig::FromAuthorizationToken(token, region);
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
    uint32_t n = static_cast<uint32_t>(data[i]) << 16;
    const bool two = i + 1 < data.size();
    if (two) n |= static_cast<uint32_t>(data[i + 1]) << 8;
    out.push_back(kTable[(n >> 18) & 63]);
    out.push_back(kTable[(n >> 12) & 63]);
    out.push_back(two ? kTable[(n >> 6) & 63] : '=');
    out.push_back('=');
  }
  return out;
}

void AppendJsonString(std::string& json, const std::string& text) {
  json += '"';
  for (const char c : text) {
    switch (c) {
      case '"':
        json += "\\\"";
        break;
      case '\\':
        json += "\\\\";
        break;
      case '\n':
        json += "\\n";
        break;
      case '\r':
        json += "\\r";
        break;
      case '\t':
        json += "\\t";
        break;
      default:
        if (static_cast<unsigned char>(c) < 0x20) {
          char buf[8];
          snprintf(buf, sizeof(buf), "\\u%04x", c);
          json += buf;
        } else {
          json += c;
        }
    }
  }
  json += '"';
}

template <typename Details>
std::string CancellationMessage(const std::shared_ptr<Details>& cancel) {
  std::ostringstream oss;
  oss << static_cast<int>(cancel->Reason) << ": " << cancel->ErrorDetails;
  return oss.str();
}

Outcome RunAssess(const Args& args) {
  const std::string audio_path = args.String("audioPath");
  const std::string reference_text = args.String("referenceText");
  std::string phoneme_alphabet = args.String("phonemeAlphabet");
  if (phoneme_alphabet.empty()) phoneme_alphabet = "IPA";

  auto config = MakeConfig(args.String("subscriptionKey"), args.String("token"),
                           args.String("region"));
  config->SetSpeechRecognitionLanguage(args.String("language"));

  auto audio_config = AudioConfig::FromWavFileInput(audio_path);
  auto pronunciation_config = PronunciationAssessmentConfig::Create(
      reference_text, PronunciationAssessmentGradingSystem::HundredMark,
      ParseGranularity(args.String("granularity")),
      args.Bool("enableMiscue", true));
  if (args.Bool("enableProsody", true)) {
    pronunciation_config->EnableProsodyAssessment();
  }
  pronunciation_config->SetPhonemeAlphabet(phoneme_alphabet);
  pronunciation_config->SetNBestPhonemeCount(
      static_cast<uint32_t>(args.Int("nbestPhonemeCount", 1)));

  auto recognizer = SpeechRecognizer::FromConfig(config, audio_config);
  pronunciation_config->ApplyTo(recognizer);
  auto result = recognizer->RecognizeOnceAsync().get();

  if (result->Reason == ResultReason::RecognizedSpeech) {
    std::string json = result->Properties.GetProperty(
        PropertyId::SpeechServiceResponse_JsonResult);
    if (json.empty()) return Failure("azure_speech_error", "Empty JsonResult");
    return Success(std::move(json));
  }
  if (result->Reason == ResultReason::NoMatch) {
    return Failure("no_speech", "No speech detected");
  }
  return Failure("azure_speech_error",
                 CancellationMessage(CancellationDetails::FromResult(result)));
}

Outcome RunTranscribe(const Args& args) {
  auto config =
      SpeechConfig::FromSubscription(args.String("subscriptionKey"),
                                     args.String("region"));
  config->SetSpeechRecognitionLanguage(args.String("language"));

  auto audio_config = AudioConfig::FromWavFileInput(args.String("audioPath"));
  auto recognizer = SpeechRecognizer::FromConfig(config, audio_config);
  auto result = recognizer->RecognizeOnceAsync().get();

  if (result->Reason == ResultReason::RecognizedSpeech) {
    return Success(result->Text);
  }
  if (result->Reason == ResultReason::NoMatch) {
    return Failure("no_speech", "No speech detected");
  }
  return Failure("azure_speech_error",
                 CancellationMessage(CancellationDetails::FromResult(result)));
}

struct WordBoundary {
  std::string text;
  int64_t audio_offset;
  int64_t duration_ticks;
};

Outcome RunSynthesize(const Args& args) {
  auto config = MakeConfig(args.String("subscriptionKey"), args.String("token"),
                           args.String("region"));
  config->SetSpeechSynthesisLanguage(args.String("language"));
  const std::string voice = args.String("voice");
  if (!voice.empty()) config->SetSpeechSynthesisVoiceName(voice);

  auto output_stream = AudioOutputStream::CreatePullStream();
  auto audio_config = AudioConfig::FromStreamOutput(output_stream);
  auto synthesizer = SpeechSynthesizer::FromConfig(config, audio_config);

  std::vector<WordBoundary> boundaries;
  synthesizer->WordBoundary.Connect(
      [&boundaries](const SpeechSynthesisWordBoundaryEventArgs& e) {
        const auto duration_ms =
            std::chrono::duration_cast<std::chrono::milliseconds>(e.Duration);
        boundaries.push_back({e.Text, static_cast<int64_t>(e.AudioOffset),
                              duration_ms.count() * 10000});
      });

  auto result = synthesizer->SpeakTextAsync(args.String("text")).get();
  if (result->Reason == ResultReason::SynthesizingAudioCompleted) {
    const auto audio = result->GetAudioData();
    if (!audio || audio->empty()) {
      return Failure("azure_speech_error", "Empty synthesis audio");
    }
    std::string json = "{\"audio\":\"" + Base64Encode(*audio) +
                       "\",\"wordBoundaries\":[";
    for (size_t i = 0; i < boundaries.size(); i++) {
      if (i > 0) json += ',';
      json += "{\"text\":";
      AppendJsonString(json, boundaries[i].text);
      json += ",\"audioOffset\":" + std::to_string(boundaries[i].audio_offset);
      json += ",\"duration\":" + std::to_string(boundaries[i].duration_ticks);
      json += '}';
    }
    json += "]}";
    return Success(std::move(json));
  }
  return Failure(
      "azure_speech_error",
      CancellationMessage(SpeechSynthesisCancellationDetails::FromResult(result)));
}

struct PendingCall {
  FlMethodCall* call;
  Outcome outcome;
};

gboolean RespondOnMainThread(gpointer data) {
  std::unique_ptr<PendingCall> pending(static_cast<PendingCall*>(data));
  g_autoptr(GError) error = nullptr;
  if (pending->outcome.ok) {
    g_autoptr(FlValue) value =
        fl_value_new_string(pending->outcome.payload.c_str());
    fl_method_call_respond_success(pending->call, value, &error);
  } else {
    fl_method_call_respond_error(pending->call, pending->outcome.code.c_str(),
                                 pending->outcome.message.c_str(), nullptr,
                                 &error);
  }
  if (error != nullptr) {
    g_warning("azure_speech: failed to respond: %s", error->message);
  }
  g_object_unref(pending->call);
  return G_SOURCE_REMOVE;
}

void HandleMethodCall(FlMethodCall* method_call) {
  const std::string method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);

  if (method != "assess" && method != "transcribe" && method != "synthesize") {
    g_autoptr(FlMethodResponse) response =
        FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
    fl_method_call_respond(method_call, response, nullptr);
    return;
  }
  if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    fl_method_call_respond_error(method_call, "bad_args",
                                 "Expected map arguments", nullptr, nullptr);
    return;
  }

  g_object_ref(method_call);
  fl_value_ref(args);
  std::thread([method, method_call, args]() {
    Outcome outcome;
    try {
      const Args parsed{args};
      if (method == "assess") {
        outcome = RunAssess(parsed);
      } else if (method == "transcribe") {
        outcome = RunTranscribe(parsed);
      } else {
        outcome = RunSynthesize(parsed);
      }
    } catch (const std::exception& e) {
      outcome = Failure("azure_speech_error", e.what());
    } catch (...) {
      outcome = Failure("azure_speech_error", "Unknown native error");
    }
    fl_value_unref(args);
    g_idle_add(RespondOnMainThread,
               new PendingCall{method_call, std::move(outcome)});
  }).detach();
}

void MethodCallCb(FlMethodChannel* channel, FlMethodCall* method_call,
                  gpointer user_data) {
  HandleMethodCall(method_call);
}

}  // namespace

static void azure_speech_plugin_class_init(AzureSpeechPluginClass* klass) {}

static void azure_speech_plugin_init(AzureSpeechPlugin* self) {}

void azure_speech_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  AzureSpeechPlugin* plugin = AZURE_SPEECH_PLUGIN(
      g_object_new(azure_speech_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar), "azure_speech",
      FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      channel, MethodCallCb, g_object_ref(plugin), g_object_unref);

  g_object_unref(plugin);
}
