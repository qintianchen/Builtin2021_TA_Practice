using UnityEngine;

[RequireComponent(typeof(Camera))]
[DisallowMultipleComponent]
[ExecuteAlways]
public class Test_Depth : MonoBehaviour
{
    public bool showColor;
    
    private Camera m_Camera;
    private Camera ThisCamera
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
    private RenderTexture colorRT;
    private RenderTexture depthRT;

    private void OnEnable()
    {
        ThisCamera.depthTextureMode = DepthTextureMode.DepthNormals;

        colorRT = new RenderTexture(Screen.width, Screen.height, 0);
        depthRT = new RenderTexture(Screen.width, Screen.height, 16, RenderTextureFormat.Depth);
        ThisCamera.SetTargetBuffers(colorRT.colorBuffer, depthRT.depthBuffer);
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (showColor)
        {
            Graphics.Blit(colorRT, dest);
        }
        else
        {
            Graphics.Blit(depthRT, dest);
        }
    }
}
