using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraController : MonoBehaviour
{
    public GameObject targetCamera;
    public float velocityRotation;
    public List<GameObject> listGameObjects;
    private int currentIndex;
    void Start()
    {
        currentIndex = 0;
        if (listGameObjects.Count > 0)
        {
            targetCamera.transform.position = listGameObjects[currentIndex].transform.position;
        }
    }

    private void Update()
    {
        CheckControls();
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

        if (Input.GetKey(KeyCode.A))
            ChangedRotation(1);
        else if (Input.GetKey(KeyCode.D))
            ChangedRotation(-1);
    }

    private void ChangedTarget(int value)
    {
        GameObject target = listGameObjects[value];
        targetCamera.transform.position = target.transform.position;
    }

    private void ChangedRotation(int value)
    {
        targetCamera.transform.Rotate(0, value * velocityRotation, 0);
    }
}
