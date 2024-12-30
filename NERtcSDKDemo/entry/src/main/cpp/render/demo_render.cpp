//
// Created by hui on 2024/12/3.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#include "demo_render.h"
#include <cstdint>
#include <memory>
#include "log.h"
#include <array>

/**
 * Vertex shader.
 */
const char VERTEX_SHADER[] = "#version 300 es\n"
    "layout(location = 0) in vec4 a_position;\n"
    "layout(location = 1) in vec4 a_color;   \n"
    "out vec4 v_color;                       \n"
    "void main()                             \n"
    "{                                       \n"
    "   gl_Position = a_position;            \n"
    "   v_color = a_color;                   \n"
    "}                                       \n";

/**
 * Fragment shader.
 */
const char FRAGMENT_SHADER[] = "#version 300 es\n"
    "precision mediump float;                  \n"
    "in vec4 v_color;                          \n"
    "out vec4 fragColor;                       \n"
    "void main()                               \n"
    "{                                         \n"
    "   fragColor = v_color;                   \n"
    "}                                         \n";


/**
 * Fifty percent.
 */
const float FIFTY_PERCENT = 0.5;


/**
 * Egl red size default.
 */
const int EGL_RED_SIZE_DEFAULT = 8;

/**
 * Egl green size default.
 */
const int EGL_GREEN_SIZE_DEFAULT = 8;

/**
 * Egl blue size default.
 */
const int EGL_BLUE_SIZE_DEFAULT = 8;

/**
 * Egl alpha size default.
 */
const int EGL_ALPHA_SIZE_DEFAULT = 8;

/**
 * Default x position.
 */
const int DEFAULT_X_POSITION = 0;

/**
 * Default y position.
 */
const int DEFAULT_Y_POSITION = 0;

/**
 * Gl red default.
 */
const GLfloat GL_RED_DEFAULT = 0.0;

/**
 * Gl green default.
 */
const GLfloat GL_GREEN_DEFAULT = 0.0;

/**
 * Gl blue default.
 */
const GLfloat GL_BLUE_DEFAULT = 0.0;

/**
 * Gl alpha default.
 */
const GLfloat GL_ALPHA_DEFAULT = 1.0;

/**
 * Program error.
 */
const GLuint PROGRAM_ERROR = 0;

/**
 * Config attribute list.
 */
const EGLint ATTRIB_LIST[] = {
    // Key,value.
    EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
    EGL_RED_SIZE, EGL_RED_SIZE_DEFAULT,
    EGL_GREEN_SIZE, EGL_GREEN_SIZE_DEFAULT,
    EGL_BLUE_SIZE, EGL_BLUE_SIZE_DEFAULT,
    EGL_ALPHA_SIZE, EGL_ALPHA_SIZE_DEFAULT,
    EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
    // End.
    EGL_NONE
};
/**
 * Context attributes.
 */
const EGLint CONTEXT_ATTRIBS[] = {
    EGL_CONTEXT_CLIENT_VERSION, 2,
    EGL_NONE
};

#define RTC_PIXEL_FORMAT GL_LUMINANCE
#define SHADER_VERSION
#define VERTEX_SHADER_IN "attribute"
#define VERTEX_SHADER_OUT "varying"
#define FRAGMENT_SHADER_IN "varying"
#define FRAGMENT_SHADER_OUT
#define FRAGMENT_SHADER_COLOR "gl_FragColor"
#define FRAGMENT_SHADER_TEXTURE "texture2D"


static const int kYTextureUnit = 0;
static const int kUTextureUnit = 1;
static const int kVTextureUnit = 2;
static const int kUvTextureUnit = 1;


const char kRTCVertexShaderSource[] =
  SHADER_VERSION
  VERTEX_SHADER_IN " vec2 position;\n"
  VERTEX_SHADER_IN " vec2 texcoord;\n"
  VERTEX_SHADER_OUT " vec2 v_texcoord;\n"
  "void main() {\n"
  "    gl_Position = vec4(position.x, position.y, 0.0, 1.0);\n"
  "    v_texcoord = texcoord;\n"
  "}\n";

// Fragment shader converts YUV values from input textures into a final RGB
// pixel. The conversion formula is from http://www.fourcc.org/fccyvrgb.php.
static const char kI420FragmentShaderSource[] =
  SHADER_VERSION
  "precision highp float;"
  FRAGMENT_SHADER_IN " vec2 v_texcoord;\n"
  "uniform lowp sampler2D s_textureY;\n"
  "uniform lowp sampler2D s_textureU;\n"
  "uniform lowp sampler2D s_textureV;\n"
  FRAGMENT_SHADER_OUT
  "void main() {\n"
  "    float y, u, v, r, g, b;\n"
  "    y = " FRAGMENT_SHADER_TEXTURE "(s_textureY, v_texcoord).r;\n"
  "    u = " FRAGMENT_SHADER_TEXTURE "(s_textureU, v_texcoord).r;\n"
  "    v = " FRAGMENT_SHADER_TEXTURE "(s_textureV, v_texcoord).r;\n"
  "    u = u - 0.5;\n"
  "    v = v - 0.5;\n"
  "    r = y + 1.403 * v;\n"
  "    g = y - 0.344 * u - 0.714 * v;\n"
  "    b = y + 1.770 * u;\n"
  "    " FRAGMENT_SHADER_COLOR " = vec4(r, g, b, 1.0);\n"
  "  }\n";

bool RTCCreateVertexBuffer(GLuint *vertexBuffer, GLuint *vertexArray) {
  glGenBuffers(1, vertexBuffer);

  if (*vertexBuffer == 0) {
    glDeleteVertexArrays(1, vertexArray);
    return false;
  }

  glBindBuffer(GL_ARRAY_BUFFER, *vertexBuffer);

  glBufferData(GL_ARRAY_BUFFER, 4 * 4 * sizeof(GLfloat), NULL, GL_DYNAMIC_DRAW);

  return true;
}

GLuint RTCCreateProgram(GLuint vertexShader, GLuint fragmentShader) {
  if (vertexShader == 0 || fragmentShader == 0) {
    return 0;
  }
  GLuint program = glCreateProgram();
  if (!program) {
    return 0;
  }
  glAttachShader(program, vertexShader);
  glAttachShader(program, fragmentShader);
  glLinkProgram(program);
  GLint linkStatus = GL_FALSE;
  glGetProgramiv(program, GL_LINK_STATUS, &linkStatus);
  if (linkStatus == GL_FALSE) {
    glDeleteProgram(program);
    program = 0;
  }
  return program;
}

// Compiles a shader of the given |type| with GLSL source |source| and returns
// the shader handle or 0 on error.
GLuint RTCCreateShader(GLenum type, const GLchar *source) {
  GLuint shader = glCreateShader(type);
  if (!shader) {
    return 0;
  }
  glShaderSource(shader, 1, &source, nullptr);
  glCompileShader(shader);
  GLint compileStatus = GL_FALSE;
  glGetShaderiv(shader, GL_COMPILE_STATUS, &compileStatus);
  if (compileStatus == GL_FALSE) {
    GLint logLength = 0;
    // The null termination character is included in the returned log length.
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
      std::unique_ptr<char[]> compileLog(new char[logLength]);
      // The returned string is null terminated.
      glGetShaderInfoLog(shader, logLength, NULL, compileLog.get());
//      RTC_LOG(LS_ERROR) << "Shader compile error: " << compileLog.get();
    }
    glDeleteShader(shader);
    shader = 0;
  }
  return shader;
}

GLuint RTCCreateProgramFromFragmentSource(const char fragmentShaderSource[]) {
  GLuint vertexShader = RTCCreateShader(GL_VERTEX_SHADER, kRTCVertexShaderSource);
  GLuint fragmentShader =
      RTCCreateShader(GL_FRAGMENT_SHADER, fragmentShaderSource);

  GLuint program = RTCCreateProgram(vertexShader, fragmentShader);
  // Shaders are created only to generate program.
  if (vertexShader) {
    glDeleteShader(vertexShader);
  }
  if (fragmentShader) {
    glDeleteShader(fragmentShader);
  }

  // Set vertex shader variables 'position' and 'texcoord' in program.
  GLint position = glGetAttribLocation(program, "position");
  GLint texcoord = glGetAttribLocation(program, "texcoord");
  if (position < 0 || texcoord < 0) {
    glDeleteProgram(program);
    return 0;
  }

  // Read position attribute with size of 2 and stride of 4 beginning at the start of the array. The
  // last argument indicates offset of data within the vertex buffer.
  glVertexAttribPointer(position, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(GLfloat), (void *)0);
  glEnableVertexAttribArray(position);

  // Read texcoord attribute  with size of 2 and stride of 4 beginning at the first texcoord in the
  // array. The last argument indicates offset of data within the vertex buffer.
  glVertexAttribPointer(
      texcoord, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(GLfloat), (void *)(2 * sizeof(GLfloat)));
  glEnableVertexAttribArray(texcoord);

  return program;
}

bool DemoRender::createAndSetupI420Program() {
  
  _i420Program = RTCCreateProgramFromFragmentSource(kI420FragmentShaderSource);
  if (!_i420Program) {
    return false;
  }
  GLint ySampler = glGetUniformLocation(_i420Program, "s_textureY");
  GLint uSampler = glGetUniformLocation(_i420Program, "s_textureU");
  GLint vSampler = glGetUniformLocation(_i420Program, "s_textureV");

  if (ySampler < 0 || uSampler < 0 || vSampler < 0) {
    AV_ERROR("Failed to get uniform variable locations in I420 shader");
    glDeleteProgram(_i420Program);
    _i420Program = 0;
    return false;
  }

  glUseProgram(_i420Program);
  glUniform1i(ySampler, kYTextureUnit);
  glUniform1i(uSampler, kUTextureUnit);
  glUniform1i(vSampler, kVTextureUnit);
  
  return true;  
}

void DemoRender::setupTextures() {
  _textureSetUp = true;
  _hasUnpackRowLength = true;
  glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    
  _isDirty = true;

  glGenTextures(kNumTextures, _textures);
  // Set parameters for each of the textures we created.
  for (GLsizei i = 0; i < kNumTextures; i++) {
    glBindTexture(GL_TEXTURE_2D, _textures[i]);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  }
}

void DemoRender::uploadPlane(const uint8_t *plane,GLuint texture, size_t width, size_t height, int32_t stride) {

  glBindTexture(GL_TEXTURE_2D, texture);
  const uint8_t *uploadPlane = plane;
  if ((size_t)stride != width) {
   if (_hasUnpackRowLength) {
      // GLES3 allows us to specify stride.
      glPixelStorei(GL_UNPACK_ROW_LENGTH, stride);
      glTexImage2D(GL_TEXTURE_2D,
                   0,
                   RTC_PIXEL_FORMAT,
                   static_cast<GLsizei>(width),
                   static_cast<GLsizei>(height),
                   0,
                   RTC_PIXEL_FORMAT,
                   GL_UNSIGNED_BYTE,
                   uploadPlane);
      glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
      return;
    } else {
      // Make an unpadded copy and upload that instead. Quick profiling showed
      // that this is faster than uploading row by row using glTexSubImage2D.
      uint8_t *unpaddedPlane = _planeBuffer.data();
      for (size_t y = 0; y < height; ++y) {
        memcpy(unpaddedPlane + y * width, plane + y * stride, width);
      }
      uploadPlane = unpaddedPlane;
    }
  }
  glTexImage2D(GL_TEXTURE_2D,
               0,
               RTC_PIXEL_FORMAT,
               static_cast<GLsizei>(width),
               static_cast<GLsizei>(height),
               0,
               RTC_PIXEL_FORMAT,
               GL_UNSIGNED_BYTE,
               uploadPlane);
}

static inline std::array<GLfloat, 2> getVertexXY(int width, int height,
                                        int viewWidth, int viewHeight,
                                        RTCVideoRendererScaleMode scaleMode) {
  std::array<GLfloat, 2> ret = {1, 1};
  if (viewWidth == 0 || viewHeight == 0 || width == 0 || height == 0) {
    return ret;
  }

  GLfloat viewAspect = (GLfloat)viewWidth / (GLfloat)viewHeight;
  GLfloat contentAspect = (GLfloat)width / (GLfloat)height;

  switch (scaleMode) {
    case RTCVideoRendererScaleAspectFit: {
      if (viewAspect > contentAspect) {
          ret[0] = contentAspect / viewAspect;
      }
      else {
          ret[1] = viewAspect / contentAspect;
      }
    }
    break;
    //
    case RTCVideoRendererScaleAspectFill: {
      if (viewAspect > contentAspect) {
          ret[1] = viewAspect / contentAspect;
      }
      else {
          ret[0] = contentAspect / viewAspect;
      }
    }
    break;
    //
    case RTCVideoRendererScaleToFill:
    default:
    break;
  }

  return ret;
}

void RTCSetVertexDataEx(RTCVideoRotation rotation, int frameWidth, int frameHeight,
                        bool mirrored,
                        RTCVideoRendererScaleMode scaleMode, 
                        int renderViewWidth, int renderViewHeight) {
  std::array<std::array<GLfloat, 2>, 4> UVCoords = {{
      {{0, 1}},  // Lower left.
      {{1, 1}},  // Lower right.
      {{1, 0}},  // Upper right.
      {{0, 0}},  // Upper left.
  }};

  // Rotate the UV coordinates.
  int rotation_offset;
  switch (rotation) {
    case kVideoRotation_0:
      rotation_offset = 0;
      break;
    case kVideoRotation_90:
      rotation_offset = 1;
      break;
    case kVideoRotation_180:
      rotation_offset = 2;
      break;
    case kVideoRotation_270:
      rotation_offset = 3;
      break;
  }
  std::rotate(UVCoords.begin(), UVCoords.begin() + rotation_offset,
              UVCoords.end());

  std::array<GLfloat, 2> v = getVertexXY(frameWidth, frameHeight, renderViewWidth,renderViewHeight,scaleMode);
 if (mirrored) {
       const GLfloat gVertices[] = {
       // X, Y, U, V.
       -v[0], -v[1], UVCoords[1][0], UVCoords[1][1],
        v[0], -v[1], UVCoords[0][0], UVCoords[0][1],
        v[0],  v[1], UVCoords[3][0], UVCoords[3][1],
       -v[0],  v[1], UVCoords[2][0], UVCoords[2][1],
   };

   glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(gVertices), gVertices);
 }
 else {
  const GLfloat gVertices[] = {
  	// X, Y, U, V.
  	-v[0], -v[1], UVCoords[0][0], UVCoords[0][1],
  	v[0], -v[1], UVCoords[1][0], UVCoords[1][1],
  	v[0],  v[1], UVCoords[2][0], UVCoords[2][1],
  	-v[0],  v[1], UVCoords[3][0], UVCoords[3][1],
  };

  glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(gVertices), gVertices);
 }
}

bool DemoRender::prepareVertexBufferWithFrameSize(int width, int height, RTCVideoRotation rotation) {
  if (!_vertexBuffer && !RTCCreateVertexBuffer(&_vertexBuffer, &_vertexArray)) {
    AV_ERROR("Failed to setup vertex buffer");
    return false;
	}
	
  glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
	
	bool needRefreshVertex = false;
  if (frame_width_ != width || frame_height_ != height) {
    AV_INFO("will update frame size, old frame width : %{public}d, , old frame height: %{public}d, new frame width: %d, new frame height: %d", frame_width_, frame_height_, width, height);
    frame_width_ = width;
    frame_height_ = height;
    needRefreshVertex = true;
  }
  if (rotation != _currentRotation || _isDirty || needRefreshVertex) {
    _currentRotation = rotation;
    RTCSetVertexDataEx(_currentRotation, width, height, mirror_, scaleMode_, m_window_width, m_window_height);
    _isDirty = false;
  }
  return true;  
}

void DemoRender::applyShadingForFrameWithWidth(int width, int height, RTCVideoRotation rotation, GLuint yPlane, GLuint uPlane, GLuint vPlane) {
  bool landscape = rotation == kVideoRotation_90 || rotation == kVideoRotation_270;

  if (!prepareVertexBufferWithFrameSize(width, height, rotation)) {
    return;
  }

  if (!_i420Program && !createAndSetupI420Program()) {
    AV_ERROR("Failed to setup I420 program %u", glGetError());
    return;
  }

  glUseProgram(_i420Program);

  glActiveTexture(static_cast<GLenum>(GL_TEXTURE0 + kYTextureUnit));
  glBindTexture(GL_TEXTURE_2D, yPlane);

  glActiveTexture(static_cast<GLenum>(GL_TEXTURE0 + kUTextureUnit));
  glBindTexture(GL_TEXTURE_2D, uPlane);

  glActiveTexture(static_cast<GLenum>(GL_TEXTURE0 + kVTextureUnit));
  glBindTexture(GL_TEXTURE_2D, vPlane);

  glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
}

GLuint DemoRender::yTexture() {
  return _textures[_currentTextureSet * kNumTexturesPerSet];
}

GLuint DemoRender::uTexture() {
  return _textures[_currentTextureSet * kNumTexturesPerSet + 1];
}

GLuint DemoRender::vTexture() {
  return _textures[_currentTextureSet * kNumTexturesPerSet + 2];
}

bool DemoRender::FinishDraw()
{
  glFlush();
  glFinish();
  return eglSwapBuffers(m_eglDisplay, m_eglSurface);
}

DemoRender::DemoRender()
  : xcomponment_(nullptr), window_(nullptr), initial_(false), frame_sink_(nullptr) {
  AV_INFO("=== DemoRender constructor ===");
  if (pthread_rwlock_init(&lock_, 0) != 0) {
    AV_ERROR("rw lock init failed.");  
  }
}

DemoRender::~DemoRender() {
  AV_INFO("=== DemoRender Deconstructor ===");
  Clear();
  pthread_rwlock_destroy(&lock_);
}

bool DemoRender::IsValid() {
  pthread_rwlock_rdlock(&lock_);
  auto valid = xcomponment_ && window_ && m_window_width > 0 && m_window_height > 0;
  pthread_rwlock_unlock(&lock_);
  return valid;
}

void DemoRender::SetComponent(void *component) {
  pthread_rwlock_wrlock(&lock_);
  xcomponment_ = component;
  pthread_rwlock_unlock(&lock_);
}

void DemoRender::SetWindow(void* window) {
  pthread_rwlock_wrlock(&lock_);
  window_ = window;
  pthread_rwlock_unlock(&lock_);
}

void DemoRender::SetDupSink(IVideoRenderSink * sink) {
  pthread_rwlock_wrlock(&lock_);
  frame_sink_ = sink;
  pthread_rwlock_unlock(&lock_);
}

void DemoRender::Clear() {
  pthread_rwlock_wrlock(&lock_);
  xcomponment_ = nullptr;
  window_ = nullptr;
  initial_ = false;
  pthread_rwlock_unlock(&lock_);
}

//type => 0:I420
void DemoRender::onRenderData(uint64_t uid, void* data, uint32_t type, uint32_t width, uint32_t height, uint32_t count, uint32_t offset[4], uint32_t stride[4], uint32_t rotation, void* user_data) {
  
  pthread_rwlock_rdlock(&lock_);
  if (!window_ || !xcomponment_) {
    AV_ERROR("onRenderData not really");
    return ;
  }
  pthread_rwlock_unlock(&lock_);
  
  uint64_t canvas_width = 0, canvas_height = 0;
  OH_NativeXComponent *component = (OH_NativeXComponent *)xcomponment_;
  int32_t ret = OH_NativeXComponent_GetXComponentSize(component, window_, &canvas_width, &canvas_height);
  if (ret == OH_NATIVEXCOMPONENT_RESULT_SUCCESS) {
    setWindowSize(canvas_width, canvas_height);
  }
  
  if (!m_eglDisplay || !m_eglSurface || !m_eglContext) {
    AV_ERROR("onRenderData error, not initial.");
    return ;
  }
  
  if (!eglMakeCurrent(m_eglDisplay, m_eglSurface, m_eglSurface, m_eglContext)) {
    if (!_contextBinded) {
      AV_ERROR("onRenderData eglMakeCurrent failed.");
      return;
    }
  } else {
    _contextBinded = true;
  }
  
  if (!_textureSetUp) {
    setupTextures();
  }
  
  const int chroma_width = (width + 1) / 2;
  const int chroma_height = (height + 1) / 2;
  
  glViewport(DEFAULT_X_POSITION, DEFAULT_X_POSITION, m_window_width, m_window_height);
  glClearColor(GL_RED_DEFAULT, GL_GREEN_DEFAULT, GL_BLUE_DEFAULT, GL_ALPHA_DEFAULT);
  glClear(GL_COLOR_BUFFER_BIT);
  
  _currentTextureSet = (_currentTextureSet + 1) % kNumTextureSets;
  
  uploadPlane((uint8_t*)data, yTexture(), width, height, stride[0]);
  uploadPlane((uint8_t*)data + offset[1], uTexture(), chroma_width, chroma_height, stride[1]);
  uploadPlane((uint8_t*)data + offset[2], vTexture(), chroma_width, chroma_height, stride[2]);
  
  applyShadingForFrameWithWidth(width,height,(RTCVideoRotation)rotation,yTexture(),uTexture(),vTexture());
  FinishDraw();
  _contextBinded = false;
  
  if (frame_sink_ != nullptr) {
    frame_sink_->onRenderData(uid, data, type, width, height, count, offset, stride, rotation, user_data);
  }
}

void DemoRender::Release() {
  if((nullptr == m_eglDisplay) 
      || (!eglMakeCurrent(m_eglDisplay, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT))) {
    AV_ERROR("Unbind egl failed");
  }
  if ((nullptr == m_eglDisplay) 
      || (nullptr == m_eglSurface)
      || (!eglDestroySurface(m_eglDisplay, m_eglSurface))) {
    AV_ERROR("Release eglDestroySurface failed");
  }
  if ((nullptr == m_eglDisplay)
      || (nullptr == m_eglContext)
      || (!eglDestroyContext(m_eglDisplay, m_eglContext))) {
    AV_ERROR("Release eglDestroyContext failed");
  }
  if ((nullptr == m_eglDisplay)
      || (!eglTerminate(m_eglDisplay))) {
    AV_ERROR("Release eglTerminate failed");
  }
  m_eglContext = nullptr;  
}

bool DemoRender::InitEglEnv() {
  
  pthread_rwlock_wrlock(&lock_);
  if(initial_) {
    AV_ERROR("egl environment init already!");
    pthread_rwlock_unlock(&lock_);
    return false;
  }
  
  AV_INFO("Egl environment init.");
  if (!window_ || m_window_width <= 0 || m_window_height <= 0) {
    AV_ERROR("Init egl environment failed, params is invalid.");
    pthread_rwlock_unlock(&lock_);
    return false;
  }
  
  m_widthPercent = FIFTY_PERCENT * m_window_height / m_window_width;
  m_eglWindow = (EGLNativeWindowType)window_;
  m_eglDisplay = eglGetDisplay(EGL_DEFAULT_DISPLAY);
  if (m_eglDisplay == EGL_NO_DISPLAY) {
    AV_ERROR("unable to get egl display.");
    pthread_rwlock_unlock(&lock_);
    return false;
  }
  
  EGLint majorVersion;
  EGLint minorVersion;
  if (!eglInitialize(m_eglDisplay, &majorVersion, &minorVersion)) {
    AV_ERROR("eglInitialize: unable to get initialize EGL display");
    pthread_rwlock_unlock(&lock_);
    return false;
  } 
  
  const EGLint maxConfigSize = 1;
  EGLint numConfigs;
  if (!eglChooseConfig(m_eglDisplay, ATTRIB_LIST, &m_eglConfig, maxConfigSize, &numConfigs)) {
    AV_ERROR("eglChooseConfig: unable to choose configs");
    pthread_rwlock_unlock(&lock_);
    return false;
  }
  
  if (!m_eglWindow) {
    AV_ERROR("egl window is nullptr.");
    pthread_rwlock_unlock(&lock_);
    return false;
  }
  
  m_eglSurface = eglCreateWindowSurface(m_eglDisplay, m_eglConfig, m_eglWindow, nullptr);
  if (!m_eglSurface) {
    AV_ERROR("unable to create surface.");
    pthread_rwlock_unlock(&lock_);
    return false;
  }
  
  m_eglContext = eglCreateContext(m_eglDisplay, m_eglConfig, nullptr, CONTEXT_ATTRIBS);
  initial_ = true;
  pthread_rwlock_unlock(&lock_);
  return true;
}

void DemoRender::setWindowSize(int width, int height) {
  
  if (initial_ && width == m_window_width && height == m_window_height){
    return;
  }

  m_window_width = width;
  m_window_height = height;

  if (0 < m_window_width) {
    m_widthPercent = FIFTY_PERCENT * m_window_height / m_window_width;
  }
  _isDirty = true;
  
  if(IsValid()) 
    InitEglEnv();
}

void DemoRender::setMirror(bool mirror) {
  mirror_ = mirror;
  _isDirty = true;  
}

void DemoRender::setScaleMode(RTCVideoRendererScaleMode mode) {
  if (mode == scaleMode_) {
      return;
  }
  scaleMode_ = mode;
  _isDirty = true;  
}


