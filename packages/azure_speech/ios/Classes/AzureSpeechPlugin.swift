import Flutter
import MicrosoftCognitiveServicesSpeech

public class AzurePronunciationAssessmentPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "azure_pronunciation_assessment",
      binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      guard call.method == "assess" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "bad_args", message: "Expected map", details: nil))
        return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          let json = try Self.performAssessment(args: args)
          DispatchQueue.main.async { result(json) }
        } catch let e as NSError where e.domain == "AzurePronunciationAssessment" {
          let code = e.code == 1 ? "no_speech" : "azure_speech_error"
          DispatchQueue.main.async {
            result(FlutterError(code: code, message: e.localizedDescription, details: nil))
          }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(code: "azure_speech_error", message: error.localizedDescription, details: nil))
          }
        }
      }
    }
  }

  private static func performAssessment(args: [String: Any]) throws -> String {
    let audioPath = args["audioPath"] as! String
    let referenceText = args["referenceText"] as! String
    let language = args["language"] as! String
    let token = args["token"] as! String
    let region = args["region"] as! String
    let enableProsody = (args["enableProsody"] as? Bool) ?? true
    let enableMiscue = (args["enableMiscue"] as? Bool) ?? true
    let nbestPhonemeCount = (args["nbestPhonemeCount"] as? Int) ?? 1
    let phonemeAlphabet = (args["phonemeAlphabet"] as? String) ?? "IPA"
    let granularityStr = (args["granularity"] as? String) ?? "Phoneme"

    let granularity: SPXPronunciationAssessmentGranularity
    switch granularityStr {
    case "Word": granularity = .word
    case "FullText": granularity = .fullText
    default: granularity = .phoneme
    }

    let speechConfig = try SPXSpeechConfiguration(authorizationToken: token, region: region)
    try speechConfig.setSpeechRecognitionLanguage(language)

    guard let audioConfig = SPXAudioConfiguration(wavFileInput: audioPath) else {
      throw NSError(
        domain: "AzurePronunciationAssessment", code: 4,
        userInfo: [NSLocalizedDescriptionKey: "Could not open audio file"])
    }

    let pronunciationConfig = try SPXPronunciationAssessmentConfiguration(
      referenceText,
      gradingSystem: .hundredMark,
      granularity: granularity,
      enableMiscue: enableMiscue)
    if enableProsody {
      pronunciationConfig.enableProsodyAssessment()
    }
    pronunciationConfig.phonemeAlphabet = phonemeAlphabet
    pronunciationConfig.nbestPhonemeCount = UInt(nbestPhonemeCount)

    guard
      let speechRecognizer = try? SPXSpeechRecognizer(
        speechConfiguration: speechConfig, audioConfiguration: audioConfig)
    else {
      throw NSError(
        domain: "AzurePronunciationAssessment", code: 5,
        userInfo: [NSLocalizedDescriptionKey: "Could not create speech recognizer"])
    }

    try pronunciationConfig.apply(to: speechRecognizer)

    let semaphore = DispatchSemaphore(value: 0)
    var jsonOut: String?
    var errOut: NSError?

    speechRecognizer.recognizeOnceAsync { result in
      defer { result.close() }
      if result.reason == SPXResultReason.recognizedSpeech {
        jsonOut = result.properties?.getPropertyBy(SPXPropertyId.speechServiceResponseJsonResult)
        if jsonOut == nil || jsonOut!.isEmpty {
          errOut = NSError(
            domain: "AzurePronunciationAssessment", code: 2,
            userInfo: [NSLocalizedDescriptionKey: "Empty JsonResult"])
        }
      } else if result.reason == SPXResultReason.noMatch {
        errOut = NSError(
          domain: "AzurePronunciationAssessment", code: 1,
          userInfo: [NSLocalizedDescriptionKey: "No speech detected"])
      } else if result.reason == SPXResultReason.canceled {
        let cancellationDetails = try? SPXCancellationDetails(fromCanceledRecognitionResult: result)
        let msg = "\(String(describing: cancellationDetails?.reason)): \(cancellationDetails?.errorDetails ?? "")"
        errOut = NSError(
          domain: "AzurePronunciationAssessment", code: 3,
          userInfo: [NSLocalizedDescriptionKey: msg])
      } else {
        errOut = NSError(
          domain: "AzurePronunciationAssessment", code: 3,
          userInfo: [NSLocalizedDescriptionKey: "Unexpected result reason"])
      }
      semaphore.signal()
    }

    semaphore.wait()

    speechRecognizer.close()
    if let e = errOut { throw e }
    guard let json = jsonOut, !json.isEmpty else {
      throw NSError(
        domain: "AzurePronunciationAssessment", code: 2,
        userInfo: [NSLocalizedDescriptionKey: "No assessment JSON"])
    }
    return json
  }
}
