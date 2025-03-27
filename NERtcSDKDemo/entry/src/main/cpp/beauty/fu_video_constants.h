//
// Created on 2025/2/14.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef HARMONY_FU_VIDEO_CONFIG_H
#define HARMONY_FU_VIDEO_CONFIG_H


/**
 * Config attribute list.
 */
#include <EGL/egl.h>
#include <EGL/eglplatform.h>


const int EGL_RED_SIZE_DEFAULT = 8;
const int EGL_GREEN_SIZE_DEFAULT = 8;
const int EGL_BLUE_SIZE_DEFAULT = 8;
const int EGL_ALPHA_SIZE_DEFAULT = 8;

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

const char* AI_FACE_PROCESSOR = "ai_face_processor.bundle";
const char* AI_HUMAN_PROCESSOR = "ai_human_processor.bundle";
const char* AI_FACE_BEAUTIFICATION = "face_beautification.bundle";
const int FACE_BEAUTY_INDEX = 0;

const int VIDEO_FU_MAX_FACES = 4;
#endif //HARMONY_FU_VIDEO_CONFIG_H
