//
// Created by hui on 2024/12/2.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#include "video_render_processing.h"
#include "log.h"
#include "render/demo_render_manager.h"
#include <cassert>
#include <string>

VideoRenderProcessing::VideoRenderProcessing()
  : env_(nullptr), process_ref_(nullptr) {}

VideoRenderProcessing::~VideoRenderProcessing() {
  AV_INFO("VideoRenderProcessing DeConstruct...");
  napi_delete_reference(env_, process_ref_);
  process_ref_ = nullptr;
}

napi_value VideoRenderProcessing::GetRenderHandle(napi_env env, napi_callback_info info) {
  
  napi_value thisVar;
  size_t argc = 1;
  napi_value args[1];
  assert(napi_get_cb_info(env, info, &argc, args, &thisVar, nullptr) == napi_ok);
  
  size_t len;
  assert(napi_get_value_string_utf8(env, args[0], nullptr, 0, &len) == napi_ok);
  
  std::vector<char> buf(len + 1);
  assert(napi_get_value_string_utf8(env, args[0], buf.data(), len + 1, &len) == napi_ok);
  
  std::string xcomponmentId = std::string(buf.data());
  AV_INFO("xcomponmentId: %{public}s", xcomponmentId.c_str());
  
  auto handle = DemoRenderManager::SharedInstance()->GetRenderHandle(xcomponmentId);
  napi_value addr;
  assert(napi_create_bigint_uint64(env, handle, &addr) == napi_ok);
  return addr;
}

napi_value VideoRenderProcessing::ChangeCanvasStyle(napi_env env, napi_callback_info info) {
  
  napi_value thisVar;
  size_t argc = 3;
  napi_value args[3];
  assert(napi_get_cb_info(env, info, &argc, args, &thisVar, nullptr) == napi_ok);
  
  size_t len;
  assert(napi_get_value_string_utf8(env, args[0], nullptr, 0, &len) == napi_ok);
  
  std::vector<char> buf(len + 1);
  assert(napi_get_value_string_utf8(env, args[0], buf.data(), len + 1, &len) == napi_ok);
  
  std::string xcomponment_id = std::string(buf.data());
  AV_INFO("xcomponmentId: %{public}s", xcomponment_id.c_str());
  
  int32_t mirror;
  assert(napi_get_value_int32(env, args[1], &mirror) == napi_ok);
  
  int scale_mode;
  assert(napi_get_value_int32(env, args[2], &scale_mode) == napi_ok);
  
  DemoRenderManager::SharedInstance()->SetRenderStyle(xcomponment_id, mirror, scale_mode);
  AV_INFO("Set xcomponment id: %{public}s, mirror:%{public}d, scale_mode:%{public}d", xcomponment_id.c_str(), mirror, scale_mode);
  return thisVar;
}

napi_value VideoRenderProcessing::Construct(napi_env env, napi_callback_info info) {
  AV_INFO("VideoRenderProcessing Construct...");
  napi_value thisVar;
  assert(napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr) == napi_ok);
  
  VideoRenderProcessing *processing = new VideoRenderProcessing;
  processing->env_ = env;
  assert(napi_wrap(env, thisVar, (void*)processing, [](napi_env env, void* data, void* hint) {
    auto data_processing = (VideoRenderProcessing *)data;
    delete data_processing;
  }, nullptr, &processing->process_ref_) == napi_ok);
  return thisVar;
}

napi_value VideoRenderProcessing::Init(napi_env env, napi_value exports) {
  
  if (DemoRenderManager::SharedInstance()->Export(env, exports)) {
    AV_INFO("Export xComponent success.");
    return exports;
  }
  
  AV_INFO("Export xComponent failed.");
  napi_property_descriptor properties[] = {
    {"getRenderHandle", nullptr, GetRenderHandle, nullptr, nullptr, nullptr, napi_default, nullptr},
    {"changeCanvasStyle", nullptr, ChangeCanvasStyle, nullptr, nullptr, nullptr, napi_default, nullptr}
  };
  
  napi_value clazz;
  assert(napi_define_class(env, "VideoRenderProcessing", NAPI_AUTO_LENGTH, Construct, nullptr, sizeof(properties)/sizeof(properties[0]), properties, &clazz) == napi_ok);
  assert(napi_set_named_property(env, exports, "VideoRenderProcessing", clazz) == napi_ok);
  return exports;
}
