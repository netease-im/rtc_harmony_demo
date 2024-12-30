//
// Created by hui on 2024/12/2.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef HARMONY_VIDEO_RENDER_PROCESSING_H
#define HARMONY_VIDEO_RENDER_PROCESSING_H

#include "napi/native_api.h"
#include <vector>

class VideoRenderProcessing {
  
  public:
    VideoRenderProcessing();
    ~VideoRenderProcessing();
  
  public:
    static napi_value Init(napi_env env, napi_value exports);
  
  private:
    static napi_value Construct(napi_env env, napi_callback_info);
    static napi_value GetRenderHandle(napi_env env, napi_callback_info info);
    static napi_value ChangeCanvasStyle(napi_env env, napi_callback_info info);
  
  private:
    napi_ref process_ref_;
    napi_env env_;
    std::vector<std::string> attach_user_;
};

#endif //HARMONY_VIDEO_RENDER_PROCESSING_H
