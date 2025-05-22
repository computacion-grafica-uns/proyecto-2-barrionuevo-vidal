using UnityEngine;

public class CookTorranceBarroSwitcher : MonoBehaviour
{
    public Renderer teteraRenderer;

    private Material mat;

    void Start()
    {
        if (teteraRenderer == null)
            teteraRenderer = GetComponent<Renderer>();
        mat = teteraRenderer.material;

        // Color base barro
        mat.SetColor("_MaterialColor", new Color(0.60f, 0.30f, 0.15f, 1f));
        // Parámetro PBR para barro: poco metálico, rugoso
        mat.SetFloat("_Metallic",  0.05f);
        mat.SetFloat("_Roughness", 0.8f);
    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.P))
            SetBarroPoint();
        else if (Input.GetKeyDown(KeyCode.L))
            SetBarroDir();
        else if (Input.GetKeyDown(KeyCode.O))
            SetBarroSpot();
    }

    void SetBarroPoint()
    {
        // Ambiente suave cálido
        mat.SetColor("_AmbientLightColor", new Color(0.20f, 0.15f, 0.10f, 1f));

        // Luz puntual
        mat.SetVector("_PointLightPosition_w", new Vector4(3f, 4f, 0f, 1f));
        mat.SetColor("_PointLightColor", Color.white);
        mat.SetFloat("_PointLightIntensity", 2.0f);
        mat.SetFloat("_PointLightRange", 12f);

        // Desactivar direccional y spot
        mat.SetFloat("_DirLightIntensity", 0f);
        mat.SetFloat("_SpotLightIntensity", 0f);

    }

    void SetBarroDir()
    {
        // Ambiente más tenue
        mat.SetColor("_AmbientLightColor", new Color(0.15f, 0.10f, 0.08f, 1f));

        // Encender direccional
        mat.SetVector("_DirLightDirection", new Vector4(45f, -30f, 0f, 0f));
        mat.SetColor("_DirLightColor", Color.white);
        mat.SetFloat("_DirLightIntensity", 1.0f);

        // Apagar puntal y spot
        mat.SetFloat("_PointLightIntensity", 0f);
        mat.SetFloat("_SpotLightIntensity", 0f);
    }

    void SetBarroSpot()
    {
        // Ambiente intermedio
        mat.SetColor("_AmbientLightColor", new Color(0.18f, 0.14f, 0.10f, 1f));

        // Spot
        mat.SetVector("_SpotLightPosition", new Vector4(3f, 4f, 0f, 1f));
        mat.SetVector("_SpotLightDirection", new Vector4(0f, -1f, 0f, 0f));
        mat.SetColor("_SpotLightColor", Color.white);
        mat.SetFloat("_SpotLightIntensity", 1.5f);
        mat.SetFloat("_SpotLightRange", 15f);
        mat.SetFloat("_SpotLightAngle", 25f);

        // Apagar las otras
        mat.SetFloat("_DirLightIntensity", 0f);
        mat.SetFloat("_PointLightIntensity", 0f);
    }
}
