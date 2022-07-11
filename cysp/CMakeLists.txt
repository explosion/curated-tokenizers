set(SPM_ENABLE_SHARED OFF CACHE BOOL "Build sentencepiece shared libraries" FORCE)

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/../sentencepiece/src
    ${CMAKE_BINARY_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/../sentencepiece/third_party/protobuf-lite)

add_subdirectory(../sentencepiece ${CMAKE_BINARY_DIR}/sentencepiece)
set_property(TARGET sentencepiece-static PROPERTY FOLDER "dependencies")
link_directories(${CMAKE_BINARY_DIR}/sentencepiece/src)

add_cython_target(sp CXX)
add_library(sp MODULE ${sp})
add_dependencies(sp sentencepiece-static)
target_include_directories(sp PRIVATE ${NumPy_INCLUDE_DIRS})
target_link_libraries(sp sentencepiece-static)
python_extension_module(sp)

install(TARGETS sp LIBRARY DESTINATION cysp)