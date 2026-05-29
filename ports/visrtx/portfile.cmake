vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO NVIDIA/VisRTX
    REF "v${VERSION}"
    SHA512 294b64a5f9b8d4e528f4995cd15963aec1c942ceab589e3cf14fde01770d205daf8776864a77e2fabc0708f965877251e25438ec6a25bcf84040d260285ecfbd
    HEAD_REF main
)

# Feature-controlled build options
if("gl" IN_LIST FEATURES)
    set(BUILD_GL_DEVICE ON)
else()
    set(BUILD_GL_DEVICE OFF)
endif()

if("rtx" IN_LIST FEATURES)
    set(BUILD_RTX_DEVICE ON)
    # VisRTX auto-fetches OptiX headers from github.com/NVIDIA/optix-dev unless
    # the user provides OPTIX_INSTALL_DIR via cmake.user.presets.json or similar.
    # Pass through whatever the user (or system) has configured.
    set(OPTIX_OPTIONS "")
    if(DEFINED ENV{OPTIX_INSTALL_DIR})
        list(APPEND OPTIX_OPTIONS "-DOptiX_INSTALL_DIR=$ENV{OPTIX_INSTALL_DIR}")
    endif()
else()
    set(BUILD_RTX_DEVICE OFF)
    set(OPTIX_OPTIONS "")
endif()

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DVISRTX_BUILD_GL_DEVICE=${BUILD_GL_DEVICE}
        -DVISRTX_BUILD_RTX_DEVICE=${BUILD_RTX_DEVICE}
        -DVISRTX_BUILD_TSD=OFF
        ${OPTIX_OPTIONS}
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/visrtx)

vcpkg_copy_pdbs()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")

configure_file("${CMAKE_CURRENT_LIST_DIR}/usage" "${CURRENT_PACKAGES_DIR}/share/${PORT}/usage" COPYONLY)
