# A shader that draws a circle.
using import glm
using import glsl

in pos : vec2
in DimBorderBlur : vec4
in corners : vec4
in fill : vec4
in outline : vec4
out out_Color : vec4
let pi = 3.14159265359

fn linearstep (low high x)
    clamp(0.0,1.0,((x - low)/(high - low)))

fn circle (x y DimBorderBlur corners fill outline)
    let xy = (vec2 x y)
    let l = ((DimBorderBlur.x + DimBorderBlur.y) * 0.5)
    let uv = ((xy * 2.0) - (vec2 1.0 1.0))
    let w = (1.0 + DimBorderBlur.w) # The original multiplies this by fwidth.
    # However, because this is taking coordinates in the range [0,width] or [0,height], we don't have to care.

    let border = ((DimBorderBlur.z / l) * 2.0)
    let t = (0.5 - (corners.x / l))
    let r = (1.0 - t - w)

    let inner = ((corners.y / l) * 2.0)
    let d0 = ((abs ((length uv) - r + (border * 0.5) - (inner * 0.5))) - t + (border * 0.5) + (inner * 0.5))
    let d1 = (abs ((length uv) - r - t))
    let s = (pow (linearstep (w * 2.0) 0.0 d0) 2.2)
    let alpha = (pow (linearstep (w * 2.0) 0.0 d1) 2.2)

    let output = (((vec4 fill.rgb 1) * fill.a * s) + ((vec4 outline.rgb 1) * outline.a * (clamp 0.0 1.0 (alpha - s))))
    output

# fn circle-shader ()
#     out_Color = (circle pos.x pos.y TODO DimBorderBlur corners fill outline)
# TODO: We'll figure out how to make this *work* later.

do
    let circle
    locals;