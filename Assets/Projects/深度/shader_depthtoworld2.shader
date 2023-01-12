Shader "Custom/shader_depthtoworld2"
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
                float3 vectorWS: TEXCOORD2;
            };

            uniform float4x4 _CornerVectors;

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _CameraDepthTexture;

            v2f vert(appdata input)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(input.vertex);
                o.uv = TRANSFORM_TEX(input.uv, _MainTex);

                if (o.uv.x < 0.5 && o.uv.y < 0.5)
                {
                    // BL
                    o.vectorWS = _CornerVectors[2].xyz;
                }
                else if (o.uv.x > 0.5 && o.uv.y < 0.5)
                {
                    // BR
                    o.vectorWS = _CornerVectors[3].xyz;
                }
                else if (o.uv.x > 0.5 && o.uv.y > 0.5)
                {
                    // TR
                    o.vectorWS = _CornerVectors[1].xyz;
                }
                else
                {
                    // TL
                    o.vectorWS = _CornerVectors[0].xyz;
                }

                return o;
            }

            half4 frag(v2f input) : SV_Target
            {
                float3 vectorWS = input.vectorWS;
                float3 cameraPositionWS = _WorldSpaceCameraPos;
                float near = _ProjectionParams.y;
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, input.uv);
                float depthVS = LinearEyeDepth(depth);
                float3 ray = vectorWS * (depthVS / near);
                float3 positionWS = ray + cameraPositionWS;
                
                return half4(positionWS, 1);
            }
            ENDCG
        }
    }
}