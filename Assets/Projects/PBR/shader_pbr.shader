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

            v2f vert (appdata input)
            {
                v2f o;
                o.positionCS = UnityObjectToClipPos(input.positionOS);
                o.positionWS = mul(unity_ObjectToWorld, input.positionOS);
                o.uv = TRANSFORM_TEX(input.uv, _MainTex);
                o.normalWS = UnityObjectToWorldNormal(input.normalOS);
                return o;
            }

            float3 FresnelSchlick(float cosTheta, float3 F0)
            {
                return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
            } 

            float DistributionGGX(float3 N, float3 H, float roughness)
            {
                float a      = roughness*roughness;
                float a2     = a*a;
                float NdotH  = max(dot(N, H), 0.0);
                float NdotH2 = NdotH*NdotH;

                float nom   = a2;
                float denom = (NdotH2 * (a2 - 1.0) + 1.0);
                denom = UNITY_PI * denom * denom;

                return nom / denom;
            }

            float GeometrySchlickGGX(float NdotV, float roughness)
            {
                float r = (roughness + 1.0);
                float k = (r*r) / 8.0;

                float nom   = NdotV;
                float denom = NdotV * (1.0 - k) + k;

                return nom / denom;
            }
            float GeometrySmith(float3 N, float3 V, float3 L, float roughness)
            {
                float NdotV = max(dot(N, V), 0.0);
                float NdotL = max(dot(N, L), 0.0);
                float ggx2  = GeometrySchlickGGX(NdotV, roughness);
                float ggx1  = GeometrySchlickGGX(NdotL, roughness);

                return ggx1 * ggx2;
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
                albedo = float3(1, 0, 0);

                float vh = saturate(dot(viewDirWS, halfDir));
                float nv = saturate(dot(normalWS, viewDirWS));
                float nl = saturate(dot(normalWS, lightDirWS));
                float nh = saturate(dot(normalWS, halfDir));

                float3 f0 = unity_ColorSpaceDielectricSpec;
                float3 ks = f0;
                float3 kd = ((float3)1 - ks) * (1 - _Metallic); // 金属性越强，漫反射的程度越弱
                float roughness = _Roughness;
                float d = DistributionGGX(normalWS, halfDir, roughness);
                float g = GeometrySmith(normalWS, viewDirWS, lightDirWS, roughness);
                float3 f = FresnelSchlick(f0, nv);

                float3 diffuseColor = kd * albedo / UNITY_PI;
                float3 specularColor = (f * d * g) / (4 * nv * nl + 0.001);

                float3 finalColor = (diffuseColor + specularColor) * nl;
                return half4(finalColor, 1);
            }
            ENDCG
        }
    }
}
