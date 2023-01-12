Shader "Custom/PostProcessing/globalfog"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _FogDensity ("Fog Density", Float) = 1.0
        _FogColor ("Fog Color", Color) = (1, 1, 1, 1)
        _FogStart ("Fog Start", Float) = 0.0
        _FogEnd ("Fog End", Float) = 1.0
    }
    SubShader
    {
        CGINCLUDE
        #include "UnityCG.cginc"

        float4x4 _FrustumCornersRay;

        sampler2D _MainTex;
        half4 _MainTex_TexelSize;
        UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
        half _FogDensity;
        fixed4 _FogColor;
        float _FogStart;
        // float _FogEnd;

        struct v2f
        {
            float4 pos : SV_POSITION;
            half2 uv : TEXCOORD0;
            half2 uv_depth : TEXCOORD1;
            float4 interpolatedRay : TEXCOORD2;
        };

        v2f vert(appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            
            o.uv = v.texcoord;
            o.uv_depth = v.texcoord;

            #if UNITY_UV_STARTS_AT_TOP
            if (_MainTex_TexelSize.y < 0)
                o.uv_depth.y = 1 - o.uv_depth.y;
            #endif

            int index = 0;
            if (v.texcoord.x < 0.5 && v.texcoord.y < 0.5)
            {
                index = 0;
            }
            else if (v.texcoord.x > 0.5 && v.texcoord.y < 0.5)
            {
                index = 1;
            }
            else if (v.texcoord.x > 0.5 && v.texcoord.y > 0.5)
            {
                index = 2;
            }
            else
            {
                index = 3;
            }

            #if UNITY_UV_STARTS_AT_TOP
            if (_MainTex_TexelSize.y < 0)
                index = 3 - index;
            #endif

            o.interpolatedRay = _FrustumCornersRay[index];

            return o;
        }

        // 基于距离的深度
        // 注意这里如果开启了 MSAA，则会出现物体边缘着色异常的问题
        // 例如对于一个深色的木桶，附近的像素是白色的天空。由于开启了 MSAA，它会在边缘处（颜色来说是三角形的边处）进行平均
        // 导致深色木桶的边缘颜色变浅（融合了天空的颜色）
        // 但是该像素的深度值并不会改变，所以天空的颜色变成了雾色，但是这里的像素可能依然还是浅色
        half4 frag(v2f input) : SV_Target
        {
            float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, input.uv_depth);
            float linearDepth = Linear01Depth(depth);

            float fogDensity = linearDepth * _FogDensity;
            fogDensity = (fogDensity - _FogStart) / (1 - _FogStart);
            fogDensity = saturate(fogDensity);
            fogDensity = pow(fogDensity, 0.5);
            
            fixed4 finalColor = tex2D(_MainTex, input.uv);
            finalColor.rgb = lerp(finalColor.rgb, _FogColor.rgb, fogDensity);

            return half4(finalColor.rgb, 1);
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