Shader "Custom/PostProcessing/edgedetection"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _EdgeSize("EdgeSize", Float) = 1.0
        _EdgeSize("_EdgeOnly", Float) = 1.0
        _EdgeColor("EdgeColor", Color) = (0, 0, 0, 1)
        _BackgroundColor("BackgroundColor", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
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

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv[9] : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;
            float _EdgeSize;
            float _EdgeOnly;
            float4 _EdgeColor;
            float4 _BackgroundColor;

            float GetLuminance(float4 color)
            {
                return 0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
            }

            float Sobel(v2f i)
            {
                const half Gx[9] = {-1, -2, -1, 0, 0, 0, 1, 2, 1};
                const half Gy[9] = {-1, 0, 1, -2, 0, 2, -1, 0, 1};

                half gradientX = 0;
                half gradientY = 0;
                for(int it = 0;it < 9;it++)
                {
                    half luminance = GetLuminance(tex2D(_MainTex, i.uv[it]));
                    gradientX += luminance * Gx[it]; // 计算水平梯度
                    gradientY += luminance * Gy[it]; // 计算垂直梯度
                }

                // 梯度应当是两者平方开根号，这里用绝对值来做近似以节省性能，实测两者相差不是很大
                // 注意这里的 gradientX 和 gradientY 的取值范围是超过[-1, 1]的，具体取决于 Gx 中最大值之和最小值之和。所以这里 totalGradient 的取值范围也就是两个区间的取值范围之和
                // 如果不做归一化，则大于1的部分都会在下面的 Lerp 函数里面当成 1 处理，如果做归一化，则原本在 1 之外的数字就变成了小于 1，此时边缘线的宽度就会减小
                half totalGradient = (abs(gradientX) + abs(gradientY)) * _EdgeSize; 
                // half totalGradient = sqrt(gradientX * gradientX + gradientY * gradientY); 
                half edge = 1 - totalGradient; // 梯度值越大（越接近白色），表示边缘区域，我们取反，这样返回的值越黑表示越是边界
                return edge;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                float2 uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.uv[0] = uv + _MainTex_TexelSize.xy * half2(-1, -1);
                o.uv[1] = uv + _MainTex_TexelSize.xy * half2(0, -1);
                o.uv[2] = uv + _MainTex_TexelSize.xy * half2(1, -1);
                o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1, 0);
                o.uv[4] = uv + _MainTex_TexelSize.xy * half2(0, 0);
                o.uv[5] = uv + _MainTex_TexelSize.xy * half2(1, 0);
                o.uv[6] = uv + _MainTex_TexelSize.xy * half2(-1, 1);
                o.uv[7] = uv + _MainTex_TexelSize.xy * half2(0, 1);
                o.uv[8] = uv + _MainTex_TexelSize.xy * half2(1, 1);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half edge = saturate(Sobel(i)); // 得到的是每个像素的颜色梯度，但是这里要做 Saturate，因为这里如果不做 Saturate，Lerp 会在超出边界的地方插值出奇怪的颜色

                fixed4 withEdgeColor = lerp(_EdgeColor, tex2D(_MainTex, i.uv[4]), edge);
                fixed4 onlyEdgeColor = lerp(_EdgeColor, _BackgroundColor, edge);
                return lerp(withEdgeColor, onlyEdgeColor, _EdgeOnly);
                // return half4(edge, edge, edge, 1);
                // return withEdgeColor;
            }
            ENDCG
        }
    }
}
