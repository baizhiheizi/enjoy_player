package dev.enjoy_player.azure_pronunciation_assessment

import android.os.Handler
import android.os.Looper
import com.microsoft.cognitiveservices.speech.*
import com.microsoft.cognitiveservices.speech.audio.AudioConfig
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.Executors

class AzurePronunciationAssessmentPlugin : FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private val executor = Executors.newSingleThreadExecutor()
  private val mainHandler = Handler(Looper.getMainLooper())

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(binding.binaryMessenger, "azure_pronunciation_assessment")
    channel.setMethodCallHandler(this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method != "assess") {
      result.notImplemented()
      return
    }
    @Suppress("UNCHECKED_CAST")
    val args = call.arguments as? Map<String, Any?>
    if (args == null) {
      result.error("bad_args", "Expected map arguments", null)
      return
    }
    executor.execute {
      try {
        val json = assess(args)
        mainHandler.post { result.success(json) }
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
    val token = args["token"] as String
    val region = args["region"] as String
    val enableProsody = args["enableProsody"] as? Boolean ?: true
    val enableMiscue = args["enableMiscue"] as? Boolean ?: true
    val nbestPhonemeCount = (args["nbestPhonemeCount"] as? Number)?.toInt() ?: 1
    val phonemeAlphabet = args["phonemeAlphabet"] as? String ?: "IPA"
    val granularityStr = args["granularity"] as? String ?: "Phoneme"
    val granularity = parseGranularity(granularityStr)

    val config = SpeechConfig.fromAuthorizationToken(token, region)
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
          pronunciationConfig.enableProsodyAssessment = enableProsody
          pronunciationConfig.phonemeAlphabet = phonemeAlphabet
          pronunciationConfig.nbestPhonemeCount = nbestPhonemeCount

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
