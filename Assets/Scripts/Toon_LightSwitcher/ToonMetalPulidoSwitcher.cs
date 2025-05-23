using UnityEngine;

public class ToonMetalPulidoSwitcher : MonoBehaviour
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
        mat.SetColor("_SpecularColor", Color.white);
        mat.SetFloat("_CoefMaterialDiffuse", 0.2f);  // poco diffuse
        mat.SetFloat("_CoefMaterialSpecular", 0.8f);  // alto specular

        // Ambiente suave cálido
        mat.SetColor("_AmbientLightColor", new Color(0.5f, 0.5f, 0.5f, 1f));
        mat.SetFloat("_AmbientLightIntensity", 0.5f);
    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.P))
            SetMetalPoint();
        else if (Input.GetKeyDown(KeyCode.L))
            SetMetalDir();
        else if (Input.GetKeyDown(KeyCode.O))
            SetMetalSpot();
    }

    void SetMetalPoint()
    {
        // Luz puntual sobre (6,0,6)
        mat.SetVector("_PointLightPosition", new Vector4(6f, 4f, 6f, 1f));
        mat.SetColor("_PointLightColor", Color.white);
        mat.SetFloat("_PointLightIntensity", 1f);
        mat.SetFloat("_PointLightRange", 12f);

        // Apagar las otras
        mat.SetFloat("_DirLightIntensity", 0f);
        mat.SetFloat("_SpotLightIntensity", 0f);
    }

    void SetMetalDir()
    {
        // Luz direccional
        mat.SetVector("_DirLightDirection", new Vector4(45f, -30f, 0f, 0f));
        mat.SetColor("_DirLightColor", Color.white);
        mat.SetFloat("_DirLightIntensity", 1f);

        // Apagar las otras
        mat.SetFloat("_PointLightIntensity", 0f);
        mat.SetFloat("_SpotLightIntensity", 0f);
    }

    void SetMetalSpot()
    {
        // Luz spot sobre (6,0,6)
        mat.SetVector("_SpotLightPosition", new Vector4(6f, 4f, 6f, 1f));
        mat.SetVector("_SpotLightDirection", new Vector4(0f, -1f, 0f, 0f));
        mat.SetColor("_SpotLightColor", Color.white);
        mat.SetFloat("_SpotLightIntensity", 1f);
        mat.SetFloat("_SpotLightRange", 15f);
        mat.SetFloat("_SpotLightAngle", 20f);

        // Apagar las otras
        mat.SetFloat("_DirLightIntensity", 0f);
        mat.SetFloat("_PointLightIntensity", 0f);
    }
}
