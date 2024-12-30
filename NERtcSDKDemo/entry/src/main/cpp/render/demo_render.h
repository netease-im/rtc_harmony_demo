//
// Created by hui on 2024/12/3.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef HARMONY_DEMO_RENDER_H
#define HARMONY_DEMO_RENDER_H

#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <EGL/eglplatform.h>
#include <GLES3/gl3.h>
#include <vector>
#include <optional>
#include "pthread.h"
#include "INERtcEngine.h"
#include <ace/xcomponent/native_interface_xcomponent.h>

static const GLsizei kNumTextureSets = 2;
static const GLsizei kNumTexturesPerSet = 3;
static const GLsizei kNumTextures = kNumTexturesPerSet * kNumTextureSets;

enum RTCVideoRotation {
    kVideoRotation_0 = 0,
    kVideoRotation_90 = 90,
    kVideoRotation_180 = 180,
    kVideoRotation_270 = 270,
};

enum RTCVideoRendererScaleMode: int32_t{
	RTCVideoRendererScaleAspectFit = 0 ,
	RTCVideoRendererScaleToFill,
	RTCVideoRendererScaleAspectFill,
};

using namespace nertc_sdk;

class DemoRender : public IVideoRenderSink {
  
  public:
    DemoRender();
    ~DemoRender();
    void SetComponent(void *component);
    void SetWindow(void* window);
    void setWindowSize(int width, int height);
    void setMirror(bool mirror);
    void setScaleMode(RTCVideoRendererScaleMode mode);
    void Clear();
    void Release();
    void onRenderData(uint64_t uid, void* data, uint32_t type, uint32_t width, uint32_t height, uint32_t count, uint32_t offset[4], uint32_t stride[4], uint32_t rotation, void* user_data);
    void SetDupSink(IVideoRenderSink * sink);
  
  private:
    bool InitEglEnv();
    bool IsValid();
    bool createAndSetupI420Program();
    void setupTextures();
    void uploadPlane(const uint8_t *plane,GLuint texture, size_t width, size_t height, int32_t stride);
    void applyShadingForFrameWithWidth(int width, int height, RTCVideoRotation rotation, GLuint yPlane, GLuint uPlane, GLuint vPlane);
    bool prepareVertexBufferWithFrameSize(int width, int height, RTCVideoRotation rotation);
    GLuint yTexture();
    GLuint uTexture();
    GLuint vTexture();
    bool FinishDraw();

  private:
    GLuint _i420Program = 0;
    bool _textureSetUp = false;
    bool _hasUnpackRowLength = false;
    bool _isDirty = false;
    bool _contextBinded = false;
    GLuint _textures[kNumTextures] = {0};
    std::vector<uint8_t> _planeBuffer;
    GLuint _vertexBuffer = 0;
    GLuint _vertexArray = 0;
    int frame_width_ = 0;
    int frame_height_ = 0;
    int m_window_width = 0;
    int m_window_height = 0;
    GLfloat m_widthPercent;  
    RTCVideoRendererScaleMode scaleMode_ = RTCVideoRendererScaleAspectFit;
    bool mirror_ = false;
    RTCVideoRotation _currentRotation;
    GLint _currentTextureSet = 0;
    EGLNativeWindowType m_eglWindow;
    EGLConfig m_eglConfig = EGL_NO_CONFIG_KHR;
    EGLDisplay m_eglDisplay = EGL_NO_DISPLAY;
    EGLSurface m_eglSurface = EGL_NO_SURFACE;
    EGLContext m_eglContext = EGL_NO_CONTEXT;

  private:
    void* xcomponment_; //xcomponment
    void* window_;
    pthread_rwlock_t lock_;
    bool initial_;
    IVideoRenderSink* frame_sink_;
};

#endif //HARMONY_DEMO_RENDER_H
