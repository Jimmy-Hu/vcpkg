# Automatically generated by scripts/boost/generate-ports.ps1

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO boostorg/mp11
    REF boost-${VERSION}
    SHA512 f4f91091e9cb45b6919aa26962867305b920c1664475876c5190145ab7b841b0ba4fa96b7f734bf3ff85c7bc16add92cce659825667513e6c91521508d08ca68
    HEAD_REF master
)

set(FEATURE_OPTIONS "")
boost_configure_and_install(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS ${FEATURE_OPTIONS}
)
