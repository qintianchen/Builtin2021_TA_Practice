Shader "Custom/PostProcessing/edgedetectionwithnormalanddepth"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _EdgeOnly("EdgeOnly", Float) = 1.0
        _EdgeColor("EdgeColor", Color) = (1, 1, 1, 1)
        _BackgroundColor("BackgroundColor", Color) = (1, 1, 1, 1)
        _SampleDistance("SampleDistance", Float) = 1
        _Sensitivity ("Sensitivity", Vector) = (1, 1, 1,1 )
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
            ZTest Always
            Cull Off
            ZWrite Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv[5] : TEXCOORD0;
            };

            sampler2D _MainTex;
            sampler2D _CameraDepthNormalsTexture;
            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;
            float _EdgeOnly;    
            float4 _EdgeColor;
            float4 _BackgroundColor;
            float _SampleDistance;
            float4 _Sensitivity;

            float CheckSame(float4 center, float4 sample)
            {
                half2 centerNormal = center.xy;
                float centerDepth = DecodeFloatRG(center.zw);
                float2 sampleNormal = sample.xy;
                float sampleDepth = DecodeFloatRG(sample.zw);

                float2 diffNormal = abs(centerNormal - sampleNormal) * _Sensitivity.x;
                int isSameNormal = (diffNormal.x + diffNormal.y) < 0.1;
                float diffDepth = abs(centerDepth - sampleDepth) * _Sensitivity.y;
                int isSameDepth = diffDepth < 0.1 * centerDepth;

                return isSameNormal * isSameDepth ? 1 : 0;
            }

            v2f vert(appdata_img v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                float2 uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                o.uv[0] = uv;
                o.uv[1] = uv + _MainTex_TexelSize.xy * half2(1, 1) * _SampleDistance;
                o.uv[2] = uv + _MainTex_TexelSize.xy * half2(-1, -1) * _SampleDistance;
                o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1, 1) * _SampleDistance;
                o.uv[4] = uv + _MainTex_TexelSize.xy * half2(1, -1) * _SampleDistance;

                return o;
            }

            fixed4 frag(v2f input) : SV_Target
            {
                float4 sample1 = tex2D(_CameraDepthNormalsTexture, input.uv[1]);
                float4 sample2 = tex2D(_CameraDepthNormalsTexture, input.uv[2]);
                float4 sample3 = tex2D(_CameraDepthNormalsTexture, input.uv[3]);
                float4 sample4 = tex2D(_CameraDepthNormalsTexture, input.uv[4]);

                float edge = 1;

                edge *= CheckSame(sample1, sample2);
                edge *= CheckSame(sample3, sample4);

                float4 withEdgeColor = lerp(_EdgeColor, tex2D(_MainTex, input.uv[0]), edge);
                fixed4 onlyEdgeColor = lerp(_EdgeColor, _BackgroundColor, edge);

                return lerp(withEdgeColor, onlyEdgeColor, _EdgeOnly);
            }
            ENDCG
        }
    }
}