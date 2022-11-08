using UnityEngine;

[ExecuteAlways]
[RequireComponent(typeof(Camera))]
public class VerticalFog : MonoBehaviour {
	public Material material;
	
	public                     Color  fogColor              = Color.white;
	[Range(0.0f, 3.0f)] public float  fogDensity            = 1.0f;
	public                     float  fogHeight             = 0.0f;
    private static readonly    int    s_FogDensity          = Shader.PropertyToID("_FogDensity");
    private static readonly    int    s_FogColor            = Shader.PropertyToID("_FogColor");
    private static readonly    int    s_FogHeight           = Shader.PropertyToID("_FogHeight");
    private static readonly    int    ViewProjectionInverse = Shader.PropertyToID("_ViewProjectionInverse");

    private                    Camera mCamera;

    private Camera camera
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
	    
    void OnEnable() {
		GetComponent<Camera>().depthTextureMode |= DepthTextureMode.Depth;
	}
	
	void OnRenderImage (RenderTexture src, RenderTexture dest) {
		if (material != null) {
			material.SetFloat(s_FogDensity, fogDensity);
			material.SetColor(s_FogColor, fogColor);
			material.SetFloat(s_FogHeight, fogHeight);

			var inverse = GL.GetGPUProjectionMatrix(camera.projectionMatrix, false) * camera.worldToCameraMatrix;
			inverse = inverse.inverse;
			material.SetMatrix(ViewProjectionInverse, inverse);
			material.SetMatrix("_WorldToCameraInverse", camera.worldToCameraMatrix.inverse);
			material.SetMatrix("_ProjectionInverse", GL.GetGPUProjectionMatrix(camera.projectionMatrix, false).inverse);

			Graphics.Blit (src, dest, material);
		} else {
			Graphics.Blit(src, dest);
		}
	}
}
