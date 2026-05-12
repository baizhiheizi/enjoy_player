# Azure Speech SDK is fetched from NuGet at configure time (requires network once).
cmake_minimum_required(VERSION 3.18)

set(PLUGIN_NAME "azure_pronunciation_assessment_plugin")
project(${PLUGIN_NAME} LANGUAGES CXX)

cmake_policy(VERSION 3.18...3.25)

set(AZURE_SDK_DIR "${CMAKE_CURRENT_BINARY_DIR}/azure_speech_nuget")
set(AZURE_NUPKG_ZIP "${AZURE_SDK_DIR}/Microsoft.CognitiveServices.Speech.1.49.0.zip")

if(NOT EXISTS "${AZURE_SDK_DIR}/.extracted")
  file(MAKE_DIRECTORY "${AZURE_SDK_DIR}/extract")
  file(DOWNLOAD
    "https://www.nuget.org/api/v2/package/Microsoft.CognitiveServices.Speech/1.49.0"
    "${AZURE_NUPKG_ZIP}"
    TLS_VERIFY ON
  )
  file(ARCHIVE_EXTRACT INPUT "${AZURE_NUPKG_ZIP}" DESTINATION "${AZURE_SDK_DIR}/extract")
  file(WRITE "${AZURE_SDK_DIR}/.extracted" "ok")
endif()

file(GLOB_RECURSE _SPEECH_CXX_HEADER "${AZURE_SDK_DIR}/extract/**/speechapi_cxx.h")
if(NOT _SPEECH_CXX_HEADER)
  message(FATAL_ERROR "speechapi_cxx.h not found under ${AZURE_SDK_DIR}/extract")
endif()
list(GET _SPEECH_CXX_HEADER 0 _SPEECH_CXX_HEADER_ONE)
cmake_path(GET _SPEECH_CXX_HEADER_ONE PARENT_PATH AZURE_CXX_INCLUDE)

file(GLOB_RECURSE _SPEECH_CAPI_HEADER "${AZURE_SDK_DIR}/extract/**/speechapi_c_common.h")
if(NOT _SPEECH_CAPI_HEADER)
  message(FATAL_ERROR "speechapi_c_common.h not found under ${AZURE_SDK_DIR}/extract")
endif()
list(GET _SPEECH_CAPI_HEADER 0 _SPEECH_CAPI_HEADER_ONE)
cmake_path(GET _SPEECH_CAPI_HEADER_ONE PARENT_PATH AZURE_CAPI_INCLUDE)

file(GLOB_RECURSE AZURE_LIB_DEBUG
  "${AZURE_SDK_DIR}/extract/**/Debug/Microsoft.CognitiveServices.Speech.core.lib")
file(GLOB_RECURSE AZURE_LIB_RELEASE
  "${AZURE_SDK_DIR}/extract/**/Release/Microsoft.CognitiveServices.Speech.core.lib")
if(NOT AZURE_LIB_DEBUG OR NOT AZURE_LIB_RELEASE)
  message(FATAL_ERROR "Could not locate Speech SDK .lib (Debug/Release) under ${AZURE_SDK_DIR}/extract")
endif()
list(GET AZURE_LIB_DEBUG 0 AZURE_LIB_DEBUG_PATH)
list(GET AZURE_LIB_RELEASE 0 AZURE_LIB_RELEASE_PATH)

file(GLOB AZURE_DLLS "${AZURE_SDK_DIR}/extract/**/runtimes/win-x64/native/*.dll")

list(APPEND PLUGIN_SOURCES
  "azure_pronunciation_assessment_plugin.cpp"
  "azure_pronunciation_assessment_plugin.h"
)

add_library(${PLUGIN_NAME} SHARED
  "include/azure_pronunciation_assessment/azure_pronunciation_assessment_plugin_c_api.h"
  "azure_pronunciation_assessment_plugin_c_api.cpp"
  ${PLUGIN_SOURCES}
)

apply_standard_settings(${PLUGIN_NAME})

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} PRIVATE
  "${AZURE_CXX_INCLUDE}"
  "${AZURE_CAPI_INCLUDE}"
)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")

target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)
target_link_libraries(${PLUGIN_NAME} PRIVATE
  "$<IF:$<CONFIG:Debug>,${AZURE_LIB_DEBUG_PATH},${AZURE_LIB_RELEASE_PATH}>")

set(azure_pronunciation_assessment_bundled_libraries
  ${AZURE_DLLS}
  PARENT_SCOPE)
