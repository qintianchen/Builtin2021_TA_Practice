using UnityEngine;

[RequireComponent(typeof(Camera))]
[ExecuteAlways]
public class SingleScattering : MonoBehaviour
{
    private Camera thisCamera;
    
    private void OnEnable()
    {
        thisCamera = GetComponent<Camera>();
    }

    void Update()
    {
        var mat = RenderSettings.skybox;

        mat.SetFloat("_FOV", thisCamera.fieldOfView);
        mat.SetFloat("_Aspect", thisCamera.aspect);
    }
}
