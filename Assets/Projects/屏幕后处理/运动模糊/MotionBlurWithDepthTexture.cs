using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class MotionBlurWithDepthTexture : MonoBehaviour
{
    public Material material;

    [Range(0, 1)] public    float     blurSize = 0.5f;
    public                  Camera    camera;
    private                 Matrix4x4 previousViewProjectionMatrix;
    private static readonly int       s_BlurSize                           = Shader.PropertyToID("_BlurSize");
    private static readonly int       s_PreviousViewProjectionMatrix       = Shader.PropertyToID("_PreviousViewProjectionMatrix");
    private static readonly int       s_CurrentViewProjectionInverseMatrix = Shader.PropertyToID("_CurrentViewProjectionInverseMatrix");

    private void OnEnable()
    {
        // 需要用到深度纹理
        camera.depthTextureMode |= DepthTextureMode.Depth;
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material != null)
        {
            material.SetFloat(s_BlurSize, blurSize);
            
            material.SetMatrix(s_PreviousViewProjectionMatrix, previousViewProjectionMatrix);
            var currentViewProjectionMatrix        = camera.projectionMatrix * camera.worldToCameraMatrix;
            var currentViewProjectionInverseMatrix = currentViewProjectionMatrix.inverse;
            material.SetMatrix(s_CurrentViewProjectionInverseMatrix, currentViewProjectionInverseMatrix);
            previousViewProjectionMatrix = currentViewProjectionMatrix;
            
            Graphics.Blit(src, dest, material);
        }
        else
        {
            Graphics.Blit(src, dest);
        }
    }
}
