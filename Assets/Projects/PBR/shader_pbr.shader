Shader "Custom/PBR/shader_pbr"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Metallic("Metallic", Range(0, 1)) = 0.5
        _Roughness ("Roughness", Range(0, 1.0)) = 0.5
//        _F0 ("F0", Color) = (1, 1, 1, 1)
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
                float4 positionOS : POSITION;
                float3 normalOS: NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD2;
                float2 uv : TEXCOORD0;
                float3 normalWS: TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Metallic;
            float _Roughness;
            // float4 _F0;

            v2f vert (appdata v)
            {
                v2f o;
                o.positionCS = UnityObjectToClipPos(v.positionOS);
                o.positionWS = mul(unity_ObjectToWorld, v.positionOS);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normalWS = UnityObjectToWorldNormal(v.normalOS);
                return o;
            }

            float3 GetFresnelTerm(float3 f0, float VDotH)
            {
                float3 a = (float3)1 - f0;
                float b = pow(1 - VDotH, 5);
                // float b= 0;
                
                return f0 + a * b;
            }

            float GetNDFTerm(float roughness, float NDotH)
            {
                float r2 = roughness * roughness;
	            float d = (NDotH * r2 - NDotH) * NDotH + 1.0;
	            return r2 / (d * d * UNITY_PI);
            }

            float GetVisibilityTerm(float3 roughness, float NDotL, float NDotV)
            {
                float r2 = roughness * roughness;
	            float gv = NDotL * sqrt(NDotV * (NDotV - NDotV * r2) + r2);
	            float gl = NDotV * sqrt(NDotL * (NDotL - NDotL * r2) + r2);
	            return 0.5 / max(gv + gl, 0.00001);
            }

            half4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv;
                float3 positionWS = i.positionWS;
                float3 normalWS = normalize(i.normalWS);
                float3 cameraPositionWS = _WorldSpaceCameraPos;
                
                float3 lightDirWS = _WorldSpaceLightPos0; // 0, 0, -1
                float3 viewDirWS = normalize(cameraPositionWS - positionWS);
                float3 halfDir = normalize(lightDirWS + viewDirWS);
                float3 albedo = tex2D(_MainTex, uv);

                float vh = saturate(dot(viewDirWS, halfDir));
                float nv = saturate(dot(normalWS, viewDirWS));
                float nl = saturate(dot(normalWS, lightDirWS));
                float nh = saturate(dot(normalWS, halfDir));

                float3 f0 = lerp(unity_ColorSpaceDielectricSpec, (half4)1, _Metallic); // 金属性越强，各个分量的反射率越高
                float3 diffuseColor = lerp(albedo, 0, _Metallic); // 金属性越强，漫反射的量越少
                
                float roughness = _Roughness;

                float d = GetNDFTerm(roughness, nh);
                float g = GetVisibilityTerm(roughness, nl, nv);
                float3 f = GetFresnelTerm(f0, vh);
         
                diffuseColor *= saturate(dot(normalWS, lightDirWS));
                float3 specularColor = f * d * g * UNITY_PI * nl;

                float3 finalColor = (diffuseColor + specularColor) * 0.4;
                
                return half4(finalColor, 1);
            }
            ENDCG
        }
    }
}
