using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class Bloom : MonoBehaviour
{
    public                     Material material;
    [Range(0, 4)]       public int      iterations           = 3;
    [Range(0.2f, 3.0f)] public float    blurSpread           = 0.6f;
    [Range(1, 8)]       public int      downSample           = 2;
    [Range(0.0f, 4.0f)] public float    luminanceThreshold   = 0.6f;
    private static readonly    int      s_LuminanceThreshold = Shader.PropertyToID("_LuminanceThreshold");
    private static readonly    int      s_BlurSize           = Shader.PropertyToID("_BlurSize");
    private static readonly    int      s_Bloom              = Shader.PropertyToID("_Bloom");

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material != null)
        {
            material.SetFloat(s_LuminanceThreshold, luminanceThreshold);

            int width  = src.width / downSample;
            int height = src.height / downSample;

            var buffer0 = RenderTexture.GetTemporary(width, height, 0);
            buffer0.filterMode = FilterMode.Bilinear;
            
            Graphics.Blit(src, buffer0, material, 0);

            for (int i = 0; i < iterations; i++)
            {
                material.SetFloat(s_BlurSize, 1f + i * blurSpread);

                var buffer1 = RenderTexture.GetTemporary(width, height, 0);
                
                Graphics.Blit(buffer0, buffer1, material, 1);
                
                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
                buffer1 = RenderTexture.GetTemporary(width, height, 0);
                
                Graphics.Blit(buffer0, buffer1, material, 2);
                
                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
            }
            
            material.SetTexture(s_Bloom, buffer0);
            Graphics.Blit(src, dest, material, 3);
            RenderTexture.ReleaseTemporary(buffer0);
        }
        else
        {
            Graphics.Blit(src, dest);
        }
    }
}