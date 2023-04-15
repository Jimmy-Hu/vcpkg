# Automatically generated by scripts/boost/generate-ports.ps1

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO boostorg/vmd
    REF boost-1.82.0
    SHA512 0a0e36c6fa4acfc2145b0b1fac79914895b41fb3de0e6688c3dc7160942f0dc1121c59a2e81d6a7a65ec005fefd12ff9453250d35ce59eee4ddeeb655a47c692
    HEAD_REF master
)

include(${CURRENT_INSTALLED_DIR}/share/boost-vcpkg-helpers/boost-modular-headers.cmake)
boost_modular_headers(SOURCE_PATH ${SOURCE_PATH})
