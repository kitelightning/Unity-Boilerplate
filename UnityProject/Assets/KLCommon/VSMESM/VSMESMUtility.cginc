#ifndef VSM_ESMUTILITY_CG_INCLUDED
#define VSM_ESMUTILITY_CG_INCLUDED

sampler2D _LightShadowMap;
uniform float4x4 _LightViewTransform;
uniform float4x4 _LightProjTransform;
uniform float2  _LightNearFarPlane;

//**************************************************************************************************
// VSM Utility Functions
//**************************************************************************************************
float ReduceLightBleeding(float p_max, float Amount)  
{  
    // Remove the [0, Amount] tail and linearly rescale p_max from [Amount,1] to [0,1]
    return p_max < Amount ? 0 : (p_max - Amount) / (1 - Amount);
}

float chebyshevUpperBound( float2 shadowUV, float linearDepth01)
{
    // We retrive the two moments previously stored (depth and depth*depth)
    float2 moments = tex2D(_LightShadowMap,shadowUV).xy;
        
    // Surface is fully lit. as the current fragment is before the light occluder
    if (linearDepth01 <= moments.x)
        return 1.0 ;
    
    // The fragment is either in shadow or penumbra. We now use chebyshev's upperBound to check
    // How likely this pixel is to be lit (p_max)
    float variance = moments.y - (moments.x*moments.x);
    variance = max(variance,0.000002);
    
    float d = linearDepth01 - moments.x;
    float p_max = variance / (variance + d*d);

    return ReduceLightBleeding(p_max, 0.10);
}
//**************************************************************************************************

//**************************************************************************************************
// ESM Utility Functions
//**************************************************************************************************
// The exponents for the EVSM techniques should be less than ln(FLT_MAX/FILTER_SIZE)/2 {ln(FLT_MAX/1)/2 ~44.3} ( we divide by 2 because if we rescale to [-1,1]
//         42.9 is the maximum possible value for MAX_FILTER_SIZE=15
//         42.0 is the truncated value that we pass into the sample
// Make sure exponents say consistent in light space regardless of partition
// scaling. This prevents the exponentials from ever getting too ridiculous
// and maintains consistency across partitions.
// Clamp to maximum range of fp32 to prevent overflow/underflow
uniform float2 _EVSMExponents;

// Convert depth to EVSM coefficients
// Input depth should be in [0, 1]
float2 WarpDepth(const float depth, const float2 exponents)
{
    // Rescale depth into [-1, 1] for increased precision from the extra sign bit
    //if (rescaleDepth) {
    //    depth = 2.0f * depth - 1.0f;
    //}
    float pos =  exp( exponents.x * depth); //NOTE: ikrimae: Should we add a light bias here like Marco Salvi does? Doesn't seem to have an effect. CX: Marco's sample code
    //float neg = -exp(-exponents.y * depth); //TODO: ikrimae: Uncomment when calculating dual warp EVSM
    return float2(pos, pos);
}

float calcESMShadow( const float2 shadowUV, const float linearShadowDepth01,const bool isUsingLogSpaceBlur)
{
    // We retrive the two moments previously stored (depth and depth*depth)
    const float2 moments = tex2D(_LightShadowMap,shadowUV.xy).xy;

    float shadow;
    if (isUsingLogSpaceBlur) {
        shadow = saturate(WarpDepth(moments.x - linearShadowDepth01, _EVSMExponents).x);
    } else {
        shadow = saturate(moments.x / WarpDepth(linearShadowDepth01, _EVSMExponents).x);
    }

    return shadow;
}

float calcShadow(const float4 lightSpaceFragPos) {
    const float2 shadowUV = lightSpaceFragPos.xy / lightSpaceFragPos.w;
    const float linearShadowDepth01 = lightSpaceFragPos.z;

    float shadow;
    #if KL_SHADOWMODE_ESM
    shadow = calcESMShadow(shadowUV, linearShadowDepth01, false);
    #elif KL_SHADOWMODE_ESMLOG
    shadow = calcESMShadow(shadowUV, linearShadowDepth01, true);
    #else /* KL_SHADOWMODE_VSM */
    shadow = chebyshevUpperBound(shadowUV, linearShadowDepth01);
    #endif

    //If the vertex is out of the light's projection frustum, turn off the shadow occlusion term 
    //This is correct for both OpenGL & DirectX because our bias-matrix maps NDC to [0,1] for both DX & OpenGL
    if (any(float3(shadowUV.x, shadowUV.y, linearShadowDepth01) <= float3(0,0,0)) || 
        any(float3(shadowUV.x, shadowUV.y, linearShadowDepth01) >= float3(1,1,1))) {
        shadow = 1.0;
    }

    return shadow;
}

float4 calcShadowCoords(float4 objectSpaceVertexPos) {
    //Bias matrix to map NDC xyz (-1 to 1) to UVW space (0 to 1)
    //OpenGL Projection matrix maps z to [-Near,Far] while DX maps z to [0,Far]
    //float linearDepth01 = UNITY_NEAR_CLIP_VALUE == 0 ? 
    //            i.depth.x  / _LightNearFarPlane.y : 
    //            (i.depth.x + _LightNearFarPlane.x) / (_LightNearFarPlane.y + _LightNearFarPlane.x);  // equiv to (z - -Near) / (Far - -Near)
    #if UNITY_UV_STARTS_AT_TOP  //DirectX most likely
        //TODO: ikrimae: Somehow assert UNITY_NEAR_CLIP_VALUE == 0
        const float4x4 biasMatrix = float4x4(
                0.5,   0,   0,                        0.5,
                0,  -0.5,   0,                        0.5,
                0,     0,   1 / _LightNearFarPlane.y,   0,
                0,     0,   0,                          1);
    #else   //OpenGL most likely
        const float4x4 biasMatrix = float4x4(
                0.5,   0,   0,                                                 0.5,
                0,   0.5,   0,                                                 0.5,
                0,     0,   1 / (_LightNearFarPlane.y + _LightNearFarPlane.x), _LightNearFarPlane.x / (_LightNearFarPlane.y + _LightNearFarPlane.x),
                0,     0,   0,                                                 1);
    #endif
                
    float4x4 lightXformMatrix = mul(biasMatrix,mul(_LightProjTransform,mul(_LightViewTransform,_Object2World)));
    return mul(lightXformMatrix, objectSpaceVertexPos);
}
#endif