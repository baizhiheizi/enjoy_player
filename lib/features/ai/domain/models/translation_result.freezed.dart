// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'translation_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TranslationResult {

 String get translatedText; String? get sourceLanguage; String get targetLanguage;
/// Create a copy of TranslationResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TranslationResultCopyWith<TranslationResult> get copyWith => _$TranslationResultCopyWithImpl<TranslationResult>(this as TranslationResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TranslationResult&&(identical(other.translatedText, translatedText) || other.translatedText == translatedText)&&(identical(other.sourceLanguage, sourceLanguage) || other.sourceLanguage == sourceLanguage)&&(identical(other.targetLanguage, targetLanguage) || other.targetLanguage == targetLanguage));
}


@override
int get hashCode => Object.hash(runtimeType,translatedText,sourceLanguage,targetLanguage);

@override
String toString() {
  return 'TranslationResult(translatedText: $translatedText, sourceLanguage: $sourceLanguage, targetLanguage: $targetLanguage)';
}


}

/// @nodoc
abstract mixin class $TranslationResultCopyWith<$Res>  {
  factory $TranslationResultCopyWith(TranslationResult value, $Res Function(TranslationResult) _then) = _$TranslationResultCopyWithImpl;
@useResult
$Res call({
 String translatedText, String? sourceLanguage, String targetLanguage
});




}
/// @nodoc
class _$TranslationResultCopyWithImpl<$Res>
    implements $TranslationResultCopyWith<$Res> {
  _$TranslationResultCopyWithImpl(this._self, this._then);

  final TranslationResult _self;
  final $Res Function(TranslationResult) _then;

/// Create a copy of TranslationResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? translatedText = null,Object? sourceLanguage = freezed,Object? targetLanguage = null,}) {
  return _then(_self.copyWith(
translatedText: null == translatedText ? _self.translatedText : translatedText // ignore: cast_nullable_to_non_nullable
as String,sourceLanguage: freezed == sourceLanguage ? _self.sourceLanguage : sourceLanguage // ignore: cast_nullable_to_non_nullable
as String?,targetLanguage: null == targetLanguage ? _self.targetLanguage : targetLanguage // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TranslationResult].
extension TranslationResultPatterns on TranslationResult {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TranslationResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TranslationResult() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TranslationResult value)  $default,){
final _that = this;
switch (_that) {
case _TranslationResult():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TranslationResult value)?  $default,){
final _that = this;
switch (_that) {
case _TranslationResult() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String translatedText,  String? sourceLanguage,  String targetLanguage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TranslationResult() when $default != null:
return $default(_that.translatedText,_that.sourceLanguage,_that.targetLanguage);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String translatedText,  String? sourceLanguage,  String targetLanguage)  $default,) {final _that = this;
switch (_that) {
case _TranslationResult():
return $default(_that.translatedText,_that.sourceLanguage,_that.targetLanguage);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String translatedText,  String? sourceLanguage,  String targetLanguage)?  $default,) {final _that = this;
switch (_that) {
case _TranslationResult() when $default != null:
return $default(_that.translatedText,_that.sourceLanguage,_that.targetLanguage);case _:
  return null;

}
}

}

/// @nodoc


class _TranslationResult implements TranslationResult {
  const _TranslationResult({required this.translatedText, this.sourceLanguage, required this.targetLanguage});
  

@override final  String translatedText;
@override final  String? sourceLanguage;
@override final  String targetLanguage;

/// Create a copy of TranslationResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TranslationResultCopyWith<_TranslationResult> get copyWith => __$TranslationResultCopyWithImpl<_TranslationResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TranslationResult&&(identical(other.translatedText, translatedText) || other.translatedText == translatedText)&&(identical(other.sourceLanguage, sourceLanguage) || other.sourceLanguage == sourceLanguage)&&(identical(other.targetLanguage, targetLanguage) || other.targetLanguage == targetLanguage));
}


@override
int get hashCode => Object.hash(runtimeType,translatedText,sourceLanguage,targetLanguage);

@override
String toString() {
  return 'TranslationResult(translatedText: $translatedText, sourceLanguage: $sourceLanguage, targetLanguage: $targetLanguage)';
}


}

/// @nodoc
abstract mixin class _$TranslationResultCopyWith<$Res> implements $TranslationResultCopyWith<$Res> {
  factory _$TranslationResultCopyWith(_TranslationResult value, $Res Function(_TranslationResult) _then) = __$TranslationResultCopyWithImpl;
@override @useResult
$Res call({
 String translatedText, String? sourceLanguage, String targetLanguage
});




}
/// @nodoc
class __$TranslationResultCopyWithImpl<$Res>
    implements _$TranslationResultCopyWith<$Res> {
  __$TranslationResultCopyWithImpl(this._self, this._then);

  final _TranslationResult _self;
  final $Res Function(_TranslationResult) _then;

/// Create a copy of TranslationResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? translatedText = null,Object? sourceLanguage = freezed,Object? targetLanguage = null,}) {
  return _then(_TranslationResult(
translatedText: null == translatedText ? _self.translatedText : translatedText // ignore: cast_nullable_to_non_nullable
as String,sourceLanguage: freezed == sourceLanguage ? _self.sourceLanguage : sourceLanguage // ignore: cast_nullable_to_non_nullable
as String?,targetLanguage: null == targetLanguage ? _self.targetLanguage : targetLanguage // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
