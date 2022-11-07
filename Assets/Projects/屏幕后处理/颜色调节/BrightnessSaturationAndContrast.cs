using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class BrightnessSaturationAndContrast : MonoBehaviour
{
    public                  Material material;
    [Range(0, 3)] public    float    brightness   = 1.0f;
    [Range(0, 3)] public    float    saturation   = 1.0f;
    [Range(0, 3)] public    float    contrast     = 1.0f;
    private static readonly int      s_Brightness = Shader.PropertyToID("_Brightness");
    private static readonly int      s_Saturation = Shader.PropertyToID("_Saturation");
    private static readonly int      s_Contrast   = Shader.PropertyToID("_Contrast");

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material != null)
        {
            material.SetFloat(s_Brightness, brightness);
            material.SetFloat(s_Saturation, saturation);
            material.SetFloat(s_Contrast, contrast);
            Graphics.Blit(src, dest, material);
        }
        else
        {
            Graphics.Blit(src, dest);
        }
    }
}