vcpkg_buildpath_length_warning(37)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO aws/aws-sdk-cpp
    REF "${VERSION}"
    SHA512 826be806ddd87eb452f97df70b19df4194e984775408d8f99246244b6949abcab583e4cbe1ae3bc5d61f3c78267d0e75ea9e69956188ab12e0318344a4314591
    PATCHES
        patch-relocatable-rpath.patch
        fix-aws-root.patch
        lock-curl-http-and-tls-settings.patch
        fix_find_curl.patch
        fix-mingw-compatibility.patch
)

string(COMPARE EQUAL "${VCPKG_CRT_LINKAGE}" "dynamic" FORCE_SHARED_CRT)

set(EXTRA_ARGS "")
if(VCPKG_TARGET_IS_OSX OR VCPKG_TARGET_IS_IOS)
    set(rpath "@loader_path")
elseif (VCPKG_TARGET_IS_ANDROID)
    set(EXTRA_ARGS "-DTARGET_ARCH=ANDROID"
            "-DGIT_EXECUTABLE=--invalid-git-executable--"
            "-DGIT_FOUND=TRUE"
            "-DNDK_DIR=$ENV{ANDROID_NDK_HOME}"
            "-DANDROID_BUILD_ZLIB=FALSE"
            "-DANDROID_BUILD_CURL=FALSE"
            "-DANDROID_BUILD_OPENSSL=FALSE"
            )
else()
    set(rpath "\$ORIGIN")
endif()

string(REPLACE "awsmigrationhub" "AWSMigrationHub" targets "${FEATURES}")
vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    DISABLE_PARALLEL_CONFIGURE
    OPTIONS
        ${EXTRA_ARGS}
        "-DENABLE_UNITY_BUILD=ON"
        "-DENABLE_TESTING=OFF"
        "-DFORCE_SHARED_CRT=${FORCE_SHARED_CRT}"
        "-DBUILD_ONLY=${targets}"
        "-DBUILD_DEPS=OFF"
        "-DBUILD_SHARED_LIBS=OFF"
        "-DAWS_SDK_WARNINGS_ARE_ERRORS=OFF"
        "-DCMAKE_INSTALL_RPATH=${rpath}"
        "-DCMAKE_MODULE_PATH=${CURRENT_INSTALLED_DIR}/share/aws-c-common" # use extra cmake files
)
vcpkg_cmake_install()

foreach(TARGET IN LISTS targets)
    string(TOLOWER "aws-cpp-sdk-${TARGET}" package)
    vcpkg_cmake_config_fixup(PACKAGE_NAME "${package}" CONFIG_PATH "lib/cmake/aws-cpp-sdk-${TARGET}" DO_NOT_DELETE_PARENT_CONFIG_PATH)
endforeach()
vcpkg_cmake_config_fixup(PACKAGE_NAME "awssdk" CONFIG_PATH "lib/cmake/AWSSDK")

vcpkg_copy_pdbs()

file(GLOB_RECURSE AWS_TARGETS "${CURRENT_PACKAGES_DIR}/share/*/*-targets-*.cmake")
foreach(AWS_TARGET IN LISTS AWS_TARGETS)
    file(READ ${AWS_TARGET} _contents)
    string(REGEX REPLACE
        "bin\\/([A-Za-z0-9_.-]+\\.lib)"
        "lib/\\1"
        _contents "${_contents}")
    file(WRITE ${AWS_TARGET} "${_contents}")
endforeach()

file(GLOB AWS_CONFIGS "${CURRENT_PACKAGES_DIR}/share/*/aws-cpp-sdk-*-config.cmake")
list(FILTER AWS_CONFIGS EXCLUDE REGEX "aws-cpp-sdk-core-config\\.cmake\$")
foreach(AWS_CONFIG IN LISTS AWS_CONFIGS)
    file(READ "${AWS_CONFIG}" _contents)
    file(WRITE "${AWS_CONFIG}" "include(CMakeFindDependencyMacro)\nfind_dependency(aws-cpp-sdk-core)\n${_contents}")
endforeach()
vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/share/awssdk/AWSSDKConfig.cmake" [[include(${CMAKE_CURRENT_LIST_DIR}/compiler_settings.cmake)]]
[[include(${CMAKE_CURRENT_LIST_DIR}/compiler_settings.cmake)
include(CMakeFindDependencyMacro)
find_dependency(ZLIB)
find_dependency(CURL)]])
vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/share/aws-cpp-sdk-core/aws-cpp-sdk-core-config.cmake" "find_dependency(aws-crt-cpp)"
[[find_dependency(aws-crt-cpp)
find_dependency(ZLIB)
find_dependency(CURL)]])

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
    "${CURRENT_PACKAGES_DIR}/lib/pkgconfig"
    "${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig"
    "${CURRENT_PACKAGES_DIR}/nuget"
    "${CURRENT_PACKAGES_DIR}/debug/nuget"
)

if(VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
    file(GLOB LIB_FILES ${CURRENT_PACKAGES_DIR}/bin/*.lib)
    if(LIB_FILES)
        file(COPY ${LIB_FILES} DESTINATION ${CURRENT_PACKAGES_DIR}/lib)
        file(REMOVE ${LIB_FILES})
    endif()
    file(GLOB DEBUG_LIB_FILES ${CURRENT_PACKAGES_DIR}/debug/bin/*.lib)
    if(DEBUG_LIB_FILES)
        file(COPY ${DEBUG_LIB_FILES} DESTINATION ${CURRENT_PACKAGES_DIR}/debug/lib)
        file(REMOVE ${DEBUG_LIB_FILES})
    endif()

    file(APPEND "${CURRENT_PACKAGES_DIR}/include/aws/core/SDKConfig.h" "#ifndef USE_IMPORT_EXPORT\n#define USE_IMPORT_EXPORT\n#endif")
endif()

configure_file("${CURRENT_PORT_DIR}/usage" "${CURRENT_PACKAGES_DIR}/share/${PORT}/usage" @ONLY)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
