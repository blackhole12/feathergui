// Copyright (c)2022 Fundament Software
// For conditions of distribution and use, see copyright notice in "BackendGL.hpp"

#include "BackendGL.hpp"
#include "FrameBuffer.hpp"
#include <cassert>
#include <cmath>


using namespace GL;


GLExpected<void> FrameBuffer::bind(GLenum target) const noexcept
{
  glBindFramebuffer(target, _ref);
  GL_ERROR("glBindFramebuffer");
  return {};
}

GLExpected<FrameBuffer> FrameBuffer::create(GLenum target, GLenum type, int level, int zoffset, std::vector<GLuint>& textures) noexcept
{
  // TODO: Default to GL_DRAW_FRAMEBUFFER?
  assert(glFramebufferTexture2D != nullptr);

  GLuint fbgl;
  glGenFramebuffers(1, &fbgl);
  GL_ERROR("glGenFramebuffers");
  FrameBuffer fb(fbgl);

  if(auto e = fb.attach(target, type, level, zoffset, textures)) {}
  else
    return std::move(e.error());


  /* GLuint rbo;
  glGenRenderbuffers(1, &rbo);
  glBindRenderbuffer(GL_RENDERBUFFER, rbo);
  glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, 800, 600);
  glBindRenderbuffer(GL_RENDERBUFFER, 0); */
  glBindFramebuffer(GL_FRAMEBUFFER, 0);
  return fb;
}

GLExpected<void> FrameBuffer::attach(GLenum target, GLenum type, int level, int zoffset, std::vector<GLuint>& textures) noexcept
{
  if(auto e = this->bind(target))
  {
    int MaxRendertargets;
    glGetIntegerv(GL_MAX_COLOR_ATTACHMENTS, &MaxRendertargets);
    GL_ERROR("glGetIntergerv");
    if((this->NumberOfColorAttachments + textures.size()) > MaxRendertargets)
    {
      return CUSTOM_ERROR(ERR_INVALID_PARAMETER, "Trying to bind more render targets than max possible");
    }
    for(const GLuint& texture : textures)
    {
      switch(type)
      {
      case GL_TEXTURE_1D:
        glFramebufferTexture1D(target, GL_COLOR_ATTACHMENT0 + this->NumberOfColorAttachments, GL_TEXTURE_1D,
                               texture, level);
        break;
      case GL_TEXTURE_3D:
        glFramebufferTexture3D(target, GL_COLOR_ATTACHMENT0 + this->NumberOfColorAttachments, GL_TEXTURE_3D,
                               texture, level, zoffset);
        break;
      default:
        glFramebufferTexture(target, GL_COLOR_ATTACHMENT0 + this->NumberOfColorAttachments, texture, level);
        break; 
         //glFramebufferTexture2D(target, this->NumberOfColorAttachments, GL_TEXTURE_2D, texture, level); 
        //break; GL_COLOR_ATTACHMENT0
      }
      this->NumberOfColorAttachments++;
      GL_ERROR("glFramebufferTexture");
    }

    auto status = glCheckFramebufferStatus(target);
    if(status != GL_FRAMEBUFFER_COMPLETE)
    {
      return CUSTOM_ERROR(status, "glCheckFramebufferStatus");
    }
    //glClearColor(0.1f, 0.1f, 0.1f, 1.0f);
    //glClear(GL_COLOR_BUFFER_BIT);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    return {};
  }
  else
    return std::move(e.error());
}