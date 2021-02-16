vcpkg_fail_port_install(ON_ARCH "x86")

# Don't file if the bin folder exists. We need exe and custom files.
SET(VCPKG_POLICY_EMPTY_PACKAGE enabled)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO PixarAnimationStudios/USD
    REF dc710925675f7f58f7a37f6c18d046a687b09271 # v21.02
    SHA512 afbbbf7f68d82afc67696dcb7a9a6bed91116cd8ff2ea366aa354a721b77d3a5ca4ca9b394a8761c0794d55c6165d439a470852a6008728b91700f6c4bfb5197
    HEAD_REF master
    PATCHES
        fix_build-location.patch
        0001-cmake-Find-HDF5-package-detection.patch
)

vcpkg_find_acquire_program(PYTHON3)
get_filename_component(PYTHON3_DIR "${PYTHON3}" DIRECTORY)
vcpkg_add_to_path("${PYTHON3_DIR}")
vcpkg_add_to_path("${PYTHON3_DIR}/Scripts")

IF (VCPKG_TARGET_IS_WINDOWS)
ELSE()
file(REMOVE ${SOURCE_PATH}/cmake/modules/FindTBB.cmake)
ENDIF()

vcpkg_check_features(
    OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        alembic PXR_BUILD_ALEMBIC_PLUGIN
        draco PXR_BUILD_DRACO_PLUGIN
        embree PXR_BUILD_EMBREE_PLUGIN
        imaging PXR_BUILD_IMAGING
        materialx PXR_BUILD_MATERIALX_PLUGIN
        materialx PXR_ENABLE_MATERIALX_IMAGING_SUPPORT
        opencolorio PXR_BUILD_OPENCOLORIO_PLUGIN
        openimageio PXR_BUILD_OPENIMAGEIO_PLUGIN
        openvdb PXR_ENABLE_OPENVDB_SUPPORT
        python PXR_ENABLE_PYTHON_SUPPORT
        python PXR_USE_PYTHON_3
        tools PXR_BUILD_USD_TOOLS
        usdimaging PXR_BUILD_IMAGING
        usdimaging PXR_BUILD_USD_IMAGING
        usdimaging PXR_ENABLE_GL_SUPPORT
        usdview PXR_BUILD_USDVIEW
)

# Handle python for debug builds
if(python IN_LIST ALL_FEATURES)
  if(VCPKG_CXX_FLAGS_DEBUG MATCHES "BOOST_DEBUG_PYTHON")
    # using debug python, make sure boost search for it
    list(APPEND FEATURE_OPTIONS "-DBoost_USE_DEBUG_PYTHON=ON")
  else()
    # not using it, make sure find python does not find it
    list(APPEND FEATURE_OPTIONS "-DPYTHON_DEBUG_LIBRARY=PYTHON_DEBUG_LIBRARY-NOTFOUND")
  endif()
  if(usdview IN_LIST ALL_FEATURES)
    if(NOT EXISTS "${PYTHON3_DIR}/Scripts/pip${VCPKG_HOST_EXECUTABLE_SUFFIX}")
        vcpkg_from_github(
            OUT_SOURCE_PATH PYFILE_PATH
            REPO pypa/get-pip
            REF 309a56c5fd94bd1134053a541cb4657a4e47e09d #2019-08-25
            SHA512 bb4b0745998a3205cd0f0963c04fb45f4614ba3b6fcbe97efe8f8614192f244b7ae62705483a5305943d6c8fedeca53b2e9905aed918d2c6106f8a9680184c7a
            HEAD_REF master
        )
        vcpkg_execute_required_process(
            COMMAND "${PYTHON3}" "${PYFILE_PATH}/get-pip.py"
            LOGNAME instal-pip
        )
    endif()
    vcpkg_execute_required_process(
        COMMAND "${PYTHON3}" -m pip install pyside2 pyopengl jinja2
        LOGNAME install-pip-dependencies
    )
  endif()
endif()

if(openvdb IN_LIST ALL_FEATURES)
    list(APPEND VCPKG_C_FLAGS "-D_USE_MATH_DEFINES")
    list(APPEND VCPKG_CXX_FLAGS "-D_USE_MATH_DEFINES")
endif()

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    OPTIONS
        ${FEATURE_OPTIONS}
        -DPXR_BUILD_MAYA_PLUGIN:BOOL=OFF
        -DPXR_BUILD_MONOLITHIC:BOOL=OFF
        -DPXR_BUILD_TESTS:BOOL=OFF
        -DPXR_BUILD_EXAMPLES:BOOL=OFF
        -DPXR_BUILD_TUTORIALS:BOOL=OFF
)

vcpkg_install_cmake()

file(
    RENAME
        "${CURRENT_PACKAGES_DIR}/pxrConfig.cmake"
        "${CURRENT_PACKAGES_DIR}/cmake/pxrConfig.cmake")
file(
    REMOVE
        "${CURRENT_PACKAGES_DIR}/debug/pxrConfig.cmake")

vcpkg_fixup_cmake_targets(CONFIG_PATH cmake TARGET_PATH share/pxr)

vcpkg_copy_pdbs()

# Remove duplicates in debug folder
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)

# Handle copyright
file(INSTALL ${SOURCE_PATH}/LICENSE.txt DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)

# Move all dlls to bin
file(GLOB RELEASE_DLL ${CURRENT_PACKAGES_DIR}/lib/*.dll)
file(MAKE_DIRECTORY ${CURRENT_PACKAGES_DIR}/bin)
file(GLOB DEBUG_DLL ${CURRENT_PACKAGES_DIR}/debug/lib/*.dll)
file(MAKE_DIRECTORY ${CURRENT_PACKAGES_DIR}/debug/bin)
foreach(CURRENT_FROM ${RELEASE_DLL} ${DEBUG_DLL})
    string(REPLACE "/lib/" "/bin/" CURRENT_TO ${CURRENT_FROM})
    file(RENAME ${CURRENT_FROM} ${CURRENT_TO})
endforeach()

function(file_replace_regex filename match_string replace_string)
    file(READ ${filename} _contents)
    string(REGEX REPLACE "${match_string}" "${replace_string}" _contents "${_contents}")
    file(WRITE ${filename} "${_contents}")
endfunction()

# fix dll path for cmake
file_replace_regex(${CURRENT_PACKAGES_DIR}/share/pxr/pxrConfig.cmake "/cmake/pxrTargets.cmake" "/pxrTargets.cmake")
file_replace_regex(${CURRENT_PACKAGES_DIR}/share/pxr/pxrTargets-debug.cmake "debug/lib/([a-zA-Z0-9_]+)\\.dll" "debug/bin/\\1.dll")
file_replace_regex(${CURRENT_PACKAGES_DIR}/share/pxr/pxrTargets-release.cmake "lib/([a-zA-Z0-9_]+)\\.dll" "bin/\\1.dll")

# fix plugInfo.json for runtime
file(GLOB_RECURSE PLUGINFO_FILES ${CURRENT_PACKAGES_DIR}/lib/usd/*/resources/plugInfo.json)
file(GLOB_RECURSE PLUGINFO_FILES_DEBUG ${CURRENT_PACKAGES_DIR}/debug/lib/usd/*/resources/plugInfo.json)
foreach(PLUGINFO ${PLUGINFO_FILES} ${PLUGINFO_FILES_DEBUG})
    file_replace_regex(${PLUGINFO} [=["LibraryPath": "../../([a-zA-Z0-9_]+).dll"]=] [=["LibraryPath": "../../../bin/\1.dll"]=])
endforeach()
