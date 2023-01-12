using UnityEngine;

[ExecuteAlways]
public class AtmosphereOcclusion : MonoBehaviour
{
    public Material material;
    public RenderTexture lightDepthTexture;
    public Camera lightDepthCamera;

    private Camera thisCamera => GetComponent<Camera>();

    // private void OnEnable()
    // {
    //     // thisCamera.depthTextureMode = DepthTextureMode.Depth;
    // }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material == null)
        {
            Graphics.Blit(src, dest);
            return;
        }
        //
        material.SetFloat("_FOV", thisCamera.fieldOfView);
        material.SetFloat("_Aspect", thisCamera.aspect);
        material.SetTexture("_LightDepthTex", lightDepthTexture);
        material.SetMatrix("_Light_VP", GL.GetGPUProjectionMatrix(lightDepthCamera.projectionMatrix, false) * lightDepthCamera.worldToCameraMatrix);
        material.SetMatrix("_Light_V", lightDepthCamera.worldToCameraMatrix);

        Graphics.Blit(src, dest, material);
    }
}
