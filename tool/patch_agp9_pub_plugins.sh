#!/usr/bin/env bash
# Patches pub-cache Android Gradle files for AGP 9 built-in Kotlin compatibility.
# Run after `flutter pub get` when Android builds warn or fail on older plugins.
set -euo pipefail

PUB_CACHE="${PUB_CACHE:-${HOME}/.pub-cache}/hosted/pub.dev"

patch_builtin_kotlin_groovy() {
  local file="$1"
  [[ -f "${file}" ]] || return 0
  if ! grep -qE 'kotlin-android|org\.jetbrains\.kotlin\.android' "${file}"; then
    return 0
  fi

  local tmp
  tmp="$(mktemp)"
  sed -E \
    -e '/^[[:space:]]*apply plugin:[[:space:]]*['\''"]kotlin-android['\''"][[:space:]]*$/d' \
    -e '/^[[:space:]]*classpath[[:space:]]+['\''"]org\.jetbrains\.kotlin:kotlin-gradle-plugin/d' \
    -e '/^[[:space:]]*implementation[[:space:]]+['\''"]org\.jetbrains\.kotlin:kotlin-stdlib/d' \
    -e '/^[[:space:]]*ext\.kotlin_version[[:space:]]*=/d' \
    "${file}" >"${tmp}"

  awk '
    /kotlinOptions[[:space:]]*\{/ { skip=1; next }
    skip && /\}/ { skip=0; next }
    !skip { print }
  ' "${tmp}" >"${file}"
  rm -f "${tmp}"

  echo "Patched built-in Kotlin: ${file}"
}

patch_builtin_kotlin_kts() {
  local file="$1"
  [[ -f "${file}" ]] || return 0
  if ! grep -qE 'kotlin-android|org\.jetbrains\.kotlin\.android' "${file}"; then
    return 0
  fi
  local tmp
  tmp="$(mktemp)"
  sed -E \
    -e '/^[[:space:]]*id\("kotlin-android"\)[[:space:]]*$/d' \
    -e '/^[[:space:]]*classpath\("org\.jetbrains\.kotlin:kotlin-gradle-plugin/d' \
    "${file}" >"${tmp}"
  if ! cmp -s "${file}" "${tmp}"; then
    mv "${tmp}" "${file}"
    echo "Patched built-in Kotlin: ${file}"
  else
    rm -f "${tmp}"
  fi
}

INAPP="${PUB_CACHE}/flutter_inappwebview_android-1.1.3/android/build.gradle"
if [[ -f "${INAPP}" ]]; then
  if grep -q "proguard-android.txt" "${INAPP}"; then
    sed -i 's/proguard-android\.txt/proguard-android-optimize.txt/g' "${INAPP}"
    echo "Patched ${INAPP} (proguard-android-optimize.txt)"
  fi
fi

for dir in "${PUB_CACHE}"/package_info_plus-*; do
  [[ -d "${dir}" ]] || continue
  patch_builtin_kotlin_groovy "${dir}/android/build.gradle"
done

for dir in "${PUB_CACHE}"/wakelock_plus-*; do
  [[ -d "${dir}" ]] || continue
  patch_builtin_kotlin_groovy "${dir}/android/build.gradle"
done

for dir in "${PUB_CACHE}"/url_launcher_android-*; do
  [[ -d "${dir}" ]] || continue
  patch_builtin_kotlin_kts "${dir}/android/build.gradle.kts"
done

echo "AGP 9 pub plugin patches applied."
