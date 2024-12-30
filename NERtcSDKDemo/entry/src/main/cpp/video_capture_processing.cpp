//
// Created by hui on 2024/11/20.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#include "video_capture_processing.h"
#include <cassert>
#include <cstdint>
#include "log.h"

VideoCaptureProcessing::VideoCaptureProcessing() 
  : env_(nullptr), process_ref_(nullptr), capture_dump_(nullptr) {}

VideoCaptureProcessing::~VideoCaptureProcessing() {
  AV_INFO("DataProcessing DeConstruct...");
  napi_delete_reference(env_, process_ref_);
  fclose(capture_dump_);
  capture_dump_ = nullptr;
}

napi_value VideoCaptureProcessing::Construct(napi_env env, napi_callback_info info) {
  AV_INFO("DataProcessing Construct ...");
  napi_value thisVar;
  assert(napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr) == napi_ok);
  
  VideoCaptureProcessing *process = new VideoCaptureProcessing();
  process->env_ = env;
  assert(napi_wrap(env, thisVar, (void*)process, [](napi_env env, void* data, void* hint) {
    auto data_processing = (VideoCaptureProcessing *)data;
    delete data_processing;
  }, nullptr, &process->process_ref_) == napi_ok);
  return thisVar;
}

napi_value VideoCaptureProcessing::GetVideoCaptureHandle(napi_env env, napi_callback_info info) {
  
  napi_value thisVar;
  assert(napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr) == napi_ok);
  
  VideoCaptureProcessing *process;
  assert(napi_unwrap(env, thisVar, reinterpret_cast<void **>(&process)) == napi_ok);  
  AV_INFO("GetVideoCaptureHandle addr: %{public}p", process);
  
  napi_value handle;
  bool loss;
  assert(napi_create_bigint_uint64(env, (uint64_t)process, &handle) == napi_ok);
  
  if(loss) AV_ERROR("convert uint64 ptr loss!");
  return handle;
}

napi_value VideoCaptureProcessing::SetFilePath(napi_env env, napi_callback_info info) {
  
  napi_value thisVar;
  size_t argc = 1;
  napi_value args[1];
  assert(napi_get_cb_info(env, info, &argc, args, &thisVar, nullptr) == napi_ok);
  
  size_t len;
  assert(napi_get_value_string_utf8(env, args[0], nullptr, 0, &len) == napi_ok);
  
  std::vector<char> buf(len + 1);
  assert(napi_get_value_string_utf8(env, args[0], buf.data(), len + 1, &len) == napi_ok);
  
  std::string file_path = std::string(buf.data());
  AV_INFO("file_path: %{public}s", file_path.c_str());
  
  VideoCaptureProcessing *process;
  assert(napi_unwrap(env, thisVar, reinterpret_cast<void **>(&process)) == napi_ok);
  
  process->file_path_ = file_path;
  return thisVar;
}

/**
 * 注意：原始视频数据很大，点击界面的开启视频回调时间不能过长。
 * 
 * @param data 原始视频帧数据
 * @param color_format 色彩格式，一般返回0 即 I420
 *        0: I420, 1: NV12, 2: NV21, 3: BGRA, 4: RBGA, 5: CVPixelBuffer(iOS格式), 6: ARGB 
 * @param width 视频宽
 * @param height 视频高
 * @param count plane_count，平面数量，yuv:3
 * @param offset 偏移
 * @param stride 步长
 * @param rotation 角度，harmony 采集出来的原始画面角度为: 270
 */
void VideoCaptureProcessing::onCaptureFrame(void* data, int32_t color_format, uint32_t width, uint32_t height, 
  uint32_t count, int64_t offset[4], uint32_t stride[4], uint16_t rotation) {
  AV_INFO("onFrame :: color_format: %{public}d, width:%{public}d, height:%{public}d, count:%{public}d, rotation:%{public}d", color_format, width, height, count, rotation);
  
  if(!capture_dump_) {
      time_t now = std::time(nullptr);
      std::string dump_path = file_path_ + "/" + std::to_string(width) + "_" + std::to_string(height) + "_" + std::to_string(now) + "_cpp.yuv";
      capture_dump_ = fopen(dump_path.c_str(), "wb");
  }
  
  if(capture_dump_) {
    size_t len = width * height * 1.5;
    auto write_len = fwrite(data, 1, len, capture_dump_);
    AV_INFO("write into file size:%{public}ld", write_len);
  }
}

napi_value VideoCaptureProcessing::Init(napi_env env, napi_value exports) {
  napi_property_descriptor properties[] = {
    {"setFilePath", nullptr, SetFilePath, nullptr, nullptr, nullptr, napi_default, nullptr},
    {"getNativeHandle", nullptr, GetVideoCaptureHandle, nullptr, nullptr, nullptr, napi_default, nullptr}
  };
  
  napi_value clazz;
  assert(napi_define_class(env, "VideoCaptureProcessing", NAPI_AUTO_LENGTH, Construct, nullptr, sizeof(properties)/sizeof(properties[0]), properties, &clazz) == napi_ok);
  assert(napi_set_named_property(env, exports, "VideoCaptureProcessing", clazz) == napi_ok);
  return exports;
}
