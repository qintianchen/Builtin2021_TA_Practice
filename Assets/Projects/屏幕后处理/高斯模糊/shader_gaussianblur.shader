Shader "Custom/PostProcessing/gaussianblur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurSize ("BlurSize", Float) = 1.0
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

        struct appdata
        {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
        };

        struct v2f
        {
            float4 vertex : SV_POSITION;
            float2 uv[5] : TEXCOORD0;
        };

        sampler2D _MainTex;
        float4 _MainTex_ST;
        float4 _MainTex_TexelSize;
        float _BlurSize;

        v2f vertBlurVertical(appdata v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            float2 uv = TRANSFORM_TEX(v.uv, _MainTex);
            // float2 uv = v.uv;

            o.uv[0] = uv;
            o.uv[1] = uv + float2(0, _MainTex_TexelSize.y * 1) * _BlurSize;
            o.uv[2] = uv - float2(0, _MainTex_TexelSize.y * 1) * _BlurSize;
            o.uv[3] = uv + float2(0, _MainTex_TexelSize.y * 2) * _BlurSize;
            o.uv[4] = uv - float2(0, _MainTex_TexelSize.y * 2) * _BlurSize;

            return o;  
        }

        v2f vertBlurHorizontal(appdata v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            float2 uv = TRANSFORM_TEX(v.uv, _MainTex);

            o.uv[0] = uv;
            o.uv[1] = uv + float2(_MainTex_TexelSize.x * 1, 0) * _BlurSize;
            o.uv[2] = uv - float2(_MainTex_TexelSize.x * 1, 0) * _BlurSize;
            o.uv[3] = uv + float2(_MainTex_TexelSize.x * 2, 0) * _BlurSize;
            o.uv[4] = uv - float2(_MainTex_TexelSize.x * 2, 0) * _BlurSize;

            return o;
        }

        fixed4 frag(v2f input) : SV_Target
        {
            float weight[3] = {0.4026, 0.2442, 0.0545};
            fixed3 sum = tex2D(_MainTex, input.uv[0]).rgb * weight[0];
            sum += tex2D(_MainTex, input.uv[1]).rgb * weight[1];
            sum += tex2D(_MainTex, input.uv[2]).rgb * weight[1];
            sum += tex2D(_MainTex, input.uv[3]).rgb * weight[2];
            sum += tex2D(_MainTex, input.uv[4]).rgb * weight[2];
            return fixed4(sum, 1);
        }
        ENDCG

        ZTest Always
        Cull Off
        ZWrite Off
        // 高斯函数具有可分离性，即 G(x,y)=G(x)*G(y)，所以我们可以将二维的高斯函数拆成两个一维的高斯函数分别做计算，这样计算的复杂度会从 N^2 变为 N，N为高斯卷积核的大小
        Pass
        {
            NAME "GAUSSIAN_BLUR_VERTICAL"
            
            CGPROGRAM
            #pragma vertex vertBlurVertical
            #pragma fragment frag
            ENDCG
        }
        Pass
        {
            NAME "GAUSSIAN_BLUR_HORIZONTAL"

            CGPROGRAM
            #pragma vertex vertBlurHorizontal  
            #pragma fragment frag
            ENDCG
        }
    }
    
    Fallback Off
}