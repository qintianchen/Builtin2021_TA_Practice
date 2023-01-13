using UnityEngine;

[ExecuteAlways]
public class TestLightDepthTextureExporting: MonoBehaviour
{
    public RenderTexture lightDepthTexture;
    public Material material;

    private void OnEnable()
    {
        GetComponent<Camera>().depthTextureMode = DepthTextureMode.Depth;
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material == null)
        {
            Graphics.Blit(src, dest);
            return;
        }
        
        material.SetTexture("_LightDepthTex", lightDepthTexture);
        Graphics.Blit(src, dest, material);
    }
}