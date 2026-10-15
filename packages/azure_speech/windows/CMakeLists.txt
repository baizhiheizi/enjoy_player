# Azure Speech SDK is fetched from NuGet at configure time (requires network once).
cmake_minimum_required(VERSION 3.18)

set(PLUGIN_NAME "azure_speech_plugin")
project(${PLUGIN_NAME} LANGUAGES CXX)

cmake_policy(VERSION 3.18...3.25)

# Set AZURE_SPEECH_SDK_CACHE to a persistent directory (CI uses the runner
# tool cache) to reuse the extracted SDK across clean builds.
set(AZURE_SPEECH_SDK_VERSION "1.49.0")
if(DEFINED ENV{AZURE_SPEECH_SDK_CACHE} AND NOT "$ENV{AZURE_SPEECH_SDK_CACHE}" STREQUAL "")
  file(TO_CMAKE_PATH "$ENV{AZURE_SPEECH_SDK_CACHE}/${AZURE_SPEECH_SDK_VERSION}" AZURE_SDK_DIR)
else()
  set(AZURE_SDK_DIR "${CMAKE_CURRENT_BINARY_DIR}/azure_speech_nuget")
endif()
set(AZURE_NUPKG_ZIP "${AZURE_SDK_DIR}/Microsoft.CognitiveServices.Speech.${AZURE_SPEECH_SDK_VERSION}.zip")

# The .extracted marker is written only after the headers are present, so a
# failed or truncated download is retried instead of poisoning the build dir.
file(GLOB_RECURSE _SPEECH_CXX_HEADER "${AZURE_SDK_DIR}/extract/**/speechapi_cxx.h")
if(NOT EXISTS "${AZURE_SDK_DIR}/.extracted" OR NOT _SPEECH_CXX_HEADER)
  file(REMOVE_RECURSE "${AZURE_SDK_DIR}/extract" "${AZURE_SDK_DIR}/.extracted")
  file(MAKE_DIRECTORY "${AZURE_SDK_DIR}/extract")
  set(_azure_dl_code 1)
  foreach(_azure_attempt RANGE 1 4)
    file(DOWNLOAD
      "https://www.nuget.org/api/v2/package/Microsoft.CognitiveServices.Speech/${AZURE_SPEECH_SDK_VERSION}"
      "${AZURE_NUPKG_ZIP}"
      TLS_VERIFY ON
      STATUS _azure_dl_status
    )
    list(GET _azure_dl_status 0 _azure_dl_code)
    if(_azure_dl_code EQUAL 0)
      break()
    endif()
    message(WARNING "Speech SDK download attempt ${_azure_attempt}/4 failed: ${_azure_dl_status}")
    file(REMOVE "${AZURE_NUPKG_ZIP}")
    execute_process(COMMAND ${CMAKE_COMMAND} -E sleep 5)
  endforeach()
  if(NOT _azure_dl_code EQUAL 0)
    message(FATAL_ERROR "Could not download the Speech SDK NuGet package: ${_azure_dl_status}")
  endif()
  file(ARCHIVE_EXTRACT INPUT "${AZURE_NUPKG_ZIP}" DESTINATION "${AZURE_SDK_DIR}/extract")
  file(REMOVE "${AZURE_NUPKG_ZIP}")
  file(GLOB_RECURSE _SPEECH_CXX_HEADER "${AZURE_SDK_DIR}/extract/**/speechapi_cxx.h")
  if(_SPEECH_CXX_HEADER)
    file(WRITE "${AZURE_SDK_DIR}/.extracted" "ok")
  endif()
endif()

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

# NuGet 1.49.x: x64 Release import lib only (no Debug import libs). Desktop layout is
# either extract/build/native/x64/Release/... (flat .nupkg) or
# extract/<packageId>/build/native/x64/Release/...
set(_azure_core_lib_flat
  "${AZURE_SDK_DIR}/extract/build/native/x64/Release/Microsoft.CognitiveServices.Speech.core.lib")
if(EXISTS "${_azure_core_lib_flat}")
  set(AZURE_CORE_IMPORT_LIB "${_azure_core_lib_flat}")
else()
  file(GLOB _azure_core_nested
    "${AZURE_SDK_DIR}/extract/*/build/native/x64/Release/Microsoft.CognitiveServices.Speech.core.lib")
  if(_azure_core_nested)
    list(GET _azure_core_nested 0 AZURE_CORE_IMPORT_LIB)
  endif()
endif()
if(NOT AZURE_CORE_IMPORT_LIB)
  message(FATAL_ERROR
    "Could not locate build/native/x64/Release/Microsoft.CognitiveServices.Speech.core.lib under ${AZURE_SDK_DIR}/extract")
endif()

# Flat NuGet extract: runtimes/ is at the root of extract/, not under a sub-folder.
file(GLOB AZURE_DLLS
  "${AZURE_SDK_DIR}/extract/runtimes/win-x64/native/*.dll")
if(NOT AZURE_DLLS)
  # Rare: extract unpacked into a versioned sub-folder.
  file(GLOB AZURE_DLLS
    "${AZURE_SDK_DIR}/extract/*/runtimes/win-x64/native/*.dll")
endif()
if(NOT AZURE_DLLS)
  message(FATAL_ERROR "Could not locate Speech SDK DLLs under ${AZURE_SDK_DIR}/extract/runtimes/win-x64/native/")
endif()

list(APPEND PLUGIN_SOURCES
  "azure_speech_plugin.cpp"
  "azure_speech_plugin.h"
)

add_library(${PLUGIN_NAME} SHARED
  "include/azure_speech/azure_speech_plugin_c_api.h"
  "azure_speech_plugin_c_api.cpp"
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
# Same import .lib for Debug and Release (SDK does not publish separate Debug import libs).
target_link_libraries(${PLUGIN_NAME} PRIVATE "${AZURE_CORE_IMPORT_LIB}")

set(azure_speech_bundled_libraries
  ${AZURE_DLLS}
  PARENT_SCOPE)
