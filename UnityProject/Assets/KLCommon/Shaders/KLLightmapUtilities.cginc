#ifndef LIGHTMAP_UTILITIES_CG_INCLUDED
#define LIGHTMAP_UTILITIES_CG_INCLUDED

// From Marmoset b/c we're using their HDR assetpostprocessor
half  toLinearFast1(half  c)  { half  c2 = c*c; return dot(half2(0.7532,0.2468),half2(c2,c*c2)); }
half3 toLinearFast3(half3 c)  { half3 c2 = c*c; return 0.7532*c2 + 0.2468*c*c2; }

//32-bit float values are gamma-compressed before being RGBM encoded. Meaning, RGBMEncode(hdrValue^1/2.2). 
//To decode, (rgbmValue * rgbmValue.a * 6)^2.2 or (rgbmValue.rgb^2.2) * a^2.2 * 51.5
half3 fromRGBMGamma(half4 c)  {
    //leave RGB*A in gamma space, gamma correction is disabled
    return c.rgb * c.a;
}

half3 fromRGBMLinear(half4 c)  {
    //RGB is pulled to linear space by sRGB sampling, alpha must be in linear space also before use
    return c.rgb * toLinearFast1(c.a) * 51.5;
}

#endif