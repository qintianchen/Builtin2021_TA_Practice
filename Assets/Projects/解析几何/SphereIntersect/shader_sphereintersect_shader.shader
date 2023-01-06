Shader "Custom/shader_sphereintersect_shader"
{
    Properties
    {
        _MainTex("MainTex", 2D) = "white" {}
        _FOV ("FOV", float) = 90
        _Aspect("Aspect", float) = 2
        _PlanetRadius("PlanetRadius", float) = 4
        _AtmosphereRadius("_AtmosphereRadius", float) = 6
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
            float _FOV;
            float _Aspect;
            float _PlanetRadius;
            float _AtmosphereRadius;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 finalColor = 0;

                float fov = _FOV * (UNITY_PI / 180);
                float aspect = _Aspect;
                float near = _ProjectionParams.y;
                float3 position = _WorldSpaceCameraPos;
                float3 dir = UVtoViewDir(i.uv, near, fov, aspect);
                float3 spherePosition = float3(0, 0, 0);

                float3 point1;
                float3 point2;
                float3 point3;
                float3 point4;

                int pointCount = GetIntersectPointWithSphere(position, dir, spherePosition, _PlanetRadius, point1, point2);
                int pointCount2 = GetIntersectPointWithSphere(position, dir, spherePosition, _AtmosphereRadius, point3, point4);

                if (pointCount2 == 0)
                {
                    finalColor = 0;
                }
                else if (pointCount2 == 1)
                {
                    finalColor = length(position - point3) / (2 * _AtmosphereRadius);
                }
                else if (pointCount2 == 2)
                {
                    finalColor = length(point3 - point4) / (2 * _AtmosphereRadius);
                }

                if (pointCount == 1)
                {
                    finalColor -= length(position - point1) / (2 * _AtmosphereRadius);
                }
                else if (pointCount == 2)
                {
                    finalColor -= length(point2 - point1) / (2 * _AtmosphereRadius);
                }

                finalColor = pow(finalColor, 2.2);
                finalColor *= float4(1, 1, 3, 0);
                
                float4 mainColor = tex2D(_MainTex, i.uv);

                finalColor += mainColor;
                
                return finalColor;
            }
            ENDCG
        }
    }
}