using UnityEngine;

public class TestSimple : MonoBehaviour
{
    public Material material;
    public Mesh     mesh;

    private ComputeBuffer positionWSBuffer;

    private void Start()
    {
        var positionArray = new Vector4[10];

        for (int i = 0; i < 10; i++)
        {
            positionArray[i] = new Vector4(i, 0, i, 1);
        }

        positionWSBuffer = new ComputeBuffer(10, 4 * sizeof(float));
        positionWSBuffer.SetData(positionArray);
        material.SetBuffer("worldPositionList", positionWSBuffer);
    }

    private void Update()
    {
        Graphics.DrawMeshInstanced(mesh, 0, material, new Matrix4x4[10]);
    }
}
