Shader "Custom/shader_depth_1"
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
                float4 positionVS: TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata input)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(input.vertex);
                o.positionCS = o.vertex;
                o.positionVS = mul(UNITY_MATRIX_MV, input.vertex);
                o.uv = TRANSFORM_TEX(input.uv, _MainTex);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 positionNDC = i.positionCS / i.positionCS.w;

                return half4(positionNDC.z, 0, 0, 1);
                // return half4(i.positionCS.w, 0, 0, 1);
                // return half4(LinearEyeDepth(i.vertex.z), 0, 0, 1);
                // return half4(-i.positionVS.z / 10, 0, 0, 1);
            }
            ENDCG
        }
    }
}
