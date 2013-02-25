
cmake_minimum_required (VERSION 2.6)
cmake_policy(VERSION 2.6)

project(Povedit)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake )

#
# Base bits

set (GETTEXT_PACKAGE "Povedit")
set (RELEASE_NAME "Povedit")
set (VERSION "0.1")
set (VERSION_INFO "Release")


configure_file (${CMAKE_SOURCE_DIR}/src/config.h.cmake ${CMAKE_BINARY_DIR}/src/config.h)

add_subdirectory (src)
add_subdirectory (icons)
add_subdirectory (data)


install (FILES ${_datafiles} DESTINATION ${PKGDATADIR}/style)

file (GLOB _imagefiles "${CMAKE_CURRENT_SOURCE_DIR}/data/style/images/*")
install (FILES ${_imagefiles} DESTINATION ${PKGDATADIR}/style/images)


install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/povedit.desktop DESTINATION /usr/share/applications)
