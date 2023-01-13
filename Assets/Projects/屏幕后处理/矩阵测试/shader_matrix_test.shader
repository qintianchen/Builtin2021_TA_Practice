Shader "Custom/MatrixTest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

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
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };
            
            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4x4 _VP_Matrix;
            
            v2f vert (appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);
                
                // float3 vertex = v.vertex.xyz;
                // vertex = mul(unity_ObjectToWorld, float4(vertex, 1.0)); 
                // o.vertex = mul(_VP_Matrix, float4(vertex, 1.0));
                
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = v.normal;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 normal = normalize(i.normal);
                fixed4 col = tex2D(_MainTex, i.uv);
                col *= dot(_WorldSpaceLightPos0, normal);
                return col;
            }
            ENDCG
        }
    }
}
