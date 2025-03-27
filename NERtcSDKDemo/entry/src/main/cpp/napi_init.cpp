//
// Created by hui on 2024/11/20.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".
#include "beauty/video_fu_render.h"
#include "video_capture_processing.h"
#include "video_render_processing.h"
#include "napi/native_api.h"

napi_value Init(napi_env env, napi_value exports) {
  VideoCaptureProcessing::Init(env, exports);
  VideoRenderProcessing::Init(env, exports);
  VideoFuRender::Init(env, exports);
  return exports;
}

static napi_module demoModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "dataprocessing",
    .nm_priv = ((void *)0),
    .reserved = {0},
};

extern "C" __attribute__((constructor)) void RegisterEntryModule(void) { napi_module_register(&demoModule); }
