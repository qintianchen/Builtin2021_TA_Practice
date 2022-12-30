using UnityEngine;

[ExecuteAlways]
[RequireComponent(typeof(Camera))]
public class EffectForComputeShader : MonoBehaviour
{
    public Material material;

    private float theta;
    private float phi;
    private float speed = 0.01f;
    
    private void OnEnable()
    {
        GetComponent<Camera>().depthTextureMode = DepthTextureMode.Depth;
    }

    private void Update()
    {
        if (Input.GetMouseButton(0))
        {
            var mouseX = Input.GetAxis("Mouse X") * speed;
            var mouseY = Input.GetAxis("Mouse Y") * speed;

            theta += mouseX;
            phi   += mouseY;
            var radius = 20f;

            var vec = new Vector4(
                radius * Mathf.Sin(theta) * Mathf.Cos(phi),
                radius * Mathf.Sin(theta) * Mathf.Sin(phi),
                radius * Mathf.Cos(theta)
            );

            material.SetVector("dirToSun", vec);
        }
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
