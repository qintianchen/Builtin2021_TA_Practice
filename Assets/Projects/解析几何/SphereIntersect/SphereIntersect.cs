using UnityEngine;

public class SphereIntersect : MonoBehaviour
{
    public Vector3 viewAngle;

    private float planetRadius = 2.5f;
    private float atmosphereHeight = 1;

    private void OnDrawGizmos()
    {
        var viewDirWS = viewAngle.normalized;
        var viewPosition = new Vector3(0, planetRadius, 0);
        var intersectPoint = GetIntersectPointWithPlanet(viewDirWS);

        Gizmos.DrawLine(viewPosition, viewPosition + 10 * viewDirWS);
        Gizmos.DrawSphere(intersectPoint, 0.1f);
    }

    private Vector3 GetIntersectPointWithPlanet(Vector3 viewDirWS)
    {
        var a = viewDirWS.x;
        var b = viewDirWS.y;
        var c = viewDirWS.z;
        var h = atmosphereHeight;
        var r = planetRadius;

        var t1 = -b * r;
        var t2 = a * a + b * b + c * c;
        var t3 = Mathf.Sqrt(b * b * r * r + t2 * (2 * r * h + h * h));

        var t = t1 + t3;
        if (t < 0)
        {
            t = t1 - t3;
        }

        t /= t2;
        return new Vector3(a * t, b * t + r, c * t);
    }
}