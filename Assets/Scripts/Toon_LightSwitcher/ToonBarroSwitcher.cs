using UnityEngine;

public class ToonBarroSwitcher : MonoBehaviour
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
        mat.SetColor("_SpecularColor", new Color(0.10f, 0.10f, 0.10f, 1f)); // reflejo muy bajo
        mat.SetFloat("_CoefMaterialDiffuse", 0.5f);
        mat.SetFloat("_CoefMaterialSpecular", 0.3f);

        // Ambiente suave cálido
        mat.SetColor("_AmbientLightColor", new Color(0.5f, 0.5f, 0.5f, 1f));
        mat.SetFloat("_AmbientLightIntensity", 0.5f);
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
        // Luz puntual sobre (6,0,0)
        mat.SetVector("_PointLightPosition", new Vector4(6f, 4f, 0f, 1f));
        mat.SetColor("_PointLightColor", Color.white);
        mat.SetFloat("_PointLightIntensity", 2.0f);
        mat.SetFloat("_PointLightRange", 12f);

        // Apagar direccional y spot
        mat.SetFloat("_DirLightIntensity", 0f);
        mat.SetFloat("_SpotLightIntensity", 0f);
    }

    void SetBarroDir()
    {
        // Luz direccional
        mat.SetVector("_DirLightDirection", new Vector4(45f, -30f, 0f, 0f));
        mat.SetColor("_DirLightColor", Color.white);
        mat.SetFloat("_DirLightIntensity", 1.2f);

        // Apagar puntual y spot
        mat.SetFloat("_PointLightIntensity", 0f);
        mat.SetFloat("_SpotLightIntensity", 0f);
    }

    void SetBarroSpot()
    {
        // Luz spot sobre (6,0,0)
        mat.SetVector("_SpotLightPosition", new Vector4(6f, 4f, 0f, 1f));
        mat.SetVector("_SpotLightDirection", new Vector4(0f, -1f, 0f, 0f));
        mat.SetColor("_SpotLightColor", Color.white);
        mat.SetFloat("_SpotLightIntensity", 1.5f);
        mat.SetFloat("_SpotLightRange", 15f);
        mat.SetFloat("_SpotLightAngle", 30f);

        // Apagar direccional y puntual
        mat.SetFloat("_DirLightIntensity", 0f);
        mat.SetFloat("_PointLightIntensity", 0f);
    }
}
