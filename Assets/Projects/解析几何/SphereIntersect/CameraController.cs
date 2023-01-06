using UnityEngine;

public class CameraController : MonoBehaviour
{
    public float moveSpeed = 0.1f;

    private void Start()
    {
        Application.targetFrameRate = 60;
    }

    private void Update()
    {
        if (Input.GetKey(KeyCode.W))
        {
            transform.Translate(new Vector3(0, 0, 1) * moveSpeed, Space.Self);
        }
        else if (Input.GetKey(KeyCode.S))
        {
            transform.Translate(new Vector3(0, 0, -1) * moveSpeed, Space.Self);
        }
        else if (Input.GetKey(KeyCode.D))
        {
            transform.Translate(new Vector3(1, 0, 0) * moveSpeed, Space.Self);
        }
        else if (Input.GetKey(KeyCode.A))
        {
            transform.Translate(new Vector3(-1, 0, 0) * moveSpeed, Space.Self);
        }

        if (Input.GetMouseButton(0))
        {
            var inputX = Input.GetAxis("Mouse X");
            var inputY = Input.GetAxis("Mouse Y");
        
            transform.RotateAround(transform.position, transform.TransformVector(new Vector3(0, 1, 0)), 0.1f * inputX );
            transform.RotateAround(transform.position, transform.TransformVector(new Vector3(1, 0, 0)), 0.1f * inputY );
        }
    }
}