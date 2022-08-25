# Automatically generated by scripts/boost/generate-ports.ps1

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO boostorg/any
    REF boost-1.80.0
    SHA512 f8dd40ef5b118f39b4cde16529dc10b12720b17370595a136a64fdf414ea3f974a33eb032c60a6235153595fb01469e9d5b3bb9fef5a73b5547acff0fda73db2
    HEAD_REF master
)

include(${CURRENT_INSTALLED_DIR}/share/boost-vcpkg-helpers/boost-modular-headers.cmake)
boost_modular_headers(SOURCE_PATH ${SOURCE_PATH})
