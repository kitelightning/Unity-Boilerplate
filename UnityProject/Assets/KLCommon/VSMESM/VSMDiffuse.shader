Shader "KnL/VSMDiffuse" {

Properties {
    _Color ("Main Color", Color) = (1,1,1,1)
    _MainTex ("Base (RGB) Alpha (A)", 2D) = "white" {}
}

SubShader {
    Tags { "RenderType"="Opaque" "Queue" = "Geometry"}
    Cull Back
    ZTest Less
    ZWrite On

    Pass {
        Tags { "LightMode" = "ForwardBase" }
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #pragma debug
        #pragma glsl
        #pragma target 3.0
        #pragma multi_compile_fwdbase                        // This line tells Unity to compile this pass for forward add, giving attenuation information for the light.
        #pragma multi_compile KL_SHADOWMODE_VSM KL_SHADOWMODE_ESM KL_SHADOWMODE_ESMLOG

        #include "UnityCG.cginc"
        #include "AutoLight.cginc"
        #include "VSMESMUtility.cginc"

        struct v2f {
            float4 pos : POSITION;
            float4 shadowCoord : TEXCOORD0;
            float2  uv          : TEXCOORD1;
            float3  lightDir    : TEXCOORD2;
            float3 normal		: TEXCOORD3;
            LIGHTING_COORDS(4,5)                            // Macro to send shadow & attenuation to the vertex shader.
        };

        sampler2D _MainTex;
        fixed4 _LightColor0; // Colour of the light used in this pass.
        uniform fixed4 _Color;
            
        v2f vert( appdata_tan v ) {
            v2f o;
            o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
            o.uv = v.texcoord.xy;
            o.lightDir = ObjSpaceLightDir(v.vertex);
            o.normal =  v.normal;
            TRANSFER_VERTEX_TO_FRAGMENT(o);                 // Macro to send shadow & attenuation to the fragment shader.
                
            //**************************************************************************************************
            //Calculate VSM Parameters
            //**************************************************************************************************
            o.shadowCoord = calcShadowCoords(v.vertex);
            //**************************************************************************************************

            return o; 
        }

        fixed4 frag(v2f i) : COLOR {
            i.lightDir = normalize(i.lightDir);
            fixed atten = LIGHT_ATTENUATION(i); // Macro to get you the combined shadow & attenuation value.
            fixed4 tex = tex2D(_MainTex, i.uv);
            tex *= _Color;
            fixed3 normal = i.normal;                    
            fixed diff = saturate(dot(normal, i.lightDir));

            fixed4 c;
            c.rgb = (tex.rgb * _LightColor0.rgb * diff) * (atten * 2); // Diffuse and specular.
            c.a = tex.a;

            //**************************************************************************************************
            //Calculate VSM Parameters
            //**************************************************************************************************
            float shadow = calcShadow(i.shadowCoord);

            c.rgba = tex.rgba * shadow;       //TODO: ikrimae: shadow^4 seems to get rid of light bleeding
            //**************************************************************************************************
            return c;
        }
    
    
        
        ENDCG
    } 
}
    
FallBack "Off"
}
