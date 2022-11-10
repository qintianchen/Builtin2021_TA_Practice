using UnityEngine;

[RequireComponent(typeof(Camera))]
public class Test : MonoBehaviour
{
    public Material material;
    public Material material2;
    public Material materialIndirect;
    public Mesh     mesh;

    private void Update()
    {
        Test_DrawMesh();
    }

    private void Test_DrawMeshInstancedIndirect()
    {
        
    }

    private void Test_DrawMeshInstanced()
    {
        if (material == null || mesh == null || material2 == null)
        {
            return;
        }

        int resolution = 10;
        var matrices   = new Matrix4x4[resolution * resolution / 2];
        var matrices2   = new Matrix4x4[resolution * resolution / 2];

        for (int i = 0; i < resolution; i++)
        {
            for (int j = 0; j < resolution; j++)
            {
                var position = new Vector3(i * 2, 0, j * 2);
                var matrix   = Matrix4x4.TRS(position, Quaternion.identity, Vector3.one);
                if ((i + j) % 2 == 0)
                {
                    matrices[(i * resolution + j)/2] = matrix;
                }
                else
                {
                    matrices2[(i * resolution + j)/2] = matrix;
                }
            }
        }

        Graphics.DrawMeshInstanced(
            mesh: mesh,
            submeshIndex: 0,
            material: material,
            matrices: matrices,
            count: matrices.Length
        );
        
        Graphics.DrawMeshInstanced(
            mesh: mesh,
            submeshIndex: 0,
            material: material2,
            matrices: matrices2,
            count: matrices2.Length
        );
    }

    private void Test_DrawMesh()
    {
        if (material == null || mesh == null || material2 == null)
        {
            return;
        }

        int resolution = 10;
        var layer      = LayerMask.NameToLayer("Default");

        for (int i = 0; i < resolution; i++)
        {
            for (int j = 0; j < resolution; j++)
            {
                var position = new Vector3(i * 2, 0, j * 2);
                // 注意事项：
                // 并不会立即渲染，而是仅仅提交渲染命令到缓冲区里，然后跟随常规的渲染流程一起走
                Graphics.DrawMesh(mesh, position, Quaternion.identity, (i * resolution + j) < resolution * resolution / 2 ? material : material2, layer, Camera.current);
            }
        }
    }
}