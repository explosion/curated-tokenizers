set(SPM_ENABLE_SHARED OFF CACHE BOOL "Build sentencepiece shared libraries" FORCE)

add_subdirectory(../sentencepiece ${CMAKE_BINARY_DIR}/sentencepiece)
set_property(TARGET sentencepiece-static PROPERTY FOLDER "dependencies")
link_directories(${CMAKE_BINARY_DIR}/sentencepiece/lib)

add_cython_target(sp CXX)
add_library(sp MODULE ${sp})
add_dependencies(sp sentencepiece)
python_extension_module(sp)

install(TARGETS sp LIBRARY DESTINATION cysp)