Shader "Custom/shader_sampler_seperate"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Tex1 ("Tex1", 2D) = "white" {}
        _Tex2 ("Tex1", 2D) = "white" {}
        _Tex3 ("Tex1", 2D) = "white" {}
        _Tex4 ("Tex1", 2D) = "white" {}
        _Tex5 ("Tex1", 2D) = "white" {}
        _Tex6 ("Tex1", 2D) = "white" {}
        _Tex7 ("Tex1", 2D) = "white" {}
        _Tex8 ("Tex1", 2D) = "white" {}
        _Tex9 ("Tex1", 2D) = "white" {}
        _Tex10 ("Tex1", 2D) = "white" {}
        _Tex11 ("Tex1", 2D) = "white" {}
        _Tex12 ("Tex1", 2D) = "white" {}
        _Tex13 ("Tex1", 2D) = "white" {}
        _Tex14 ("Tex1", 2D) = "white" {}
        _Tex15 ("Tex1", 2D) = "white" {}
        _Tex16 ("Tex1", 2D) = "white" {}
        _Tex17 ("Tex1", 2D) = "white" {}
        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Pass
        {
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

            Texture2D _MainTex;
            SamplerState sampler_MainTex;
            float4 _MainTex_ST;
            Texture2D _Tex1 ;
            Texture2D _Tex2 ;
            Texture2D _Tex3 ;
            Texture2D _Tex4 ;
            Texture2D _Tex5 ;
            Texture2D _Tex6 ;
            Texture2D _Tex7 ;
            Texture2D _Tex8 ;
            Texture2D _Tex9 ;
            Texture2D _Tex10;
            Texture2D _Tex11;
            Texture2D _Tex12;
            Texture2D _Tex13;
            Texture2D _Tex14;
            Texture2D _Tex15;
            Texture2D _Tex16;
            Texture2D _Tex17;

            // sampler2D _MainTex;
            // float4 _MainTex_ST;
            // sampler2D _Tex1 ;
            // sampler2D _Tex2 ;
            // sampler2D _Tex3 ;
            // sampler2D _Tex4 ;
            // sampler2D _Tex5 ;
            // sampler2D _Tex6 ;
            // sampler2D _Tex7 ;
            // sampler2D _Tex8 ;
            // sampler2D _Tex9 ;
            // sampler2D _Tex10;
            // sampler2D _Tex11;
            // sampler2D _Tex12;
            // sampler2D _Tex13;
            // sampler2D _Tex14;
            // sampler2D _Tex15;
            // sampler2D _Tex16;
            // sampler2D _Tex17;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // fixed4 col = tex2D(_MainTex, i.uv);
                // col *= tex2D(_Tex1   , i.uv);
                // col *= tex2D(_Tex2   , i.uv);
                // col *= tex2D(_Tex3   , i.uv);
                // col *= tex2D(_Tex4   , i.uv);
                // col *= tex2D(_Tex5   , i.uv);
                // col *= tex2D(_Tex6   , i.uv);
                // col *= tex2D(_Tex7   , i.uv);
                // col *= tex2D(_Tex8   , i.uv);
                // col *= tex2D(_Tex9   , i.uv);
                // col *= tex2D(_Tex10  , i.uv);
                // col *= tex2D(_Tex11  , i.uv);
                // col *= tex2D(_Tex12  , i.uv);
                // col *= tex2D(_Tex13  , i.uv);
                // col *= tex2D(_Tex14  , i.uv);
                // col *= tex2D(_Tex15  , i.uv);
                // col *= tex2D(_Tex16  , i.uv);
                // col *= tex2D(_Tex17  , i.uv);

                fixed4 col = _MainTex.Sample(sampler_MainTex, i.uv);
                col *= _Tex1 .Sample(sampler_MainTex  , i.uv);
                col *= _Tex2 .Sample(sampler_MainTex  , i.uv);
                col *= _Tex3 .Sample(sampler_MainTex  , i.uv);
                col *= _Tex4 .Sample(sampler_MainTex  , i.uv);
                col *= _Tex5 .Sample(sampler_MainTex  , i.uv);
                col *= _Tex6 .Sample(sampler_MainTex  , i.uv);
                col *= _Tex7 .Sample(sampler_MainTex  , i.uv);
                col *= _Tex8 .Sample(sampler_MainTex  , i.uv);
                col *= _Tex9 .Sample(sampler_MainTex  , i.uv);
                col *= _Tex10.Sample(sampler_MainTex  , i.uv);
                col *= _Tex11.Sample(sampler_MainTex  , i.uv);
                col *= _Tex12.Sample(sampler_MainTex  , i.uv);
                col *= _Tex13.Sample(sampler_MainTex  , i.uv);
                col *= _Tex14.Sample(sampler_MainTex  , i.uv);
                col *= _Tex15.Sample(sampler_MainTex  , i.uv);
                col *= _Tex16.Sample(sampler_MainTex  , i.uv);
                col *= _Tex17.Sample(sampler_MainTex  , i.uv);
       
                return col;
            }
            ENDCG
        }
    }
}
