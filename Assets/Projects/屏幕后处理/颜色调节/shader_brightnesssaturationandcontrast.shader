Shader "Custom/PostProcessing/brightnesssaturationandcontrast"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Brightness("Brightness", Float) = 1
        _Saturation("Saturation", Float) = 1
        _Contrast("Contrast", Float) = 1
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

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Brightness;
            float _Saturation;
            float _Contrast;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                float2 uv = i.uv;
                fixed4 originalColor = tex2D(_MainTex, uv);

                float3 finalColor = originalColor.rgb;

                // 这里亮度，饱和度，对比度的应用顺序不一样会导致结果不一样。但是《Unity Shader入门精要》里面并没有说明为什么是按照亮度->饱和度->对比度的顺序去做
                // UPR 的做法是先 Contrast，再 HueShift，最后 Saturation，参考 LutBuilderLdr.shader
                
                // Apply Brightness
                finalColor *= _Brightness;

                // Apply Saturation
                float3 luminanceColor = Luminance(originalColor);
                finalColor = lerp(luminanceColor, finalColor, _Saturation);
                
                // Apply Contrast
                float3 avgColor = 0.5;
                finalColor = lerp(avgColor, finalColor, _Contrast);
               
                return half4(finalColor, 1);
            }
            ENDCG
        }
    }
}