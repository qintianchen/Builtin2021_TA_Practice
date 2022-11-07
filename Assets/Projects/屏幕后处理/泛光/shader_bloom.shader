Shader "Custom/PostProcessing/bloom"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Bloom ("Bloom", 2D) = "black" {}
        _LuminanceThreshold ("LuminanceThreshold", Float) = 0.5
        _BlurSize ("BlurSize", Float) = 1
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }
        LOD 100

        CGINCLUDE
        #include "UnityCG.cginc"

        struct v2f
        {
            float4 pos : SV_POSITION;
            float2 uv : TEXCOORD0;
        };

        struct v2fBloom
        {
            float4 pos : SV_POSITION;
            half4 uv : TEXCOORD0;
        };

        sampler2D _MainTex;
        sampler2D _Bloom;
        float4 _MainTex_ST;
        float4 _MainTex_TexelSize;
        float _LuminanceThreshold;
        float _BlurSize;

        // 提取高亮度的区域
        v2f vertExtractBright(appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord;
            return o;
        }

        fixed4 fragExtractBright(v2f i) :SV_Target
        {
            fixed4 c = tex2D(_MainTex, i.uv);
            fixed val = saturate(Luminance(c) - _LuminanceThreshold);
            return c * val;
        }

        v2fBloom vertBloom(appdata_img v)
        {
            v2fBloom o;

            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv.xy = v.texcoord;
            o.uv.zw = v.texcoord;

            return o;
        }

        fixed4 fragBloom(v2fBloom i) :SV_Target
        {
            return tex2D(_MainTex, i.uv.xy) + tex2D(_Bloom, i.uv.zw);
        }
        ENDCG

        ZTest Always
        Cull Off
        ZWrite Off
        // 高斯函数具有可分离性，即 G(x,y)=G(x)*G(y)，所以我们可以将二维的高斯函数拆成两个一维的高斯函数分别做计算，这样计算的复杂度会从 N^2 变为 N，N为高斯卷积核的大小
        // 总得来说，Bloom 分三步：分离亮度图，高斯模糊亮度图，混合亮度图到原图
        Pass
        {
            CGPROGRAM
            #pragma vertex vertExtractBright
            #pragma fragment fragExtractBright
            ENDCG
        }
        UsePass "Custom/PostProcessing/gaussianblur/GAUSSIAN_BLUR_VERTICAL"
        UsePass "Custom/PostProcessing/gaussianblur/GAUSSIAN_BLUR_HORIZONTAL"
        Pass
        {
            CGPROGRAM
            #pragma vertex vertBloom
            #pragma fragment fragBloom
            ENDCG
        }
    }

    Fallback Off
}