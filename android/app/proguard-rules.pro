# R8 / Azure Speech SDK transitive references (optional at runtime).
# See build output missing_rules.txt when upgrading AGP or Azure deps.
-dontwarn io.micrometer.context.ContextAccessor
-dontwarn reactor.blockhound.integration.BlockHoundIntegration

# ffmpeg_kit_flutter_new registers JNI methods by their Java names during
# plugin attachment. Release builds must keep these names intact; otherwise
# libffmpegkit_abidetect.so fails to register AbiDetect.getNativeCpuAbi().
-keep class com.antonkarpenko.ffmpegkit.** { *; }
-dontwarn com.antonkarpenko.ffmpegkit.**

-keepclasseswithmembernames class * {
    native <methods>;
}

-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
