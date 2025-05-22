using UnityEngine;

public class CookTorranceMetalPulidoSwitcher : MonoBehaviour
{
    public Renderer teteraRenderer;

    private Material mat;

    void Start()
    {
        if (teteraRenderer == null)
            teteraRenderer = GetComponent<Renderer>();
        mat = teteraRenderer.material;

        // Base Metal Pulido (gris)
        mat.SetColor("_MaterialColor", new Color(0.7f, 0.7f, 0.7f, 1f));
        mat.SetFloat("_Metallic",  1.0f);   // totalmente metálico
        mat.SetFloat("_Roughness", 0.05f);  // muy pulido, poco roughness
    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.P))
            SetMetalPulidoPoint();
        else if (Input.GetKeyDown(KeyCode.L))
            SetMetalPulidoDir();
        else if (Input.GetKeyDown(KeyCode.O))
            SetMetalPulidoSpot();
    }

    void SetMetalPulidoPoint()
    {
        // Ambiente muy tenue
        mat.SetColor("_AmbientLightColor", new Color(0.02f, 0.02f, 0.02f, 1f));

        // Luz puntual sobre (3,0,6)
        mat.SetVector("_PointLightPosition", new Vector4(3f, 4f, 6f, 1f));
        mat.SetColor("_PointLightColor", Color.white);
        mat.SetFloat("_PointLightIntensity", 4.0f);
        mat.SetFloat("_PointLightRange", 12f);

        // Apagar direccional y spot
        mat.SetFloat("_DirLightIntensity", 0f);
        mat.SetFloat("_SpotLightIntensity",  0f);
    }

    void SetMetalPulidoDir()
    {
        // Ambiente muy tenue
        mat.SetColor("_AmbientLightColor", new Color(0.02f, 0.02f, 0.02f, 1f));

        // Luz direccional
        mat.SetVector("_DirLightDirection", new Vector4(45f, -30f, 0f, 0f));
        mat.SetColor("_DirLightColor", Color.white);
        mat.SetFloat("_DirLightIntensity", 2.5f);

        // Apagar puntual y spot
        mat.SetFloat("_PointLightIntensity", 0f);
        mat.SetFloat("_SpotLightIntensity", 0f);
    }

    void SetMetalPulidoSpot()
    {
        // Ambiente muy tenue
        mat.SetColor("_AmbientLightColor", new Color(0.02f, 0.02f, 0.02f, 1f));

        // Luz spot sobre (3,0,6)
        mat.SetVector("_SpotLightPosition", new Vector4(3f, 4f, 6f, 1f));
        mat.SetVector("_SpotLightDirection", new Vector4(0f, -1f, 0f, 0f));
        mat.SetColor("_SpotLightColor", Color.white);
        mat.SetFloat("_SpotLightIntensity", 3.0f);
        mat.SetFloat("_SpotLightRange", 15f);
        mat.SetFloat("_SpotLightAngle", 20f);

        // Apagar direccional y puntual
        mat.SetFloat("_DirLightIntensity", 0f);
        mat.SetFloat("_PointLightIntensity", 0f);
    }
}
