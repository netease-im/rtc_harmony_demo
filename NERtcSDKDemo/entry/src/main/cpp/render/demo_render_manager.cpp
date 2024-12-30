//
// Created by hui on 2024/12/3.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#include "demo_render_manager.h"
#include "log.h"
#include "render/demo_render.h"
#include <cstdint>

OH_NativeXComponent_Callback DemoRenderManager::xcomponent_callback;
static DemoRenderManager* g_render_manager = nullptr;

void onSurfaceCreatedCB(OH_NativeXComponent* component, void* window) {
  
  AV_INFO("component %{public}p, onSurfaceCreateCB", component);
  if (!component || !window) {
    AV_ERROR("onSurfaceCreatedCB component or window is nullptr.");
    return;
  }

  char id_str[OH_XCOMPONENT_ID_LEN_MAX] = {};
  uint64_t id_len = OH_XCOMPONENT_ID_LEN_MAX;
  if (OH_NativeXComponent_GetXComponentId(component, id_str, &id_len) != OH_NATIVEXCOMPONENT_RESULT_SUCCESS) {
    AV_ERROR("onSurfaceCreatedCB get xcomponent id error.");
    return;
  }

  std::string id(id_str);
  AV_INFO("onSurfaceCreatedCB get xcomponent id :%{public}s", id_str);
  DemoRenderManager::SharedInstance()->SetWindow(id, window);
}

void onSurfaceChangedCB(OH_NativeXComponent* component, void* window) {
  (void)window;
  AV_INFO("component %{public}p, onSurfaceChangedCB", component);
}

void onSurfaceDispatchTouchEventCB(OH_NativeXComponent* component, void* window) {
  (void)component;
  (void)window;
}

void onSurfaceDestroyedCB(OH_NativeXComponent *component, void *window) {
  AV_INFO("component %{public}p, onSurfaceDestroyedCB", component);
  if (!component || !window) {
    AV_ERROR("component or window is null.");
    return;
  }
  
  char id_str[OH_XCOMPONENT_ID_LEN_MAX] = {};
  uint64_t id_len = OH_XCOMPONENT_ID_LEN_MAX;
  if (OH_NativeXComponent_GetXComponentId(component, id_str, &id_len) != OH_NATIVEXCOMPONENT_RESULT_SUCCESS) {
    AV_ERROR("onSurfaceDestroyedCB, get xcomponent id failed.");
    return;
  }
  
  std::string id(id_str);
  DemoRenderManager::SharedInstance()->DestroyRender(id);
}

void DemoRenderManager::SetNativeXComponent(std::string& id, OH_NativeXComponent* native_x_component) {
  
  if (!native_x_component) {
    AV_ERROR("xcomponent is nullptr.");
    return;
  }
  
  if (render_maps_.find(id) == render_maps_.end()) {
    DemoRender demo_render;
    demo_render.SetComponent(native_x_component);
    render_maps_[id] = demo_render;
    return;
  }
  render_maps_[id].SetComponent(native_x_component);
}

void DemoRenderManager::SetWindow(std::string& id, void* window) {
  
  if (!window) {
    AV_ERROR("window is nullptr");
    return;
  }
  
  if (render_maps_.find(id) == render_maps_.end()) {
    DemoRender demo_render;
    demo_render.SetWindow(window);
    render_maps_[id] = demo_render;
    return;
  }
  render_maps_[id].SetWindow(window);
  HandleDupSink(id);
}

void DemoRenderManager::HandleDupSink(std::string& id) {
  if (id.compare(0, 3, "dup") == 0) {
    std::string dest_id = id.substr(4);
    AV_INFO("dest_id: %{public}s", dest_id.c_str());
    if (render_maps_.find(id) != render_maps_.end()) {
      render_maps_[dest_id].SetDupSink(&render_maps_[id]);
    }
  } else {
    std::string sink_id = "dup_" + id;
    AV_INFO("sink_id: %{public}s", sink_id.c_str());
    if (render_maps_.find(sink_id) != render_maps_.end()) {
      render_maps_[id].SetDupSink(&render_maps_[sink_id]);
    }
  }
}

DemoRenderManager* DemoRenderManager::SharedInstance() {
  if (!g_render_manager) {
    g_render_manager = new DemoRenderManager();
  }
  return g_render_manager;
}

void DemoRenderManager::DestroyInstance() {
  delete std::exchange(g_render_manager, nullptr);
}

void DemoRenderManager::DestroyRender(std::string &id) {
  if (render_maps_.find(id) == render_maps_.end()) {
    return;
  }
  
  render_maps_[id].Clear();
  render_maps_.erase(render_maps_.find(id)); //may be cause nullptr, So need set external canvas null in demo.
}

uint64_t DemoRenderManager::GetRenderHandle(std::string& xcomponment_id) {
  if (render_maps_.find(xcomponment_id) != render_maps_.end()) {
    return (uint64_t)(&render_maps_[xcomponment_id]);
  }
  return NULL;
}

void DemoRenderManager::SetRenderStyle(std::string& xcomponment_id, int mirror, int scale_mode) {
  if (render_maps_.find(xcomponment_id) != render_maps_.end()) {
    if (mirror != -1) {
      render_maps_[xcomponment_id].setMirror(mirror);
    }
    render_maps_[xcomponment_id].setScaleMode(static_cast<RTCVideoRendererScaleMode>(scale_mode));
  } else {
    AV_ERROR("SetRenderStyle failed, can't find render.'");
  }
}

bool DemoRenderManager::Export(napi_env env, napi_value exports) {
  
  napi_value export_instance = nullptr;
  if(napi_get_named_property(env, exports, OH_NATIVE_XCOMPONENT_OBJ, &export_instance) != napi_ok) {
    AV_INFO("render manager export failed, event: get xcomponent obj.");
    return false;
  }
  
  OH_NativeXComponent *native_x_component = nullptr;
  if(napi_unwrap(env, export_instance, reinterpret_cast<void **>(&native_x_component)) != napi_ok) {
    AV_INFO("render manager export failed, event: unwrap.");
    return false;
  }
  
  char id_str[OH_XCOMPONENT_ID_LEN_MAX] = {};
  uint64_t id_len = OH_XCOMPONENT_ID_LEN_MAX;
  if(OH_NativeXComponent_GetXComponentId(native_x_component, id_str, &id_len) != OH_NATIVEXCOMPONENT_RESULT_SUCCESS) {
    AV_INFO("render manager export failed, event: get xcomponent id.");
    return false;
  }
  
  std::string id(id_str);
  if(native_x_component) {
    OH_NativeXComponent_Callback *render_callback = &DemoRenderManager::xcomponent_callback;
    render_callback->OnSurfaceCreated = onSurfaceCreatedCB;
    render_callback->OnSurfaceChanged = onSurfaceChangedCB;
    render_callback->OnSurfaceDestroyed = onSurfaceDestroyedCB;
    render_callback->DispatchTouchEvent = onSurfaceDispatchTouchEventCB;
    SetNativeXComponent(id, native_x_component);
    OH_NativeXComponent_RegisterCallback(native_x_component, &DemoRenderManager::xcomponent_callback);
  }
  return true;
}
