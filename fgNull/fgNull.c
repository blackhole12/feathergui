// Copyright �2016 Black Sphere Studios
// For conditions of distribution and use, see copyright notice in "feathergui.h"

#include "fgNull.h"
#include "fgText.h"
#include "fgResource.h"
#include "fgRoot.h"
#include "fgButton.h"
#include "fgMenu.h"
#include "fgWindow.h"
#include "fgRadioButton.h"
#include "fgSlider.h"
#include "fgProgressbar.h"

#if defined(BSS_DEBUG) && defined(BSS_CPU_x86_64)
#pragma comment(lib, "../bin/feathergui_d.lib")
#elif defined(BSS_CPU_x86_64)
#pragma comment(lib, "../bin/feathergui.lib")
#elif defined(BSS_DEBUG)
#pragma comment(lib, "../bin32/feathergui32_d.lib")
#else
#pragma comment(lib, "../bin32/feathergui32.lib")
#endif

fgRoot* _fgroot=0; // fgRoot singleton variable


void* FG_FASTCALL fgCreateFont(fgFlag flags, const char* font, unsigned int fontsize, unsigned int dpi) { return (void*)~0; }
void* FG_FASTCALL fgCloneFontDPI(void* font, unsigned int dpi) { return (void*)~0; }
void* FG_FASTCALL fgCloneFont(void* font) { return (void*)~0; }
void FG_FASTCALL fgDestroyFont(void* font) { }
void* FG_FASTCALL fgDrawFont(void* font, const char* text, float lineheight, float letterspacing, unsigned int color, const AbsRect* area, FABS rotation, AbsVec* center, fgFlag flags, void* cache) { return 0; }
void FG_FASTCALL fgFontSize(void* font, const char* text, float lineheight, float letterspacing, AbsRect* area, fgFlag flags) { }

void* FG_FASTCALL fgCreateResource(fgFlag flags, const char* data, size_t length) { return (void*)~0; }
void* FG_FASTCALL fgCloneResource(void* res) { return (void*)~0; }
void FG_FASTCALL fgDestroyResource(void* res) { }
void FG_FASTCALL fgDrawResource(void* res, const CRect* uv, unsigned int color, unsigned int edge, FABS outline, const AbsRect* area, FABS rotation, AbsVec* center, fgFlag flags) {}
void FG_FASTCALL fgResourceSize(void* res, const CRect* uv, AbsVec* dim, fgFlag flags) { }

#define DEFAULT_CREATE(type, init, ...) \
  type* r = (type*)malloc(sizeof(type)); \
  init(r, __VA_ARGS__); \
  ((fgElement*)r)->free = &free

fgElement* FG_FASTCALL fgResource_Create(void* res, const CRect* uv, unsigned int color, fgFlag flags, fgElement* BSS_RESTRICT parent, fgElement* BSS_RESTRICT prev, const fgTransform* transform)
{
  DEFAULT_CREATE(fgResource, fgResource_Init, res, uv, color, flags, parent, prev, transform);
  return (fgElement*)r;
}
fgElement* FG_FASTCALL fgText_Create(char* text, void* font, unsigned int color, fgFlag flags, fgElement* BSS_RESTRICT parent, fgElement* BSS_RESTRICT prev, const fgTransform* transform)
{
  DEFAULT_CREATE(fgText, fgText_Init, text, font, color, flags, parent, prev, transform);
  return (fgElement*)r;
}
fgElement* FG_FASTCALL fgButton_Create(const char* text, fgFlag flags, fgElement* BSS_RESTRICT parent, fgElement* BSS_RESTRICT prev, const fgTransform* transform)
{
  DEFAULT_CREATE(fgButton, fgButton_Init, flags, parent, prev, transform);
  fgVoidMessage((fgElement*)r, FG_SETTEXT, text, 0);
  return (fgElement*)r;
}
fgElement* FG_FASTCALL fgWindow_Create(const char* caption, fgFlag flags, const fgTransform* transform)
{
  DEFAULT_CREATE(fgWindow, fgWindow_Init, flags, transform);
  fgVoidMessage((fgElement*)r, FG_SETPARENT, fgSingleton(), 0);
  fgVoidMessage((fgElement*)r, FG_SETTEXT, caption, 0);
  return (fgElement*)r;
}

fgElement* FG_FASTCALL fgCheckbox_Create(const char* text, fgFlag flags, fgElement* BSS_RESTRICT parent, fgElement* BSS_RESTRICT prev, const fgTransform* transform)
{
  DEFAULT_CREATE(fgCheckbox, fgCheckbox_Init, flags, parent, prev, transform);
  fgVoidMessage((fgElement*)r, FG_SETTEXT, text, 0);
  return (fgElement*)r;
}
fgElement* FG_FASTCALL fgRadiobutton_Create(const char* text, fgFlag flags, fgElement* BSS_RESTRICT parent, fgElement* BSS_RESTRICT prev, const fgTransform* transform)
{
  DEFAULT_CREATE(fgRadiobutton, fgRadiobutton_Init, flags, parent, prev, transform);
  fgVoidMessage((fgElement*)r, FG_SETTEXT, text, 0);
  return (fgElement*)r;
}
fgElement* FG_FASTCALL fgProgressbar_Create(FREL value, fgFlag flags, fgElement* BSS_RESTRICT parent, fgElement* BSS_RESTRICT prev, const fgTransform* transform)
{
  DEFAULT_CREATE(fgProgressbar, fgProgressbar_Init, flags, parent, prev, transform);
  fgIntMessage((fgElement*)r, FG_SETSTATE, *((ptrdiff_t*)&value), 0);
  return (fgElement*)r;
}
fgElement* FG_FASTCALL fgSlider_Create(size_t range, fgFlag flags, fgElement* BSS_RESTRICT parent, fgElement* BSS_RESTRICT prev, const fgTransform* transform)
{
  DEFAULT_CREATE(fgSlider, fgSlider_Init, range, flags, parent, prev, transform);
  return (fgElement*)r;
}


fgRoot* FG_FASTCALL fgInitialize()
{
  fgRoot* r = (fgRoot*)malloc(sizeof(fgRoot));
  assert(!_fgroot);
  AbsRect area = { 0 };
  fgRoot_Init(r, &area, 0);
  return _fgroot=r;
}

AbsRect* clipstack = 0;
size_t clipcapacity = 0;
size_t clipnum = 0;

void fgPushClipRect(AbsRect* clip)
{
  if(clipcapacity >= clipnum)
  {
    clipcapacity = clipcapacity * 2;
    clipstack = realloc(clipstack, sizeof(AbsRect)*clipcapacity);
  }
  clipstack[clipnum++] = *clip;
}
AbsRect fgPeekClipRect()
{
  static const AbsRect BLANK = { 0,0,0,0 };
  return !clipnum ? BLANK : clipstack[clipnum - 1];
}
void fgPopClipRect()
{
  --clipnum;
}

char FG_FASTCALL fgLoadExtension(const char* extname, void* fg, size_t sz) { return -1; }
void FG_FASTCALL fgDrawLine(AbsVec p1, AbsVec p2, unsigned int color) {}
void fgSetCursor(unsigned int type, void* custom) {}
void fgClipboardCopy(unsigned int type, const void* data, size_t length) {}
char fgClipboardExists(unsigned int type) { return 0; }
const void* fgClipboardPaste(unsigned int type, size_t* length) { return 0; }
void fgClipboardFree(const void* mem) {}
void fgDirtyElement(fgTransform* elem) {}