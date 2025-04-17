# Automatically generated by scripts/boost/generate-ports.ps1

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO boostorg/foreach
    REF boost-${VERSION}
    SHA512 0278a0616af976ca1ebff1edb70c16e1113565bcf50a1bd5fbd8fdeee644635c8c98b84f8bc81626151964a78afddb4bc65da3cfe324582f9a215c9a9b5edaf8
    HEAD_REF master
)

set(FEATURE_OPTIONS "")
boost_configure_and_install(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS ${FEATURE_OPTIONS}
)
