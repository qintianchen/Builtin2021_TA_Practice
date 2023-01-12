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
        [Slide(0, 1)]_Anisotropy_Mie("米氏散射各向异性参数", float) = 0.65
        _Absorption_H0_Mie("米氏散射吸收系数", vector) = (1, 1, 1)
        _Absorption_H0_Ozone("臭氧层吸收系数", vector) = (1, 1, 1)
        
        _TransmittanceLUT("透视率LUT", 2D) = "white" {}
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
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

            sampler2D _TransmittanceLUT;
            float4 _TransmittanceLUT_ST;

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
                atmosphereParam.scatteringRate_h0_rayleigh = float3(5.802, 13.558, 33.1) * 1e-6;
                atmosphereParam.height_rayleigh = _Height_Rayleigh;
                atmosphereParam.scatteringRate_h0_mie = float3(3.996, 3.996, 3.996) * 1e-6;
                atmosphereParam.height_mie = _Height_Mie;
                atmosphereParam.anisotropy_mie = _Anisotropy_Mie;
                atmosphereParam.absorption_h0_mie = float3(4.4, 4.4, 4.4) * 1e-6;
                atmosphereParam.absorption_h0_ozone = _Absorption_H0_Ozone;

                float fov = _FOV * (UNITY_PI / 180);
                float aspect = _Aspect;
                float near = _ProjectionParams.y;
                float2 positionSS = (input.positionSS / input.positionSS.w).xy;

                // 当前像素的视线方向
                float3 viewDirWS = ScreenSpacetoViewDirWS(positionSS, fov, aspect, near);
                
                if(dot(viewDirWS, _WorldSpaceLightPos0) > 0.9999) return _LightColor0;
      
                float3 finalColor = float3(0, 0, 0);
                float eyePos = _WorldSpaceCameraPos;
                finalColor = GetSkyView(atmosphereParam, eyePos, viewDirWS, normalize(_WorldSpaceLightPos0), _TransmittanceLUT);
                
                return half4(finalColor, 1);
            }
            ENDCG
        }
    }
}