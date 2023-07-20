#ifndef SOBEL_OUTLINES_INCLUDED
#define SOBEL_OUTLINES_INCLUDED
#include "Packages/com.unity.shadergraph/ShaderGraphLibrary/Functions.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
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

float intensity(float3 incolor){
    return sqrt((incolor.x*incolor.x)+(incolor.y*incolor.y)+(incolor.z*incolor.z));
}

float sobel_edge_detect(UnityTexture2D image,UnitySamplerState st,float x, float y, float2 mainPixel) {
    float tleft  = intensity(SAMPLE_TEXTURE2D(image, st, mainPixel + float2(-x, y)) );
    float left   = intensity(SAMPLE_TEXTURE2D(image, st, mainPixel + float2(-x, 0)) );
    float bleft  = intensity(SAMPLE_TEXTURE2D(image, st, mainPixel + float2(-x,-y)) );
    float top    = intensity(SAMPLE_TEXTURE2D(image, st, mainPixel + float2( 0, y)) );
    float bottom = intensity(SAMPLE_TEXTURE2D(image, st, mainPixel + float2( 0,-y)) );
    float tright = intensity(SAMPLE_TEXTURE2D(image, st, mainPixel + float2( x, y)) );
    float right  = intensity(SAMPLE_TEXTURE2D(image, st, mainPixel + float2( x, 0)) );
    float bright = intensity(SAMPLE_TEXTURE2D(image, st, mainPixel + float2( x,-y)) );
    
    float gx = tleft  + 2.0*left + bleft - tright - 2.0*right - bright;
    float gy = -left  - 2.0*top - tright + bleft + 2.0*bottom + bright;
    
    float color = sqrt( (gx*gx) + (gy*gy) );
    return color;
}


void ColorSobel_float(float2 uv, UnityTexture2D blitSource, UnitySamplerState st, float x, float y, float thickness, out float sobel)
{
    float col = sobel_edge_detect( blitSource,st, x, y, uv);
    sobel = col;
}

void ColorSobelN_float(float2 uv, UnityTexture2D blitSource, UnitySamplerState st, float thickness, out float sobel)
{
    float2 sobelR = 0;
    float2 sobelG = 0;
    float2 sobelB = 0;

    for(int i = 0; i<9;i++)
    {
        float3 rgb = SAMPLE_TEXTURE2D(blitSource, st, uv + sobelSamplePoints[i] * thickness);
        
        float2 kernel = float2(sobelXMatrix[i],sobelYMatrix[i]);

        sobelR += rgb.r * kernel;
        sobelG += rgb.g * kernel;
        sobelB += rgb.b * kernel;
        

    }

    sobel = max(length(sobelR), max(length(sobelG), length(sobelB)));
}

#endif
