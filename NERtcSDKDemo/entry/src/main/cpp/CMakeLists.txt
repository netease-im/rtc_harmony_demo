cmake_minimum_required(VERSION 3.4.1)
project(dataProcessing)

# so 和 .h 在模块层级的 oh_modules 和 项目级别的 oh_modules 下找找，不同版本 ide 生成的路径可能不一样 。
#include_directories(${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/../../../oh_modules/@nertc/nertc_sdk/oh_modules/wrapper/include)
#set(NERTC_LIB_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../../../oh_modules/@nertc/nertc_sdk/oh_modules/wrapper/libs)

include_directories(${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/../../../../oh_modules/.ohpm/@nertc+nertc_sdk@5.8.5/oh_modules/wrapper/include)
set(NERTC_LIB_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../../../../oh_modules/.ohpm/@nertc+nertc_sdk@5.8.5/oh_modules/wrapper/libs)

add_library(nertc_sdk SHARED IMPORTED)
set_target_properties(nertc_sdk PROPERTIES IMPORTED_LOCATION ${NERTC_LIB_PATH}/${CMAKE_OHOS_ARCH_ABI}/libnertc_sdk.so)

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