using UnityEngine;

public class RayMarching : MonoBehaviour
{
    public ComputeShader rayMarchingShader;
    
    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (rayMarchingShader != null)
        {
            
        }
        else
        {
            Graphics.Blit(src, dest);
        }
    }

    public class Shape
    {
        public enum ShapeType
        {
            Circle = 0,
        }

        /// <summary>
        /// Circle: size[0] = radius
        /// </summary>
        public Vector3 size;

        public Vector3 position;
    }
}
