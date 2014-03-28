Shader "KL/KLLightmap_Diffuse_Dissolve" {
Properties {
    _MainTex ("Base (RGB) Gloss (A)", 2D) = "white" {}
    _LightmapTex ("Lightmap (MUST BE RGBM)", 2D) = "black" {}
    _LightmapPower ("Exposure", Float) = 1
    _Gamma ("Gamma power", Float) = 1
    [KeywordEnum(On, Off)] CORY_GAMMA ("Turn On Gamma Correction", Float) = 0
    [Toggle(WIPE_ON)] _WipeOn("Wipe On?", Float) = 0
}
SubShader { 
    Tags { "RenderType"="Transparent" "Queue"="Transparent" }
    LOD 400
    
    Blend SrcAlpha OneMinusSrcAlpha
    ZWrite On
    ColorMask RGB

CGPROGRAM
#pragma target 3.0
#pragma debug

#pragma multi_compile CORY_GAMMA_OFF CORY_GAMMA_ON
#pragma multi_compile WIPE_OFF WIPE_ON

#pragma surface surf Lambert vertex:vert exclude_path:prepass noambient novertexlights nolightmap nodirlightmap noforwardadd 
#pragma multi_compile_fwdbase

#pragma glsl
#pragma only_renderers d3d11 opengl

#include "KLLightmapUtilities.cginc"
#include "noiseSimplex.cginc"

sampler2D _MainTex;
sampler2D _LightmapTex;
half _LightmapPower;
half _Gamma;

struct Input {
    float2 uv_MainTex;
    float2 uv2_LightmapTex;
    float3 oPos;
};

    half3 _StartWipeOPos;
    half3 _EndWipeOPos;
    float _StartingTime;
    float _WipeDuration; //the length of time it takes the ring to traverse all depth values
    float _RingWidth; //width of the ring in linearized 0-1 coordinats.
    float _EnableDissolve;

    static const float KL_DISSOLVE_LAYERA       = 0;
    static const float KL_DISSOLVE_LAYERRING    = 1;
    static const float KL_DISSOLVE_LAYERB       = 2;

    float ApplyElectricWipe(half3 oPos) {
        if (_EnableDissolve != 1) {
            return KL_DISSOLVE_LAYERA;
        }

        half d = (oPos.z - _StartWipeOPos.z) / (_EndWipeOPos.z - _StartWipeOPos.z);
        
        half t = (_Time.y - _StartingTime) / _WipeDuration;
        //t += snoise(half2(oPos.x*2, t*5))/ (5*(_EndWipeOPos.z - _StartWipeOPos.z));
        
        //t += sin(snoise(half2(oPos.x*2, oPos.z*10)))*t;
        //t += snoise(sin(half2(oPos.x*2, oPos.z*1)*t)*t);
        //t += snoise(sin(half2(oPos.x*2, oPos.z/20)*t)*t);

        //t += sin(snoise(half2(oPos.x*2, oPos.z*1)*t))*t;
        //t += sin(snoise(half2(oPos.x*2, oPos.z*1)/t))*t;        
        
        //t += sin(snoise(half2(oPos.x*2, oPos.z*5))/ (0.1*(_EndWipeOPos.z - _StartWipeOPos.z))*t)/t;
        //t += snoise(sin(half2(oPos.x/20, oPos.z/20)*t*t*t)*t);
        #if WIPE_ON
        t *= -1;
        d *= -1;
        #else
        t += sin(snoise(half2(oPos.x*2, oPos.z*5))/ (0.1*(_EndWipeOPos.z - _StartWipeOPos.z))*t)/t;
        #endif

        if (d >= t) {
            return KL_DISSOLVE_LAYERA;
        } else if (d >= (t - _RingWidth)) {
            return saturate(sin((t-d)*3.14 / (_RingWidth/2) - 3.14/2) * 0.5 + 0.5);
        }
        else {
            return KL_DISSOLVE_LAYERB;
        }
    }

    void vert (inout appdata_full v, out Input o) {
        UNITY_INITIALIZE_OUTPUT(Input,o);
        o.oPos = v.vertex.xyz;
    }

void surf (Input IN, inout SurfaceOutput o) {
    half4 tex = tex2D(_MainTex, IN.uv_MainTex);
    o.Albedo = half3(0,0,0);
    o.Alpha = 1.0;

    const float fadeLayer = ApplyElectricWipe(IN.oPos);
    if(fadeLayer == KL_DISSOLVE_LAYERA) {
        #ifdef CORY_GAMMA_ON
        o.Emission = pow(_LightmapPower * tex.rgb * fromRGBMLinear(tex2D(_LightmapTex, IN.uv2_LightmapTex)), float3(_Gamma,_Gamma,_Gamma));  
        #else
        o.Emission = tex.rgb * _LightmapPower * fromRGBMGamma(tex2D(_LightmapTex, IN.uv2_LightmapTex)).rgb;
        #endif
        o.Alpha = 1;
    } else if (fadeLayer == KL_DISSOLVE_LAYERB) {
        //discard;
        o.Alpha = 0;
    }
    else {
        #ifdef CORY_GAMMA_ON
        o.Emission = pow(_LightmapPower * tex.rgb * fromRGBMLinear(tex2D(_LightmapTex, IN.uv2_LightmapTex)), float3(_Gamma,_Gamma,_Gamma));  
        #else
        o.Emission = tex.rgb * _LightmapPower * fromRGBMGamma(tex2D(_LightmapTex, IN.uv2_LightmapTex)).rgb;
        #endif
        o.Emission = o.Emission * 10 * fadeLayer + o.Emission;
        o.Alpha = 1;
    } 
}
ENDCG
}

FallBack Off
}
