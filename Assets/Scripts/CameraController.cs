using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraController : MonoBehaviour
{
    public float mouseSensitivity;
    public float minPitch;
    public float maxPitch;

    public float zoomSpeed;
    public float minFOV, maxFOV, heightCompensation;
    public GameObject targetCamera;
    public List<GameObject> listGameObjects;
    private int currentIndex;
    private float pitch; // rotación vertical acumulada
    private float yValue;

    void Start()
    {
        yValue = 0;
        pitch = 0;

        currentIndex = 0;
        if (listGameObjects.Count > 0)
        {
            targetCamera.transform.position = listGameObjects[currentIndex].transform.position;
        }
    }

    private void Update()
    {
        CheckControls();
        checkZoom();
        CheckMouseLook();
    }

    private void CheckControls()
    {
        if (Input.GetKeyDown(KeyCode.UpArrow))
        {
            if (currentIndex == listGameObjects.Count - 1)
                return;
            else
                currentIndex++;

            ChangedTarget(currentIndex);
        }
        else if (Input.GetKeyDown(KeyCode.DownArrow))
        {
            if (currentIndex == 0)
                return;
            else
                currentIndex--;

            ChangedTarget(currentIndex);
        }
    }

    private void checkZoom()
    {
        float scroll = Input.GetAxis("Mouse ScrollWheel");
        Camera.main.fieldOfView -= scroll * zoomSpeed;
        Camera.main.fieldOfView = Mathf.Clamp(Camera.main.fieldOfView, minFOV, maxFOV);
    }

    

    private void ChangedTarget(int value)
    {
        GameObject target = listGameObjects[value];
        targetCamera.transform.position = target.transform.position;
    }

    private void CheckMouseLook()
    {
        if (Input.GetMouseButton(1)) // botón derecho presionado
        {
            float mouseY = Input.GetAxis("Mouse Y");
            float mouseX = Input.GetAxis("Mouse X");

            pitch -= mouseY * mouseSensitivity;
            pitch = Mathf.Clamp(pitch, minPitch, maxPitch);

            yValue += mouseX * mouseSensitivity;

            ApplyRotation();
        }
    }

    private void ApplyRotation()
    {
        targetCamera.transform.rotation = Quaternion.Euler(pitch, yValue,0);
    }
}
