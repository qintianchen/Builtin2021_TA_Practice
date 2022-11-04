Shader "Custom/PBR/shader_pbr"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Smoothness("Smoothness", Range (0, 1)) = 0.5
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
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 normal: TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Smoothness;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = v.normal;
                return o;
            }

            inline float3 Unity_SafeNormalize(float3 inVec)
            {
                float dp3 = max(0.001f, dot(inVec, inVec));
                return inVec * rsqrt(dp3);
            }

            inline half Pow5 (half x)
            {
                return x*x * x*x * x;
            }

            half DisneyDiffuse(half NdotV, half NdotL, half LdotH, half perceptualRoughness)
            {
                // half fd90 = 0.5 + 2 * LdotH * LdotH * perceptualRoughness;
                // // Two schlick fresnel term
                // half lightScatter   = (1 + (fd90 - 1) * Pow5(1 - NdotL));
                // half viewScatter    = (1 + (fd90 - 1) * Pow5(1 - NdotV));
                //
                // return lightScatter * viewScatter;
                return 0;
            }

            // Ref: http://jcgt.org/published/0003/02/03/paper.pdf
            inline float SmithJointGGXVisibilityTerm (float NdotL, float NdotV, float roughness)
            {
            #if 0
                // Original formulation:
                //  lambda_v    = (-1 + sqrt(a2 * (1 - NdotL2) / NdotL2 + 1)) * 0.5f;
                //  lambda_l    = (-1 + sqrt(a2 * (1 - NdotV2) / NdotV2 + 1)) * 0.5f;
                //  G           = 1 / (1 + lambda_v + lambda_l);

                // Reorder code to be more optimal
                half a          = roughness;
                half a2         = a * a;

                half lambdaV    = NdotL * sqrt((-NdotV * a2 + NdotV) * NdotV + a2);
                half lambdaL    = NdotV * sqrt((-NdotL * a2 + NdotL) * NdotL + a2);

                // Simplify visibility term: (2.0f * NdotL * NdotV) /  ((4.0f * NdotL * NdotV) * (lambda_v + lambda_l + 1e-5f));
                return 0.5f / (lambdaV + lambdaL + 1e-5f);  // This function is not intended to be running on Mobile,
                                                            // therefore epsilon is smaller than can be represented by half
            #else
                // Approximation of the above formulation (simplify the sqrt, not mathematically correct but close enough)
                float a = roughness;
                float lambdaV = NdotL * (NdotV * (1 - a) + a);
                float lambdaL = NdotV * (NdotL * (1 - a) + a);

            #if defined(SHADER_API_SWITCH)
                return 0.5f / (lambdaV + lambdaL + UNITY_HALF_MIN);
            #else
                return 0.5f / (lambdaV + lambdaL + 1e-5f);
            #endif

            #endif
            }

            inline float GGXTerm (float NdotH, float roughness)
            {
                float a2 = roughness * roughness;
                float d = (NdotH * a2 - NdotH) * NdotH + 1.0f; // 2 mad
                return UNITY_INV_PI * a2 / (d * d + 1e-7f); // This function is not intended to be running on Mobile,
                                                        // therefore epsilon is smaller than what can be represented by half
            }

            inline half3 FresnelTerm (half3 F0, half cosA)
            {
                half t = Pow5 (1 - cosA);   // ala Schlick interpoliation
                return F0 + (1-F0) * t;
            }
            inline half3 FresnelLerp (half3 F0, half3 F90, half cosA)
            {
                half t = Pow5 (1 - cosA);   // ala Schlick interpoliation
                return lerp (F0, F90, t);
            }

            half4 BRDF1_Unity_PBS(half3 diffColor, half3 specColor, half oneMinusReflectivity, half perceptualRoughness,float3 normal, float3 viewDir, UnityLight light, UnityIndirect gi)
            {
                float3 halfDir = Unity_SafeNormalize(float3(light.dir) + viewDir);

                half shiftAmount = dot(normal, viewDir);
                normal = shiftAmount < 0.0f ? normal + viewDir * (-shiftAmount + 1e-5f) : normal;

                float nv = saturate(dot(normal, viewDir)); // TODO: this saturate should no be necessary here
                float nl = saturate(dot(normal, light.dir));
                float nh = saturate(dot(normal, halfDir));

                half lv = saturate(dot(light.dir, viewDir));
                half lh = saturate(dot(light.dir, halfDir));

                // Diffuse term
                half diffuseTerm = DisneyDiffuse(nv, nl, lh, perceptualRoughness) * nl;

                // Specular term
                // HACK: theoretically we should divide diffuseTerm by Pi and not multiply specularTerm!
                // BUT 1) that will make shader look significantly darker than Legacy ones
                // and 2) on engine side "Non-important" lights have to be divided by Pi too in cases when they are injected into ambient SH
                float roughness = perceptualRoughness * perceptualRoughness;
                roughness = max(roughness, 0.002);
                float V = SmithJointGGXVisibilityTerm (nl, nv, roughness);
                float D = GGXTerm (nh, roughness);

                float specularTerm = V * D * UNITY_PI; // Torrance-Sparrow model, Fresnel is applied later

                specularTerm = max(0, specularTerm * nl);

                half surfaceReduction;
             
                surfaceReduction = 1.0 / (roughness * roughness + 1.0); // fade \in [0.5;1]
                specularTerm *= any(specColor) ? 1.0 : 0.0;

                half grazingTerm = saturate((1-perceptualRoughness) + (1 - oneMinusReflectivity));
                half3 color = diffColor * (gi.diffuse + light.color * diffuseTerm)
                    + specularTerm * light.color * FresnelTerm(specColor, lh)
                    + surfaceReduction * gi.specular * FresnelLerp(specColor, grazingTerm, nv);

                return half4(color, 1);
            }

            half4 frag(v2f i) : SV_Target
            {
                UnityLight light;
                light.color = _LightColor0;
                light.dir = _WorldSpaceLightPos0;

                // fixed4 col = tex2D(_MainTex, i.uv);
                half3 diffuseColor = 1;
                half3 specColor = 1;
                half oneMinusReflectivity = unity_ColorSpaceDielectricSpec.a;
                half smoothness = _Smoothness;
                float3 normal = normalize(i.normal);
                float3 viewDir = _WorldSpaceCameraPos;
                UnityIndirect gi = (UnityIndirect)0;
                gi.diffuse = 0.15f;
                gi.specular = 0;
                return BRDF1_Unity_PBS(diffuseColor, specColor, oneMinusReflectivity, 1 - smoothness, normal, viewDir, light, gi);
            }
            ENDCG
        }
    }
}