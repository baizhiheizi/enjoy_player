// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_service_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BYOKConfig {

 BYOKVendor get vendor; String get apiKey; String? get endpoint; String? get region; String? get model;
/// Create a copy of BYOKConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BYOKConfigCopyWith<BYOKConfig> get copyWith => _$BYOKConfigCopyWithImpl<BYOKConfig>(this as BYOKConfig, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BYOKConfig&&(identical(other.vendor, vendor) || other.vendor == vendor)&&(identical(other.apiKey, apiKey) || other.apiKey == apiKey)&&(identical(other.endpoint, endpoint) || other.endpoint == endpoint)&&(identical(other.region, region) || other.region == region)&&(identical(other.model, model) || other.model == model));
}


@override
int get hashCode => Object.hash(runtimeType,vendor,apiKey,endpoint,region,model);

@override
String toString() {
  return 'BYOKConfig(vendor: $vendor, apiKey: $apiKey, endpoint: $endpoint, region: $region, model: $model)';
}


}

/// @nodoc
abstract mixin class $BYOKConfigCopyWith<$Res>  {
  factory $BYOKConfigCopyWith(BYOKConfig value, $Res Function(BYOKConfig) _then) = _$BYOKConfigCopyWithImpl;
@useResult
$Res call({
 BYOKVendor vendor, String apiKey, String? endpoint, String? region, String? model
});




}
/// @nodoc
class _$BYOKConfigCopyWithImpl<$Res>
    implements $BYOKConfigCopyWith<$Res> {
  _$BYOKConfigCopyWithImpl(this._self, this._then);

  final BYOKConfig _self;
  final $Res Function(BYOKConfig) _then;

/// Create a copy of BYOKConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? vendor = null,Object? apiKey = null,Object? endpoint = freezed,Object? region = freezed,Object? model = freezed,}) {
  return _then(_self.copyWith(
vendor: null == vendor ? _self.vendor : vendor // ignore: cast_nullable_to_non_nullable
as BYOKVendor,apiKey: null == apiKey ? _self.apiKey : apiKey // ignore: cast_nullable_to_non_nullable
as String,endpoint: freezed == endpoint ? _self.endpoint : endpoint // ignore: cast_nullable_to_non_nullable
as String?,region: freezed == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BYOKConfig].
extension BYOKConfigPatterns on BYOKConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BYOKConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BYOKConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BYOKConfig value)  $default,){
final _that = this;
switch (_that) {
case _BYOKConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BYOKConfig value)?  $default,){
final _that = this;
switch (_that) {
case _BYOKConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BYOKVendor vendor,  String apiKey,  String? endpoint,  String? region,  String? model)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BYOKConfig() when $default != null:
return $default(_that.vendor,_that.apiKey,_that.endpoint,_that.region,_that.model);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BYOKVendor vendor,  String apiKey,  String? endpoint,  String? region,  String? model)  $default,) {final _that = this;
switch (_that) {
case _BYOKConfig():
return $default(_that.vendor,_that.apiKey,_that.endpoint,_that.region,_that.model);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BYOKVendor vendor,  String apiKey,  String? endpoint,  String? region,  String? model)?  $default,) {final _that = this;
switch (_that) {
case _BYOKConfig() when $default != null:
return $default(_that.vendor,_that.apiKey,_that.endpoint,_that.region,_that.model);case _:
  return null;

}
}

}

/// @nodoc


class _BYOKConfig implements BYOKConfig {
  const _BYOKConfig({required this.vendor, required this.apiKey, this.endpoint, this.region, this.model});
  

@override final  BYOKVendor vendor;
@override final  String apiKey;
@override final  String? endpoint;
@override final  String? region;
@override final  String? model;

/// Create a copy of BYOKConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BYOKConfigCopyWith<_BYOKConfig> get copyWith => __$BYOKConfigCopyWithImpl<_BYOKConfig>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BYOKConfig&&(identical(other.vendor, vendor) || other.vendor == vendor)&&(identical(other.apiKey, apiKey) || other.apiKey == apiKey)&&(identical(other.endpoint, endpoint) || other.endpoint == endpoint)&&(identical(other.region, region) || other.region == region)&&(identical(other.model, model) || other.model == model));
}


@override
int get hashCode => Object.hash(runtimeType,vendor,apiKey,endpoint,region,model);

@override
String toString() {
  return 'BYOKConfig(vendor: $vendor, apiKey: $apiKey, endpoint: $endpoint, region: $region, model: $model)';
}


}

/// @nodoc
abstract mixin class _$BYOKConfigCopyWith<$Res> implements $BYOKConfigCopyWith<$Res> {
  factory _$BYOKConfigCopyWith(_BYOKConfig value, $Res Function(_BYOKConfig) _then) = __$BYOKConfigCopyWithImpl;
@override @useResult
$Res call({
 BYOKVendor vendor, String apiKey, String? endpoint, String? region, String? model
});




}
/// @nodoc
class __$BYOKConfigCopyWithImpl<$Res>
    implements _$BYOKConfigCopyWith<$Res> {
  __$BYOKConfigCopyWithImpl(this._self, this._then);

  final _BYOKConfig _self;
  final $Res Function(_BYOKConfig) _then;

/// Create a copy of BYOKConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? vendor = null,Object? apiKey = null,Object? endpoint = freezed,Object? region = freezed,Object? model = freezed,}) {
  return _then(_BYOKConfig(
vendor: null == vendor ? _self.vendor : vendor // ignore: cast_nullable_to_non_nullable
as BYOKVendor,apiKey: null == apiKey ? _self.apiKey : apiKey // ignore: cast_nullable_to_non_nullable
as String,endpoint: freezed == endpoint ? _self.endpoint : endpoint // ignore: cast_nullable_to_non_nullable
as String?,region: freezed == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$AIServiceConfig {

 AIProvider get provider; BYOKConfig? get byok; String? get localModelId;
/// Create a copy of AIServiceConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AIServiceConfigCopyWith<AIServiceConfig> get copyWith => _$AIServiceConfigCopyWithImpl<AIServiceConfig>(this as AIServiceConfig, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AIServiceConfig&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.byok, byok) || other.byok == byok)&&(identical(other.localModelId, localModelId) || other.localModelId == localModelId));
}


@override
int get hashCode => Object.hash(runtimeType,provider,byok,localModelId);

@override
String toString() {
  return 'AIServiceConfig(provider: $provider, byok: $byok, localModelId: $localModelId)';
}


}

/// @nodoc
abstract mixin class $AIServiceConfigCopyWith<$Res>  {
  factory $AIServiceConfigCopyWith(AIServiceConfig value, $Res Function(AIServiceConfig) _then) = _$AIServiceConfigCopyWithImpl;
@useResult
$Res call({
 AIProvider provider, BYOKConfig? byok, String? localModelId
});


$BYOKConfigCopyWith<$Res>? get byok;

}
/// @nodoc
class _$AIServiceConfigCopyWithImpl<$Res>
    implements $AIServiceConfigCopyWith<$Res> {
  _$AIServiceConfigCopyWithImpl(this._self, this._then);

  final AIServiceConfig _self;
  final $Res Function(AIServiceConfig) _then;

/// Create a copy of AIServiceConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? provider = null,Object? byok = freezed,Object? localModelId = freezed,}) {
  return _then(_self.copyWith(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as AIProvider,byok: freezed == byok ? _self.byok : byok // ignore: cast_nullable_to_non_nullable
as BYOKConfig?,localModelId: freezed == localModelId ? _self.localModelId : localModelId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of AIServiceConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BYOKConfigCopyWith<$Res>? get byok {
    if (_self.byok == null) {
    return null;
  }

  return $BYOKConfigCopyWith<$Res>(_self.byok!, (value) {
    return _then(_self.copyWith(byok: value));
  });
}
}


/// Adds pattern-matching-related methods to [AIServiceConfig].
extension AIServiceConfigPatterns on AIServiceConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AIServiceConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AIServiceConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AIServiceConfig value)  $default,){
final _that = this;
switch (_that) {
case _AIServiceConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AIServiceConfig value)?  $default,){
final _that = this;
switch (_that) {
case _AIServiceConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AIProvider provider,  BYOKConfig? byok,  String? localModelId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AIServiceConfig() when $default != null:
return $default(_that.provider,_that.byok,_that.localModelId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AIProvider provider,  BYOKConfig? byok,  String? localModelId)  $default,) {final _that = this;
switch (_that) {
case _AIServiceConfig():
return $default(_that.provider,_that.byok,_that.localModelId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AIProvider provider,  BYOKConfig? byok,  String? localModelId)?  $default,) {final _that = this;
switch (_that) {
case _AIServiceConfig() when $default != null:
return $default(_that.provider,_that.byok,_that.localModelId);case _:
  return null;

}
}

}

/// @nodoc


class _AIServiceConfig implements AIServiceConfig {
  const _AIServiceConfig({required this.provider, this.byok, this.localModelId});
  

@override final  AIProvider provider;
@override final  BYOKConfig? byok;
@override final  String? localModelId;

/// Create a copy of AIServiceConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AIServiceConfigCopyWith<_AIServiceConfig> get copyWith => __$AIServiceConfigCopyWithImpl<_AIServiceConfig>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AIServiceConfig&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.byok, byok) || other.byok == byok)&&(identical(other.localModelId, localModelId) || other.localModelId == localModelId));
}


@override
int get hashCode => Object.hash(runtimeType,provider,byok,localModelId);

@override
String toString() {
  return 'AIServiceConfig(provider: $provider, byok: $byok, localModelId: $localModelId)';
}


}

/// @nodoc
abstract mixin class _$AIServiceConfigCopyWith<$Res> implements $AIServiceConfigCopyWith<$Res> {
  factory _$AIServiceConfigCopyWith(_AIServiceConfig value, $Res Function(_AIServiceConfig) _then) = __$AIServiceConfigCopyWithImpl;
@override @useResult
$Res call({
 AIProvider provider, BYOKConfig? byok, String? localModelId
});


@override $BYOKConfigCopyWith<$Res>? get byok;

}
/// @nodoc
class __$AIServiceConfigCopyWithImpl<$Res>
    implements _$AIServiceConfigCopyWith<$Res> {
  __$AIServiceConfigCopyWithImpl(this._self, this._then);

  final _AIServiceConfig _self;
  final $Res Function(_AIServiceConfig) _then;

/// Create a copy of AIServiceConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? provider = null,Object? byok = freezed,Object? localModelId = freezed,}) {
  return _then(_AIServiceConfig(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as AIProvider,byok: freezed == byok ? _self.byok : byok // ignore: cast_nullable_to_non_nullable
as BYOKConfig?,localModelId: freezed == localModelId ? _self.localModelId : localModelId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of AIServiceConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BYOKConfigCopyWith<$Res>? get byok {
    if (_self.byok == null) {
    return null;
  }

  return $BYOKConfigCopyWith<$Res>(_self.byok!, (value) {
    return _then(_self.copyWith(byok: value));
  });
}
}

// dart format on
