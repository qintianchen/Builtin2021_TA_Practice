using UnityEngine;

public class SphereIntersectShader : MonoBehaviour
{
    public Material material;

    private Camera thisCamera;
    public Camera ThisCamera
    {
        get
        {
            if (thisCamera == null)
            {
                thisCamera = GetComponent<Camera>();
            }

            return thisCamera;
        }
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material == null)
        {
            Graphics.Blit(src, dest);
            return;
        }
        
        material.SetFloat("_FOV", ThisCamera.fieldOfView);
        material.SetFloat("_Aspect", ThisCamera.aspect);
        Graphics.Blit(src, dest, material);        
    }
}
