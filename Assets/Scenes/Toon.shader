Shader "Unlit/Toon"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Smoothness("Smoothness", Range(0, 1)) = 0
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType"="Opaque"
        }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment

            #define _SPECULAR_COLOR

            #include "CustomLighting.hlsl"
            ENDHLSL
        }
    }
}