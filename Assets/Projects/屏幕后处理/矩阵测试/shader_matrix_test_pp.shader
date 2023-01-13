Shader "Custom/MatrixTest_pp"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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

            float4x4 _VP_Matrix;
            float _FOV;
            float _Aspect;

            float3 UVtoViewDirWS(float2 uv, float fov, float aspect)
            {
                float near = _ProjectionParams.y;
                float height = 2 * near * tan(fov / 2);
                float width = height * aspect;
                float3 viewDirWS = float3(width * (uv.x - 0.5), height * (uv.y - 0.5), near);
                viewDirWS = mul(unity_CameraToWorld, float4(viewDirWS, 0));
                return normalize(viewDirWS).xyz;
            }

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float fov = _FOV;
                float aspect = _Aspect;
                float3 viewDirWS = UVtoViewDirWS(i.uv, fov, aspect);

                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
                float eyeDepth = LinearEyeDepth(depth);

                float3 worldPos = _WorldSpaceCameraPos + viewDirWS * depth;
                float4 clipPos = mul(_VP_Matrix, float4(worldPos, 1));
                clipPos /= clipPos.w;

                float depthFromClipPos = clipPos.z;

                // fixed4 col = tex2D(_MainTex, i.uv);

                // float newDepth = (1.0 - depth) * 1.0;
                // return float4(depth, 0, 0, 1);
                if (depthFromClipPos - depth > 0)
                {
                    return 1;
                }
                else
                {
                    return 0;
                }

                // return (depthFromClipPos - depth) * 1000000;
            }
            ENDCG
        }
    }
}