using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class EdgeDetectionWithNormalAndDepth : MonoBehaviour
{
    public Material material;

    [Range(0, 1)] public float edgeOnly  = 0;
    
    public Color edgeColor         = Color.black;
    public Color backgroundColor   = Color.white;
    public float sampleDistance    = 1;
    public float sensitivityDepth  = 1;
    public float sensitivityNormal = 1;

    private void OnEnable()
    {
        GetComponent<Camera>().depthTextureMode |= DepthTextureMode.DepthNormals;
    }

    [ImageEffectOpaque]
    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material != null)
        {
            material.SetFloat("_EdgeOnly", edgeOnly);
            material.SetColor("_EdgeColor", edgeColor);
            material.SetColor("_BackgroundColor", backgroundColor);
            material.SetFloat("_SampleDistance", sampleDistance);
            material.SetVector("_Sensitivity", new Vector4(sensitivityNormal, sensitivityDepth, 0, 0));
            
            Graphics.Blit(src, dest, material);
        }
        else
        {
            Graphics.Blit(src, dest);
        }
    }
}
