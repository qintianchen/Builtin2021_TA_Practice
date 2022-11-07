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
        // Alpha 和 RGB 分开渲染是对于一些具有透明物体的场景来说比较有用
        // 假设我们只用一个 Pass，即在 RGB Pass 里面就将 Alpha 写入，此时 alpha 的最终值会受到 SrcAlpha 和 OneMinusSrcAlpha 的影响
        // 但是我们只想要保留原图中的 Alpha 值
        Pass
        {
            NAME "MOTIONBLUR_RGB"
            Blend SrcAlpha OneMinusSrcAlpha
            ColorMask RGB
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragRGB
            ENDCG
        }
        Pass
        {
            NAME "MOTIONBLUR_A"
            
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