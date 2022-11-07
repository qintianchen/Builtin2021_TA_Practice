Shader "Custom/PostProcessing/motionblur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurAmount ("BlurAmount", Float) = 1.0
        
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
            half2 uv : TEXCOORD0;
        };

        sampler2D _MainTex;
        float _BlurAmount;

        v2f vert(appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord; 
            return o;
        }

        fixed4 fragRGB(v2f i): SV_Target
        {
            return fixed4(tex2D(_MainTex, i.uv).rgb, _BlurAmount);
        }

        half4 fragA(v2f i): SV_Target
        {
            return tex2D(_MainTex, i.uv);
        }
     
        ENDCG

        ZTest Always
        Cull Off
        ZWrite Off
        // 高斯函数具有可分离性，即 G(x,y)=G(x)*G(y)，所以我们可以将二维的高斯函数拆成两个一维的高斯函数分别做计算，这样计算的复杂度会从 N^2 变为 N，N为高斯卷积核的大小
        // 总得来说，Bloom 分三步：分离亮度图，高斯模糊亮度图，混合亮度图到原图
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ColorMask RGB
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragRGB
            ENDCG
        }
        Pass
        {
            Blend One Zero
            ColorMask A
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragA
            ENDCG   
        }
    }

    Fallback Off
}