cmake_minimum_required(VERSION 3.16)

project(Welle.Io LANGUAGES C CXX)

file(READ "src/welle-gui/_current_version" VERSION_FILE)
string(STRIP ${VERSION_FILE} CURRENT_VERSION)
set(PROJECT_VERSION ${CURRENT_VERSION})

message ("Building project '${PROJECT_NAME}' version '${PROJECT_VERSION}'...")

if(NOT WELLE-IO_VERSION)
  set(WELLE-IO_VERSION ${PROJECT_VERSION})
endif()

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 14)

# ---------------------------------------------------------------------------
# Slimmed-down "rtl_tcp only" build (preparation for the iOS port)
# ---------------------------------------------------------------------------
# Compared to upstream welle.io this build:
#   * keeps rtl_tcp as the ONLY input device (a plain TCP client, no libusb)
#   * drops all USB-SDR backends: RTL-SDR, Airspy, SoapySDR, LimeSDR
#   * always builds the FFT and the audio codecs from the bundled sources in
#     src/libs (KISS FFT, mpg123, faad2) -> no external libfftw3 / libfaad /
#     libmpg123 dependency
#   * does not build the welle-cli command line tool
#   * builds MPRIS / D-Bus support only on explicit request (Linux desktop)
# The only remaining native dependency is Qt itself.
# ---------------------------------------------------------------------------

option(BUILD_WELLE_IO  "Build Welle.io"                                  ON  )
option(WITH_APP_BUNDLE "Enable Application Bundle for macOS"              ON  )
option(PROFILING       "Enable profiling (see README.md)"                OFF )
option(MPRIS           "Build MPRIS / D-Bus support (Linux desktop only)" OFF )

# iOS code-signing / bundle settings (only used when building for iOS).
# Override on the command line, e.g. -DWELLE_IO_TEAM_ID=ABCDE12345
set(WELLE_IO_BUNDLE_ID "io.welle.welle" CACHE STRING "iOS app bundle identifier")
set(WELLE_IO_TEAM_ID   ""               CACHE STRING "Apple Development Team ID for iOS code signing")

add_definitions(-Wall)
add_definitions(-g)
add_definitions(-DDABLIN_AAC_FAAD2)

if(MINGW)
    add_definitions(-municode)
endif()

if(NOT CMAKE_BUILD_TYPE)
   set(CMAKE_BUILD_TYPE "Release")
   message(STATUS "Build type not specified: defaulting to release.")
endif(NOT CMAKE_BUILD_TYPE)
set(CMAKE_BUILD_TYPE ${CMAKE_BUILD_TYPE} CACHE STRING "")

list(INSERT CMAKE_MODULE_PATH 0 ${CMAKE_SOURCE_DIR}/cmake/Modules)

if(APPLE AND WITH_APP_BUNDLE)
    if(NOT DEFINED BUNDLE_INSTALL_DIR)
        set(BUNDLE_INSTALL_DIR "/Applications")
    endif()

    set(GUI_INSTALL_DIR "${BUNDLE_INSTALL_DIR}")
else()
    include(GNUInstallDirs)

    set(GUI_INSTALL_DIR "${CMAKE_INSTALL_BINDIR}")
endif()

if(BUILD_WELLE_IO)
    find_package(Qt6 COMPONENTS Widgets Quick QuickControls2 Multimedia Charts Qml REQUIRED)
    set(CMAKE_AUTOMOC ON)
    if(ANDROID AND Qt6Core_VERSION VERSION_LESS 6.8.0)
        # Workaround for QTBUG-106466
        set(CMAKE_AUTORCC ON)
    endif()
endif()

if(PROFILING)
    add_definitions(-DWITH_PROFILING)
endif()

find_package(Threads REQUIRED)

# ---------------------------------------------------------------------------
# FFT and audio codecs are always built from the bundled sources in src/libs.
# This removes the external libfftw3, libfaad and libmpg123 dependencies.
# ---------------------------------------------------------------------------

# KISS FFT (replaces FFTW)
add_definitions(-DKISSFFT)
include_directories(src/libs/kiss_fft)
set(fft_sources
    src/libs/kiss_fft/kiss_fft.c
)

# mpg123 - DAB (MP2) decoder
add_definitions(-DOPT_GENERIC)
include_directories(src/libs/mpg123)
set(mpg123_sources
    src/libs/mpg123/compat.c
    src/libs/mpg123/compat_str.c
    src/libs/mpg123/parse.c
    src/libs/mpg123/frame.c
    src/libs/mpg123/format.c
    src/libs/mpg123/dct64.c
    src/libs/mpg123/equalizer.c
    src/libs/mpg123/id3.c
    src/libs/mpg123/icy.c
    src/libs/mpg123/icy2utf8.c
    src/libs/mpg123/optimize.c
    src/libs/mpg123/readers.c
    src/libs/mpg123/tabinit.c
    src/libs/mpg123/libmpg123.c
    src/libs/mpg123/index.c
    src/libs/mpg123/layer1.c
    src/libs/mpg123/layer2.c
    src/libs/mpg123/layer3.c
    src/libs/mpg123/dither.c
    src/libs/mpg123/feature.c
    src/libs/mpg123/synth.c
    src/libs/mpg123/synth_real.c
    src/libs/mpg123/ntom.c
    src/libs/mpg123/synth_8bit.c
    src/libs/mpg123/synth_s32.c
    src/libs/mpg123/stringbuf.c
)

# faad2 - DAB+ (AAC) decoder
add_definitions(-DHAVE_CONFIG_H)
include_directories(
    src/libs/faad2
    src/libs/faad2/include
    src/libs/faad2/libfaad
    src/libs/faad2/libfaad/codebook
)
set(faad_sources
    src/libs/faad2/libfaad/bits.c
    src/libs/faad2/libfaad/cfft.c
    src/libs/faad2/libfaad/common.c
    src/libs/faad2/libfaad/decoder.c
    src/libs/faad2/libfaad/drc.c
    src/libs/faad2/libfaad/drm_dec.c
    src/libs/faad2/libfaad/error.c
    src/libs/faad2/libfaad/filtbank.c
    src/libs/faad2/libfaad/hcr.c
    src/libs/faad2/libfaad/huffman.c
    src/libs/faad2/libfaad/ic_predict.c
    src/libs/faad2/libfaad/is.c
    src/libs/faad2/libfaad/lt_predict.c
    src/libs/faad2/libfaad/mdct.c
    src/libs/faad2/libfaad/mp4.c
    src/libs/faad2/libfaad/ms.c
    src/libs/faad2/libfaad/output.c
    src/libs/faad2/libfaad/pns.c
    src/libs/faad2/libfaad/ps_dec.c
    src/libs/faad2/libfaad/ps_syntax.c
    src/libs/faad2/libfaad/pulse.c
    src/libs/faad2/libfaad/rvlc.c
    src/libs/faad2/libfaad/sbr_dct.c
    src/libs/faad2/libfaad/sbr_dec.c
    src/libs/faad2/libfaad/sbr_e_nf.c
    src/libs/faad2/libfaad/sbr_fbt.c
    src/libs/faad2/libfaad/sbr_hfadj.c
    src/libs/faad2/libfaad/sbr_hfgen.c
    src/libs/faad2/libfaad/sbr_huff.c
    src/libs/faad2/libfaad/sbr_qmf.c
    src/libs/faad2/libfaad/sbr_syntax.c
    src/libs/faad2/libfaad/sbr_tf_grid.c
    src/libs/faad2/libfaad/specrec.c
    src/libs/faad2/libfaad/ssr.c
    src/libs/faad2/libfaad/ssr_fb.c
    src/libs/faad2/libfaad/ssr_ipqf.c
    src/libs/faad2/libfaad/syntax.c
    src/libs/faad2/libfaad/tns.c
)

include_directories(
    ${CMAKE_CURRENT_BINARY_DIR}
    src
    src/backend
    src/output
    src/various
    src/input
    src/gui
    src/libs/fec
)

set(backend_sources
    src/backend/dab-audio.cpp
    src/backend/decoder_adapter.cpp
    src/backend/dab_decoder.cpp
    src/backend/dabplus_decoder.cpp
    src/backend/charsets.cpp
    src/backend/dab-constants.cpp
    src/backend/mot_manager.cpp
    src/backend/pad_decoder.cpp
    src/backend/eep-protection.cpp
    src/backend/fib-processor.cpp
    src/backend/fic-handler.cpp
    src/backend/msc-handler.cpp
    src/backend/freq-interleaver.cpp
    src/backend/ofdm-decoder.cpp
    src/backend/ofdm-processor.cpp
    src/backend/phasereference.cpp
    src/backend/phasetable.cpp
    src/backend/tii-decoder.cpp
    src/backend/protTables.cpp
    src/backend/radio-receiver.cpp
    src/backend/tools.cpp
    src/backend/uep-protection.cpp
    src/backend/viterbi.cpp
    src/various/Socket.cpp
    src/various/Xtan2.cpp
    src/various/channels.cpp
    src/various/fft.cpp
    src/various/profiling.cpp
    src/various/wavfile.c
    src/libs/fec/decode_rs_char.c
    src/libs/fec/encode_rs_char.c
    src/libs/fec/init_rs_char.c
)

set(welle_io_sources
    src/welle-gui/main.cpp
    src/welle-gui/audio_output.cpp
    src/welle-gui/mot_image_provider.cpp
    src/welle-gui/gui_helper.cpp
    src/welle-gui/radio_controller.cpp
    src/welle-gui/debug_output.cpp
    src/welle-gui/waterfallitem.cpp
)

# MPRIS / D-Bus is a Linux-desktop only feature and is off by default.
if(MPRIS AND NOT ANDROID)
    find_package(Qt6 COMPONENTS DBus REQUIRED)
    add_definitions(-DHAVE_MPRIS)
    list(APPEND welle_io_sources
        src/welle-gui/mpris/mpris.cpp
        src/welle-gui/mpris/mpris_mp2.cpp
        src/welle-gui/mpris/mpris_mp2_player.cpp
    )
endif()

if(ANDROID)
    include_directories(
        src/welle-gui
    )
    list(APPEND welle_io_sources
        src/welle-gui/android_rtl_sdr.cpp
    )
endif()

if(IOS)
    # Objective-C++ glue (audio session configuration, etc.)
    list(APPEND welle_io_sources
        src/welle-gui/ios/ios_platform.mm
    )
endif()

# rtl_tcp is the only input device. It is a plain TCP client and needs no
# external libraries beyond the C library / Qt.
set(input_sources
    src/input/input_factory.cpp
    src/input/null_device.cpp
    src/input/raw_file.cpp
    src/input/rtl_tcp.cpp
)

if(NOT GIT_COMMIT_HASH)
  execute_process(
    COMMAND git rev-parse --short HEAD
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    OUTPUT_VARIABLE GIT_COMMIT_HASH
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
endif()

if(GIT_COMMIT_HASH)
  add_definitions("-DGITHASH=\"${GIT_COMMIT_HASH}\"")
endif()

if(NOT GIT_DESCRIBE)
  execute_process(
    COMMAND git describe --tags --long
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    OUTPUT_VARIABLE GIT_DESCRIBE
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
endif()

if(GIT_DESCRIBE)
  add_definitions("-DGITDESCRIBE=\"${GIT_DESCRIBE}\"")
endif()

add_definitions("-DCURRENT_VERSION=\"${CURRENT_VERSION}\"")

STRING(TIMESTAMP BUILD_DATE "%s" UTC)
add_definitions("-DBUILD_DATE=\"${BUILD_DATE}\"")

if(BUILD_WELLE_IO)
    set(executableName welle-io)

    if(CMAKE_AUTORCC)
        qt_add_executable (${executableName} MANUAL_FINALIZATION ${welle_io_sources} ${backend_sources} ${input_sources} ${fft_sources} ${mpg123_sources} ${faad_sources} ${EXTRA_MOCS} src/welle-gui/resources.qrc)
    else()
        qt_add_resources(welle_io_sources src/welle-gui/resources.qrc)
        qt_add_executable (${executableName} MANUAL_FINALIZATION ${welle_io_sources} ${backend_sources} ${input_sources} ${fft_sources} ${mpg123_sources} ${faad_sources} ${EXTRA_MOCS})
    endif()

    if(ANDROID)
        # Compute version code from CURRENT_VERSION value
        string(REGEX MATCH
          "^([0-9]+)\.([0-9]+)\.?([0-9]*)([^0-9]*)"
          CVC_MATCH
          "${CURRENT_VERSION}"
          )

        if(NOT CMAKE_MATCH_3 STREQUAL "")
          math(EXPR CURRENT_VERSION_CODE "${CMAKE_MATCH_1} * 100 + ${CMAKE_MATCH_2} * 10 + ${CMAKE_MATCH_3}")
        else()
          math(EXPR CURRENT_VERSION_CODE "${CMAKE_MATCH_1} * 100 + ${CMAKE_MATCH_2} * 10")
        endif()

        if(NOT CMAKE_MATCH_4 STREQUAL "")
          math(EXPR CURRENT_VERSION_CODE "${CURRENT_VERSION_CODE} - 1")
        endif()

        message (VERBOSE "CURRENT_VERSION_CODE: '${CURRENT_VERSION_CODE}'")

        if(CMAKE_AUTORCC)
            set_property(TARGET ${executableName} PROPERTY AUTORCC_OPTIONS "--no-zstd")
        endif()

        set_property(TARGET ${executableName} PROPERTY QT_ANDROID_PACKAGE_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/src/welle-gui/android)
        set_property(TARGET ${executableName} PROPERTY QT_ANDROID_VERSION_NAME ${CURRENT_VERSION})
        set_property(TARGET ${executableName} PROPERTY QT_ANDROID_VERSION_CODE ${CURRENT_VERSION_CODE})

        # Additional requirements when using Android
        target_link_libraries (${executableName} PRIVATE
            Qt6::CorePrivate
        )

        # Additional components to link to, because otherwise, the builder reports errors like this one:
        #   Skipping /usr/lib/qt-android-6.3-armeabi-v7a/plugins/platforminputcontexts/libplugins_platforminputcontexts_qtvirtualkeyboardplugin_armeabi-v7a.so. It has unmet dependencies: lib/libQt6VirtualKeyboard_armeabi-v7a.so.
        find_package(Qt6 COMPONENTS Svg REQUIRED)
        target_link_libraries (${executableName} PRIVATE
            Qt6::Svg
        )
        find_package(Qt6 COMPONENTS VirtualKeyboard)
        if(Qt6VirtualKeyboard_FOUND)
            target_link_libraries (${executableName} PRIVATE
                Qt6::VirtualKeyboard
            )
        endif()
        if(Qt6Core_VERSION_MAJOR EQUAL 6 AND Qt6Core_VERSION_MINOR GREATER_EQUAL 3)
            find_package(Qt6 COMPONENTS Quick3DUtils REQUIRED)
            target_link_libraries (${executableName} PRIVATE
                Qt6::Quick3DUtils
            )
        endif()
    endif()

    target_link_libraries (${executableName} PRIVATE
      Threads::Threads
      Qt6::Core Qt6::Widgets Qt6::Multimedia Qt6::Charts Qt6::Qml Qt6::Quick Qt6::QuickControls2
    )

    if(MPRIS AND NOT ANDROID)
        target_link_libraries (${executableName} PRIVATE Qt6::DBus)
    endif()

    if(IOS)
        # --- iOS application bundle ---
        set_target_properties(${executableName} PROPERTIES
            MACOSX_BUNDLE TRUE
            MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/src/welle-gui/ios/Info.plist"
            XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "${WELLE_IO_BUNDLE_ID}"
            XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2"
            XCODE_ATTRIBUTE_ASSETCATALOG_COMPILER_APPICON_NAME "AppIcon"
        )

        # App icon: the asset catalog holds the AppIcon image set.
        set(ios_asset_catalog "${CMAKE_CURRENT_SOURCE_DIR}/src/welle-gui/ios/Assets.xcassets")
        target_sources(${executableName} PRIVATE "${ios_asset_catalog}")
        set_source_files_properties("${ios_asset_catalog}" PROPERTIES
            MACOSX_PACKAGE_LOCATION Resources)

        # Native iOS audio-session code (ios_platform.mm) needs AVFoundation.
        target_link_libraries(${executableName} PRIVATE "-framework AVFoundation")

        # Qt Multimedia on iOS uses the FFmpeg backend; embed its static
        # libraries (shipped with the Qt online installer) into the app bundle.
        qt_add_ios_ffmpeg_libraries(${executableName})

        # Development team is only needed for signing on a real device.
        # Leave WELLE_IO_TEAM_ID empty for simulator builds.
        if(WELLE_IO_TEAM_ID)
            set_target_properties(${executableName} PROPERTIES
                XCODE_ATTRIBUTE_DEVELOPMENT_TEAM "${WELLE_IO_TEAM_ID}")
        endif()
    elseif(APPLE AND WITH_APP_BUNDLE)
        set(macOsIcon ${CMAKE_CURRENT_SOURCE_DIR}/src/welle-gui/icons/icon.icns)
        set_source_files_properties(${macOsIcon} PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")
        target_sources(${executableName} PRIVATE ${macOsIcon})

        set(SHORT_VERSION "${WELLE-IO_VERSION}")
        set(EXECUTABLE "${executableName}")
        set(TYPEINFO "io.welle.welle")
        set(PRODUCT_BUNDLE_IDENTIFIER "io.welle.welle")

        set_target_properties("${executableName}" PROPERTIES
            MACOSX_BUNDLE TRUE
            MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_SOURCE_DIR}/welle-io.plist
        )

        INSTALL (TARGETS ${executableName} BUNDLE DESTINATION ${GUI_INSTALL_DIR})
    elseif(NOT ANDROID AND NOT WIN32)
        INSTALL (TARGETS ${executableName} RUNTIME DESTINATION ${GUI_INSTALL_DIR})
        INSTALL (FILES src/welle-gui/doc/man/welle-io.1 DESTINATION ${CMAKE_INSTALL_MANDIR}/man1/)

        if(UNIX AND NOT APPLE)
            INSTALL (FILES ${PROJECT_SOURCE_DIR}/io.welle.welle-gui.desktop DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/applications)
            INSTALL (FILES ${PROJECT_SOURCE_DIR}/io.welle.welle-gui.appdata.xml DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/metainfo)

            INSTALL (FILES ${PROJECT_SOURCE_DIR}/src/welle-gui/icons/16x16/welle-io.png DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/16x16/apps RENAME io.welle.welle-gui.png)
            INSTALL (FILES ${PROJECT_SOURCE_DIR}/src/welle-gui/icons/24x24/welle-io.png DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/24x24/apps RENAME io.welle.welle-gui.png)
            INSTALL (FILES ${PROJECT_SOURCE_DIR}/src/welle-gui/icons/32x32/welle-io.png DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/32x32/apps RENAME io.welle.welle-gui.png)
            INSTALL (FILES ${PROJECT_SOURCE_DIR}/src/welle-gui/icons/48x48/welle-io.png DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/48x48/apps RENAME io.welle.welle-gui.png)
            INSTALL (FILES ${PROJECT_SOURCE_DIR}/src/welle-gui/icons/128x128/welle-io.png DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/128x128/apps RENAME io.welle.welle-gui.png)
            INSTALL (FILES ${PROJECT_SOURCE_DIR}/src/welle-gui/icons/256x256/welle-io.png DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/256x256/apps RENAME io.welle.welle-gui.png)
        endif()
    endif()
endif()

configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/cmake_uninstall.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
    IMMEDIATE @ONLY)

add_custom_target(uninstall
    COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)

if(Qt6Core_FOUND)
  if(BUILD_WELLE_IO)
    qt_finalize_target(welle-io)
  endif()
  if(CMAKE_VERSION VERSION_LESS "3.19")
    message("since CMAKE_VERSION=${CMAKE_VERSION}, add qt6_finalize_project")
    qt6_finalize_project()
  endif()
endif()
