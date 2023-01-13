using System;
using UnityEngine;

[RequireComponent(typeof(Camera))]
[DisallowMultipleComponent]
[ExecuteAlways]
public class MatrixTest : MonoBehaviour
{
    public Material material;
    public Material postProcessMaterial;

    private Camera thisCamera => GetComponent<Camera>();
    
    private void OnEnable()
    {
        thisCamera.depthTextureMode = DepthTextureMode.Depth;
    }

    private void Update()
    {
        var vp = GL.GetGPUProjectionMatrix(thisCamera.projectionMatrix, false) * thisCamera.worldToCameraMatrix;
        material.SetMatrix("_VP_Matrix", vp);
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (postProcessMaterial != null)
        {
            var vp = GL.GetGPUProjectionMatrix(thisCamera.projectionMatrix, false) * thisCamera.worldToCameraMatrix;
            postProcessMaterial.SetMatrix("_VP_Matrix", vp);

            postProcessMaterial.SetFloat("_FOV", thisCamera.fieldOfView);
            postProcessMaterial.SetFloat("_Aspect", thisCamera.aspect);
            
            Graphics.Blit(src, dest, postProcessMaterial);
        }
        else
        {
            Graphics.Blit(src, dest);
        }
    }
}
