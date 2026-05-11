/// Riverpod wiring for Enjoy worker AI HTTP clients.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/data/api/api_client_provider.dart';
import 'package:enjoy_player/data/api/services/ai/asr_api.dart';
import 'package:enjoy_player/data/api/services/ai/azure_token_api.dart';
import 'package:enjoy_player/data/api/services/ai/chat_api.dart';
import 'package:enjoy_player/data/api/services/ai/dictionary_api.dart';
import 'package:enjoy_player/data/api/services/ai/translation_api.dart';

part 'ai_api_providers.g.dart';

@Riverpod(keepAlive: true)
AsrApi asrApi(Ref ref) => AsrApi(ref.watch(apiClientProvider));

@Riverpod(keepAlive: true)
ChatApi chatApi(Ref ref) => ChatApi(ref.watch(apiClientProvider));

@Riverpod(keepAlive: true)
TranslationApi translationApi(Ref ref) =>
    TranslationApi(ref.watch(apiClientProvider));

@Riverpod(keepAlive: true)
DictionaryApi dictionaryApi(Ref ref) =>
    DictionaryApi(ref.watch(apiClientProvider));

@Riverpod(keepAlive: true)
AzureTokenApi azureTokenApi(Ref ref) =>
    AzureTokenApi(ref.watch(apiClientProvider));
