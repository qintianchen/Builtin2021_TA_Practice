using System.Runtime.InteropServices;
#if UNITY_EDITOR
using UnityEditor;
#endif
using UnityEngine;

public class ComputeTransmittanceLut : MonoBehaviour
{
    public static ComputeTransmittanceLut instance => Object.FindObjectOfType<ComputeTransmittanceLut>();

    public ComputeShader computeShader;
    public RenderTexture renderTexture;

    [MenuItem("Tools/Compute Trans LUT")]
    public static void Run()
    {
        var rt = new RenderTexture(512, 512, 0);
        var shader = instance.computeShader;

        var width = rt.width;
        var height = rt.height;

        var kernelIndex = shader.FindKernel("CSMain");

        rt.enableRandomWrite = true;

        var size = Marshal.SizeOf<AtmosphereParam>();
        Debug.Log($"数据大小: {size} byte. width={width}");
        var buffer = new ComputeBuffer(1, Marshal.SizeOf<AtmosphereParam>());

        var param = new AtmosphereParam
        {
            planetRadius = 6400000,
            atmosphereHeight = 60000f,
            scatteringRate_h0_rayleigh = new Vector3(5.802f, 13.558f, 33.1f) * 0.000001f,
            height_rayleigh = 8000,
            scatteringRate_h0_mie = Vector3.one * 3.996f * 0.000001f,
            height_mie = 1200,
            anisotropy_mie = 0.8f,
            absorption_h0_mie = Vector3.one * 4.4f * 0.000001f,
            absorption_h0_ozone = new Vector3(0.65f, 1.881f, 0.085f) * 0.000001f,
            ozoneCenter = 25000f,
            ozoneHeight = 15000f,
        };
        
        buffer.SetData(new[] { param });

        shader.SetTexture(kernelIndex, "Result", rt);
        shader.SetBuffer(kernelIndex, "atmosphereParams", buffer);

        shader.Dispatch(kernelIndex, Mathf.CeilToInt(width / 8f), Mathf.CeilToInt(height / 8f), 1);

        Graphics.Blit(rt, instance.renderTexture);

        buffer.Release();
        rt.Release();

#if UNITY_EDITOR
        AssetDatabase.Refresh();
#endif
    }

    public struct AtmosphereParam
    {
        public float planetRadius;
        public float atmosphereHeight;
        public Vector3 scatteringRate_h0_rayleigh;
        public float height_rayleigh;
        public Vector3 scatteringRate_h0_mie;
        public float height_mie;
        public float anisotropy_mie;
        public Vector3 absorption_h0_mie;
        public Vector3 absorption_h0_ozone;
        public float ozoneCenter;
        public float ozoneHeight;
    }
}