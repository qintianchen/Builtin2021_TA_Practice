using UnityEngine;

[ExecuteAlways]
public class VolumeLightingAndShadow : MonoBehaviour {
    private Matrix4x4 frustumCorners = Matrix4x4.identity;
    private Transform camTransform;
    private Camera cam;
    private RenderTexture marchingRT;
    private RenderTexture tempRT;

    public Material mat;
    [Range(0,5)]
    public int downSample=2;
    [Range(0f, 5f)]
    public float samplerScale = 1f;
    [Range(0,256)]
    public int rayMarchingStep=16;
    [Range(0f,100f)]
    public float maxRayLength=15f;
    [Range(0f, 2f)]
    public float volumetricLightIntenstiy = 0.05f;
    [Range(0f, 2f)]
    public float lightScatteringFactor = 0.5f;
    [Range(0f, 5f)]
    public float volumetricShadowIntenstiy = 0f;
    [Range(0f, 0.1f)]
    public float shadowAttenuation = 0.08f;
    [Range(0f, 1f)]
    public float minShadow = 0.5f;

    void Start () {
        camTransform = transform;
        cam = GetComponent<Camera>();
        cam.depthTextureMode = DepthTextureMode.Depth;
        mat.SetTexture("_DitherMap", GenerateDitherMap());
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {        
        //field of view
        float fov = cam.fieldOfView;
        //近裁面距离
        float near = cam.nearClipPlane;
        //横纵比
        float aspect = cam.aspect;
        //近裁面一半的高度
        float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);
        //向上和向右的向量
        Vector3 toRight = cam.transform.right * halfHeight * aspect;
        Vector3 toTop = cam.transform.up * halfHeight;

        //分别得到相机到近裁面四个角的向量
        //depth/dist=near/|topLeft|
        //dist=depth*(|TL|/near)
        //scale=|TL|/near
        Vector3 topLeft = camTransform.forward * near + toTop - toRight;
        float scale = topLeft.magnitude / near;

        topLeft.Normalize();
        topLeft *= scale;

        Vector3 topRight = camTransform.forward * near + toTop + toRight;
        topRight.Normalize();
        topRight *= scale;

        Vector3 bottomLeft = camTransform.forward * near - toTop - toRight;
        bottomLeft.Normalize();
        bottomLeft *= scale;

        Vector3 bottomRight = camTransform.forward * near - toTop + toRight;
        bottomRight.Normalize();
        bottomRight *= scale;

        frustumCorners.SetRow(0, bottomLeft);
        frustumCorners.SetRow(1, bottomRight);
        frustumCorners.SetRow(3, topRight);
        frustumCorners.SetRow(2, topLeft);

        mat.SetMatrix("_FrustumCornorsRay", frustumCorners);
        mat.SetInt("_RayMarchingStep", rayMarchingStep);
        mat.SetFloat("_MaxRayLength", maxRayLength);
        mat.SetFloat("_VolumetricLightIntensity", volumetricLightIntenstiy);
        mat.SetFloat("_VolumetricShadowIntenstiy", volumetricShadowIntenstiy);
        mat.SetFloat("_ScatteringFactor", lightScatteringFactor);
        mat.SetFloat("_MinShadow", minShadow);
        mat.SetFloat("_ShadowAttenuation", shadowAttenuation);

        marchingRT = RenderTexture.GetTemporary(Screen.width >> downSample, Screen.height >> downSample, 0, source.format);
        tempRT = RenderTexture.GetTemporary(Screen.width >> downSample, Screen.height >> downSample, 0, source.format);

        //计算阴影
        Graphics.Blit(source, marchingRT, mat, 0);

        //模糊阴影信息
        mat.SetVector("_Offsets", new Vector4(0, samplerScale, 0, 0));
        Graphics.Blit(marchingRT, tempRT,mat,1);
        mat.SetVector("_Offsets", new Vector4(samplerScale, 0, 0, 0));
        Graphics.Blit(tempRT, marchingRT, mat, 1);
        mat.SetVector("_Offsets", new Vector4(0, samplerScale, 0, 0));
        Graphics.Blit(marchingRT, tempRT, mat, 1);
        mat.SetVector("_Offsets", new Vector4(samplerScale, 0, 0, 0));
        Graphics.Blit(tempRT, marchingRT, mat, 1);

        //合并
        mat.SetTexture("_MarchingTex", marchingRT);
        Graphics.Blit(source, destination, mat, 2);

        RenderTexture.ReleaseTemporary(marchingRT);
        RenderTexture.ReleaseTemporary(tempRT);
    }

    //Guerrilla Games 分享 DitherMap
    private Texture2D GenerateDitherMap()
    {
        int texSize = 4;
        Texture2D ditherMap = new Texture2D(texSize, texSize, TextureFormat.Alpha8, false, true);
        ditherMap.filterMode = FilterMode.Point;
        Color32[] colors = new Color32[texSize * texSize];

        colors[0] = GetDitherColor(0.0f);
        colors[1] = GetDitherColor(8.0f);
        colors[2] = GetDitherColor(2.0f);
        colors[3] = GetDitherColor(10.0f);

        colors[4] = GetDitherColor(12.0f);
        colors[5] = GetDitherColor(4.0f);
        colors[6] = GetDitherColor(14.0f);
        colors[7] = GetDitherColor(6.0f);

        colors[8] = GetDitherColor(3.0f);
        colors[9] = GetDitherColor(11.0f);
        colors[10] = GetDitherColor(1.0f);
        colors[11] = GetDitherColor(9.0f);

        colors[12] = GetDitherColor(15.0f);
        colors[13] = GetDitherColor(7.0f);
        colors[14] = GetDitherColor(13.0f);
        colors[15] = GetDitherColor(5.0f);

        ditherMap.SetPixels32(colors);
        ditherMap.Apply();
        return ditherMap;
    }

    private Color32 GetDitherColor(float value)
    {
        byte byteValue = (byte)(value / 16.0f * 255);
        return new Color32(byteValue, byteValue, byteValue, byteValue);
    }
}
