Shader "KnL/VSMSpecNormal" {
Properties {
    _Color ("Main Color", Color) = (1,1,1,1)
    _SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
    _Shininess ("Shininess", Range (0.03, 1)) = 0.078125
    _MainTex ("Base (RGB) Gloss (A)", 2D) = "white" {}
    _BumpMap ("Normalmap", 2D) = "bump" {}
}
SubShader {
    Tags { "RenderType"="Opaque" }
    LOD 400
    Cull Back
    ZTest Less
    ZWrite On

    Pass {
        Tags { "LightMode" = "ForwardBase" }
        CGPROGRAM
        #pragma vertex vert_surf
        #pragma fragment frag_surf
        #pragma multi_compile_fwdbase nolightmap
        #include "HLSLSupport.cginc"
        #include "UnityShaderVariables.cginc"
        #define UNITY_PASS_FORWARDBASE
        #include "UnityCG.cginc"
        #include "Lighting.cginc"
        #include "AutoLight.cginc"

        #define INTERNAL_DATA
        #define WorldReflectionVector(data,normal) data.worldRefl
        #define WorldNormalVector(data,normal) normal
        #line 1
        #line 14

        //#pragma surface surf BlinnPhong exclude_path:prepass nolightmap noforwardadd 
        #pragma target 5.0
        #pragma debug

        sampler2D _MainTex;
        sampler2D _BumpMap;
        fixed4 _Color;
        half _Shininess;

        struct Input {
            float2 uv_MainTex;
            float2 uv_BumpMap;
            float3 worldNormal; 
            INTERNAL_DATA
        };

        void surf (Input IN, inout SurfaceOutput o) {
            fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
            o.Albedo = tex.rgb * _Color.rgb;
            o.Gloss = tex.a;
            o.Alpha = tex.a * _Color.a;
            o.Specular = _Shininess;
            o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
        }

        //#ifdef LIGHTMAP_OFF
        //struct v2f_surf {
        //  float4 pos : SV_POSITION;
        //  float4 pack0 : TEXCOORD0;
        //  fixed3 lightDir : TEXCOORD1;
        //  fixed3 vlight : TEXCOORD2;
        //  float3 viewDir : TEXCOORD3;
        //  LIGHTING_COORDS(4,5)
        //};
        //#endif

        struct v2f_surf {
            float4 pos : SV_POSITION;
            float4 pack0 : TEXCOORD0;
            float2 lmap : TEXCOORD1;
            float3 viewDir : TEXCOORD2;
            float4 shadowCoord : TEXCOORD3;
            LIGHTING_COORDS(4,5)

        };

        sampler2D _LightShadowMap;
        uniform float4x4 _LightViewTransform;
        uniform float4x4 _LightProjTransform;

        float4 unity_LightmapST;

        float4 _MainTex_ST;
        float4 _BumpMap_ST;
        v2f_surf vert_surf (appdata_full v) {
            v2f_surf o;
            o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
            o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
            o.pack0.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);

            o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;

            float3 worldN = mul((float3x3)_Object2World, SCALED_NORMAL);
            TANGENT_SPACE_ROTATION;
            float3 lightDir = mul (rotation, ObjSpaceLightDir(v.vertex));       //Calculate light dir in tangent space

            float3 viewDirForLight = mul (rotation, ObjSpaceViewDir(v.vertex)); //Calculate view dir in tangent space
            o.viewDir = viewDirForLight;

            TRANSFER_VERTEX_TO_FRAGMENT(o);   //Project this vertex into light space and store in o.LightCoord

            //**************************************************************************************************
            //Calculate VSM Parameters
            //**************************************************************************************************
            //Bias matrix to map NDC xyz (-1 to 1) to UVW space (0 to 1)
            #if UNITY_UV_STARTS_AT_TOP  //DirectX most likely
                //float4x4 biasMatrix = float4x4(
                //    0.5,   0,   0,   0.5,
                //    0,  -0.5,   0,   0.5,
                //    0,     0,   UNITY_NEAR_CLIP_VALUE == 0 ? 1 : 0.5, UNITY_NEAR_CLIP_VALUE == 0 ? 0 : 0.5,
                //    0,     0,   0,     1);
                float4x4 biasMatrix = float4x4(
                    0.5,   0,   0,   0.5,
                    0,  -0.5,   0,   0.5,
                    0,     0,   1,     0,
                    0,     0,   0,     1);
            #else   //OpenGL most likely
                float4x4 biasMatrix = float4x4(
                0.5,   0,   0, 0.5,
                0,   0.5,   0, 0.5,
                0,     0,   UNITY_NEAR_CLIP_VALUE == 0 ? 1 : 0.5, UNITY_NEAR_CLIP_VALUE == 0 ? 0 : 0.5,
                0,     0,   0,   1);
            #endif
                
            float4x4 lightXformMatrix = mul(biasMatrix,mul(_LightProjTransform,mul(_LightViewTransform,_Object2World)));
            o.shadowCoord = mul(lightXformMatrix,v.vertex);
            //**************************************************************************************************

            return o;
        }

        sampler2D unity_Lightmap;

        sampler2D unity_LightmapInd;

        float ReduceLightBleeding(float p_max, float Amount)  
        {  
          // Remove the [0, Amount] tail and linearly rescale [p_max>Amount,1] to [0,1]
          return p_max < Amount ? 0 : (p_max - Amount) / (1 - Amount);
        }

        float chebyshevUpperBound( float3 shadowCoord)
        {
            // We retrive the two moments previously stored (depth and depth*depth)
            float2 moments = tex2D(_LightShadowMap,shadowCoord.xy).xy;
            //return moments.x; //!!!!!!!!!!!!!!!!!!!Try with culling the front and just returning the first moment....it works ridiculously well?
        
            // Surface is fully lit. as the current fragment is before the light occluder
            if (shadowCoord.z <= moments.x)
                return 1.0 ;
    
            // The fragment is either in shadow or penumbra. We now use chebyshev's upperBound to check
            // How likely this pixel is to be lit (p_max)
            float variance = moments.y - (moments.x*moments.x);
            variance = max(variance,0.00002);
    
            float d = shadowCoord.z - moments.x;
            float p_max = variance / (variance + d*d);

            return ReduceLightBleeding(p_max, 0.1);
        }

        fixed4 frag_surf (v2f_surf IN) : COLOR {

            #ifdef UNITY_COMPILER_HLSL
            Input surfIN = (Input)0;
            #else
            Input surfIN;
            #endif
            surfIN.uv_MainTex = IN.pack0.xy;
            surfIN.uv_BumpMap = IN.pack0.zw;

            #ifdef UNITY_COMPILER_HLSL
            SurfaceOutput o = (SurfaceOutput)0;
            #else
            SurfaceOutput o;
            #endif

            o.Albedo = 0.0;
            o.Emission = 0.0;
            o.Specular = 0.0;
            o.Alpha = 0.0;
            o.Gloss = 0.0;
            surf (surfIN, o);
            fixed atten = LIGHT_ATTENUATION(IN);  //Compute light attenuation based on lookup texture parameterized over the vertex's length in lightspace (i.e. how far it is from the light)
            fixed4 c = 0;

            half3 specColor;
            fixed4 lmtex = tex2D(unity_Lightmap, IN.lmap.xy);
            fixed4 lmIndTex = tex2D(unity_LightmapInd, IN.lmap.xy);

            /*
                Retrieves lightmap full illumination 1st lightmap and the directional light direction from 2nd lightmap. Lightmap is encoded as RGBM
                Converts fragment normal into RNM basis and compute lambertian contribution from diffuse lightmap (newNormalInRNM * dirLight)
                Calculates regular PhongLighting based on dirLightMap
            */

            half3 lm = LightingBlinnPhong_DirLightmap(o, lmtex, lmIndTex, normalize(half3(IN.viewDir)), 1, specColor).rgb;
            c.rgb += specColor;

            c.rgb += o.Albedo * lm;
            c.a = o.Alpha;


            //**************************************************************************************************
            //Calculate VSM Parameters
            //**************************************************************************************************
            float3 shadowCoordPostW = IN.shadowCoord.xyz / IN.shadowCoord.w;
            //float3 shadowCoordPostW = float3(i.shadowCoord.x, i.shadowCoord.y, i.shadowCoord.z) * float3(1/i.shadowCoord.w, 1/i.shadowCoord.w, 1);

            float shadow = chebyshevUpperBound(shadowCoordPostW);;
            //float shadow = tex2D(_LightShadowMap,shadowCoordPostW.xy).x < (shadowCoordPostW.z / 50) ? 0 : 1;

            //If the vertex is out of the light's projection frustum, turn off the shadow occlusion term 
            if (any(shadowCoordPostW.xyz <= float3(0,0,0)) || 
                any(shadowCoordPostW.xyz >= float3(1,1,1))) {
                shadow = 1.0;
            }
            //**************************************************************************************************
    
            c.rgb *= shadow;       //TODO: ikrimae: shadow^4 seems to get rid of light bleeding

            return c;
        }
        ENDCG
    }
}

FallBack "Off"
}