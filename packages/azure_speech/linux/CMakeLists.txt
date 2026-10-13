# Azure Speech SDK is fetched from NuGet at configure time (requires network once),
# the same pinned package the Windows build uses; it ships linux-x64 and
# linux-arm64 native libraries plus the C/C++ headers.
cmake_minimum_required(VERSION 3.18)

set(PROJECT_NAME "azure_speech")
project(${PROJECT_NAME} LANGUAGES CXX)

set(PLUGIN_NAME "azure_speech_plugin")

set(AZURE_SPEECH_VERSION "1.49.0")
set(AZURE_SDK_DIR "${CMAKE_CURRENT_BINARY_DIR}/azure_speech_nuget")
set(AZURE_NUPKG_ZIP "${AZURE_SDK_DIR}/Microsoft.CognitiveServices.Speech.${AZURE_SPEECH_VERSION}.zip")

if(NOT EXISTS "${AZURE_SDK_DIR}/.extracted-${AZURE_SPEECH_VERSION}")
  file(MAKE_DIRECTORY "${AZURE_SDK_DIR}/extract")
  file(DOWNLOAD
    "https://www.nuget.org/api/v2/package/Microsoft.CognitiveServices.Speech/${AZURE_SPEECH_VERSION}"
    "${AZURE_NUPKG_ZIP}"
    TLS_VERIFY ON
    STATUS _azure_download_status
  )
  list(GET _azure_download_status 0 _azure_download_code)
  if(NOT _azure_download_code EQUAL 0)
    message(FATAL_ERROR "Downloading the Azure Speech SDK failed: ${_azure_download_status}")
  endif()
  file(ARCHIVE_EXTRACT INPUT "${AZURE_NUPKG_ZIP}" DESTINATION "${AZURE_SDK_DIR}/extract")
  file(WRITE "${AZURE_SDK_DIR}/.extracted-${AZURE_SPEECH_VERSION}" "ok")
endif()

set(AZURE_CXX_INCLUDE "${AZURE_SDK_DIR}/extract/build/native/include/cxx_api")
set(AZURE_CAPI_INCLUDE "${AZURE_SDK_DIR}/extract/build/native/include/c_api")
if(NOT EXISTS "${AZURE_CXX_INCLUDE}/speechapi_cxx.h")
  message(FATAL_ERROR "speechapi_cxx.h not found under ${AZURE_CXX_INCLUDE}")
endif()

if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64|arm64|ARM64)$")
  set(AZURE_RUNTIME "linux-arm64")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86_64|AMD64|amd64)$")
  set(AZURE_RUNTIME "linux-x64")
else()
  message(FATAL_ERROR "Azure Speech SDK has no Linux build for ${CMAKE_SYSTEM_PROCESSOR}")
endif()
set(AZURE_NATIVE_DIR "${AZURE_SDK_DIR}/extract/runtimes/${AZURE_RUNTIME}/native")
set(AZURE_CORE_LIB "${AZURE_NATIVE_DIR}/libMicrosoft.CognitiveServices.Speech.core.so")
if(NOT EXISTS "${AZURE_CORE_LIB}")
  message(FATAL_ERROR "libMicrosoft.CognitiveServices.Speech.core.so not found under ${AZURE_NATIVE_DIR}")
endif()

# Core + the OpenSSL platform shims it loads from its own directory. The
# keyword-spotting, GStreamer codec and ALSA audio-device extensions are not
# needed for WAV-file input and in-memory output.
set(AZURE_SDK_LIB_NAMES
  "libMicrosoft.CognitiveServices.Speech.core.so"
  "libpal_azure_c_shared.so"
  "libpal_azure_c_shared_openssl3.so"
)

# Copied next to the plugin library: the runner's link step already searches
# this directory, and the plugin's $ORIGIN RUNPATH finds them in the bundle.
set(AZURE_BUNDLED_LIBS "")
foreach(_azure_lib ${AZURE_SDK_LIB_NAMES})
  file(COPY "${AZURE_NATIVE_DIR}/${_azure_lib}" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}")
  list(APPEND AZURE_BUNDLED_LIBS "${CMAKE_CURRENT_BINARY_DIR}/${_azure_lib}")
endforeach()

add_library(${PLUGIN_NAME} SHARED
  "azure_speech_plugin.cc"
)

apply_standard_settings(${PLUGIN_NAME})

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden
  BUILD_WITH_INSTALL_RPATH ON
  INSTALL_RPATH "$ORIGIN")
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} SYSTEM PRIVATE
  "${AZURE_CXX_INCLUDE}"
  "${AZURE_CAPI_INCLUDE}"
)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")

target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GTK)
target_link_directories(${PLUGIN_NAME} PRIVATE "${CMAKE_CURRENT_BINARY_DIR}")
target_link_libraries(${PLUGIN_NAME} PRIVATE Microsoft.CognitiveServices.Speech.core)

set(azure_speech_bundled_libraries
  ${AZURE_BUNDLED_LIBS}
  PARENT_SCOPE)
