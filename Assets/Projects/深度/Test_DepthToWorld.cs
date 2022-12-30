using UnityEngine;

[RequireComponent(typeof(Camera))]
[ExecuteAlways]
[DisallowMultipleComponent]
public class Test_DepthToWorld : MonoBehaviour
{
    private Camera m_Camera;

    public Camera ThisCamera
    {
        get
        {
            if (m_Camera == null)
            {
                m_Camera = GetComponent<Camera>();
            }

            return m_Camera;
        }
    }

    public Material material;
    
    private void OnEnable()
    {
        ThisCamera.depthTextureMode = DepthTextureMode.Depth;
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material == null)
        {
            Graphics.Blit(src, dest);
        }
        else
        {
            var projectionMatrix = GL.GetGPUProjectionMatrix(ThisCamera.projectionMatrix, false);
            var vp = projectionMatrix * ThisCamera.worldToCameraMatrix;
            material.SetMatrix("_VP_Inverse", vp.inverse);
            Graphics.Blit(src, dest, material);
        }
    }
}
