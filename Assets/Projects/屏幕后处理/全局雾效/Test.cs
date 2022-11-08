using System;
using UnityEngine;

[ExecuteInEditMode]
public class Test : MonoBehaviour
{
    private void OnEnable()
    {
        GetComponent<Camera>().depthTextureMode |= DepthTextureMode.Depth;
    }

    private void OnDisable()
    {
        GetComponent<Camera>().depthTextureMode = DepthTextureMode.None;
    }
}
