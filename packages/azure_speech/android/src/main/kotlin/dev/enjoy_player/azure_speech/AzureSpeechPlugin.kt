package dev.enjoy_player.azure_speech

import android.os.Handler
import android.os.Looper
import android.util.Base64
import com.microsoft.cognitiveservices.speech.*
import com.microsoft.cognitiveservices.speech.audio.AudioConfig
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.Executors

class AzureSpeechPlugin : FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private val executor = Executors.newSingleThreadExecutor()
  private val mainHandler = Handler(Looper.getMainLooper())

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(binding.binaryMessenger, "azure_speech")
    channel.setMethodCallHandler(this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    @Suppress("UNCHECKED_CAST")
    val args = call.arguments as? Map<String, Any?>
    if (args == null) {
      result.error("bad_args", "Expected map arguments", null)
      return
    }
    executor.execute {
      try {
        val payload = when (call.method) {
          "assess" -> assess(args)
          "transcribe" -> transcribe(args)
          "synthesize" -> synthesize(args)
          else -> {
            mainHandler.post { result.notImplemented() }
            return@execute
          }
        }
        mainHandler.post { result.success(payload) }
      } catch (e: Exception) {
        val code = mapErrorCode(e)
        mainHandler.post {
          result.error(code, e.message ?: code, null)
        }
      }
    }
  }

  private fun assess(args: Map<String, Any?>): String {
    val audioPath = args["audioPath"] as String
    val referenceText = args["referenceText"] as String
    val language = args["language"] as String
    val token = args["token"] as? String
    val subscriptionKey = args["subscriptionKey"] as? String
    val region = args["region"] as String
    val enableProsody = args["enableProsody"] as? Boolean ?: true
    val enableMiscue = args["enableMiscue"] as? Boolean ?: true
    val nbestPhonemeCount = (args["nbestPhonemeCount"] as? Number)?.toInt() ?: 1
    val phonemeAlphabet = args["phonemeAlphabet"] as? String ?: "IPA"
    val granularityStr = args["granularity"] as? String ?: "Phoneme"
    val granularity = parseGranularity(granularityStr)

    val config =
      if (!subscriptionKey.isNullOrBlank()) {
        SpeechConfig.fromSubscription(subscriptionKey, region)
      } else {
        SpeechConfig.fromAuthorizationToken(token!!, region)
      }
    try {
      config.speechRecognitionLanguage = language
      val audioConfig = AudioConfig.fromWavFileInput(audioPath)
      try {
        val pronunciationConfig = PronunciationAssessmentConfig(
          referenceText,
          PronunciationAssessmentGradingSystem.HundredMark,
          granularity,
          enableMiscue,
        )
        try {
          if (enableProsody) {
            pronunciationConfig.enableProsodyAssessment()
          }
          pronunciationConfig.setPhonemeAlphabet(phonemeAlphabet)
          pronunciationConfig.setNBestPhonemeCount(nbestPhonemeCount)

          val recognizer = SpeechRecognizer(config, audioConfig)
          try {
            pronunciationConfig.applyTo(recognizer)
            val speechResult = recognizer.recognizeOnceAsync().get()
            when (speechResult.reason) {
              ResultReason.RecognizedSpeech -> {
                val json =
                  speechResult.properties.getProperty(
                    PropertyId.SpeechServiceResponse_JsonResult,
                  )
                if (json.isNullOrBlank()) {
                  throw IllegalStateException("Azure returned empty JsonResult property")
                }
                return json
              }
              ResultReason.NoMatch -> {
                throw NoSpeechException()
              }
              else -> {
                val cancel = CancellationDetails.fromResult(speechResult)
                throw IllegalStateException(
                  "${cancel.reason}: ${cancel.errorDetails}",
                )
              }
            }
          } finally {
            recognizer.close()
          }
        } finally {
          pronunciationConfig.close()
        }
      } finally {
        audioConfig.close()
      }
    } finally {
      config.close()
    }
  }

  private fun transcribe(args: Map<String, Any?>): String {
    val audioPath = args["audioPath"] as String
    val language = args["language"] as String
    val subscriptionKey = args["subscriptionKey"] as String
    val region = args["region"] as String

    val config = SpeechConfig.fromSubscription(subscriptionKey, region)
    try {
      config.speechRecognitionLanguage = language
      val audioConfig = AudioConfig.fromWavFileInput(audioPath)
      try {
        val recognizer = SpeechRecognizer(config, audioConfig)
        try {
          val speechResult = recognizer.recognizeOnceAsync().get()
          when (speechResult.reason) {
            ResultReason.RecognizedSpeech -> {
              val text = speechResult.text
              if (text.isNullOrBlank()) {
                throw IllegalStateException("Azure returned empty transcription text")
              }
              return text
            }
            ResultReason.NoMatch -> {
              throw NoSpeechException()
            }
            else -> {
              val cancel = CancellationDetails.fromResult(speechResult)
              throw IllegalStateException(
                "${cancel.reason}: ${cancel.errorDetails}",
              )
            }
          }
        } finally {
          recognizer.close()
        }
      } finally {
        audioConfig.close()
      }
    } finally {
      config.close()
    }
  }

  private fun synthesize(args: Map<String, Any?>): String {
    val text = args["text"] as String
    val language = args["language"] as String
    val token = args["token"] as? String
    val subscriptionKey = args["subscriptionKey"] as? String
    val region = args["region"] as String
    val voice = args["voice"] as? String

    val config = if (!subscriptionKey.isNullOrBlank()) {
      SpeechConfig.fromSubscription(subscriptionKey, region)
    } else {
      SpeechConfig.fromAuthorizationToken(token!!, region)
    }
    try {
      config.speechSynthesisLanguage = language
      if (!voice.isNullOrBlank()) {
        config.speechSynthesisVoiceName = voice
      }
      // Create synthesizer with null AudioConfig to disable auto-playback
      // (default behavior auto-plays through the device speaker).
      val synthesizer = SpeechSynthesizer(config, null as AudioConfig?)
      try {
        // Collect word boundary events for transcript timing.
        val wordBoundaries = org.json.JSONArray()
        synthesizer.WordBoundary.addEventListener { _, e ->
          val wb = org.json.JSONObject()
          wb.put("text", e.text)
          wb.put("audioOffset", e.audioOffset.ticks)
          wb.put("duration", e.duration.ticks)
          wordBoundaries.put(wb)
        }

        val speechResult = synthesizer.SpeakTextAsync(text).get()
        when (speechResult.reason) {
          ResultReason.SynthesizingAudioCompleted -> {
            val audio = speechResult.audioData
            if (audio == null || audio.isEmpty()) {
              throw IllegalStateException("Azure returned empty synthesis audio")
            }
            val audioB64 = Base64.encodeToString(audio, Base64.NO_WRAP)
            // Return JSON with audio + word boundaries.
            val result = org.json.JSONObject()
            result.put("audio", audioB64)
            result.put("wordBoundaries", wordBoundaries)
            return result.toString()
          }
          else -> {
            val cancel = SpeechSynthesisCancellationDetails.fromResult(speechResult)
            throw IllegalStateException(
              "${cancel.reason}: ${cancel.errorDetails}",
            )
          }
        }
      } finally {
        synthesizer.close()
      }
    } finally {
      config.close()
    }
  }

  private fun parseGranularity(s: String): PronunciationAssessmentGranularity =
    when (s) {
      "Word" -> PronunciationAssessmentGranularity.Word
      "FullText" -> PronunciationAssessmentGranularity.FullText
      else -> PronunciationAssessmentGranularity.Phoneme
    }

  private fun mapErrorCode(e: Exception): String =
    when (e) {
      is NoSpeechException -> "no_speech"
      else -> "azure_speech_error"
    }

  private class NoSpeechException : RuntimeException("No speech detected in the audio.")
}
