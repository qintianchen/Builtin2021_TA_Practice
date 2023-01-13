Shader "Custom/shader_testlightdepthexporting"
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
            };

            sampler2D _LightDepthTex;
            float4 _LightDepthTex_ST;

            sampler2D _CameraDepthTexture;
            float4 _CameraDepthTexture_ST;
            
            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float depthFromCurCamera = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
                float depthFromLastCamera = SAMPLE_DEPTH_TEXTURE(_LightDepthTex, i.uv);
                float dis = abs(depthFromCurCamera - depthFromLastCamera);

                
                // return half4(pow(depthFromCurCamera,1), 0, 0, 1);
                // return half4(depthFromLastCamera, 0, 0, 1);
                return half4(dis * 100, 0, 0, 1);
            }
            ENDCG
        }
    }
}
