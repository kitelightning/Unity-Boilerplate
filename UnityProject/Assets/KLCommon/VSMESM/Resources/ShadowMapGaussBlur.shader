Shader "Hidden/ShadowMapGaussBlur" {
    Properties {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _Bloom ("Bloom (RGB)", 2D) = "black" {}
    }
    
    CGINCLUDE

        #include "UnityCG.cginc"

        sampler2D _MainTex;
        sampler2D _Bloom;
                
        uniform half4 _MainTex_TexelSize;
        uniform half4 _Parameter;

        struct v2f_tap
        {
            float4 pos : SV_POSITION;
            half2 uv20 : TEXCOORD0;
            half2 uv21 : TEXCOORD1;
            half2 uv22 : TEXCOORD2;
            half2 uv23 : TEXCOORD3;
        };			

        v2f_tap vert4Tap ( appdata_img v )
        {
            v2f_tap o;

            o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
            o.uv20 = v.texcoord + _MainTex_TexelSize.xy;				
            o.uv21 = v.texcoord + _MainTex_TexelSize.xy * half2(-0.5h,-0.5h);	
            o.uv22 = v.texcoord + _MainTex_TexelSize.xy * half2(0.5h,-0.5h);		
            o.uv23 = v.texcoord + _MainTex_TexelSize.xy * half2(-0.5h,0.5h);		

            return o; 
        }					
        
        float4 fragDownsample ( v2f_tap i ) : COLOR
        {				
            float4 color = tex2D (_MainTex, i.uv20);
            color += tex2D (_MainTex, i.uv21);
            color += tex2D (_MainTex, i.uv22);
            color += tex2D (_MainTex, i.uv23);
            return color / 4.0;
        }

        static const float4 curve4[7] = { half4(0.0205,0.0205,0.0205,0), half4(0.0855,0.0855,0.0855,0), half4(0.232,0.232,0.232,0),
            half4(0.324,0.324,0.324,1), half4(0.232,0.232,0.232,0), half4(0.0855,0.0855,0.0855,0), half4(0.0205,0.0205,0.0205,0) };
        
        struct v2f_withBlurCoordsSGX 
        {
            float4 pos : SV_POSITION;
            half2 uv : TEXCOORD0;
            half4 offs[3] : TEXCOORD1;
        };

        float log_conv ( float x0, float X, float y0, float Y )
        {
            return (X + log(x0 + (y0 * exp(Y - X))));
        }

        v2f_withBlurCoordsSGX vertBlurHorizontalSGX (appdata_img v)
        {
            v2f_withBlurCoordsSGX o;
            o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
            
            o.uv = v.texcoord.xy;
            half2 netFilterWidth = _MainTex_TexelSize.xy * half2(1.0, 0.0) * _Parameter.x; 
            half4 coords = -netFilterWidth.xyxy * 3.0;
            
            o.offs[0] = v.texcoord.xyxy + coords * half4(1.0h,1.0h,-1.0h,-1.0h);
            coords += netFilterWidth.xyxy;
            o.offs[1] = v.texcoord.xyxy + coords * half4(1.0h,1.0h,-1.0h,-1.0h);
            coords += netFilterWidth.xyxy;
            o.offs[2] = v.texcoord.xyxy + coords * half4(1.0h,1.0h,-1.0h,-1.0h);

            return o; 
        }		
        
        v2f_withBlurCoordsSGX vertBlurVerticalSGX (appdata_img v)
        {
            v2f_withBlurCoordsSGX o;
            o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
            
            o.uv = half4(v.texcoord.xy,1,1);
            half2 netFilterWidth = _MainTex_TexelSize.xy * half2(0.0, 1.0) * _Parameter.x;
            half4 coords = -netFilterWidth.xyxy * 3.0;
            
            o.offs[0] = v.texcoord.xyxy + coords * half4(1.0h,1.0h,-1.0h,-1.0h);
            coords += netFilterWidth.xyxy;
            o.offs[1] = v.texcoord.xyxy + coords * half4(1.0h,1.0h,-1.0h,-1.0h);
            coords += netFilterWidth.xyxy;
            o.offs[2] = v.texcoord.xyxy + coords * half4(1.0h,1.0h,-1.0h,-1.0h);

            return o; 
        }	

        float4 fragBlurSGX ( v2f_withBlurCoordsSGX i ) : COLOR
        {
            half2 uv = i.uv.xy;
            
            float4 color = tex2D(_MainTex, i.uv) * curve4[3];
            
            for( int l = 0; l < 3; l++ )  
            {   
                float4 tapA = tex2D(_MainTex, i.offs[l].xy);
                float4 tapB = tex2D(_MainTex, i.offs[l].zw); 
                color += (tapA + tapB) * curve4[l];
            }

            return color;

        }

        float4 fragLogBlurSGX ( v2f_withBlurCoordsSGX i ) : COLOR
        {
            half2 uv = i.uv.xy;
            
            float4 color = log_conv(curve4[3], tex2D(_MainTex, i.uv), curve4[0], tex2D(_MainTex, i.offs[0].xy));
            color = log_conv(1.0, color, curve4[0], tex2D(_MainTex, i.offs[0].zw));
            
            for( int l = 1; l < 3; l++ )  
            {   
                color = log_conv(1.0, color, curve4[l], tex2D(_MainTex, i.offs[l].xy));
                color = log_conv(1.0, color, curve4[l], tex2D(_MainTex, i.offs[l].zw));
            }

            return color;

        }	
                    
    ENDCG
    
    SubShader {
      ZTest Off Cull Off ZWrite Off Blend Off
      Fog { Mode off }  

    // 0
    Pass { 
    
        CGPROGRAM
        
        #pragma vertex vert4Tap
        #pragma fragment fragDownsample
        //#pragma fragmentoption ARB_precision_hint_fastest 
        
        ENDCG
         
        }
        
    // 1
    Pass {
        ZTest Always
        Cull Off
        
        CGPROGRAM 
        
        #pragma vertex vertBlurVerticalSGX
        #pragma fragment fragBlurSGX
        //#pragma fragmentoption ARB_precision_hint_fastest 
        
        ENDCG
        }	
        
    // 2
    Pass {		
        ZTest Always
        Cull Off
                
        CGPROGRAM
        
        #pragma vertex vertBlurHorizontalSGX
        #pragma fragment fragBlurSGX
        //#pragma fragmentoption ARB_precision_hint_fastest 
        
        ENDCG
        }	

    // alternate blur
    // 3
    Pass {
        ZTest Always
        Cull Off
        
        CGPROGRAM 
        
        #pragma vertex vertBlurVerticalSGX
        #pragma fragment fragLogBlurSGX
        //#pragma fragmentoption ARB_precision_hint_fastest 
        
        ENDCG
        }	
        
    // 4
    Pass {		
        ZTest Always
        Cull Off
                
        CGPROGRAM
        
        #pragma vertex vertBlurHorizontalSGX
        #pragma fragment fragLogBlurSGX
        //#pragma fragmentoption ARB_precision_hint_fastest 
        
        ENDCG
        }	
    }	

    FallBack Off
}
