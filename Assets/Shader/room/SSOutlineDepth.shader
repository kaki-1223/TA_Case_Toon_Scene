Shader "Hidden/NPR/SSOutlineDepth"
{
    Properties
    {
        _OutlineColor ("Outline Color", Color) = (0.12, 0.06, 0.08, 1)
        _Thickness ("Thickness", Range(0.5, 4.0)) = 1.0
        _DepthThreshold ("Depth Threshold", Range(0.001, 0.1)) = 0.01
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
            Name "ScreenSpaceOutline"

            ZWrite Off
            ZTest Always
            Cull Off

            HLSLPROGRAM

            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            float4 _OutlineColor;
            float _Thickness;
            float _DepthThreshold;

            float GetEyeDepth(float2 uv)
            {
                float rawDepth = SampleSceneDepth(uv);
                return LinearEyeDepth(rawDepth, _ZBufferParams);
            }

            half4 Frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                float2 uv = input.texcoord;

                // 原始画面颜色
                half4 sceneColor =
                    SAMPLE_TEXTURE2D_X(
                        _BlitTexture,
                        sampler_LinearClamp,
                        uv
                    );

                // 1 = 大约一个屏幕像素
                float2 texel =
                    (1.0 / _ScreenParams.xy) * _Thickness;

                float center = GetEyeDepth(uv);

                float left =
                    GetEyeDepth(uv + float2(-texel.x, 0));

                float right =
                    GetEyeDepth(uv + float2(texel.x, 0));

                float up =
                    GetEyeDepth(uv + float2(0, texel.y));

                float down =
                    GetEyeDepth(uv + float2(0, -texel.y));

                // 找周围最大的深度跳变
                float depthDifference =
                    max(
                        max(abs(center - left),
                            abs(center - right)),
                        max(abs(center - up),
                            abs(center - down))
                    );

                // 除以当前深度，让远近处阈值更稳定
                float relativeDifference =
                    depthDifference / max(center, 0.01);

                // 硬切成 Toon 描边
                float edge =
                    step(_DepthThreshold, relativeDifference);

                return lerp(
                    sceneColor,
                    _OutlineColor,
                    edge * _OutlineColor.a
                );
            }

            ENDHLSL
        }
    }
}
