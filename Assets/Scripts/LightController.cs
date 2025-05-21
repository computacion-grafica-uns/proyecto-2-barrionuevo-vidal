using UnityEngine;

public class LightController : MonoBehaviour
{
    public Vector3 directionalDir = new Vector3(50, -30, 0);
    public Vector3 pointPosition = new Vector3(0, 5, 0);
    public Vector3 spotPosition = new Vector3(0, 5, 5);
    public Vector3 spotDirection = new Vector3(0, -1, -1);

    private Light dirLight, pointLight, spotLight;

    void Awake()
    {
        // Luz direccional
        GameObject goDir = new GameObject("Luz_Direccional");
        dirLight = goDir.AddComponent<Light>();
        dirLight.type = LightType.Directional;
        dirLight.transform.rotation = Quaternion.Euler(directionalDir);
        dirLight.color = Color.white;
        dirLight.intensity = 1f;

        // Luz puntual
        GameObject goPoint = new GameObject("Luz_Puntual");
        pointLight = goPoint.AddComponent<Light>();
        pointLight.type = LightType.Point;
        pointLight.transform.position = pointPosition;
        pointLight.range = 10f;
        pointLight.intensity = 1f;
        pointLight.color = Color.white;

        // Luz spot
        GameObject goSpot = new GameObject("Luz_Spot");
        spotLight = goSpot.AddComponent<Light>();
        spotLight.type = LightType.Spot;
        spotLight.transform.position = spotPosition;
        spotLight.transform.rotation = Quaternion.LookRotation(spotDirection);
        spotLight.range = 15f;
        spotLight.spotAngle = 30f;
        spotLight.intensity = 1f;
        spotLight.color = Color.white;

        // Todas apagadas al inicio
        dirLight.enabled   = false;
        pointLight.enabled = false;
        spotLight.enabled  = false;
    }

    void Update()
    {
        // Direccional con tecla L
        if (Input.GetKeyDown(KeyCode.L))
            dirLight.enabled = !dirLight.enabled;

        // Puntual con tecla P
        if (Input.GetKeyDown(KeyCode.P))
            pointLight.enabled = !pointLight.enabled;

        // Spot con tecla S
        if (Input.GetKeyDown(KeyCode.S))
            spotLight.enabled = !spotLight.enabled;
    }
}
