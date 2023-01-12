using UnityEngine;

[ExecuteAlways]
public class Camera_LightDepthGenerater : MonoBehaviour
{
    public Light sun;
    public Vector3 center;
    public float distance;

    public Material material;

    private void OnEnable()
    {
        GetComponent<Camera>().depthTextureMode = DepthTextureMode.Depth;
    }

    private void Update()
    {
        transform.position = center - sun.transform.forward * distance;
        transform.LookAt(center);
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material != null)
        {
            Graphics.Blit(src, dest, material);
        }
        else
        {
            Graphics.Blit(src, dest);
        }
    }
}
