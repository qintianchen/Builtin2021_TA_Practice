#ifndef __SINGLE_SCATTERING_HELPER_H__
#define __SINGLE_SCATTERING_HELPER_H__

#include "UnityCG.cginc"
#include "UnityLightingCommon.cginc"

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
};

/**
 * \brief 屏幕空间转换到世界坐标的视线方向
 */
float3 ScreenSpacetoViewDirWS(float2 positionSS, float fov, float aspect, float near)
{
    float height = 2 * near * tan(fov / 2);
    float width = aspect * height;
    float3 viewDirCS = float3(width * (positionSS.x - 0.5), height * (positionSS.y - 0.5), near);
    return normalize(mul(unity_CameraToWorld, float4(viewDirCS, 0)).xyz);
}

/**
 * \param positionWS 世界坐标系转换为海拔高度
 */
float PositionWStoAltitude(float3 positionWS, AtmosphereParam atmosphereParam)
{
    return length(float3(0, atmosphereParam.planetRadius, 0) + positionWS) - atmosphereParam.planetRadius;
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

/**
 * \brief 根据海拔高度 height 和角度 theta （出射方向和入射方向的夹角），求解瑞利散射系数
 */
float3 GetRayleighScatteringRate(float height, float cosTheta, AtmosphereParam atmosphereParam)
{
    float phase = (3.0 * (1.0 + cosTheta * cosTheta)) / (16.0 * UNITY_PI);
    return atmosphereParam.scatteringRate_h0_rayleigh * exp(-height / atmosphereParam.height_rayleigh) * phase;
}

/**
 * \brief 根据海拔高度 height 和角度 theta （出射方向和入射方向的夹角），求解米氏散射系数
 */
float3 GetMieScatteringRate(float height, float cosTheta, AtmosphereParam atmosphereParam)
{
    float g = atmosphereParam.anisotropy_mie;
    float2 g2 = g * g;
    float denominator = 18.0 * UNITY_PI * (2.0 + g2) * (1.0 + g2 - 2.0 * g * cosTheta);
    denominator = pow(denominator, 1.5);

    float phase = (3.0 * (1.0 - g2) * (1.0 + cosTheta * cosTheta)) / denominator;
    return atmosphereParam.absorption_h0_mie * exp(-height / atmosphereParam.height_mie) * phase;
}

/**
 * \brief 根据海拔高度 height 和角度 theta （出射方向和入射方向的夹角），求解散射系数
 */
float3 GetScatteringRate(float height, float cosTheta, AtmosphereParam atmosphereParam)
{
    return GetRayleighScatteringRate(height, cosTheta, atmosphereParam) + GetMieScatteringRate(height, cosTheta, atmosphereParam);
}

/**
 * \brief 求解星球内部两点之间的光线传输率，方向 positionWS1 -> positionWS2
 */
float3 GetTransmissionRate(float3 positionWS1, float positionWS2)
{
    return 1;
}

/**
 * \brief 求解两点构成的线段在该方向 positionWS1 -> positionWS2 的光照贡献
 * \param ds positionWS1 到 positionWS2 的长度. 从外部传进来主要是为了避免重复计算
 */
float3 GetLightOfPath(float3 positionWS1, float3 positionWS2, float ds, AtmosphereParam atmosphereParam)
{
    float3 positionCenterWS = (positionWS1 + positionWS2) / 2; // 中点
    float altitude = PositionWStoAltitude(positionCenterWS, atmosphereParam); // 中点的海拔高度
    float3 lightDirWS = _WorldSpaceLightPos0; // 太阳光的方向
    float3 lightColor = _LightColor0;

    // 由于我们假设当前的环境是地表，所以从大气层内部发射的射线一定和星球有且仅有一个交点，定义为C点
    float3 positionCWS;
    float3 tempFloat3;
    GetIntersectPointWithSphere(positionWS1, lightDirWS, float3(0, -atmosphereParam.planetRadius, 0), atmosphereParam.planetRadius + atmosphereParam.atmosphereHeight, positionCWS, tempFloat3);

    float3 t1 = GetTransmissionRate(positionCWS, positionWS1);
    float3 s = GetScatteringRate(altitude, dot(-lightDirWS, positionWS2 - positionWS1), atmosphereParam);
    float3 t2 = GetTransmissionRate(positionWS1, positionWS2);

    return lightColor * s * ds;
}

#endif
