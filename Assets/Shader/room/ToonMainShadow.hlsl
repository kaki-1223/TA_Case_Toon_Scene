#ifndef TOON_MAIN_SHADOW_INCLUDED
#define TOON_MAIN_SHADOW_INCLUDED

// 避开你之前 Shader Graph Preview 中 include Lighting.hlsl 的报错
#ifndef SHADERGRAPH_PREVIEW
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
#endif

void MainLightShadow_float(float3 PositionWS, out float ShadowAtten)
{
#if defined(SHADERGRAPH_PREVIEW)

    ShadowAtten = 1.0;

#else

    // 找到当前像素属于哪个 Directional Light shadow cascade
    half cascadeIndex = ComputeCascadeIndex(PositionWS);

    // World Space -> Main Light Shadow Space
    float4 shadowCoord =
        float4(
            mul(
                _MainLightWorldToShadow[cascadeIndex],
                float4(PositionWS, 1.0)
            ).xyz,
            0.0
        );

    ShadowSamplingData samplingData =
        GetMainLightShadowSamplingData();

    half4 shadowParams =
        GetMainLightShadowParams();

    // 读取 Directional Light Shadow Map
    half realtimeShadow =
        SampleShadowmap(
            TEXTURE2D_ARGS(
                _MainLightShadowmapTexture,
                sampler_LinearClampCompare
            ),
            shadowCoord,
            samplingData,
            shadowParams,
            false
        );

    // 处理 URP Shadow Distance 的渐隐
    half fade = GetMainLightShadowFade(PositionWS);

    ShadowAtten = lerp(realtimeShadow, 1.0, fade);

#endif
}

void MainLightShadow_half(half3 PositionWS, out half ShadowAtten)
{
    float shadow;
    MainLightShadow_float((float3)PositionWS, shadow);
    ShadowAtten = (half)shadow;
}

#endif
