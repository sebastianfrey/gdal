add_gdal_driver(TARGET ogr_SVG SOURCES ogr_svg.h ogrsvgdatasource.cpp ogrsvgdriver.cpp ogrsvglayer.cpp PLUGIN_CAPABLE
                                       NO_DEPS)
gdal_standard_includes(ogr_SVG)
if (GDAL_USE_EXPAT)
  target_compile_definitions(ogr_SVG PRIVATE -DHAVE_EXPAT=1)
  gdal_target_link_libraries(TARGET ogr_SVG LIBRARIES EXPAT::EXPAT)
endif ()
