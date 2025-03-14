# CMake4GDAL project is distributed under X/MIT license. See accompanying file LICENSE.txt.

# Switches to control build targets(cached)
option(ENABLE_GNM "Build GNM (Geography Network Model) component" ON)
option(ENABLE_PAM "Set ON to enable Persistent Auxiliary Metadata (.aux.xml)" ON)
option(BUILD_APPS "Build command line utilities" ON)
option(BUILD_DOCS "Build documentation" ON)

# This option is to build drivers as plugins, for drivers that have external dependencies, that are not parf of GDAL
# core dependencies Examples are netCDF, HDF4, Oracle, PDF, etc. This global setting can be overridden at the driver
# level with GDAL_ENABLE_FRMT_{foo}_PLUGIN or OGR_ENABLE_{foo}_PLUGIN variables.
option(GDAL_ENABLE_PLUGINS "Set ON to build drivers that have non-core external dependencies as plugin" OFF)

# This option is to build drivers as plugins, for drivers that have no external dependencies or dependencies that are
# part of GDAL core dependencies Examples are BMP, FlatGeobuf, etc.
option(GDAL_ENABLE_PLUGINS_NO_DEPS "Set ON to build drivers that have no non-core external dependencies as plugin" OFF)
mark_as_advanced(GDAL_ENABLE_PLUGINS_NO_DEPS)

option(ENABLE_IPO "Enable Inter-Procedural Optimization if possible" OFF)
if (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
  option(GDAL_ENABLE_MACOSX_FRAMEWORK "Enable Framework on Mac OS X" OFF)
endif ()
option(GDAL_BUILD_OPTIONAL_DRIVERS "Whether to build GDAL optional drivers by default" ON)
option(OGR_BUILD_OPTIONAL_DRIVERS "Whether to build OGR optional drivers by default" ON)

# libgdal shared/satic library generation
option(BUILD_SHARED_LIBS "Set ON to build shared library" ON)

# ######################################################################################################################
# Detect available warning flags

# Do that check now, since we need the result of HAVE_GCC_WARNING_ZERO_AS_NULL_POINTER_CONSTANT for cpl_config.h

set(GDAL_C_WARNING_FLAGS)
set(GDAL_CXX_WARNING_FLAGS)

if (MSVC)
  # 1. conditional expression is constant
  # 2. 'identifier' : class 'type' needs to have dll-interface to be used by clients of class 'type2'
  # 3. non DLL-interface classkey 'identifier' used as base for DLL-interface classkey 'identifier'
  # 4. ??????????
  # 5. 'identifier' : unreferenced formal parameter
  # 6. 'conversion' : conversion from 'type1' to 'type2', signed/unsigned mismatch
  # 7. nonstandard extension used : translation unit is empty (only applies to C source code)
  # 8. new behavior: elements of array 'array' will be default initialized (needed for
  #    https://trac.osgeo.org/gdal/changeset/35593)
  # 9. interaction between '_setjmp' and C++ object destruction is non-portable
  #
  set(GDAL_C_WARNING_FLAGS
      /W4
      /wd4127
      /wd4251
      /wd4275
      /wd4786
      /wd4100
      /wd4245
      /wd4206
      /wd4351
      /wd4611)
  set(GDAL_CXX_WARNING_FLAGS ${GDAL_C_WARNING_FLAGS})
  add_compile_options(/EHsc)

  # The following are extra disables that can be applied to external source not under our control that we wish to use
  # less stringent warnings with.
  set(GDAL_SOFTWARNFLAGS
      /wd4244
      /wd4702
      /wd4701
      /wd4013
      /wd4706
      /wd4057
      /wd4210
      /wd4305)

else ()

  set(GDAL_SOFTWARNFLAGS "")

  macro (detect_and_set_c_warning_flag flag_name)
    string(TOUPPER ${flag_name} flag_name_upper)
    string(REPLACE "-" "_" flag_name_upper "${flag_name_upper}")
    string(REPLACE "=" "_" flag_name_upper "${flag_name_upper}")
    check_c_compiler_flag(-W${flag_name} "HAVE_WFLAG_${flag_name_upper}")
    if (HAVE_WFLAG_${flag_name_upper})
      set(GDAL_C_WARNING_FLAGS ${GDAL_C_WARNING_FLAGS} -W${flag_name})
    endif ()
  endmacro ()

  macro (detect_and_set_cxx_warning_flag flag_name)
    string(TOUPPER ${flag_name} flag_name_upper)
    string(REPLACE "-" "_" flag_name_upper "${flag_name_upper}")
    string(REPLACE "=" "_" flag_name_upper "${flag_name_upper}")
    check_cxx_compiler_flag(-W${flag_name} "HAVE_WFLAG_${flag_name_upper}")
    if (HAVE_WFLAG_${flag_name_upper})
      set(GDAL_CXX_WARNING_FLAGS ${GDAL_CXX_WARNING_FLAGS} -W${flag_name})
    endif ()
  endmacro ()

  macro (detect_and_set_c_and_cxx_warning_flag flag_name)
    string(TOUPPER ${flag_name} flag_name_upper)
    string(REPLACE "-" "_" flag_name_upper "${flag_name_upper}")
    string(REPLACE "=" "_" flag_name_upper "${flag_name_upper}")
    check_c_compiler_flag(-W${flag_name} "HAVE_WFLAG_${flag_name_upper}")
    if (HAVE_WFLAG_${flag_name_upper})
      set(GDAL_C_WARNING_FLAGS ${GDAL_C_WARNING_FLAGS} -W${flag_name})
      set(GDAL_CXX_WARNING_FLAGS ${GDAL_CXX_WARNING_FLAGS} -W${flag_name})
    endif ()
  endmacro ()

  detect_and_set_c_and_cxx_warning_flag(all)
  detect_and_set_c_and_cxx_warning_flag(extra)
  detect_and_set_c_and_cxx_warning_flag(init-self)
  detect_and_set_c_and_cxx_warning_flag(unused-parameter)
  detect_and_set_c_warning_flag(missing-prototypes)
  detect_and_set_c_and_cxx_warning_flag(missing-declarations)
  detect_and_set_c_and_cxx_warning_flag(shorten-64-to-32)
  detect_and_set_c_and_cxx_warning_flag(logical-op)
  detect_and_set_c_and_cxx_warning_flag(shadow)
  detect_and_set_c_and_cxx_warning_flag(missing-include-dirs)
  check_c_compiler_flag("-Wformat -Werror=format-security -Wno-format-nonliteral" HAVE_WFLAG_FORMAT_SECURITY)
  if (HAVE_WFLAG_FORMAT_SECURITY)
    set(GDAL_C_WARNING_FLAGS ${GDAL_C_WARNING_FLAGS} -Wformat -Werror=format-security -Wno-format-nonliteral)
    set(GDAL_CXX_WARNING_FLAGS ${GDAL_CXX_WARNING_FLAGS} -Wformat -Werror=format-security -Wno-format-nonliteral)
  else ()
    detect_and_set_c_and_cxx_warning_flag(format)
  endif ()
  detect_and_set_c_and_cxx_warning_flag(error=vla)
  detect_and_set_c_and_cxx_warning_flag(no-clobbered)
  detect_and_set_c_and_cxx_warning_flag(date-time)
  detect_and_set_c_and_cxx_warning_flag(null-dereference)
  detect_and_set_c_and_cxx_warning_flag(duplicate-cond)
  detect_and_set_cxx_warning_flag(extra-semi)
  detect_and_set_c_and_cxx_warning_flag(no-sign-compare)
  detect_and_set_c_and_cxx_warning_flag(comma)
  detect_and_set_c_and_cxx_warning_flag(float-conversion)
  check_c_compiler_flag("-Wdocumentation -Wno-documentation-deprecated-sync" HAVE_WFLAG_DOCUMENTATION_AND_NO_DEPRECATED)
  if (HAVE_WFLAG_DOCUMENTATION_AND_NO_DEPRECATED)
    set(GDAL_C_WARNING_FLAGS ${GDAL_C_WARNING_FLAGS} -Wdocumentation -Wno-documentation-deprecated-sync)
    set(GDAL_CXX_WARNING_FLAGS ${GDAL_CXX_WARNING_FLAGS} -Wdocumentation -Wno-documentation-deprecated-sync)
  endif ()
  detect_and_set_cxx_warning_flag(unused-private-field)
  detect_and_set_cxx_warning_flag(non-virtual-dtor)
  detect_and_set_cxx_warning_flag(overloaded-virtual)

  check_cxx_compiler_flag(-fno-operator-names HAVE_FLAG_NO_OPERATOR_NAMES)
  if (HAVE_FLAG_NO_OPERATOR_NAMES)
    set(GDAL_CXX_WARNING_FLAGS ${GDAL_CXX_WARNING_FLAGS} -fno-operator-names)
  endif ()

  check_cxx_compiler_flag(-Wzero-as-null-pointer-constant HAVE_GCC_WARNING_ZERO_AS_NULL_POINTER_CONSTANT)
  if (HAVE_GCC_WARNING_ZERO_AS_NULL_POINTER_CONSTANT)
    set(GDAL_CXX_WARNING_FLAGS ${GDAL_CXX_WARNING_FLAGS} -Wzero-as-null-pointer-constant)
  endif ()

  # Detect -Wold-style-cast but do not add it by default, as not all targets support it
  check_cxx_compiler_flag(-Wold-style-cast HAVE_WFLAG_OLD_STYLE_CAST)
  if (HAVE_WFLAG_OLD_STYLE_CAST)
    set(WFLAG_OLD_STYLE_CAST -Wold-style-cast)
  endif ()

  # Detect Weffc++ but do not add it by default, as not all targets support it
  check_cxx_compiler_flag(-Weffc++ HAVE_WFLAG_EFFCXX)
  if (HAVE_WFLAG_EFFCXX)
    set(WFLAG_EFFCXX -Weffc++)
  endif ()

  if (CMAKE_BUILD_TYPE MATCHES Debug)
    check_c_compiler_flag(-ftrapv HAVE_FTRAPV)
    if (HAVE_FTRAPV)
      set(GDAL_C_WARNING_FLAGS ${GDAL_C_WARNING_FLAGS} -ftrapv)
      set(GDAL_CXX_WARNING_FLAGS ${GDAL_CXX_WARNING_FLAGS} -ftrapv)
    endif ()
  endif ()

endif ()

# message("GDAL_C_WARNING_FLAGS: ${GDAL_C_WARNING_FLAGS}") message("GDAL_CXX_WARNING_FLAGS: ${GDAL_CXX_WARNING_FLAGS}")

if (CMAKE_CXX_COMPILER_ID STREQUAL "IntelLLVM")
  check_cxx_compiler_flag(-fno-finite-math-only HAVE_FLAG_NO_FINITE_MATH_ONLY)
  if (HAVE_FLAG_NO_FINITE_MATH_ONLY)
    # Intel CXX compiler based on clang defaults to -ffinite-math-only, which breaks std::isinf(), std::isnan(), etc.
    set(CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS} -fno-finite-math-only)
  endif ()
endif ()

# ######################################################################################################################
# generate ${CMAKE_CURRENT_BINARY_DIR}/port/cpl_config.h

set(_CMAKE_C_FLAGS_backup ${CMAKE_C_FLAGS})
set(_CMAKE_CXX_FLAGS_backup ${CMAKE_CXX_FLAGS})
if (CMAKE_C_FLAGS)
  string(REPLACE "-Werror" " " CMAKE_C_FLAGS ${CMAKE_C_FLAGS})
  string(REPLACE "/WX" " " CMAKE_C_FLAGS ${CMAKE_C_FLAGS})
endif ()
if (CMAKE_CXX_FLAGS)
  string(REPLACE "-Werror" " " CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS})
  string(REPLACE "/WX" " " CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS})
endif ()
include(configure)

# generate ${CMAKE_CURRENT_BINARY_DIR}/gcore/gdal_version.h and set GDAL_VERSION variable
include(GdalVersion)

# find 3rd party libraries
include(CheckDependentLibraries)

# Generates now port/cpl_config.h (it depends on at least iconv detection in CheckDependentLibraries)
configure_file(${GDAL_CMAKE_TEMPLATE_PATH}/cpl_config.h.in ${PROJECT_BINARY_DIR}/port/cpl_config.h @ONLY)

set(CMAKE_C_FLAGS ${_CMAKE_C_FLAGS_backup})
set(CMAKE_CXX_FLAGS ${_CMAKE_CXX_FLAGS_backup})

if (GDAL_HIDE_INTERNAL_SYMBOLS)
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fvisibility=hidden")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fvisibility=hidden")
endif ()

# Check that all symbols we need are present in our dependencies This is in particular useful to check that drivers
# built as plugins can access all symbols they need.
if (CMAKE_CXX_COMPILER_ID MATCHES "Clang" OR CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
  include(CheckLinkerFlag)
  check_linker_flag(C "-Wl,--no-undefined" HAS_NO_UNDEFINED)
  if (HAS_NO_UNDEFINED)
    string(APPEND CMAKE_SHARED_LINKER_FLAGS " -Wl,--no-undefined")
    string(APPEND CMAKE_MODULE_LINKER_FLAGS " -Wl,--no-undefined")
  endif ()
endif ()

# Default definitions during build
add_definitions(-DGDAL_COMPILATION -DGDAL_CMAKE_BUILD)

if (ENABLE_IPO)
  if (POLICY CMP0069)
    include(CheckIPOSupported)
    check_ipo_supported(RESULT result)
    if (result)
      set(CMAKE_INTERPROCEDURAL_OPTIMIZATION True)
    endif ()
  endif ()
endif ()

# ######################################################################################################################

set_property(GLOBAL PROPERTY gdal_private_link_libraries)
function (gdal_add_private_link_libraries)
  get_property(tmp GLOBAL PROPERTY gdal_private_link_libraries)
  foreach (arg ${ARGV})
    set(tmp ${tmp} ${arg})
  endforeach ()
  set_property(GLOBAL PROPERTY gdal_private_link_libraries ${tmp})
endfunction (gdal_add_private_link_libraries)

add_library(${GDAL_LIB_TARGET_NAME} gcore/gdal.h)
set_target_properties(${GDAL_LIB_TARGET_NAME} PROPERTIES OUTPUT_NAME "gdal")
add_library(GDAL::GDAL ALIAS ${GDAL_LIB_TARGET_NAME})
add_dependencies(${GDAL_LIB_TARGET_NAME} generate_gdal_version_h)
if (M_LIB)
  gdal_add_private_link_libraries(-lm)
endif ()
# Set project and C++ Standard properties
set_target_properties(
  ${GDAL_LIB_TARGET_NAME}
  PROPERTIES PROJECT_LABEL ${PROJECT_NAME}
             VERSION ${GDAL_ABI_FULL_VERSION}
             SOVERSION "${GDAL_SOVERSION}"
             ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
             LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
             RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
             CXX_STANDARD 11
             CXX_STANDARD_REQUIRED YES)
set_property(TARGET ${GDAL_LIB_TARGET_NAME} PROPERTY PLUGIN_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/gdalplugins")
file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/gdalplugins")

if (MSVC)
  set(GDAL_DEBUG_POSTFIX
      "d"
      CACHE STRING "Postfix to add to the GDAL dll name for debug builds")
  set_target_properties(${GDAL_LIB_TARGET_NAME} PROPERTIES DEBUG_POSTFIX "${GDAL_DEBUG_POSTFIX}")
endif ()

if (MSVC AND NOT BUILD_SHARED_LIBS)
  target_compile_definitions(${GDAL_LIB_TARGET_NAME} PUBLIC CPL_DISABLE_DLL=)
endif ()

if (MINGW)
  if (TARGET_CPU MATCHES "x86_64")
    add_definitions(-m64)
  endif ()
  # Workaround for export too large error - force problematic large file to be optimized to prevent string table
  # overflow error Used -Os instead of -O2 as previous issues had mentioned, since -Os is roughly speaking -O2,
  # excluding any optimizations that take up extra space. Given that the issue is a string table overflowing, -Os seemed
  # appropriate.
  if (CMAKE_BUILD_TYPE MATCHES Debug)
    set_compile_options(-Os)
  endif ()
endif ()

# Install properties
if (GDAL_ENABLE_MACOSX_FRAMEWORK)
  set(CMAKE_MACOSX_RPATH ON)
  set(FRAMEWORK_VERSION ${GDAL_VERSION_MAJOR}.${GDAL_VERSION_MINOR})
  set(FRAMEWORK_DESTINATION
      "Library/Frameworks"
      CACHE STRING "Framework destination sub-directory")
  set(FRAMEWORK_SUBDIR "${FRAMEWORK_DESTINATION}/gdal.framework/Versions/${FRAMEWORK_VERSION}")
  set(INSTALL_PLUGIN_DIR
      "${FRAMEWORK_SUBDIR}/PlugIns"
      CACHE PATH "Installation sub-directory for plugins")
  set(CMAKE_INSTALL_BINDIR
      "bin"
      CACHE STRING "Installation sub-directory for executables")
  set(CMAKE_INSTALL_LIBDIR
      "${FRAMEWORK_SUBDIR}"
      CACHE INTERNAL "Installation sub-directory for libraries" FORCE)
  # CMAKE_INSTALL_INCLUDEDIR should normally not be used
  set(CMAKE_INSTALL_INCLUDEDIR
      "${FRAMEWORK_SUBDIR}/Headers"
      CACHE INTERNAL "Installation sub-directory for headers" FORCE)
  set(CMAKE_INSTALL_DATADIR
      "${FRAMEWORK_SUBDIR}/Resources"
      CACHE INTERNAL "Installation sub-directory for resources" FORCE)
  set(GDAL_RESOURCE_PATH ${CMAKE_INSTALL_DATADIR})
  set_target_properties(
    ${GDAL_LIB_TARGET_NAME}
    PROPERTIES FRAMEWORK TRUE
               FRAMEWORK_VERSION ${GDAL_VERSION_MAJOR}.${GDAL_VERSION_MINOR}
               MACOSX_FRAMEWORK_SHORT_VERSION_STRING ${GDAL_VERSION_MAJOR}.${GDAL_VERSION_MINOR}
               MACOSX_FRAMEWORK_BUNDLE_VERSION "GDAL ${GDAL_VERSION_MAJOR}.${GDAL_VERSION_MINOR}"
               MACOSX_FRAMEWORK_IDENTIFIER org.osgeo.libgdal
               XCODE_ATTRIBUTE_INSTALL_PATH "@rpath"
               INSTALL_NAME_DIR "${CMAKE_INSTALL_PREFIX}/${FRAMEWORK_DESTINATION}"
               BUILD_WITH_INSTALL_RPATH TRUE
               # MACOSX_FRAMEWORK_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/info.plist.in"
    )
else ()
  include(GNUInstallDirs)
  set(INSTALL_PLUGIN_DIR
      "lib/gdalplugins/${GDAL_VERSION_MAJOR}.${GDAL_VERSION_MINOR}"
      CACHE PATH "Installation sub-directory for plugins")
  set(GDAL_RESOURCE_PATH ${CMAKE_INSTALL_DATADIR}/gdal)
endif ()

set(INSTALL_PLUGIN_FULL_DIR "${CMAKE_INSTALL_PREFIX}/${INSTALL_PLUGIN_DIR}")

# detect portability libs and set, so it should add at first Common Portability layer
add_subdirectory(port)

# Configure internal libraries
if (GDAL_USE_LIBZ_INTERNAL)
  add_subdirectory(frmts/zlib)
endif ()
if (GDAL_USE_LIBJSONC_INTERNAL)
  add_subdirectory(ogr/ogrsf_frmts/geojson/libjson)
endif ()
if (GDAL_USE_LIBTIFF_INTERNAL)
  option(RENAME_INTERNAL_LIBTIFF_SYMBOLS "Rename internal libtiff symbols" ON)
  add_subdirectory(frmts/gtiff/libtiff)
endif ()
if (GDAL_USE_LIBGEOTIFF_INTERNAL)
  option(RENAME_INTERNAL_LIBGEOTIFF_SYMBOLS "Rename internal libgeotiff symbols" ON)
  add_subdirectory(frmts/gtiff/libgeotiff)
endif ()
if (GDAL_USE_LIBJPEG_INTERNAL)
  option(RENAME_INTERNAL_LIBJPEG_SYMBOLS "Rename internal libjpeg symbols" ON)
  add_subdirectory(frmts/jpeg/libjpeg)
endif ()
option(GDAL_JPEG12_SUPPORTED "Set ON to use libjpeg12 support" ON)
if (GDAL_JPEG12_SUPPORTED)
  add_subdirectory(frmts/jpeg/libjpeg12)
endif ()
if (GDAL_USE_GIFLIB_INTERNAL)
  add_subdirectory(frmts/gif/giflib)
endif ()
if (GDAL_USE_LIBPNG_INTERNAL)
  add_subdirectory(frmts/png/libpng)
endif ()
if (GDAL_USE_LIBLERC_INTERNAL)
  add_subdirectory(third_party/LercLib)
endif ()
if (GDAL_USE_SHAPELIB_INTERNAL)
  option(RENAME_INTERNAL_SHAPELIB_SYMBOLS "Rename internal Shapelib symbols" ON)
endif ()

# Core components
add_subdirectory(alg)
add_subdirectory(ogr)
if (ENABLE_GNM)
  add_subdirectory(gnm)
endif ()

# Raster/Vector drivers (built-in and plugins)
set(GDAL_RASTER_FORMAT_SOURCE_DIR "${PROJECT_SOURCE_DIR}/frmts")
set(GDAL_VECTOR_FORMAT_SOURCE_DIR "${PROJECT_SOURCE_DIR}/ogr/ogrsf_frmts")

# We need to forward declare a few OGR drivers because raster formats need them
option(OGR_ENABLE_AVC "Set ON to build OGR AVC driver" ${OGR_BUILD_OPTIONAL_DRIVERS})
cmake_dependent_option(OGR_ENABLE_SQLITE "Set ON to build OGR SQLite driver" ${OGR_BUILD_OPTIONAL_DRIVERS}
                       "GDAL_USE_SQLITE3" OFF)
cmake_dependent_option(OGR_ENABLE_GPKG "Set ON to build OGR GPKG driver" ${OGR_BUILD_OPTIONAL_DRIVERS}
                       "GDAL_USE_SQLITE3;OGR_ENABLE_SQLITE" OFF)

add_subdirectory(frmts)
add_subdirectory(ogr/ogrsf_frmts)

# It needs to be after ogr/ogrsf_frmts so it can use OGR_ENABLE_SQLITE
add_subdirectory(gcore)

# Bindings
if (BUILD_SHARED_LIBS)
  add_subdirectory(swig)
endif ()

# Utilities
add_subdirectory(apps)

# Add all library dependencies of target gdal
get_property(GDAL_PRIVATE_LINK_LIBRARIES GLOBAL PROPERTY gdal_private_link_libraries)
target_link_libraries(${GDAL_LIB_TARGET_NAME} PRIVATE ${GDAL_PRIVATE_LINK_LIBRARIES})

# Document/Manuals
if (BUILD_DOCS)
  add_subdirectory(doc)
endif ()

# GDAL 4.0 ? Install headers in ${CMAKE_INSTALL_INCLUDEDIR}/gdal ?
set(GDAL_INSTALL_INCLUDEDIR ${CMAKE_INSTALL_INCLUDEDIR})

# So that GDAL can be used as a add_subdirectory() of another project
target_include_directories(
  ${GDAL_LIB_TARGET_NAME}
  PUBLIC $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/apps>
         $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/alg>
         $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/gcore>
         $<BUILD_INTERFACE:${PROJECT_BINARY_DIR}/gcore/gdal_version_full>
         $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/port>
         $<BUILD_INTERFACE:${PROJECT_BINARY_DIR}/port>
         $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/ogr>
         $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/ogr/ogrsf_frmts>
         $<INSTALL_INTERFACE:${GDAL_INSTALL_INCLUDEDIR}>)

# MSVC specific resource preparation
if (MSVC)
  target_sources(${GDAL_LIB_TARGET_NAME} PRIVATE gcore/Version.rc)
  source_group("Resource Files" FILES gcore/Version.rc)
  if (CMAKE_CL_64)
    set_target_properties(${GDAL_LIB_TARGET_NAME} PROPERTIES STATIC_LIBRARY_FLAGS "/machine:x64")
  endif ()
endif ()

# Windows(Mingw/MSVC) link libraries
if (CMAKE_SYSTEM_NAME MATCHES "Windows")
  # wbemuuid needed for port/cpl_aws_win32.cpp
  target_link_libraries(${GDAL_LIB_TARGET_NAME} PRIVATE wsock32 ws2_32 secur32 psapi wbemuuid)
endif ()

get_property(_plugins GLOBAL PROPERTY PLUGIN_MODULES)
add_custom_target(gdal_plugins DEPENDS ${_plugins})

# ######################################################################################################################
configure_file(${GDAL_CMAKE_TEMPLATE_PATH}/gdal_def.h.in ${CMAKE_CURRENT_BINARY_DIR}/gcore/gdal_def.h @ONLY)

# ######################################################################################################################
set_property(
  TARGET ${GDAL_LIB_TARGET_NAME}
  APPEND
  PROPERTY PUBLIC_HEADER ${CMAKE_CURRENT_BINARY_DIR}/port/cpl_config.h)

set(GDAL_DATA_FILES
    LICENSE.TXT
    data/GDALLogoBW.svg
    data/GDALLogoColor.svg
    data/GDALLogoGS.svg
    data/bag_template.xml
    data/cubewerx_extra.wkt
    data/default.rsc
    data/ecw_cs.wkt
    data/eedaconf.json
    data/epsg.wkt
    data/esri_StatePlane_extra.wkt
    data/gdalicon.png
    data/gdalmdiminfo_output.schema.json
    data/gdalvrt.xsd
    data/gml_registry.xml
    data/gmlasconf.xml
    data/gmlasconf.xsd
    data/grib2_table_versions.csv
    data/grib2_center.csv
    data/grib2_process.csv
    data/grib2_subcenter.csv
    data/grib2_table_4_2_0_0.csv
    data/grib2_table_4_2_0_13.csv
    data/grib2_table_4_2_0_14.csv
    data/grib2_table_4_2_0_15.csv
    data/grib2_table_4_2_0_16.csv
    data/grib2_table_4_2_0_17.csv
    data/grib2_table_4_2_0_18.csv
    data/grib2_table_4_2_0_190.csv
    data/grib2_table_4_2_0_191.csv
    data/grib2_table_4_2_0_19.csv
    data/grib2_table_4_2_0_1.csv
    data/grib2_table_4_2_0_20.csv
    data/grib2_table_4_2_0_2.csv
    data/grib2_table_4_2_0_3.csv
    data/grib2_table_4_2_0_4.csv
    data/grib2_table_4_2_0_5.csv
    data/grib2_table_4_2_0_6.csv
    data/grib2_table_4_2_0_7.csv
    data/grib2_table_4_2_10_0.csv
    data/grib2_table_4_2_10_191.csv
    data/grib2_table_4_2_10_1.csv
    data/grib2_table_4_2_10_2.csv
    data/grib2_table_4_2_10_3.csv
    data/grib2_table_4_2_10_4.csv
    data/grib2_table_4_2_1_0.csv
    data/grib2_table_4_2_1_1.csv
    data/grib2_table_4_2_1_2.csv
    data/grib2_table_4_2_20_0.csv
    data/grib2_table_4_2_20_1.csv
    data/grib2_table_4_2_20_2.csv
    data/grib2_table_4_2_2_0.csv
    data/grib2_table_4_2_2_3.csv
    data/grib2_table_4_2_2_4.csv
    data/grib2_table_4_2_2_5.csv
    data/grib2_table_4_2_3_0.csv
    data/grib2_table_4_2_3_1.csv
    data/grib2_table_4_2_3_2.csv
    data/grib2_table_4_2_3_3.csv
    data/grib2_table_4_2_3_4.csv
    data/grib2_table_4_2_3_5.csv
    data/grib2_table_4_2_3_6.csv
    data/grib2_table_4_2_4_0.csv
    data/grib2_table_4_2_4_10.csv
    data/grib2_table_4_2_4_1.csv
    data/grib2_table_4_2_4_2.csv
    data/grib2_table_4_2_4_3.csv
    data/grib2_table_4_2_4_4.csv
    data/grib2_table_4_2_4_5.csv
    data/grib2_table_4_2_4_6.csv
    data/grib2_table_4_2_4_7.csv
    data/grib2_table_4_2_4_8.csv
    data/grib2_table_4_2_4_9.csv
    data/grib2_table_4_2_local_Canada.csv
    data/grib2_table_4_2_local_HPC.csv
    data/grib2_table_4_2_local_index.csv
    data/grib2_table_4_2_local_MRMS.csv
    data/grib2_table_4_2_local_NCEP.csv
    data/grib2_table_4_2_local_NDFD.csv
    data/grib2_table_4_5.csv
    data/gt_datum.csv
    data/gt_ellips.csv
    data/header.dxf
    data/inspire_cp_BasicPropertyUnit.gfs
    data/inspire_cp_CadastralBoundary.gfs
    data/inspire_cp_CadastralParcel.gfs
    data/inspire_cp_CadastralZoning.gfs
    data/jpfgdgml_AdmArea.gfs
    data/jpfgdgml_AdmBdry.gfs
    data/jpfgdgml_AdmPt.gfs
    data/jpfgdgml_BldA.gfs
    data/jpfgdgml_BldL.gfs
    data/jpfgdgml_Cntr.gfs
    data/jpfgdgml_CommBdry.gfs
    data/jpfgdgml_CommPt.gfs
    data/jpfgdgml_Cstline.gfs
    data/jpfgdgml_ElevPt.gfs
    data/jpfgdgml_GCP.gfs
    data/jpfgdgml_LeveeEdge.gfs
    data/jpfgdgml_RailCL.gfs
    data/jpfgdgml_RdASL.gfs
    data/jpfgdgml_RdArea.gfs
    data/jpfgdgml_RdCompt.gfs
    data/jpfgdgml_RdEdg.gfs
    data/jpfgdgml_RdMgtBdry.gfs
    data/jpfgdgml_RdSgmtA.gfs
    data/jpfgdgml_RvrMgtBdry.gfs
    data/jpfgdgml_SBAPt.gfs
    data/jpfgdgml_SBArea.gfs
    data/jpfgdgml_SBBdry.gfs
    data/jpfgdgml_WA.gfs
    data/jpfgdgml_WL.gfs
    data/jpfgdgml_WStrA.gfs
    data/jpfgdgml_WStrL.gfs
    data/netcdf_config.xsd
    data/nitf_spec.xml
    data/nitf_spec.xsd
    data/ogrvrt.xsd
    data/osmconf.ini
    data/ozi_datum.csv
    data/ozi_ellips.csv
    data/pci_datum.txt
    data/pci_ellips.txt
    data/pdfcomposition.xsd
    data/pds4_template.xml
    data/plscenesconf.json
    data/ruian_vf_ob_v1.gfs
    data/ruian_vf_st_uvoh_v1.gfs
    data/ruian_vf_st_v1.gfs
    data/ruian_vf_v1.gfs
    data/s57agencies.csv
    data/s57attributes.csv
    data/s57expectedinput.csv
    data/s57objectclasses.csv
    data/seed_2d.dgn
    data/seed_3d.dgn
    data/stateplane.csv
    data/template_tiles.mapml
    data/tms_LINZAntarticaMapTileGrid.json
    data/tms_MapML_APSTILE.json
    data/tms_MapML_CBMTILE.json
    data/tms_NZTM2000.json
    data/trailer.dxf
    data/vdv452.xml
    data/vdv452.xsd
    data/vicar.json)
set_property(
  TARGET ${GDAL_LIB_TARGET_NAME}
  APPEND
  PROPERTY RESOURCE "${GDAL_DATA_FILES}")

if (GDAL_ENABLE_MACOSX_FRAMEWORK)
  # We need to add data files and public headers as sources of the library os they get installed through the framework
  # installation mechanisms
  target_sources(${GDAL_LIB_TARGET_NAME} PRIVATE "${GDAL_DATA_FILES}")
  get_property(
    _public_headers
    TARGET ${GDAL_LIB_TARGET_NAME}
    PROPERTY PUBLIC_HEADER)
  target_sources(${GDAL_LIB_TARGET_NAME} PRIVATE "${_public_headers}")
endif ()

install(
  TARGETS ${GDAL_LIB_TARGET_NAME}
  EXPORT gdal-export
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  RESOURCE DESTINATION ${GDAL_RESOURCE_PATH}
  PUBLIC_HEADER DESTINATION ${GDAL_INSTALL_INCLUDEDIR}
  FRAMEWORK DESTINATION "${FRAMEWORK_DESTINATION}")

if (UNIX AND NOT GDAL_ENABLE_MACOSX_FRAMEWORK)
  # Generate GdalConfig.cmake and GdalConfigVersion.cmake
  export(
    EXPORT gdal-export
    NAMESPACE GDAL::
    FILE gdal-export.cmake)
  install(
    EXPORT gdal-export
    FILE GDALConfig.cmake
    NAMESPACE GDAL::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/gdal/
    EXPORT_LINK_INTERFACE_LIBRARIES)
  include(CMakePackageConfigHelpers)
  write_basic_package_version_file(
    GDALConfigVersion.cmake
    VERSION ${GDAL_VERSION}
    # SameMinorVersion compatibility are supported CMake > 3.10.1 so use ExactVersion instead. COMPATIBILITY
    # SameMinorVersion)
    COMPATIBILITY ExactVersion)
  install(FILES ${CMAKE_CURRENT_BINARY_DIR}/GDALConfigVersion.cmake DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/gdal/)

  # gdal-config utility command generation
  include(GenerateConfig)
  if (ENABLE_GNM)
    set(CONFIG_GNM_ENABLED "yes")
  else ()
    set(CONFIG_GNM_ENABLED "no")
  endif ()
  get_property(_GDAL_FORMATS GLOBAL PROPERTY GDAL_FORMATS)
  get_property(_OGR_FORMATS GLOBAL PROPERTY OGR_FORMATS)
  string(REPLACE ";" " " CONFIG_FORMATS "${_GDAL_FORMATS} ${_OGR_FORMATS}")
  generate_config(${GDAL_LIB_TARGET_NAME} "gdal_private_link_libraries" ${GDAL_CMAKE_TEMPLATE_PATH}/gdal-config.in
                  ${PROJECT_BINARY_DIR}/apps/gdal-config)
  add_custom_target(gdal_config ALL DEPENDS ${PROJECT_BINARY_DIR}/apps/gdal-config)
  install(
    PROGRAMS ${PROJECT_BINARY_DIR}/apps/gdal-config
    DESTINATION ${CMAKE_INSTALL_BINDIR}
    PERMISSIONS OWNER_READ
                OWNER_WRITE
                OWNER_EXECUTE
                GROUP_READ
                GROUP_EXECUTE
                WORLD_READ
                WORLD_EXECUTE
    COMPONENT applications)

  # pkg-config resource
  get_property(
    _gdal_lib_name
    TARGET ${GDAL_LIB_TARGET_NAME}
    PROPERTY OUTPUT_NAME)
  set(CONFIG_INST_LIBS "-L${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR} -l${_gdal_lib_name}")
  set(CONFIG_INST_CFLAGS "-I${CMAKE_INSTALL_PREFIX}/${GDAL_INSTALL_INCLUDEDIR}")
  set(CONFIG_INST_DATA "${CMAKE_INSTALL_PREFIX}/${GDAL_RESOURCE_PATH}")
  get_dep_libs(${GDAL_LIB_TARGET_NAME} "gdal_private_link_libraries" CONFIG_INST_DEP_LIBS)
  configure_file(${GDAL_CMAKE_TEMPLATE_PATH}/gdal.pc.in ${CMAKE_CURRENT_BINARY_DIR}/gdal.pc @ONLY)
  install(
    FILES ${CMAKE_CURRENT_BINARY_DIR}/gdal.pc
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig
    COMPONENT libraries)
endif ()

configure_file(${GDAL_CMAKE_TEMPLATE_PATH}/uninstall.cmake.in ${PROJECT_BINARY_DIR}/cmake_uninstall.cmake IMMEDIATE
               @ONLY)
add_custom_target(uninstall COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)

# Print summary
include(SystemSummary)
system_summary(DESCRIPTION "GDAL is now configured on;")

# Do not warn about Shapelib being an optional package not found, as we don't recommend using it. Same for external
# LERC. Mono/DotNetFrameworkSdk is also an internal detail of CSharp that we don't want to report
get_property(_packages_not_found GLOBAL PROPERTY PACKAGES_NOT_FOUND)
set(_new_packages_not_found)
foreach (_package IN LISTS _packages_not_found)
  if (NOT ${_package} STREQUAL "Shapelib"
      AND NOT ${_package} STREQUAL "LERC"
      AND NOT ${_package} STREQUAL "OpenCAD"
      AND NOT ${_package} STREQUAL "Podofo"
      AND NOT ${_package} STREQUAL "Mono"
      AND NOT ${_package} STREQUAL "DotNetFrameworkSdk")
    set(_new_packages_not_found ${_new_packages_not_found} "${_package}")
  endif ()
endforeach ()

include(FeatureSummary)
set_property(GLOBAL PROPERTY PACKAGES_NOT_FOUND ${_new_packages_not_found})
feature_summary(DESCRIPTION "Enabled drivers and features and found dependency packages" WHAT ALL)
set_property(GLOBAL PROPERTY PACKAGES_NOT_FOUND ${_packages_not_found})

set(_has_found_disabled_packages 0)
get_property(_packages_found GLOBAL PROPERTY PACKAGES_FOUND)
foreach (_package IN LISTS _packages_found)
  string(TOUPPER ${_package} key)
  if (DEFINED GDAL_USE_${key} AND NOT GDAL_USE_${key})
    if (NOT _has_found_disabled_packages)
      set(_has_found_disabled_packages 1)
      message("\nDisabled components:")
    endif ()
    message("* ${key} component has been detected, but is disabled with GDAL_USE_${key}=${GDAL_USE_${key}}")
  endif ()
endforeach ()
if (_has_found_disabled_packages)
  message("\n")
endif ()

if (NOT SILENCE_EXPERIMENTAL_WARNING)
  message(WARNING "CMake builds are considered only EXPERIMENTAL for now. Do not use them for production.")
endif ()

# vim: ts=4 sw=4 sts=4 et
