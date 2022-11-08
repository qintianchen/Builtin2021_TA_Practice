using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class GlobalFog : MonoBehaviour
{
    public Material material;

    [Range(0, 10f)] public  float edgeSize          = 1f;
    [Range(0, 1f)]  public  float edgeOnly          = 0.0f;
    public                  Color edgeColor         = Color.black;
    public                  Color backgroundColor   = Color.white;
    private static readonly int   s_EdgeSize        = Shader.PropertyToID("_EdgeSize");
    private static readonly int   s_EdgeOnly        = Shader.PropertyToID("_EdgeOnly");
    private static readonly int   s_EdgeColor       = Shader.PropertyToID("_EdgeColor");
    private static readonly int   s_BackgroundColor = Shader.PropertyToID("_BackgroundColor");

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material != null)
        {
            material.SetFloat(s_EdgeSize, edgeSize);
            material.SetFloat(s_EdgeOnly, edgeOnly);
            material.SetColor(s_EdgeColor, edgeColor);
            material.SetColor(s_BackgroundColor, backgroundColor);
            Graphics.Blit(src, dest, material);
        }
        else
        {
            Graphics.Blit(src, dest);
        }
    }
}