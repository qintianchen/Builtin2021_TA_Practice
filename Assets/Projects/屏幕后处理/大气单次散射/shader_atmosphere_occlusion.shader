// 后处理脚本
Shader "Custom/shader_atmosphere_occlusion"
{
    Properties
    {
        _MainTex("MainTex", 2D) = "white"{}
        //        _LightDepthTex ("LightDepthTex", 2D) = "white" {}
        //        _FOV("FOV", float) = 80
        //        _Aspect("Aspect", float) = 2
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

            float4x4 _Light_VP;
            float4x4 _Light_V;

            float3 UVtoViewDirWS(float2 uv, float fov, float aspect)
            {
                float near = _ProjectionParams.y;
                float height = 2 * near * tan(fov / 2);
                float width = aspect * height;
                float3 viewDirCS = float3(width * (uv.x - 0.5), height * (uv.y - 0.5), near);
                return normalize(mul(unity_CameraToWorld, float4(viewDirCS, 0)).xyz);
            }

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag(v2f input) : SV_Target
            {
                float fov = _FOV * (UNITY_PI / 180.0);
                float aspect = _Aspect;
                float3 viewDirWS = UVtoViewDirWS(input.uv, fov, aspect);
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, input.uv);
                float linearDepth = LinearEyeDepth(depth);
                float3 cameraPositionWS = _WorldSpaceCameraPos;

                float sampleCount = 32;
                float ds = linearDepth / sampleCount;

                float3 lightDS = float3(1, 1, 1) * 0.002;
                float3 finalColor = 1;

                for (int i = 0; i < sampleCount; i++)
                {
                    float3 curPositionWS = cameraPositionWS + viewDirWS * i * ds;
                    float4 curPositionCS = mul(_Light_VP, float4(curPositionWS, 1));
                    // float3 curPositionVS = mul(_Light_V, float4(curPositionWS, 1));
                    // curPositionCS = curPositionCS / curPositionCS.w;

                    float curLightDepth = curPositionCS.z;
                    // curLightDepth = -curPositionVS.z / 1000.0; // 光线相机的实际深度值

                    float2 lightUV = curPositionCS.xy * 0.5 + 1;
                    float lightDepth = tex2D(_LightDepthTex, lightUV);

                    if (curLightDepth < lightDepth)
                    {
                        // finalColor += lightDS * ds;
                        finalColor = 0;
                    }
                }

                float3 positionWS = cameraPositionWS + viewDirWS * linearDepth;
                float4 lightPositionCS = mul(_Light_VP, float4(positionWS, 1));
                // float3 lightPositionVS = mul(_Light_V, float4(positionWS, 1));
                lightPositionCS /= lightPositionCS.w;

                finalColor = 0;
                finalColor.r = lightPositionCS.z;
                
                // float2 lightUV = lightPositionCS.xy;
                // float lightDepth = tex2D(_LightDepthTex, lightUV);
                // float lightLinearDepth = lightPositionVS.z;
                // lightDepth = lightLinearDepth / 1000.0;

                // finalColor += tex2D(_MainTex, input.uv).xyz;
                // return float4(viewDirWS.yyy, 1);
                // return float4(-lightDepth, 0, 0, 1);
                return half4(finalColor, 1);
            }
            ENDCG
        }
    }
}