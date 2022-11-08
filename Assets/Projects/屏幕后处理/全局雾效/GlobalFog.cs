using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class GlobalFog : MonoBehaviour
{
    public  Material material;
    private Camera   mCamera;
    private Transform cameraTransform => camera.transform;
    public Camera camera
    {
        get
        {
            if (mCamera == null)
            {
                mCamera = GetComponent<Camera>();
            }

            return mCamera;
        }
    }

    [Range(0, 3)] public float fogDensity = 1f;
    public               Color fogColor   = Color.white;
    public               float fogStart   = 0f;
    public               float fogEnd     = 2f;

    private void OnEnable()
    {
        camera.depthTextureMode |= DepthTextureMode.Depth;
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material != null)
        {
            Matrix4x4 frustumCorners = Matrix4x4.identity;

            float   fov        = camera.fieldOfView;
            float   near       = camera.nearClipPlane;
            float   far        = camera.farClipPlane;
            float   aspect     = camera.aspect;
            
            float   halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);
            Vector3 toRight    = cameraTransform.right * halfHeight * aspect;
            Vector3 toTop      = cameraTransform.up * halfHeight;
            
            Vector3 topLeft    = cameraTransform.forward * near + toTop - toRight;
            float   scale      = topLeft.magnitude / near;
            topLeft.Normalize();
            topLeft *= scale;

            Vector3 topRight = cameraTransform.forward * near + toRight + toTop;
            topRight.Normalize();
            topRight *= scale;

            Vector3 bottomLeft = cameraTransform.forward * near - toTop - toRight;
            bottomLeft.Normalize();
            bottomLeft *= scale;

            Vector3 bottomRight = cameraTransform.forward * near + toRight - toTop;
            bottomRight.Normalize();
            bottomRight *= scale;

            frustumCorners.SetRow(0, bottomLeft);
            frustumCorners.SetRow(1, bottomRight);
            frustumCorners.SetRow(2, topRight);
            frustumCorners.SetRow(3, topLeft);

            material.SetMatrix("_FrustumCornersRay", frustumCorners);
            material.SetMatrix("_ViewProjectionInverseMatrix", (camera.projectionMatrix * camera.worldToCameraMatrix).inverse);

            material.SetFloat("_FogDensity", fogDensity);
            material.SetColor("_FogColor", fogColor);
            material.SetFloat("_FogStart", fogStart);
            material.SetFloat("_FogEnd", fogEnd);

            Graphics.Blit(src, dest, material);
        }
        else
        {
            Graphics.Blit(src, dest);
        }
    }
}