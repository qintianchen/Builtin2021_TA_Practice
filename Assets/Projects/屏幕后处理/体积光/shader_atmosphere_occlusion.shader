// 后处理脚本
Shader "Custom/shader_atmosphere_occlusion"
{
    Properties
    {
        _MainTex("MainTex", 2D) = "white"{}
        _LightDepthTex ("LightDepthTex", 2D) = "white" {}
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _CameraDepthTexture;
            float4 _CameraDepthTexture_ST;

            sampler2D _LightDepthTex;
            float4 _LightDepthTex_ST;

            float _FOV;
            float _Aspect;
            float _Near;
            float _Far;

            float4x4 _CurCameraToWorld;

            float4x4 _Light_VP;
            float4x4 _Light_V;

            float3 UVtoViewDirWS(float2 uv, float fov, float aspect, float near)
            {
                float height = 2 * near * tan(fov / 2);
                float width = aspect * height;
                float3 viewDirCS = float3(width * (uv.x - 0.5), height * (uv.y - 0.5), near);

                float3 nV = normalize(viewDirCS);
                
                return normalize(mul(_CurCameraToWorld, float4(viewDirCS, 0)).xyz);
            }

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float3 GetViewDirWS(float2 uv)
            {
                float fov = _FOV * (UNITY_PI / 180.0);
                float aspect = _Aspect;
                float near = _Near;
                float3 viewDirWS = UVtoViewDirWS(uv, fov, aspect, near);

                viewDirWS.x = -viewDirWS.x; // Unity 相机的 forward 为 (-1, 0, 0)

                return viewDirWS;
            }

            // 通过视角和
            float3 GetScatteringColor(float2 uv)
            {
                float fov = _FOV * (UNITY_PI / 180.0);
                float aspect = _Aspect;
                float near = _Near;
                float3 viewDirWS = GetViewDirWS(uv);

                float3 nN = normalize(mul(_CurCameraToWorld, float3(0, 0, -1)));
                float cos_theta = dot(viewDirWS, nN);

                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
                float linearDepth = LinearEyeDepth(depth);

                float3 cameraPositionWS = _WorldSpaceCameraPos;
                float3 finalColor = 0;
                float sampleCount = 256;
                float ds = linearDepth / sampleCount;
                for (int i = 0; i < sampleCount; i++)
                {
                    // 世界坐标
                    float3 curPositionWS = cameraPositionWS + viewDirWS * ds * i / cos_theta;

                    // Light 相机的 Clip Space
                    float4 curLightPositionCS = mul(_Light_VP, float4(curPositionWS, 1.0));

                    // Light 相机的 NDC
                    float4 curLightPositionNDC = curLightPositionCS / curLightPositionCS.w;

                    // Light 相机的 UV
                    float2 curLightUV = curLightPositionNDC.xy * 0.5 + 0.5;

                    // Light 相机的 深度图
                    float lightDepthFromDepthTex = SAMPLE_DEPTH_TEXTURE(_LightDepthTex, curLightUV);

                    // Light 相机的实际深度
                    float curLightDepth = curLightPositionNDC.z * 0.5 + 0.5;

                    if (curLightDepth < lightDepthFromDepthTex)
                    {
                        finalColor += 0.02 * ds;
                    }
                    else
                    {
                        // return -100000;
                    }
                }

                // return cameraPositionWS + viewDirWS * linearDepth/ cos_theta;
                return finalColor;
            }


            float3 TestLinearDepth(float2 uv)
            {
                float far = _Far;
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
                float linearDepth = LinearEyeDepth(depth);

                return linearDepth / far;
            }

            fixed4 frag(v2f input) : SV_Target
            {
                float3 finalColor = GetScatteringColor(input.uv);

                // float3 finalColor = TestLinearDepth(input.uv);

                // float3 finalColor = GetViewDirWS(input.uv);

                finalColor += tex2D(_MainTex, input.uv) * 0.6;

                return float4(finalColor.xyz, 1);
            }
            ENDCG
        }
    }
}