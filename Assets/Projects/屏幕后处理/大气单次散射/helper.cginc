#ifndef __SINGLE_SCATTERING_HELPER_H__
#define __SINGLE_SCATTERING_HELPER_H__

#include "UnityCG.cginc"

struct AtmosphereParam
{
    float planetRadius;
    float atmosphereHeight;

    float3 scatteringRate_h0_rayleigh;
    float height_rayleigh;

    float3 scatteringRate_h0_mie;
    float height_mie;
    float anisotropy_mie;

    float3 absorption_h0_mie;
    float3 absorption_h0_ozone;

    float ozoneCenter;
    float ozoneHeight;
};

float3 RayleighCoefficient(in AtmosphereParam param, float h)
{
    const float3 sigma = float3(5.802, 13.558, 33.1) * 1e-6;
    float H_R = param.height_rayleigh;
    float rho_h = exp(-h / H_R);
    return sigma * rho_h;
}

float RayleiPhase(in AtmosphereParam param, float cos_theta)
{
    return (3.0 / (16.0 * UNITY_PI)) * (1.0 + cos_theta * cos_theta);
}

float3 MieCoefficient(in AtmosphereParam param, float h)
{
    const float3 sigma = (3.996 * 1e-6).xxx;
    float H_M = param.height_mie;
    float rho_h = exp(-(h / H_M));
    return sigma * rho_h;
}

float MiePhase(in AtmosphereParam param, float cos_theta)
{
    float g = param.anisotropy_mie;

    float a = 3.0 / (8.0 * UNITY_PI);
    float b = (1.0 - g * g) / (2.0 + g * g);
    float c = 1.0 + cos_theta * cos_theta;
    float d = pow(1.0 + g * g - 2 * g * cos_theta, 1.5);

    return a * b * (c / d);
}

float3 MieAbsorption(in AtmosphereParam param, float h)
{
    const float3 sigma = (4.4 * 1e-6).xxx;
    float H_M = param.height_mie;
    float rho_h = exp(-(h / H_M));
    return sigma * rho_h;
}

float3 OzoneAbsorption(in AtmosphereParam param, float h)
{
    // #define sigma_lambda (float3(0.650f, 1.881f, 0.085f)) * 1e-6
    // float center = param.OzoneLevelCenterHeight;
    // float width = param.OzoneLevelWidth;
    // float rho = max(0, 1.0 - (abs(h - center) / width));
    // return sigma_lambda * rho;
    return 1;
}

float3 Scattering(in AtmosphereParam param, float h, float3 lightDir, float3 viewDir)
{
    float cos_theta = dot(lightDir, viewDir);

    // float h = length(p); // - param.planetRadius;
    float3 rayleigh = RayleighCoefficient(param, h) * RayleiPhase(param, cos_theta);
    float3 mie = MieCoefficient(param, h) * MiePhase(param, cos_theta);

    return rayleigh + mie;
}

/**
 * \brief 屏幕空间转换到世界坐标的视线方向
 */
float3 ScreenSpacetoViewDirWS(float2 positionSS, float fov, float aspect, float near)
{
    float height = 2 * near * tan(fov / 2);
    float width = aspect * height;
    float3 viewDirCS = float3(width * (positionSS.x - 0.5), height * (positionSS.y - 0.5), near); // Camera Space
    return normalize(mul(unity_CameraToWorld, float4(viewDirCS, 0)).xyz);
}

/**
 * \brief 求解射线 (position, dir) 与球体 (spherePosition, sphereRadius) 的两个交点 (point1, point2)
 */
int GetIntersectPointWithSphere(float3 position, float3 dir, float3 spherePosition, float sphereRadius, out float3 point1, out float3 point2)
{
    const float a = position.x - spherePosition.x;
    const float b = position.y - spherePosition.y;
    const float c = position.z - spherePosition.z;
    const float m = dir.x;
    const float n = dir.y;
    const float o = dir.z;
    const float r = sphereRadius;

    const float ta = m * m + n * n + o * o;
    const float tb = 2 * (a * m + b * n + c * o);
    const float tc = a * a + b * b + c * c - r * r;

    const float z1 = tb * tb - 4 * ta * tc;

    point1 = float3(0, 0, 0);
    point2 = float3(0, 0, 0);

    if (z1 < 0)
    {
        return 0;
    }

    const float z2 = sqrt(z1);
    const float t1 = (-tb + z2) / (2 * ta);
    const float t2 = (-tb - z2) / (2 * ta);
    if (t1 > 0 && t2 > 0)
    {
        point1 = position + t1 * dir;
        point2 = position + t2 * dir;
        return 2;
    }

    if (t1 < 0 && t2 < 0)
    {
        return 0;
    }

    const float t = max(t1, t2);
    if (t > 0)
    {
        point1 = position + t * dir;
        return 1;
    }

    return 0;
}

// 计算天空颜色
float3 GetSkyView(in AtmosphereParam param, float3 eyePos, float3 viewDir, float3 lightDir, sampler2D transmittanceLUT)
{
    const int N_SAMPLE = 32;
    float3 color = float3(0, 0, 0);

    // 光线和大气层, 星球求交
    float3 intersectPoint;
    float3 tempFloat3;
    GetIntersectPointWithSphere(eyePos, viewDir, float3(0, -param.planetRadius, 0), param.planetRadius + param.atmosphereHeight, intersectPoint, tempFloat3);

    float dis = length(intersectPoint - eyePos);

    if (dis < 0) return 0;

    float ds = dis / float(N_SAMPLE);
    float3 p = eyePos + (viewDir * ds) * 0.5;
    float3 sunLuminance = 2;

    for (int i = 0; i < N_SAMPLE; i++)
    {
        float altitute = length(float3(0, param.planetRadius, 0) + p) - param.planetRadius;
        float3 s = Scattering(param, altitute, lightDir, viewDir);

        // 计算透视率
        float3 OP = float3(0, param.planetRadius, 0) + p; // OP
        float cos_theta = dot(lightDir, normalize(OP));
        float altitute0 = length(float3(0, param.planetRadius, 0) + p + viewDir * ds * 0.5) - param.planetRadius;
        float3 t1 = tex2D(transmittanceLUT, float2(cos_theta, altitute0));

        float cos_theta_2 = dot(float3(0, 1, 0), viewDir);
        float altitude_1 = length(p + viewDir * ds * 0.5 + float3(0, param.planetRadius, 0)) - param.planetRadius;
        float altitude_2 = length(p - viewDir * ds * 0.5 + float3(0, param.planetRadius, 0)) - param.planetRadius;
        float3 t2_1 = tex2D(transmittanceLUT, float2(cos_theta_2, altitude_1));
        float3 t2_2 = tex2D(transmittanceLUT, float2(cos_theta_2, altitude_2));
        float3 t2 = t2_2 / t2_1;
        
        // 单次散射
        float3 inScattering = t1 * 1 * s * ds * sunLuminance;
        color += inScattering;

        p += viewDir * ds;
    }

    return color;
}

#endif
