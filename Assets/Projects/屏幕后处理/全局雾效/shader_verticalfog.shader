Shader "Custom/PostProcessing/verticalfog"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _FogDensity ("Fog Density", Float) = 1.0
        _FogColor ("Fog Color", Color) = (1, 1, 1, 1)
        _FogHeight ("Fog Height", Float) = 0.0
    }
    SubShader
    {
        CGINCLUDE
        #include "UnityCG.cginc"

        sampler2D _CameraDepthTexture;
        sampler2D _MainTex;
        half4 _MainTex_TexelSize;
        half _FogDensity;
        fixed4 _FogColor;
        float _FogHeight;
        float4x4 _ViewProjectionInverse;
        float4x4 _WorldToCameraInverse;
        float4x4 _ProjectionInverse;

        struct v2f
        {
            float4 pos : SV_POSITION;
            float3 worldPos : TEXCOORD3;
            half2 uv : TEXCOORD0;
            half2 uv_depth : TEXCOORD1;
            float4 interpolatedRay : TEXCOORD2;
        };

        v2f vert(appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.worldPos = mul(unity_ObjectToWorld, v.vertex);

            o.uv = v.texcoord;
            o.uv_depth = v.texcoord;

            #if UNITY_UV_STARTS_AT_TOP
            if (_MainTex_TexelSize.y < 0)
            {
                o.uv_depth.y = 1 - o.uv_depth.y;
            }
            #endif
            return o;
        }

        half4 frag(v2f input) : SV_Target
        {
            float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, input.uv_depth);
            float4 positionCS = float4(input.uv.x * 2 - 1, input.uv.y * 2 - 1, depth, 1);
            float4 positionVS = mul(_ProjectionInverse, positionCS);
            positionVS = positionVS / positionVS.w;
            float4 tmp = mul(_WorldToCameraInverse, positionVS);
            float4 positionWS = tmp;

            float fogDensity =  (_FogHeight - abs(positionWS.y)) / _FogHeight;
            fogDensity = clamp(fogDensity* _FogDensity, 0, 0.5) ;
            fogDensity = pow(fogDensity, 5);

            fixed4 finalColor = tex2D(_MainTex, input.uv);
            finalColor.rgb = lerp(finalColor.rgb, _FogColor.rgb, fogDensity);

            return half4(finalColor.rgb, 1);
            // return half4((half3)fogDensity, 1);
            // return half4(fogDensity,fogDensity, fogDensity, 1);
        }
        ENDCG

        Pass
        {
            ZTest Always Cull Off ZWrite Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }
    }
    FallBack Off
}