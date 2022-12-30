Shader "Custom/shader_depthtoworld"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
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
                float4 positionCS: TEXCOORD1;
                
            };

            uniform float4x4 _VP_Inverse;

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _CameraDepthTexture;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.positionCS = o.vertex;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
                float w = LinearEyeDepth(depth);

                float4 positionNDC = float4(i.uv.x * 2 - 1, i.uv.y * 2 - 1, depth, 1);
                float4 positionCS = positionNDC * w;
                float4 positionWS = mul(_VP_Inverse, positionCS);
                positionWS /= positionWS.w; // 这里为什么 w 不是 1

                return half4(positionWS.xyz, 1);
            }
            ENDCG
        }
    }
}
