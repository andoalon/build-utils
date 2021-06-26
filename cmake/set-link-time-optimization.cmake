cmake_minimum_required(VERSION 3.13)
include_guard()

include(CheckIPOSupported)
check_ipo_supported(RESULT ipo_supported OUTPUT check_ipo_supported_output LANGUAGES CXX)

if(ipo_supported)
    set(CMAKE_INTERPROCEDURAL_OPTIMIZATION_RELEASE TRUE)
else()
    message(WARNING "Link time optimization is not supported: ${check_ipo_supported_output}")
endif()

unset(ipo_supported)
