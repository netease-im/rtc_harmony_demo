//
// Created by hui on 2024/11/20.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef HARMONY_DATA_PROCESSING_H
#define HARMONY_DATA_PROCESSING_H

#include "napi/native_api.h"
#include "INERtcEngine.h"
#include <cstdint>
#include <string>

using namespace nertc_sdk;

/**
 * 视频前处理前回调 (Camera 原始采集数据)
 */
class VideoCaptureProcessing : public IVideoFrameObserver {
  
  public:
    VideoCaptureProcessing();
    ~VideoCaptureProcessing();
    static napi_value Init(napi_env env, napi_value exports);
  
  public:
    void onCaptureFrame(void* data, int32_t color_format, uint32_t width, uint32_t height, 
      uint32_t count, int64_t offset[4], uint32_t stride[4], uint16_t rotation) override ;
    static napi_value Construct(napi_env env, napi_callback_info info);
    static napi_value GetVideoCaptureHandle(napi_env env, napi_callback_info info);
    static napi_value SetFilePath(napi_env env, napi_callback_info info);
  
  private:
    napi_ref process_ref_;
    napi_env env_;
    std::string file_path_;
    FILE *capture_dump_;
};

#endif //HARMONY_DATA_PROCESSING_H
