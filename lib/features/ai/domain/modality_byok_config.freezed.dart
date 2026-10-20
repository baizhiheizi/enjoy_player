// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'modality_byok_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LlmByokConfig {

 LlmApiSpec get apiSpec; String get baseUrl; String get model; String? get presetId;
/// Create a copy of LlmByokConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LlmByokConfigCopyWith<LlmByokConfig> get copyWith => _$LlmByokConfigCopyWithImpl<LlmByokConfig>(this as LlmByokConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LlmByokConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LlmByokConfig&&(identical(other.apiSpec, _this.apiSpec) || other.apiSpec == _this.apiSpec)&&(identical(other.baseUrl, _this.baseUrl) || other.baseUrl == _this.baseUrl)&&(identical(other.model, _this.model) || other.model == _this.model)&&(identical(other.presetId, _this.presetId) || other.presetId == _this.presetId));
}


@override
int get hashCode {
  final _this = this as LlmByokConfig;
  return Object.hash(runtimeType,_this.apiSpec,_this.baseUrl,_this.model,_this.presetId);
}

@override
String toString() {
  final _this = this as LlmByokConfig;
  return 'LlmByokConfig(apiSpec: ${_this.apiSpec}, baseUrl: ${_this.baseUrl}, model: ${_this.model}, presetId: ${_this.presetId})';
}


}

/// @nodoc
abstract mixin class $LlmByokConfigCopyWith<$Res>  {
  factory $LlmByokConfigCopyWith(LlmByokConfig value, $Res Function(LlmByokConfig) _then) = _$LlmByokConfigCopyWithImpl;
@useResult
$Res call({
 LlmApiSpec apiSpec, String baseUrl, String model, String? presetId
});




}
/// @nodoc
class _$LlmByokConfigCopyWithImpl<$Res>
    implements $LlmByokConfigCopyWith<$Res> {
  _$LlmByokConfigCopyWithImpl(this._self, this._then);

  final LlmByokConfig _self;
  final $Res Function(LlmByokConfig) _then;

/// Create a copy of LlmByokConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? apiSpec = null,Object? baseUrl = null,Object? model = null,Object? presetId = freezed,}) {
  return _then(LlmByokConfig(
apiSpec: null == apiSpec ? _self.apiSpec : apiSpec // ignore: cast_nullable_to_non_nullable
as LlmApiSpec,baseUrl: null == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,presetId: freezed == presetId ? _self.presetId : presetId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LlmByokConfig].
extension LlmByokConfigPatterns on LlmByokConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LlmByokConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LlmByokConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LlmByokConfig value)  $default,){
final _that = this;
switch (_that) {
case _LlmByokConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LlmByokConfig value)?  $default,){
final _that = this;
switch (_that) {
case _LlmByokConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( LlmApiSpec apiSpec,  String baseUrl,  String model,  String? presetId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LlmByokConfig() when $default != null:
return $default(_that.apiSpec,_that.baseUrl,_that.model,_that.presetId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( LlmApiSpec apiSpec,  String baseUrl,  String model,  String? presetId)  $default,) {final _that = this;
switch (_that) {
case _LlmByokConfig():
return $default(_that.apiSpec,_that.baseUrl,_that.model,_that.presetId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( LlmApiSpec apiSpec,  String baseUrl,  String model,  String? presetId)?  $default,) {final _that = this;
switch (_that) {
case _LlmByokConfig() when $default != null:
return $default(_that.apiSpec,_that.baseUrl,_that.model,_that.presetId);case _:
  return null;

}
}

}

/// @nodoc


class _LlmByokConfig implements LlmByokConfig {
  const _LlmByokConfig({required this.apiSpec, required this.baseUrl, required this.model, this.presetId});
  

@override final  LlmApiSpec apiSpec;
@override final  String baseUrl;
@override final  String model;
@override final  String? presetId;

/// Create a copy of LlmByokConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LlmByokConfigCopyWith<_LlmByokConfig> get copyWith => __$LlmByokConfigCopyWithImpl<_LlmByokConfig>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LlmByokConfig&&(identical(other.apiSpec, apiSpec) || other.apiSpec == apiSpec)&&(identical(other.baseUrl, baseUrl) || other.baseUrl == baseUrl)&&(identical(other.model, model) || other.model == model)&&(identical(other.presetId, presetId) || other.presetId == presetId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,apiSpec,baseUrl,model,presetId);
}

@override
String toString() {
    return 'LlmByokConfig(apiSpec: $apiSpec, baseUrl: $baseUrl, model: $model, presetId: $presetId)';
}


}

/// @nodoc
abstract mixin class _$LlmByokConfigCopyWith<$Res> implements $LlmByokConfigCopyWith<$Res> {
  factory _$LlmByokConfigCopyWith(_LlmByokConfig value, $Res Function(_LlmByokConfig) _then) = __$LlmByokConfigCopyWithImpl;
@override @useResult
$Res call({
 LlmApiSpec apiSpec, String baseUrl, String model, String? presetId
});




}
/// @nodoc
class __$LlmByokConfigCopyWithImpl<$Res>
    implements _$LlmByokConfigCopyWith<$Res> {
  __$LlmByokConfigCopyWithImpl(this._self, this._then);

  final _LlmByokConfig _self;
  final $Res Function(_LlmByokConfig) _then;

/// Create a copy of LlmByokConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? apiSpec = null,Object? baseUrl = null,Object? model = null,Object? presetId = freezed,}) {
  return _then(_LlmByokConfig(
apiSpec: null == apiSpec ? _self.apiSpec : apiSpec // ignore: cast_nullable_to_non_nullable
as LlmApiSpec,baseUrl: null == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,presetId: freezed == presetId ? _self.presetId : presetId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$SpeechByokConfig {

 SpeechByokKind get kind; String? get baseUrl; String? get model; String? get region; String? get presetId;
/// Create a copy of SpeechByokConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpeechByokConfigCopyWith<SpeechByokConfig> get copyWith => _$SpeechByokConfigCopyWithImpl<SpeechByokConfig>(this as SpeechByokConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SpeechByokConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpeechByokConfig&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.baseUrl, _this.baseUrl) || other.baseUrl == _this.baseUrl)&&(identical(other.model, _this.model) || other.model == _this.model)&&(identical(other.region, _this.region) || other.region == _this.region)&&(identical(other.presetId, _this.presetId) || other.presetId == _this.presetId));
}


@override
int get hashCode {
  final _this = this as SpeechByokConfig;
  return Object.hash(runtimeType,_this.kind,_this.baseUrl,_this.model,_this.region,_this.presetId);
}

@override
String toString() {
  final _this = this as SpeechByokConfig;
  return 'SpeechByokConfig(kind: ${_this.kind}, baseUrl: ${_this.baseUrl}, model: ${_this.model}, region: ${_this.region}, presetId: ${_this.presetId})';
}


}

/// @nodoc
abstract mixin class $SpeechByokConfigCopyWith<$Res>  {
  factory $SpeechByokConfigCopyWith(SpeechByokConfig value, $Res Function(SpeechByokConfig) _then) = _$SpeechByokConfigCopyWithImpl;
@useResult
$Res call({
 SpeechByokKind kind, String? baseUrl, String? model, String? region, String? presetId
});




}
/// @nodoc
class _$SpeechByokConfigCopyWithImpl<$Res>
    implements $SpeechByokConfigCopyWith<$Res> {
  _$SpeechByokConfigCopyWithImpl(this._self, this._then);

  final SpeechByokConfig _self;
  final $Res Function(SpeechByokConfig) _then;

/// Create a copy of SpeechByokConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? baseUrl = freezed,Object? model = freezed,Object? region = freezed,Object? presetId = freezed,}) {
  return _then(SpeechByokConfig(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as SpeechByokKind,baseUrl: freezed == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,region: freezed == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as String?,presetId: freezed == presetId ? _self.presetId : presetId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SpeechByokConfig].
extension SpeechByokConfigPatterns on SpeechByokConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SpeechByokConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SpeechByokConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SpeechByokConfig value)  $default,){
final _that = this;
switch (_that) {
case _SpeechByokConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SpeechByokConfig value)?  $default,){
final _that = this;
switch (_that) {
case _SpeechByokConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SpeechByokKind kind,  String? baseUrl,  String? model,  String? region,  String? presetId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpeechByokConfig() when $default != null:
return $default(_that.kind,_that.baseUrl,_that.model,_that.region,_that.presetId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SpeechByokKind kind,  String? baseUrl,  String? model,  String? region,  String? presetId)  $default,) {final _that = this;
switch (_that) {
case _SpeechByokConfig():
return $default(_that.kind,_that.baseUrl,_that.model,_that.region,_that.presetId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SpeechByokKind kind,  String? baseUrl,  String? model,  String? region,  String? presetId)?  $default,) {final _that = this;
switch (_that) {
case _SpeechByokConfig() when $default != null:
return $default(_that.kind,_that.baseUrl,_that.model,_that.region,_that.presetId);case _:
  return null;

}
}

}

/// @nodoc


class _SpeechByokConfig implements SpeechByokConfig {
  const _SpeechByokConfig({required this.kind, this.baseUrl, this.model, this.region, this.presetId});
  

@override final  SpeechByokKind kind;
@override final  String? baseUrl;
@override final  String? model;
@override final  String? region;
@override final  String? presetId;

/// Create a copy of SpeechByokConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpeechByokConfigCopyWith<_SpeechByokConfig> get copyWith => __$SpeechByokConfigCopyWithImpl<_SpeechByokConfig>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpeechByokConfig&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.baseUrl, baseUrl) || other.baseUrl == baseUrl)&&(identical(other.model, model) || other.model == model)&&(identical(other.region, region) || other.region == region)&&(identical(other.presetId, presetId) || other.presetId == presetId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,kind,baseUrl,model,region,presetId);
}

@override
String toString() {
    return 'SpeechByokConfig(kind: $kind, baseUrl: $baseUrl, model: $model, region: $region, presetId: $presetId)';
}


}

/// @nodoc
abstract mixin class _$SpeechByokConfigCopyWith<$Res> implements $SpeechByokConfigCopyWith<$Res> {
  factory _$SpeechByokConfigCopyWith(_SpeechByokConfig value, $Res Function(_SpeechByokConfig) _then) = __$SpeechByokConfigCopyWithImpl;
@override @useResult
$Res call({
 SpeechByokKind kind, String? baseUrl, String? model, String? region, String? presetId
});




}
/// @nodoc
class __$SpeechByokConfigCopyWithImpl<$Res>
    implements _$SpeechByokConfigCopyWith<$Res> {
  __$SpeechByokConfigCopyWithImpl(this._self, this._then);

  final _SpeechByokConfig _self;
  final $Res Function(_SpeechByokConfig) _then;

/// Create a copy of SpeechByokConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? baseUrl = freezed,Object? model = freezed,Object? region = freezed,Object? presetId = freezed,}) {
  return _then(_SpeechByokConfig(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as SpeechByokKind,baseUrl: freezed == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,region: freezed == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as String?,presetId: freezed == presetId ? _self.presetId : presetId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
