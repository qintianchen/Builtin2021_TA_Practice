Shader "Custom/shader_Skybox_single_scattering"
{
    Properties
    {
        _FOV("fov vertical", float) = 90
        _Aspect("aspect", float) = 2
        
        [Header(Scattering Param)]
        _PlanetRadius("星球半径", float) = 6400
        _AtmosphereHeight("大气层高度", float) = 1600
        _ScatteringRate_H0_Rayleigh("地表处瑞利散射系数", vector) = (1, 1, 1)
        _Height_Rayleigh("瑞利散射标定高度", float) = 8500
        _Scattering_H0_Mie("地表处米氏散射系数", vector) = (1, 1, 1)
        _Height_Mie("米氏散射标定高度", float) = 1200
        _Anisotropy_Mie("米氏散射各向异性参数", float) = 0.65
        _Absorption_H0_Mie("米氏散射吸收系数", vector) = (1, 1, 1)
        _Absorption_H0_Ozone("臭氧层吸收系数", vector) = (1, 1, 1)
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "helper.cginc"

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 positionSS: TEXCOORD1; // Screen Space
                float4 positionWS: TEXCOORD2; // World Space
            };

            float _FOV;
            float _Aspect;

            float _PlanetRadius;
            float _AtmosphereHeight;
            float4 _ScatteringRate_H0_Rayleigh;
            float _Height_Rayleigh;
            float4 _Scattering_H0_Mie;
            float _Height_Mie;
            float _Anisotropy_Mie;
            float4 _Absorption_H0_Mie;
            float4 _Absorption_H0_Ozone;

            v2f vert(appdata input)
            {
                v2f output = (v2f)0;
                output.positionCS = UnityObjectToClipPos(input.positionOS);
                output.positionSS = ComputeScreenPos(output.positionCS);
                output.positionWS = mul(unity_ObjectToWorld, float4(input.positionOS.xyz, 1));
                return output;
            }

            half4 frag(v2f input) : SV_Target
            {
                AtmosphereParam atmosphereParam;
                atmosphereParam.planetRadius = _PlanetRadius;
                atmosphereParam.atmosphereHeight = _AtmosphereHeight;
                atmosphereParam.scatteringRate_h0_rayleigh = _ScatteringRate_H0_Rayleigh.xyz * 1e-6;
                atmosphereParam.height_rayleigh = _Height_Rayleigh;
                atmosphereParam.scatteringRate_h0_mie = _Scattering_H0_Mie.xyz * 1e-6;
                atmosphereParam.height_mie = _Height_Mie;
                atmosphereParam.anisotropy_mie = _Anisotropy_Mie;
                atmosphereParam.absorption_h0_mie = _Absorption_H0_Mie.xyz * 1e-6;
                atmosphereParam.absorption_h0_ozone = _Absorption_H0_Ozone;

                float fov = _FOV / (UNITY_PI / 180);
                float aspect = _Aspect;
                float near = _ProjectionParams.y;
                float2 positionSS = (input.positionSS / input.positionSS.w).xy;

                // 当前像素的视线方向
                // float3 viewDirWS = ScreenSpacetoViewDirWS(positionSS, fov, aspect, near);
                float3 viewDirWS = normalize(input.positionWS);
                
                if(viewDirWS.y < 0) return 0;
                
                float3 intersectPositionWS; // PlanetSpace 
                float3 tmpFloat3;
                int count = GetIntersectPointWithSphere(
                    float3(0, 0, 0),
                    viewDirWS,
                    float3(0, -atmosphereParam.planetRadius, 0),
                    atmosphereParam.planetRadius + atmosphereParam.atmosphereHeight,
                    intersectPositionWS,
                    tmpFloat3);

                float stepCount = 64;
                float3 step = (float3(0, 0, 0) - intersectPositionWS) / stepCount;
                float ds = length(step);
                float3 finalColor = float3(0, 0, 0);
                for (int i = 0; i < stepCount; i++)
                {
                    float3 position1 = intersectPositionWS + step * i;
                    float3 position2 = position1 + step;
                    finalColor += GetLightOfPath(position1, position2, ds, atmosphereParam);
                }

                float altitude = PositionWStoAltitude(float3(0, 20000, 0), atmosphereParam);
                finalColor = float3(altitude / 60000.0, 0, 0);
                finalColor = pow(finalColor, 2.2);

                return half4(finalColor, 1);
            }
            ENDCG
        }
    }
}