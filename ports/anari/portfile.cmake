vcpkg_from_github(
  OUT_SOURCE_PATH SOURCE_PATH
  REPO KhronosGroup/ANARI-SDK
  REF "v${VERSION}"
  SHA512 cf2c2e044b04d695e0a6c6c1abfb3495ea0996a018742ad3a6baccc6e0e3e9b83cb91b61eda8cf07e8f67f4beba24d07d927697a27606ae008a85fee9fa64fa8
  HEAD_REF next_release
  PATCHES handle-static-libjpeg.patch
)

vcpkg_find_acquire_program(PYTHON3)
get_filename_component(PYTHON3_DIR "${PYTHON3}" DIRECTORY)
vcpkg_add_to_path("${PYTHON3_DIR}")

vcpkg_check_features(
  OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        remote-device BUILD_REMOTE_DEVICE
)

vcpkg_cmake_configure(
  SOURCE_PATH "${SOURCE_PATH}"
  OPTIONS
    -DBUILD_EXAMPLES=OFF
    -DBUILD_VIEWER=OFF
    -DBUILD_CTS=OFF
    -DBUILD_EXAMPLES=OFF
    -DBUILD_HDANARI=OFF
    -DBUILD_HELIDE_DEVICE=OFF
    -DBUILD_TESTING=OFF
    -DINSTALL_CODE_GEN_SCRIPTS=ON
    -DINSTALL_VIEWER_LIBRARY=ON
    -DUSE_DRACO=OFF
    -DUSE_KTX=OFF
    -DUSE_WEBP=OFF

    ${FEATURE_OPTIONS}
)

vcpkg_cmake_install()
vcpkg_cmake_config_fixup(
  CONFIG_PATH "lib/cmake/${PORT}-${VERSION}"
)
vcpkg_fixup_pkgconfig()
vcpkg_copy_pdbs()
vcpkg_replace_string(
  "${CURRENT_PACKAGES_DIR}/share/anari/anariConfig.cmake"
  "  \${CMAKE_CURRENT_LIST_DIR}/../../../share/anari"
  "  \${CMAKE_CURRENT_LIST_DIR}/../../share/anari"
)
if("remote-device" IN_LIST FEATURES)
    vcpkg_copy_tools(TOOL_NAMES "anariRemoteServer" AUTO_CLEAN)
endif()


file(REMOVE_RECURSE
  "${CURRENT_PACKAGES_DIR}/debug/include"
  "${CURRENT_PACKAGES_DIR}/debug/share"
  "${CURRENT_PACKAGES_DIR}/share/anari/code_gen/__pycache__"
)

if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    file(REMOVE_RECURSE
    # "${CURRENT_PACKAGES_DIR}/bin"
    # "${CURRENT_PACKAGES_DIR}/debug/bin"
  )
endif()

vcpkg_install_copyright(
  FILE_LIST "${SOURCE_PATH}/LICENSE"
)
