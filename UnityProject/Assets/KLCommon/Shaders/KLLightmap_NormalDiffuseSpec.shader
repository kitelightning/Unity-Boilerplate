Shader "KL/KLLightmap_NormalDiffuseSpec" {
Properties {
    _SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
    _Shininess ("Shininess", Range (0.03, 1)) = 0.078125
    _MainTex ("Base (RGB) Gloss (A)", 2D) = "white" {}
    _LightmapTex ("Lightmap (MUST BE RGBM)", 2D) = "black" {}
    _BumpMap ("Normalmap", 2D) = "bump" {}
    _LightmapPower ("Exposure", Float) = 1
    _Gamma ("Gamma power", Float) = 1
    [KeywordEnum(On, Off)] CORY_GAMMA ("Turn On Gamma Correction", Float) = 0
}
SubShader { 
    Tags { "RenderType"="Opaque" }
    LOD 400
    
    CGPROGRAM
    #pragma target 3.0
    #pragma debug
    #pragma surface surf BlinnPhong exclude_path:prepass noambient novertexlights nolightmap nodirlightmap noforwardadd 
    #pragma multi_compile_fwdbase
    #pragma multi_compile CORY_GAMMA_ON CORY_GAMMA_OFF
    #pragma glsl
    #pragma only_renderers d3d11 opengl

    #include "KLLightmapUtilities.cginc"

    sampler2D _MainTex;
    sampler2D _LightmapTex;
    sampler2D _BumpMap;
    half _Shininess;
    half _LightmapPower;
    half _Gamma;

    struct Input {
        float2 uv_MainTex;
        float2 uv_BumpMap;
        float2 uv2_LightmapTex;
    };

    void surf (Input IN, inout SurfaceOutput o) {
        half4 tex = tex2D(_MainTex, IN.uv_MainTex);
        o.Albedo = half3(0,0,0);
        o.Gloss = tex.a;
        o.Specular = _Shininess;
        #ifdef CORY_GAMMA_ON
        o.Emission = pow(_LightmapPower * tex.rgb * fromRGBMLinear(tex2D(_LightmapTex, IN.uv2_LightmapTex)), float3(_Gamma,_Gamma,_Gamma));
        #else
        o.Emission = tex.rgb * _LightmapPower * fromRGBMGamma(tex2D(_LightmapTex, IN.uv2_LightmapTex)).rgb;
        #endif
        o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
    }
    ENDCG
    }

FallBack Off
}
