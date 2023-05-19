#ifndef SOBEL_OUTLINES_INCLUDED
#define SOBEL_OUTLINES_INCLUDED
#include "Packages/com.unity.shadergraph/ShaderGraphLibrary/Functions.hlsl" 
static float2 sobelSamplePoints[9] = {
    float2(-1, 1), float2(0, 1), float2(1, 1),
    float2(-1, 0), float2(0, 0), float2(1, 1),
    float2(-1, -1), float2(0, -1), float2(1, -1),
};

static float sobelXMatrix[9] = {
    1, 0, -1,
    2, 0, -2,
    1, 0, -1
};

static float sobelYMatrix[9] = {
    1, 2, 1,
    0, 0, 0,
    -1, -2, -1
};

void DepthSobel_float(float2 uv, float thickness, out float sobel)
{
    float2 sobelValue = 0;

    for(int i = 0; i<9;i++)
    {
       float depth = SHADERGRAPH_SAMPLE_SCENE_DEPTH(uv + sobelSamplePoints[i] * thickness);
        sobelValue += depth * float2(sobelXMatrix[i], sobelYMatrix[i]);

    }

    sobel = length(sobelValue);
}


void ColorSobel_float(float2 uv, float thickness, out float sobel)
{
    float2 sobelR = 0;
    float2 sobelG = 0;
    float2 sobelB = 0;

    for(int i = 0; i<9;i++)
    {
        float3 rgb = SHADERGRAPH_SAMPLE_SCENE_COLOR(uv + sobelSamplePoints[i] * thickness);
        float2 kernel = float2(sobelXMatrix[i], sobelYMatrix[i]);
        
        sobelR += rgb.r * kernel;
        sobelG += rgb.g * kernel;
        sobelB += rgb.b * kernel;
    }

    sobel = max(length(sobelR), max(length(sobelG), length(sobelB)));
}

#endif
