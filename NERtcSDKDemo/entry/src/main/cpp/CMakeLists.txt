cmake_minimum_required(VERSION 3.4.1)
project(dataProcessing)

set(FIND_WRAPPER ${CMAKE_CURRENT_SOURCE_DIR}/../../../find_dir.sh)

execute_process(
    COMMAND chmod +x ${FIND_WRAPPER}
    RESULT_VARIABLE CHMOD_RESULT
    ERROR_VARIABLE CHMOD_ERROR
)

execute_process(
    COMMAND ${SHELL} ${FIND_WRAPPER}
    RESULT_VARIABLE result
    OUTPUT_VARIABLE output
    ERROR_VARIABLE error
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

if(NOT result EQUAL 0)
    message(FATAL_ERROR "Command failed: ${error}")
else()
    message(WARNING "Command output: ${output}")
endif()

set(WRAPPER_PATH ${output})

include_directories(${CMAKE_CURRENT_SOURCE_DIR} ${WRAPPER_PATH}/include)
set(NERTC_LIB_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../../../../oh_modules/.ohpm/@nertc+nertc_sdk@5.8.5/oh_modules/wrapper/libs)

add_library(nertc_sdk SHARED IMPORTED)
set_target_properties(nertc_sdk PROPERTIES IMPORTED_LOCATION ${WRAPPER_PATH}/libs/${CMAKE_OHOS_ARCH_ABI}/libnertc_sdk.so)

add_library(FUAI SHARED IMPORTED)
set_target_properties(FUAI PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/beauty/lib/${CMAKE_OHOS_ARCH_ABI}/libfuai.so)

add_library(CNameSDK SHARED IMPORTED)
set_target_properties(CNameSDK PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/beauty/lib/${CMAKE_OHOS_ARCH_ABI}/libCNamaSDK.so)

file(GLOB RENDERS "${CMAKE_SOURCE_DIR}/render/*.cpp")
file(GLOB BEAUTY "${CMAKE_SOURCE_DIR}/beauty/*.cpp")

set(ALL_SOURCES ${RENDERS})
list(APPEND ALL_SOURCES ${BEAUTY})

add_library(dataprocessing SHARED napi_init.cpp video_capture_processing.cpp video_render_processing.cpp ${ALL_SOURCES})

target_link_libraries(dataprocessing PUBLIC nertc_sdk FUAI CNameSDK libace_ndk.z.so libace_napi.z.so libhilog_ndk.z.so EGL GLESv3)