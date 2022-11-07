using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class MotionBlur : MonoBehaviour
{
    public                  Material material;
    [Range(0, 0.9f)] public float    blurAmount = 0.5f;

    private                 RenderTexture accumulationTexture;
    private static readonly int           s_BlurAmount = Shader.PropertyToID("_BlurAmount");

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material != null)
        {
            if (accumulationTexture == null || accumulationTexture.width != src.width || accumulationTexture.height != src.height)
            {
                DestroyImmediate(accumulationTexture);
                accumulationTexture           = new RenderTexture(src.width, src.height, 0);
                accumulationTexture.hideFlags = HideFlags.HideAndDontSave;
                Graphics.Blit(src, accumulationTexture);
            }
            
            material.SetFloat(s_BlurAmount, 1 - blurAmount);
            
            Graphics.Blit(src, accumulationTexture, material);
            Graphics.Blit(accumulationTexture, dest);
        }
        else
        {
            Graphics.Blit(src, dest);
        }
    }

    private void OnDisable()
    {
        DestroyImmediate(accumulationTexture);
    }
}