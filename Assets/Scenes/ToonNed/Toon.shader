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
            Name "ForwardLit"

            Tags
            {
                "LightMode" = "UniversalForward"
            }
            HLSLPROGRAM
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile_fragment _ _SHADOWS_SOFT

            #pragma vertex Vertex
            #pragma fragment Fragment

            #define _SPECULAR_COLOR

            #include "CustomLighting.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "Shadow Caster"

            Tags
            {
                "LightMode" = "ShadowCaster"
            }
            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Interpolators
            {
                float4 positionCS : SV_POSITION;
            };

            Interpolators Vertex(Attributes input)
            {
                Interpolators output;

                VertexPositionInputs posInputs = GetVertexPositionInputs(input.positionOS);
                output.positionCS = posInputs.positionCS;

                return output;
            }


            float4 Fragment(Interpolators input) : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }
    }
}