#ifndef __HELPER_INCLUDED__
#define __HELPER_INCLUDED__

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

    const float z1 = tb * tb - 4 * ta * tc; // b^2 - 4ac

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

int GetIntersectPointDistanceWithSphere(float3 position, float3 dir, float3 spherePosition, float sphereRadius, out float t1, out float t2)
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

    if (z1 < 0)
    {
        return 0;
    }

    const float z2 = sqrt(z1);
    t1 = (-tb + z2) / (2 * ta);
    t2 = (-tb - z2) / (2 * ta);
    if (t1 > 0 && t2 > 0)
    {
        return 2;
    }

    if (t1 < 0 && t2 < 0)
    {
        return 0;
    }

    const float t = max(t1, t2);
    if (t > 0)
    {
        return 1;
    }

    return 0;
}

float3 UVtoViewDir(float2 uv, float near, float fov, float aspect)
{
    float height = 2 * near * tan(fov / 2);
    float width = aspect * height;

    float3 A = float3(0, 0, near);
    float3 B = float3((uv.x - 0.5) * width, (uv.y - 0.5) * height, 0);
    float3 C = A + B;

    return normalize(mul(unity_CameraToWorld, float4(C, 0)).xyz);
}

#endif
