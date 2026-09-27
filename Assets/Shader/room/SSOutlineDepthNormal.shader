Shader "Hidden/NPR/SSOutlineDepthNormal"
{
    Properties
    {
        _OutlineColor ("Outline Color", Color) = (0.12, 0.06, 0.08, 1)

        _Thickness ("Thickness", Range(0.5, 4.0)) = 1.0

        _DepthThreshold (
            "Depth Threshold",
            Range(0.001, 0.1)
        ) = 0.005

        _NormalThreshold (
            "Normal Threshold",
            Range(0.01, 1.0)
        ) = 0.15
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
            Name "ScreenSpaceOutlineDepthNormal"

            ZWrite Off
            ZTest Always
            Cull Off

            HLSLPROGRAM

            #pragma vertex Vert
            #pragma fragment Frag

            // 兼容 URP Normal Texture 的不同编码方式
            #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"


            CBUFFER_START(UnityPerMaterial)

            float4 _OutlineColor;

            float _Thickness;

            float _DepthThreshold;

            float _NormalThreshold;

            CBUFFER_END


            float GetEyeDepth(float2 uv)
            {
                float rawDepth =
                    SampleSceneDepth(uv);

                return LinearEyeDepth(
                    rawDepth,
                    _ZBufferParams
                );
            }


            float GetNormalDifference(
                float3 normalA,
                float3 normalB
            )
            {
                normalA = normalize(normalA);
                normalB = normalize(normalB);

                return
                    1.0 -
                    saturate(
                        dot(
                            normalA,
                            normalB
                        )
                    );
            }


            half4 Frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(
                    input
                );

                float2 uv =
                    input.texcoord;


                // -------------------------
                // 原始画面
                // -------------------------

                half4 sceneColor =
                    SAMPLE_TEXTURE2D_X(
                        _BlitTexture,
                        sampler_LinearClamp,
                        uv
                    );


                // -------------------------
                // 屏幕像素采样距离
                // -------------------------

                float2 texel =
                    (1.0 / _ScreenParams.xy)
                    * _Thickness;


                float2 uvL =
                    uv + float2(-texel.x, 0);

                float2 uvR =
                    uv + float2( texel.x, 0);

                float2 uvU =
                    uv + float2(0,  texel.y);

                float2 uvD =
                    uv + float2(0, -texel.y);


                // =========================
                // 1. DEPTH EDGE
                // =========================

                float depthC =
                    GetEyeDepth(uv);

                float depthL =
                    GetEyeDepth(uvL);

                float depthR =
                    GetEyeDepth(uvR);

                float depthU =
                    GetEyeDepth(uvU);

                float depthD =
                    GetEyeDepth(uvD);


                float depthDifference =
                    max(
                        max(
                            abs(depthC - depthL),
                            abs(depthC - depthR)
                        ),
                        max(
                            abs(depthC - depthU),
                            abs(depthC - depthD)
                        )
                    );


                // 防止远距离 Outline 灵敏度变化太大
                float relativeDepthDifference =
                    depthDifference /
                    max(depthC, 0.01);


                float depthEdge =
                    step(
                        _DepthThreshold,
                        relativeDepthDifference
                    );


                // =========================
                // 2. NORMAL EDGE
                // =========================

                float3 normalC =
                    SampleSceneNormals(uv);

                float3 normalL =
                    SampleSceneNormals(uvL);

                float3 normalR =
                    SampleSceneNormals(uvR);

                float3 normalU =
                    SampleSceneNormals(uvU);

                float3 normalD =
                    SampleSceneNormals(uvD);


                float normalDifference =
                    max(
                        max(
                            GetNormalDifference(
                                normalC,
                                normalL
                            ),
                            GetNormalDifference(
                                normalC,
                                normalR
                            )
                        ),
                        max(
                            GetNormalDifference(
                                normalC,
                                normalU
                            ),
                            GetNormalDifference(
                                normalC,
                                normalD
                            )
                        )
                    );


                float normalEdge =
                    step(
                        _NormalThreshold,
                        normalDifference
                    );


                // =========================
                // 3. 合并两种边
                // =========================

                float edge =
                    max(
                        depthEdge,
                        normalEdge
                    );


                // =========================
                // 4. 覆盖描边颜色
                // =========================

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
