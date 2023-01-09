Shader "Custom/Billboard/shader_billboard"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Color", Color) = (1, 1, 1,1 )
        _VerticalBillboarding ("Vertical Restraints", Range(0, 1)) = 1
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
            Tags
            {
                "Queue" = "Transparent" "IgnoreProjector"="True" "RenderType" = "Transparent" "DisableBatching" = "True"
            }
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off

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
            float4 _Color;
            float _VerticalBillboarding;

            v2f vert(appdata input)
            {
                v2f o;
                o.uv = TRANSFORM_TEX(input.uv, _MainTex);

                float3 centerOS = 0;
                float3 viewDirOS = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
                float3 normalDirOS = viewDirOS - centerOS;
                normalDirOS.y = normalDirOS.y * _VerticalBillboarding;
                normalDirOS = normalize(normalDirOS);
                float3 upDirOS = abs(normalDirOS.y) > 0.999 ? float3(0, 0, 1) : float3(0, 1, 0);
                float3 rightDir = normalize(cross(upDirOS, normalDirOS));
                upDirOS = normalize(cross(normalDirOS, rightDir));
                float3 centerOffs = input.vertex.xyz - centerOS;
                float3 localPos = centerOS + rightDir * centerOffs.x + upDirOS * centerOffs.y + normalDirOS.z * centerOffs.z;
                o.vertex = UnityObjectToClipPos(localPos);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDCG
        }
    }
}