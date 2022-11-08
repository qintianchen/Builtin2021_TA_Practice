using UnityEngine;

[ExecuteAlways]
[RequireComponent(typeof(Camera))]
public class GlobalFog : MonoBehaviour {
	public Material material;

    private Camera myCamera;
	public Camera MyCamera {
		get {
			if (myCamera == null) {
				myCamera = GetComponent<Camera>();
			}
			return myCamera;
		}
	}

	private Transform myCameraTransform;
	public Transform cameraTransform {
		get {
			if (myCameraTransform == null) {
				myCameraTransform = MyCamera.transform;
			}

			return myCameraTransform;
		}
	}

	[Range(0.0f, 3.0f)]
	public float fogDensity = 1.0f;

	public Color fogColor = Color.white;

	[Range(0, 1)] public    float fogStart            = 0.0f;
    private static readonly int   s_FogDensity        = Shader.PropertyToID("_FogDensity");
    private static readonly int   s_FogColor          = Shader.PropertyToID("_FogColor");
    private static readonly int   s_FogStart          = Shader.PropertyToID("_FogStart");
    private static readonly int   s_FrustumCornersRay = Shader.PropertyToID("_FrustumCornersRay");

    void OnEnable() {
		MyCamera.depthTextureMode |= DepthTextureMode.Depth;
	}
	
	void OnRenderImage (RenderTexture src, RenderTexture dest) {
		if (material != null) {
			Matrix4x4 frustumCorners = Matrix4x4.identity;

			float fov = MyCamera.fieldOfView;
			float near = MyCamera.nearClipPlane;
			float aspect = MyCamera.aspect;

			float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);
			Vector3 toRight = cameraTransform.right * halfHeight * aspect;
			Vector3 toTop = cameraTransform.up * halfHeight;

			Vector3 topLeft = cameraTransform.forward * near + toTop - toRight;
			float scale = topLeft.magnitude / near;

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

			material.SetMatrix(s_FrustumCornersRay, frustumCorners);

			material.SetFloat(s_FogDensity, fogDensity);
			material.SetColor(s_FogColor, fogColor);
			material.SetFloat(s_FogStart, fogStart);

			Graphics.Blit (src, dest, material);
		} else {
			Graphics.Blit(src, dest);
		}
	}
}
