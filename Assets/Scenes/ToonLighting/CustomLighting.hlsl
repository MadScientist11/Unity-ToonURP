#ifndef CUSTOM_LIGHTING_INCLUDED
#define CUSTOM_LIGHTING_INCLUDED
//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
/*
- This undef (un-define) is required to prevent the "invalid subscript 'shadowCoord'" error,
  which occurs when _MAIN_LIGHT_SHADOWS is used with 1/No Shadow Cascades with the Unlit Graph.
- It's technically not required for the PBR/Lit graph, so I'm using the SHADERPASS_FORWARD to ignore it for the pass.
*/
#ifndef SHADERGRAPH_PREVIEW
    #if VERSION_GREATER_EQUAL(9, 0)
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #if (SHADERPASS != SHADERPASS_FORWARD)
            #undef REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
        #endif
    #else
        #ifndef SHADERPASS_FORWARD
            #undef REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
        #endif
    #endif
#endif
// Also see https://github.com/Cyanilux/URP_ShaderGraphCustomLighting

void MainLight_float(float3 positionWS, out float3 Direction, out float3 Color, out float ShadowAttenuation)
{
#if defined(SHADERGRAPH_PREVIEW)
    Direction = float3(0.5, 0.5, 0);
    Color = 1;
    ShadowAttenuation = 1;
#else
	float4 shadowCoord = TransformWorldToShadowCoord(positionWS);

    Light mainLight = GetMainLight(shadowCoord);
    Direction = mainLight.direction;
    Color = mainLight.color;

    //!defined(_MAIN_LIGHT_SHADOWS) || doesn't work
	#if defined(_RECEIVE_SHADOWS_OFF)
		ShadowAttenuation = 1.0h;
    #else
	    ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
	    float shadowStrength = GetMainLightShadowStrength();
	    ShadowAttenuation = SampleShadowmap(shadowCoord, TEXTURE2D_ARGS(_MainLightShadowmapTexture,
	    sampler_MainLightShadowmapTexture),
	    shadowSamplingData, shadowStrength, false);
    #endif
#endif
}


#endif