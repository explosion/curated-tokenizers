cmake_minimum_required(VERSION 3.11.0)
project(thinc_sleef_ops)

set (CMAKE_CXX_STANDARD 14)

find_package(PythonExtensions REQUIRED)
find_package(Cython REQUIRED)
find_package(NumPy REQUIRED)

cmake_policy(SET CMP0069 NEW)
set(CMAKE_POLICY_DEFAULT_CMP0069 NEW)

add_subdirectory(cysp)