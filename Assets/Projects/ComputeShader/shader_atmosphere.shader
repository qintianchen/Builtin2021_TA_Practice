Shader "Hidden/Atmosphere"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	    dirToSun("DstToSun", Vector) = (1, 1, 1)
	    planetCentre("PlanetCentre", Vector) = (1, 1, 1)
	    atmosphereRadius("AtmosphereRadius", Float) = 1
	    planetRadius("PlanetRadius", Float) = 1
	    numInScatteringPoints("numInScatteringPoints", Int) = 1
	    numOpticalDepthPoints("numOpticalDepthPoints", Int) = 1
	    densityFalloff("densityFalloff", Float) = 1
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Math.cginc"

			struct appdata {
					float4 vertex : POSITION;
					float4 uv : TEXCOORD0;
			};

			struct v2f {
					float4 pos : SV_POSITION;
					float2 uv : TEXCOORD0;
					float3 viewVector : TEXCOORD1;
			};

			v2f vert (appdata input) {
					v2f output;
					output.pos = UnityObjectToClipPos(input.vertex);
					output.uv = input.uv;
					// Camera space matches OpenGL convention where cam forward is -z. In unity forward is positive z.
					// (https://docs.unity3d.com/ScriptReference/Camera-cameraToWorldMatrix.html)
					float3 viewVector = mul(unity_CameraInvProjection, float4(input.uv.xy * 2 - 1, 0, -1));
					output.viewVector = mul(unity_CameraToWorld, float4(viewVector,0));
					return output;
			}
			
			sampler2D _MainTex;
			sampler2D _CameraDepthTexture;

			float3 dirToSun = 5;
			float3 planetCentre = 0;
			float atmosphereRadius = 6;
			float planetRadius = 4;

			// Paramaters
			int numInScatteringPoints = 10;
			int numOpticalDepthPoints = 10;
			float densityFalloff = 13;

			float densityAtPoint(float3 densitySamplePoint) {
				float heightAboveSurface = length(densitySamplePoint - planetCentre) - planetRadius;
				float height01 = heightAboveSurface / (atmosphereRadius - planetRadius);
				float localDensity = exp(-height01 * densityFalloff) * (1 - height01);
				return localDensity;
			}
			
			float opticalDepth(float3 rayOrigin, float3 rayDir, float rayLength) {
				float3 densitySamplePoint = rayOrigin;
				float stepSize = rayLength / (numOpticalDepthPoints - 1);
				float opticalDepth = 0;

				for (int i = 0; i < numOpticalDepthPoints; i ++) {
					float localDensity = densityAtPoint(densitySamplePoint);
					opticalDepth += localDensity * stepSize;
					densitySamplePoint += rayDir * stepSize;
				}
				return opticalDepth;
			}
			
			float3 calculateLight(float3 rayOrigin, float3 rayDir, float rayLength) {
				float3 inScatterPoint = rayOrigin;
			    float stepSize = rayLength / (numInScatteringPoints - 1);
			    float inScatteredLight = 0;

			    for(int i = 0;i < numInScatteringPoints; i++)
			    {
			        float sunRayLength = raySphere(planetCentre, atmosphereRadius, inScatterPoint, dirToSun).y;
			        float sunRayOpticalDepth = opticalDepth(inScatterPoint, dirToSun, sunRayLength);
			        float viewRayOpticalDepth = opticalDepth(inScatterPoint, -rayDir, stepSize * i);
			        float transmittance = exp(-(sunRayOpticalDepth + viewRayOpticalDepth));
			        float localDensity = densityAtPoint(inScatterPoint);

			        inScatteredLight += localDensity * transmittance * stepSize;
			        inScatterPoint += rayDir * stepSize;
			    }

			    return inScatteredLight;
			}

			float4 frag (v2f i) : SV_Target
			{
			    float4 originalCol = tex2D(_MainTex, i.uv);
			    float sceneDepthNonLinear = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
			    float sceneDepth = LinearEyeDepth(sceneDepthNonLinear) * length(i.viewVector);

			    float3 rayOrigin = _WorldSpaceCameraPos;
			    float3 rayDir = normalize(i.viewVector);

			    float dstToSurface = sceneDepth;

			    float2 hitInfo = raySphere(planetCentre, atmosphereRadius, rayOrigin, rayDir);
			    float dstToAtmosphere = hitInfo.x;
			    float dstThroughAtmosphere = min(hitInfo.y, dstToSurface - dstToAtmosphere);

			    if(dstThroughAtmosphere > 0)
			    {
			        const float epsilon = 0.0001;
			        float3 pointInAtmosphere = rayOrigin + rayDir * (dstToAtmosphere + epsilon);
			        float light = calculateLight(pointInAtmosphere, rayDir, dstThroughAtmosphere - epsilon * 2);
			        return originalCol * (1 - light) + light;
			    }

			    return originalCol;
			}

			ENDCG
		}
	}
}
