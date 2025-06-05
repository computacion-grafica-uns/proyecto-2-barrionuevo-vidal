using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EscenaB_CameraController : MonoBehaviour
{
    public enum CameraMode { FirstPerson, Orbital }
    public CameraMode mode;
    public float mouseSensitivity = 100f;

    // camara orbital
    public float zoomSpeed, radius, pitchMin, pitchMax,minFOV, maxFOV;
    public Vector3 centerPoint;
    // camara primera persona
    public float moveSpeed, heightCameraFirstPerson;

    private float pitch, yaw;

    void Start()
    {
        pitch = 20f;
        yaw = 0f;
        UpdateAnglesOrbital();
    }

    private void Update()
    {
        CheckControls();


        switch (mode)
        {
            case CameraMode.FirstPerson:
                Camera.main.fieldOfView = maxFOV;
                CheckControlFirstPerson();
                break;
            case CameraMode.Orbital:
                UpdateCameraPosition();
                CheckZoom();
                CheckMouseLook();
                break;
        }
    }

    private void CheckControls()
    {
        if (Input.GetKeyDown(KeyCode.Space))
        {
            if (mode == CameraMode.FirstPerson)
            {
                pitch = 20f;
                UpdateAnglesOrbital();
                mode = CameraMode.Orbital;
            }
            else if (mode == CameraMode.Orbital)
            {
                Camera.main.transform.position = centerPoint + Vector3.up * heightCameraFirstPerson;
                mode = CameraMode.FirstPerson;
            }
        }
    }
    
    private void CheckControlFirstPerson()
    {
        // Movimiento
        float horizontal = Input.GetAxis("Horizontal");
        float vertical = Input.GetAxis("Vertical");

        Vector3 moveDirection = new Vector3(horizontal, 0f, vertical).normalized;
        if (moveDirection.magnitude >= 0.1f)
        {
            // Movimiento relativo a la dirección actual de la cámara
            Vector3 move = Camera.main.transform.right * horizontal + Camera.main.transform.forward * vertical;
            move.y = 0f; // Opcional: evitar que suba/baje si estás mirando hacia arriba/abajo
            Camera.main.transform.position += move * moveSpeed * Time.deltaTime;
        }

        // Rotación con el mouse
        float mouseX = Input.GetAxis("Mouse X");
        float mouseY = Input.GetAxis("Mouse Y");

        yaw += mouseX * mouseSensitivity * Time.deltaTime;
        pitch -= mouseY * mouseSensitivity * Time.deltaTime;
        pitch = Mathf.Clamp(pitch, -90f, 90f); // evita dar la vuelta completa

        // Aplicar rotación en ejes locales
        Camera.main.transform.rotation = Quaternion.Euler(pitch, yaw, 0f);
    }

    private void CheckZoom()
    {
        float scroll = Input.GetAxis("Mouse ScrollWheel");
        Camera.main.fieldOfView -= scroll * zoomSpeed;
        Camera.main.fieldOfView = Mathf.Clamp(Camera.main.fieldOfView, minFOV, maxFOV);
    }

    private void CheckMouseLook()
    {
        if (Input.GetMouseButton(1)) // Botón derecho presionado
            UpdateAnglesOrbital();
    }

    private void UpdateAnglesOrbital()
    {
        float mouseX = Input.GetAxis("Mouse X");
        float mouseY = Input.GetAxis("Mouse Y");

        // Acumular rotaciones
        yaw += mouseX * mouseSensitivity * Time.deltaTime;
        pitch -= mouseY * mouseSensitivity * Time.deltaTime; // restamos para que mover hacia arriba suba la cámara

        // Limitar pitch para evitar rotación completa
        pitch = Mathf.Clamp(pitch, pitchMin, pitchMax);
        UpdateCameraPosition();
    }



    private void UpdateCameraPosition()
    {
        // Convertimos ángulos a radianes
        float yawRad = Mathf.Deg2Rad * yaw;
        float pitchRad = Mathf.Deg2Rad * pitch;

        // Coordenadas esféricas para posicionar la cámara
        float x = centerPoint.x + radius * Mathf.Cos(pitchRad) * Mathf.Sin(yawRad);
        float y = centerPoint.y + radius * Mathf.Sin(pitchRad);
        float z = centerPoint.z + radius * Mathf.Cos(pitchRad) * Mathf.Cos(yawRad);

        Camera.main.transform.position = new Vector3(x, y, z);

        // Hacer que mire al centro
        Camera.main.transform.LookAt(centerPoint);
    }
}
