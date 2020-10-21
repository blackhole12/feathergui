// Copyright (c)2020 Fundament Software
// For conditions of distribution and use, see copyright notice in "fgOpenGL.h"

#ifndef GL__LAYER_H
#define GL__LAYER_H

#include "backend.h"

namespace GL {
  struct Context;

  struct Layer : FG_Asset
  {
    Layer(FG_Vec s, Context* c);
    ~Layer();
    // Moves the texture to another window if necessary
    bool Update(float* tf, float o, FG_BlendState* blend, Context* context);
    void Destroy();
    bool Create();

    unsigned int framebuffer;
    float transform[16];
    float opacity;
    Context* context;
    bool initialized;
    FG_BlendState blend;
  };
}

#endif