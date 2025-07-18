cmake_minimum_required (VERSION 3.8)
project (xmlsec1 C CXX)

option(INSTALL_HEADERS_TOOLS "Install public header files and tools" ON)

find_package(LibXml2 REQUIRED)
find_package(OpenSSL REQUIRED)

FILE(GLOB SOURCESXMLSEC
	src/*.c
)

FILE(GLOB SOURCESXMLSECOPENSSL
	src/openssl/*.c
	src/strings.c
)

# Generate xmlexports with fixed definition of XMLSEC_STATIC
file(READ include/xmlsec/exports.h EXPORTS_H)
if(BUILD_SHARED_LIBS)
    string(REPLACE "!defined(XMLSEC_STATIC)" "1" EXPORTS_H "${EXPORTS_H}")
else()
    string(REPLACE "!defined(XMLSEC_STATIC)" "0" EXPORTS_H "${EXPORTS_H}")
endif()
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/exports.h "${EXPORTS_H}")

message(STATUS "Reading version info from configure.ac")

file(STRINGS "configure.ac"
    _xmlsec_version_defines REGEX "XMLSEC_VERSION_(MAJOR|MINOR|SUBMINOR)=([0-9]+)$")

foreach(ver ${_xmlsec_version_defines})
    if(ver MATCHES "XMLSEC_VERSION_(MAJOR|MINOR|SUBMINOR)=([0-9]+)$")
        set(XMLSEC_VERSION_${CMAKE_MATCH_1} "${CMAKE_MATCH_2}" CACHE INTERNAL "")
    endif()
endforeach()

set(XMLSEC_VERSION ${XMLSEC_VERSION_MAJOR}.${XMLSEC_VERSION_MINOR}.${XMLSEC_VERSION_SUBMINOR})
math(EXPR XMLSEC_VERSION_INFO_NUMBER
	"${XMLSEC_VERSION_MAJOR} + ${XMLSEC_VERSION_MINOR}")
set(XMLSEC_VERSION_INFO ${XMLSEC_VERSION_INFO_NUMBER}:${XMLSEC_VERSION_SUBMINOR}:${XMLSEC_VERSION_MINOR})

message(STATUS "XMLSEC_VERSION: ${XMLSEC_VERSION}")
message(STATUS "XMLSEC_VERSION_MAJOR: ${XMLSEC_VERSION_MAJOR}")
message(STATUS "XMLSEC_VERSION_MINOR: ${XMLSEC_VERSION_MINOR}")
message(STATUS "XMLSEC_VERSION_SUBMINOR: ${XMLSEC_VERSION_SUBMINOR}")
message(STATUS "XMLSEC_VERSION_INFO: ${XMLSEC_VERSION_INFO}")

message(STATUS "Generating version.h")

configure_file(include/xmlsec/version.h.in include/xmlsec/version.h)

if(MSVC)
  add_compile_options(/wd4130 /wd4127 /wd4152)
endif()

set(CMAKE_SHARED_LIBRARY_PREFIX "lib")
set(CMAKE_STATIC_LIBRARY_PREFIX "lib")

add_library(xmlsec1 ${SOURCESXMLSEC})
add_library(xmlsec1-openssl ${SOURCESXMLSECOPENSSL})

target_include_directories(xmlsec1 PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)
target_link_libraries(xmlsec1 PUBLIC LibXml2::LibXml2)
target_link_libraries(xmlsec1-openssl PUBLIC xmlsec1 OpenSSL::Crypto)

add_compile_definitions(
	inline=__inline
	PACKAGE="xmlsec1"
	HAVE_STDIO_H
	HAVE_STDLIB_H
	HAVE_STRING_H
	HAVE_CTYPE_H
	HAVE_MALLOC_H
	HAVE_MEMORY_H
	XMLSEC_DEFAULT_CRYPTO="openssl"
	UNICODE
	_UNICODE
	_MBCS
	_REENTRANT
	WIN32_LEAN_AND_MEAN
)

set_target_properties(xmlsec1 xmlsec1-openssl PROPERTIES VERSION ${XMLSEC_VERSION_MAJOR}.${XMLSEC_VERSION_MINOR})

set(XMLSEC_CORE_CFLAGS XMLSEC_NO_XSLT XMLSEC_CRYPTO_OPENSSL XMLSEC_NO_FTP XMLSEC_NO_HTTP)
if(NOT BUILD_SHARED_LIBS)
    list(APPEND XMLSEC_CORE_CFLAGS XMLSEC_STATIC XMLSEC_NO_CRYPTO_DYNAMIC_LOADING)
endif()
set(XMLSEC_OPENSSL_CFLAGS XMLSEC_NO_MD5 XMLSEC_NO_RIPEMD160 XMLSEC_NO_GOST XMLSEC_NO_GOST2012)

target_compile_definitions(xmlsec1
    PRIVATE $<$<PLATFORM_ID:Windows>:XMLSEC_DL_WIN32>
    PUBLIC ${XMLSEC_CORE_CFLAGS} 
)
target_compile_definitions(xmlsec1-openssl PUBLIC ${XMLSEC_OPENSSL_CFLAGS})

install(TARGETS xmlsec1 xmlsec1-openssl
    EXPORT unofficial-xmlsec-targets
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
)

install(EXPORT unofficial-xmlsec-targets
    NAMESPACE unofficial::xmlsec::
    DESTINATION share/unofficial-xmlsec
)

if(INSTALL_HEADERS_TOOLS)
	file(GLOB PUBLIC_HEADERS
		include/xmlsec/*.h
		include/xmlsec/openssl/*.h)
	list(FILTER PUBLIC_HEADERS EXCLUDE REGEX "exports\\.h$")

	foreach(file IN LISTS PUBLIC_HEADERS)
		get_filename_component(dir ${file} DIRECTORY)
		file(RELATIVE_PATH rel_dir ${CMAKE_SOURCE_DIR}/xmlsec/${LIB} ${dir})
		install(FILES ${file} DESTINATION "include/${rel_dir}")
	endforeach()

	install(FILES ${CMAKE_CURRENT_BINARY_DIR}/include/xmlsec/version.h DESTINATION "include/xmlsec")
	install(FILES ${CMAKE_CURRENT_BINARY_DIR}/exports.h DESTINATION "include/xmlsec")

	# xmlsec application
	add_executable(xmlsec
		apps/crypto.c
		apps/cmdline.c
		apps/xmlsec.c)

	if(CMAKE_SYSTEM_NAME STREQUAL "Windows" OR CMAKE_SYSTEM_NAME STREQUAL "WindowsStore")
		target_link_libraries(xmlsec PRIVATE crypt32.lib)
	endif()

	target_link_libraries(xmlsec PRIVATE xmlsec1-openssl)

	if(BUILD_SHARED_LIBS)
		target_compile_definitions(xmlsec PRIVATE -DXMLSEC_CRYPTO_DYNAMIC_LOADING)
	else()
		find_package(Threads REQUIRED)
		target_link_libraries(xmlsec PUBLIC Threads::Threads)
	endif()
	install(TARGETS xmlsec DESTINATION tools/xmlsec)
endif()

message(STATUS "Generating pkgconfig files")

set(prefix ${CMAKE_INSTALL_PREFIX})
set(exec_prefix ${prefix})
set(libdir ${prefix}/${CMAKE_INSTALL_LIBDIR})
set(includedir ${prefix}/${CMAKE_INSTALL_INCLUDEDIR})
set(VERSION ${XMLSEC_VERSION})
set(LIBXML_MIN_VERSION ${LIBXML2_VERSION_STRING})
list(JOIN XMLSEC_CORE_CFLAGS " -D" XMLSEC_CORE_CFLAGS)
set(XMLSEC_CORE_CFLAGS "-D${XMLSEC_CORE_CFLAGS} -I\${includedir}/xmlsec1")
set(XMLSEC_CORE_LIBS "-lxmlsec1 -lltdl")
list(JOIN XMLSEC_OPENSSL_CFLAGS " -D" XMLSEC_OPENSSL_CFLAGS)
set(XMLSEC_OPENSSL_CFLAGS "${XMLSEC_CORE_CFLAGS} -D${XMLSEC_OPENSSL_CFLAGS}")
set(XMLSEC_OPENSSL_LIBS "-L\${libdir} -lxmlsec1-openssl ${XMLSEC_CORE_LIBS} -lcrypto")

configure_file(${PROJECT_SOURCE_DIR}/xmlsec.pc.in ${PROJECT_BINARY_DIR}/xmlsec1.pc @ONLY)
configure_file(${PROJECT_SOURCE_DIR}/xmlsec-openssl.pc.in ${PROJECT_BINARY_DIR}/xmlsec1-openssl.pc @ONLY)
install(FILES ${PROJECT_BINARY_DIR}/xmlsec1.pc DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig/)
install(FILES ${PROJECT_BINARY_DIR}/xmlsec1-openssl.pc DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig/)
