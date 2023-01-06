using UnityEngine;

public class CircleIntersect : MonoBehaviour
{
    [Range(0, 2.5f)]           public float height;
    [Range(0, 3.14159265359f)] public float angle;
    [Range(0, 31)]             public int   stepIndex;

    private int stepCount = 32;

    void Start()
    {
        Application.targetFrameRate = 60;
    }

    private void OnDrawGizmos()
    {
        float cosAngle       = Mathf.Cos(angle);
        float sinAngle       = Mathf.Sin(angle);
        var   point          = new Vector3(0, height, 0);
        var   intersectPoint = GetIntersectWithCircle(2.5f, height, angle);
        intersectPoint.z = 0;
        float length   = (intersectPoint - point).magnitude;
        var   newPoint = point + length * ((stepIndex + 0.5f) / stepCount) * new Vector3(sinAngle, cosAngle, 0);
        newPoint.z = 0;
        float newLength = (newPoint - point).magnitude;
        var   lengthC = LawOfCosine(height, newLength, Mathf.PI - angle);
        
        // 垂直线
        Gizmos.DrawLine(new Vector3(0, 0, 0), point);

        // 相交线
        Gizmos.DrawLine(point, intersectPoint);

        var originalColor = Gizmos.color;
        Gizmos.color = Color.red;

        Gizmos.DrawLine(point, newPoint);
        Gizmos.DrawLine(new Vector3(0, 0, 0), newPoint.normalized * lengthC);

        Gizmos.color = originalColor;
    }

    private float LawOfCosine(float a, float b, float angle)
    {
        float c2 = a * a + b * b - 2 * a * b * Mathf.Cos(angle);
        return Mathf.Sqrt(c2);
    }

    private Vector3 GetIntersectWithCircle(float radius, float height, float angle)
    {
        float cos_theta = Mathf.Cos(angle);
        float sin_theta = Mathf.Sin(angle);

        float a = -height * cos_theta;
        float b = Mathf.Sqrt(height * height * cos_theta * cos_theta - height * height + radius * radius);

        float t = a + b;
        if (t < 0)
        {
            t = a - b;
        }

        float x = t * sin_theta;
        float y = height + t * cos_theta;

        return new Vector3(x, y, 0);
    }
}