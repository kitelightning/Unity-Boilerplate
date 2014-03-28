Shader "KnL/VSMCaster" {
SubShader {
    Tags { "RenderType"="Opaque"}
    //Cull Front
    Cull Back
    
    Blend One Zero
    ZTest Less
    ZWrite On

    Pass {
        Fog { Mode Off }
        
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #pragma debug
        #pragma glsl
        #pragma target 3.0 
        #pragma multi_compile KL_SHADOWMODE_VSM KL_SHADOWMODE_ESM KL_SHADOWMODE_ESMLOG

        #include "UnityCG.cginc"
        #include "VSMESMUtility.cginc"

        struct v2f {
            float4 pos : SV_POSITION;
            float2 depth : TEXCOORD0;
        };
        #line 100
        v2f vert( appdata_base v ) {
            v2f o;
            o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
            float4x4 transformMatrix = mul(_LightProjTransform,mul(_LightViewTransform,_Object2World));
            o.pos = mul(transformMatrix,v.vertex);
            //o.depth = o.pos.zw;
            o.depth = calcShadowCoords(v.vertex).zw;
            //o.depth = mul(mul(_LightViewTransform,_Object2World),v.vertex).zz;
            return o;
        }

        float2 frag(v2f i) : COLOR {
            float linearDepth01 = i.depth.x;

            #if KL_SHADOWMODE_ESM
            linearDepth01 = WarpDepth(linearDepth01, _EVSMExponents).x;
            #elif KL_SHADOWMODE_ESMLOG
                //We want to store the actual depth and perform Gaussian blurring in log space
            #else /* KL_SHADOWMODE_VSM */
            #endif

            const float moment1 = linearDepth01;
            float moment2 = linearDepth01 * linearDepth01;

            #if KL_SHADOWMODE_VSM
            // Adjusting moments (this is sort of bias per pixel) using partial derivative
            float dx = ddx(linearDepth01);
            float dy = ddy(linearDepth01);
            moment2 += 0.25*(dx*dx+dy*dy);
            #endif
        
            return float2( moment1,moment2);
        }

        ENDCG

    }
}

Fallback Off

}