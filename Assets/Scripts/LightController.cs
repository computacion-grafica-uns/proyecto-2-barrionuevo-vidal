using UnityEngine;

public class LightController : MonoBehaviour
{
    [Header("Directional Light Settings")]
    public Vector3 directionalDir   = new Vector3(50, -30, 0);
    public float   dirIntensityStep = 0.2f;

    [Header("Point Light Settings")]
    public Vector3 pointPosition    = new Vector3(0, 5, 0);
    public float   pointRangeStep   = 1f;

    [Header("Spot Light Settings")]
    public Vector3 spotPosition     = new Vector3(0, 5, 5);
    public Vector3 spotDirection    = new Vector3(0, -1, -1);
    public float   spotAngleStep    = 2f;

    private Light dirLight, pointLight, spotLight;

    void Awake()
    {
        // --- Directional ---
        GameObject goDir = new GameObject("Luz_Direccional");
        dirLight = goDir.AddComponent<Light>();
        dirLight.type      = LightType.Directional;
        dirLight.transform.rotation = Quaternion.Euler(directionalDir);
        dirLight.color     = Color.white;
        dirLight.intensity = 1f;
        dirLight.enabled   = false;

        // --- Point ---
        GameObject goPoint = new GameObject("Luz_Puntual");
        pointLight = goPoint.AddComponent<Light>();
        pointLight.type      = LightType.Point;
        pointLight.transform.position = pointPosition;
        pointLight.range     = 10f;
        pointLight.intensity = 1f;
        pointLight.color     = Color.white;
        pointLight.enabled   = false;

        // --- Spot ---
        GameObject goSpot = new GameObject("Luz_Spot");
        spotLight = goSpot.AddComponent<Light>();
        spotLight.type       = LightType.Spot;
        spotLight.transform.position  = spotPosition;
        spotLight.transform.rotation  = Quaternion.LookRotation(spotDirection);
        spotLight.range      = 15f;
        spotLight.spotAngle  = 30f;
        spotLight.intensity  = 1f;
        spotLight.color      = Color.white;
        spotLight.enabled    = false;
    }

    void Update()
    {
        // Toggle luces
        if (Input.GetKeyDown(KeyCode.L))
            dirLight.enabled = !dirLight.enabled;
        if (Input.GetKeyDown(KeyCode.P))
            pointLight.enabled = !pointLight.enabled;
        if (Input.GetKeyDown(KeyCode.S))
            spotLight.enabled = !spotLight.enabled;

        // Ajustar intensidad de la luz direccional (K/J)
        if (dirLight.enabled)
        {
            if (Input.GetKeyDown(KeyCode.K))
                dirLight.intensity += dirIntensityStep;
            if (Input.GetKeyDown(KeyCode.J))
                dirLight.intensity = Mathf.Max(0, dirLight.intensity - dirIntensityStep);
        }

        // Ajustar rango de la luz puntual (O/I)
        if (pointLight.enabled)
        {
            if (Input.GetKeyDown(KeyCode.O))
                pointLight.range += pointRangeStep;
            if (Input.GetKeyDown(KeyCode.I))
                pointLight.range = Mathf.Max(0, pointLight.range - pointRangeStep);
        }

        // Ajustar ángulo del spot (]/[)
        if (spotLight.enabled)
        {
            if (Input.GetKeyDown(KeyCode.RightBracket)) // ]
                spotLight.spotAngle = Mathf.Min(179, spotLight.spotAngle + spotAngleStep);
            if (Input.GetKeyDown(KeyCode.LeftBracket))  // [
                spotLight.spotAngle = Mathf.Max(1, spotLight.spotAngle - spotAngleStep);
        }
    }
}
