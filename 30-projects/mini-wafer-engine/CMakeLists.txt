cmake_minimum_required(VERSION 4.3)

project(mini_wafer_engine LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(mini_wafer_engine cpp/main.cpp)
