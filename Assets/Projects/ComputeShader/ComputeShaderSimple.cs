using UnityEngine;

/// <summary>
/// Render simple shape using compute shader on update
/// </summary>
public class ComputeShaderSimple : MonoBehaviour
{
    public ComputeShader computeShader;
    public ComputeBuffer computeBuffer;

    private void Update()
    {
        computeShader.Dispatch(0, 1, 1, 1);
    }
}
