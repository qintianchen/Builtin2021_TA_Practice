using System;
using UnityEngine;

[RequireComponent(typeof(Camera))]
[ExecuteAlways]
[DisallowMultipleComponent]
public class Test_DepthToWorld2 : MonoBehaviour
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

    public Vector3 right;
    public Vector3 up;
    public Vector3 forward;

    public Material material;

    private void Update()
    {
        var transform1 = ThisCamera.transform;
        right   = transform1.right;
        up      = transform1.up;
        forward = transform1.forward;
    }

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
            var fov     = ThisCamera.fieldOfView * Mathf.Deg2Rad;
            var near    = ThisCamera.nearClipPlane;
            var aspect  = ThisCamera.aspect;

            var cameraTransform = ThisCamera.transform;
            var forward         = cameraTransform.forward;
            var up         = cameraTransform.up;
            var right         = cameraTransform.right;
            
            var height     = 2 * near * Mathf.Tan(fov / 2);
            var width      = height * aspect;
            var halfHeight = height / 2;
            var halfWidth  = width / 2;

            var TL = forward * near + halfHeight * up - halfWidth * right;
            var TR = forward * near + halfHeight * up + halfWidth * right;
            var BL = forward * near - halfHeight * up - halfWidth * right;
            var BR = forward * near - halfHeight * up + halfWidth * right;

            var cornerVectors = new Matrix4x4();
            cornerVectors.SetRow(0, TL);
            cornerVectors.SetRow(1, TR);
            cornerVectors.SetRow(2, BL);
            cornerVectors.SetRow(3, BR);
            
            material.SetMatrix("_CornerVectors", cornerVectors);
            Graphics.Blit(src, dest, material);
        }
    }
}