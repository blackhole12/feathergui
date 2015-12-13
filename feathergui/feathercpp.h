// Copyright �2015 Black Sphere Studios
// For conditions of distribution and use, see copyright notice in "feathergui.h"

#ifndef __FEATHER_CPP_H__
#define __FEATHER_CPP_H__

#include "fgResource.h"
#include "fgText.h"
#include "bss-util\cDynArray.h"
#include "fgLayout.h"

template<void* (FG_FASTCALL *CLONE)(void*), void (FG_FASTCALL *DESTROY)(void*)>
struct fgArbitraryRef
{
  fgArbitraryRef() : ref(0) {}
  fgArbitraryRef(const fgArbitraryRef& copy) : ref(!copy.ref ? 0 : CLONE(copy.ref)) {}
  fgArbitraryRef(fgArbitraryRef&& mov) : ref(mov.ref) { mov.ref = 0; }
  fgArbitraryRef(void* r) : ref(!r ? 0 : CLONE(r)) {}
  ~fgArbitraryRef() { if(ref) DESTROY(ref); }

  fgArbitraryRef& operator=(const fgArbitraryRef& copy) { if(ref) DESTROY(ref); ref = !copy.ref ? 0 : CLONE(copy.ref); return *this; }
  fgArbitraryRef& operator=(fgArbitraryRef&& mov) { if(ref) DESTROY(ref); ref = mov.ref; mov.ref = 0; return *this; }

  void* ref;
};

template<class T, typename... Args>
struct fgConstruct
{
  template<void (FG_FASTCALL *DESTROY)(T*), void (FG_FASTCALL *CONSTRUCT)(T*, Args...)>
  struct fgConstructor : public T
  {
    fgConstructor() {}
    fgConstructor(Args... args) { CONSTRUCT((T*)this, args...); }
    ~fgConstructor() { DESTROY((T*)this); }
    operator T&() { return *this; }
    operator const T&() const { return *this; }
  };
};

template<class T>
struct fgConstruct<T>
{
  template<void (FG_FASTCALL *DESTROY)(T*), void (FG_FASTCALL *CONSTRUCT)(T*)>
  struct fgConstructor : public T
  {
    fgConstructor() { CONSTRUCT((T*)this); }
    ~fgConstructor() { DESTROY((T*)this); }
    operator T&() { return *this; }
    operator const T&() const { return *this; }
  };
};

typedef bss_util::cDynArray<fgArbitraryRef<fgCloneResource, fgDestroyResource>, FG_UINT, bss_util::CARRAY_CONSTRUCT> fgResourceArray;
typedef bss_util::cDynArray<fgArbitraryRef<fgCloneFont, fgDestroyFont>, FG_UINT, bss_util::CARRAY_CONSTRUCT> fgFontArray;

template<class T>
auto DynGet(const fgVector& r, FG_UINT i) { return ((T&)r)[i]; }
template<class T>
auto DynGetP(const fgVector& r, FG_UINT i) { return ((T&)r).begin()+i; }

template<class T>
char DynArrayRemove(T& a, FG_UINT index)
{
  if(index >= a.Length())
    return 0;
  a.Remove(index);
  return 1;
}

typedef bss_util::cDynArray<typename fgConstruct<fgStyleLayout, const char*, fgElement*, fgFlag>::fgConstructor<fgStyleLayout_Destroy, fgStyleLayout_Init>, size_t, bss_util::CARRAY_CONSTRUCT> fgStyleLayoutArray;
typedef bss_util::cDynArray<typename fgConstruct<fgStyle>::fgConstructor<fgStyle_Destroy, fgStyle_Init>, size_t, bss_util::CARRAY_CONSTRUCT> fgStyleArray;
typedef bss_util::cDynArray<typename fgConstruct<fgSkin, int>::fgConstructor<fgSkin_Destroy, fgSubskin_Init>, size_t, bss_util::CARRAY_CONSTRUCT> fgSubskinArray;
typedef bss_util::cDynArray<typename fgConstruct<fgClassLayout, const char*, fgElement*, fgFlag>::fgConstructor<fgClassLayout_Destroy, fgClassLayout_Init>, size_t, bss_util::CARRAY_CONSTRUCT> fgClassLayoutArray;

struct __kh_fgRadioGroup_t;
extern __inline struct __kh_fgRadioGroup_t* fgRadioGroup_init();
extern void fgRadioGroup_destroy(struct __kh_fgRadioGroup_t*);

struct _FG_ROOT;
extern struct _FG_ROOT* fgroot_instance;

#endif