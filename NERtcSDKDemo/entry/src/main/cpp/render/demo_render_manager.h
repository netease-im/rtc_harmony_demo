//
// Created by hui on 2024/12/3.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef HARMONY_DEMO_RENDER_MANAGER_H
#define HARMONY_DEMO_RENDER_MANAGER_H

#include "render/demo_render.h"
#include <js_native_api.h>
#include <js_native_api_types.h>
#include <unordered_map>
#include <ace/xcomponent/native_interface_xcomponent.h>
#include <string>

class DemoRenderManager {
  
  public:
    static DemoRenderManager* SharedInstance();
    static void DestroyInstance();
    bool Export(napi_env env, napi_value exports);
    void SetWindow(std::string& id, void* window);
    void DestroyRender(std::string &id);
    uint64_t GetRenderHandle(std::string& xcomponment_id);
    void SetRenderStyle(std::string& xcomponent_id, int mirror, int scale_mode);

  private:
    DemoRenderManager() = default;
    ~DemoRenderManager() = default;
    void SetNativeXComponent(std::string& id, OH_NativeXComponent* native_x_component);
    void HandleDupSink(std::string& id);

  private:
    static OH_NativeXComponent_Callback xcomponent_callback;
    std::unordered_map<std::string, DemoRender> render_maps_;
};

#endif //HARMONY_DEMO_RENDER_MANAGER_H
