# Automatically generated by scripts/boost/generate-ports.ps1

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO boostorg/icl
    REF boost-${VERSION}
    SHA512 fd1346495ce408fed874e68baf24641552553f5754fa59e29d2b36b10ef5cae8cd655af13fe378620c1dff45afc5412ff63bf2bfbca33aad62631406eab181bf
    HEAD_REF master
)

set(FEATURE_OPTIONS "")
boost_configure_and_install(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS ${FEATURE_OPTIONS}
)
