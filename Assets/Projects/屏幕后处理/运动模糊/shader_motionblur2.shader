Shader "Custom/PostProcessing/shader_motionblur2"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurSize("BlurSize", float) = 1
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
            float4 vertex : SV_POSITION;
            float2 uv : TEXCOORD0;
            float2 uv_depth : TEXCOORD1;
        };

        sampler2D _MainTex;
        float4 _MainTex_ST;
        float4 _MainTex_TexelSize;
        sampler2D _CameraDepthTexture;
        float _BlurSize;
        float4x4 _CurrentViewProjectionInverseMatrix;
        float4x4 _PreviousViewProjectionMatrix;

        v2f vert(appdata_img v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            
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

        // fix: 实测当汽车倒退的时候，画面会出现严重的抖动现象，_BlurSize 越大越明显，原因未知
        fixed4 frag(v2f i) : SV_Target
        {
            float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth);
            float4 positionVS = float4(i.uv.x * 2 - 1, i.uv.y * 2 - 1, depth * 2 - 1, 1); // position In View Space
            float4 tmp = mul(_CurrentViewProjectionInverseMatrix, positionVS);
            float4 positionWS = tmp / tmp.w;

            float4 currentPositionVS = positionVS;
            float4 previousPositionVS = mul(_PreviousViewProjectionMatrix, positionWS);
            previousPositionVS /= previousPositionVS.w;

            float2 velocity = (currentPositionVS.xy - previousPositionVS.xy) / 2.0f;

            float2 uv = i.uv;
            float4 c = tex2D(_MainTex, uv);
            uv += velocity * _BlurSize * _MainTex_TexelSize.xy * 24;
            for (int it = 1; it < 3; it++, uv += velocity * _BlurSize * _MainTex_TexelSize.xy * 24)
            {
                float4 currentColor = tex2D(_MainTex, uv);
                c += currentColor;
            }

            c /= 3;

            return fixed4(c.rgb, 1);
        }
        ENDCG


        Pass
        {
            ZTest Always
            Cull Off
            ZWrite Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }
    }
    
    Fallback Off
}