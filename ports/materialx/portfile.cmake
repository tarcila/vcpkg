vcpkg_fail_port_install(ON_ARCH "arm" "arm64" ON_TARGET "uwp")

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO materialx/MaterialX
    REF f26db8285f0db2648cf3a251a88d742a081fe329
    SHA512 06e1ece4c73a9fbfc0af42c45b9a834d31390336912586c26e0324e03468059227b30b2a63b95c64a98091f8d2b04573bffce2e896dce23b0a54bc0d39de7621
    HEAD_REF master
)

if(VCPKG_TARGET_IS_LINUX)
    message(STATUS "MaterialX currently requires the following libraries from the system package manager:\n    libx11\n    libxt\n    freeglut3\n\nThese can be installed on Ubuntu systems via sudo apt-get install libx11-dev libxt-dev freeglut3-dev")
endif()

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
)

vcpkg_install_cmake()

vcpkg_fixup_cmake_targets(CONFIG_PATH cmake/)

 file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/libraries"
    "${CURRENT_PACKAGES_DIR}/debug/mdl"
    "${CURRENT_PACKAGES_DIR}/debug/resources"
)
file(REMOVE
    "${CURRENT_PACKAGES_DIR}/CHANGELOG.md"
    "${CURRENT_PACKAGES_DIR}/README.md"
    "${CURRENT_PACKAGES_DIR}/debug/CHANGELOG.md"
    "${CURRENT_PACKAGES_DIR}/debug/README.md")
file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/include/MaterialXGenMdl/mdl"
    "${CURRENT_PACKAGES_DIR}/include/MaterialXRender/External/OpenImageIO"
    )

file(INSTALL "${SOURCE_PATH}/LICENSE.txt" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)

vcpkg_copy_pdbs()

