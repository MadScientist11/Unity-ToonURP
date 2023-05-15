#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


float _Smoothness;

struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float2 uv : TEXCOORD0;
};

struct Interpolators
{
    float4 positionCS : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 positionWS : TEXCOORD1;
    float3 normalWS : TEXCOORD2;
};

Interpolators Vertex(Attributes input)
{
    Interpolators output;
    
    VertexPositionInputs posInputs = GetVertexPositionInputs(input.positionOS);
    output.positionCS = posInputs.positionCS;
    output.positionWS = posInputs.positionWS;
    
    VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS);
    output.normalWS = normalInputs.normalWS;
    
    return output;
}

half3 LightingLambertFixed(half3 lightDir, half3 normal)
{
    half NdotL = saturate(dot(normal, lightDir));
    return NdotL;
}

half3 CalculateBlinnPhongFixed(Light light, InputData inputData, SurfaceData surfaceData)
{
    half3 attenuatedLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation);
    half lightDiffuseMask = LightingLambertFixed(light.direction, inputData.normalWS);
    half3 lightDiffuseColor = attenuatedLightColor * lightDiffuseMask;

    half3 lightSpecularColor = half3(0,0,0);
    #if defined(_SPECGLOSSMAP) || defined(_SPECULAR_COLOR)
    half smoothness = exp2(10 * surfaceData.smoothness + 1);

    lightSpecularColor += LightingSpecular(attenuatedLightColor, light.direction, inputData.normalWS, inputData.viewDirectionWS, half4(surfaceData.specular, 1), smoothness);
    #endif

    #if _ALPHAPREMULTIPLY_ON
    return lightDiffuseColor * surfaceData.albedo * surfaceData.alpha + lightSpecularColor * lightDiffuseMask;
    #else
    return lightDiffuseColor * surfaceData.albedo + lightSpecularColor * lightDiffuseMask;
    #endif
}

half4 UniversalFragmentBlinnPhongFixed(InputData inputData, SurfaceData surfaceData)
{
    #if defined(DEBUG_DISPLAY)
    half4 debugColor;

    if (CanDebugOverrideOutputColor(inputData, surfaceData, debugColor))
    {
        return debugColor;
    }
    #endif

    uint meshRenderingLayers = GetMeshRenderingLayer();
    half4 shadowMask = CalculateShadowMask(inputData);
    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);
    Light mainLight = GetMainLight(inputData, shadowMask, aoFactor);

    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, aoFactor);

    inputData.bakedGI *= surfaceData.albedo;

    LightingData lightingData = CreateLightingData(inputData, surfaceData);
#ifdef _LIGHT_LAYERS
    if (IsMatchingLightLayer(mainLight.layerMask, meshRenderingLayers))
#endif
    {
        lightingData.mainLightColor += CalculateBlinnPhongFixed(mainLight, inputData, surfaceData);
    }

    #if defined(_ADDITIONAL_LIGHTS)
    uint pixelLightCount = GetAdditionalLightsCount();

    #if USE_FORWARD_PLUS
    for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
    {
        FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);
#ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
#endif
        {
            lightingData.additionalLightsColor += CalculateBlinnPhong(light, inputData, surfaceData);
        }
    }
    #endif

    LIGHT_LOOP_BEGIN(pixelLightCount)
        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);
#ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
#endif
        {
            lightingData.additionalLightsColor += CalculateBlinnPhong(light, inputData, surfaceData);
        }
    LIGHT_LOOP_END
    #endif

    #if defined(_ADDITIONAL_LIGHTS_VERTEX)
    lightingData.vertexLightingColor += inputData.vertexLighting * surfaceData.albedo;
    #endif

    return CalculateFinalColor(lightingData, surfaceData.alpha);
}


float4 Fragment(Interpolators input) : SV_Target
{
    InputData lightingInput = (InputData)0;
    lightingInput.normalWS = normalize(input.normalWS);
    lightingInput.viewDirectionWS = GetWorldSpaceViewDir(input.positionWS);
    lightingInput.shadowCoord = TransformWorldToShadowCoord(input.positionWS);
    
    SurfaceData surfaceInput = (SurfaceData)0;
    surfaceInput.albedo = half3(1,1,0);
    surfaceInput.alpha = 1;
    surfaceInput.specular = 1;
    surfaceInput.smoothness = _Smoothness;
    
    return UniversalFragmentBlinnPhongFixed(lightingInput, surfaceInput);
}
