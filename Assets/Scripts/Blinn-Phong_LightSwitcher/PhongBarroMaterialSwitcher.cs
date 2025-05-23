using UnityEngine;

public class PhongBarroMaterialSwitcher : MonoBehaviour
{
    public Renderer teteraRenderer;

    private Material mat;

    void Start()
    {
        if (teteraRenderer == null)
            teteraRenderer = GetComponent<Renderer>();

        mat = teteraRenderer.material;

        mat.SetColor("_MaterialColor", new Color(0.60f, 0.30f, 0.15f, 1f));
        mat.SetColor("_SpecularColor", new Color(0.10f, 0.10f, 0.10f, 1f));
        mat.SetFloat("_Shininess", 8f);
        mat.SetFloat("Diffuse Coef", 1f);

        // Ambiente
        mat.SetColor("_AmbientLightColor", new Color(0.5f, 0.5f, 0.5f, 1f));
    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.P))
            SetBarroPointLight();
        else if (Input.GetKeyDown(KeyCode.L))
            SetBarroDirLight();
        else if (Input.GetKeyDown(KeyCode.O))
            SetBarroSpotLight();
    }

    void SetBarroPointLight()
    {
        // Luz puntual
        mat.SetVector("_PointLightPosition", new Vector4(0, 4, 0, 1));
        mat.SetColor("_PointLightColor", new Color(1f, 0.95f, 0.80f, 1f));
        mat.SetFloat("_PointLightIntensity", 2.2f);
        mat.SetFloat("_PointLightRange", 12f);

        // Desactivar las otras luces
        mat.SetFloat("_DirLightIntensity", 0f);
        mat.SetFloat("_SpotLightIntensity", 0f);
    }

    void SetBarroDirLight()
    {
        // Luz direccional
        mat.SetVector("_DirLightDirection", new Vector4(45f, -30f, 0f, 0f));
        mat.SetColor("_DirLightColor", new Color(1f, 1f, 0.95f, 1f));
        mat.SetFloat("_DirLightIntensity", 0.4f);

        // Desactivar las otras
        mat.SetFloat("_PointLightIntensity", 0f);
        mat.SetFloat("_SpotLightIntensity",  0f);
    }

    void SetBarroSpotLight()
    {
        // Luz spot
        mat.SetVector("_SpotLightPosition", new Vector4(0f, 4f, 0f, 1f));
        mat.SetVector("_SpotLightDirection", new Vector4(0f, -1f, 0f, 0f));
        mat.SetColor("_SpotLightColor", Color.white);
        mat.SetFloat("_SpotLightIntensity", 1.2f);
        mat.SetFloat("_SpotLightRange", 12f);
        mat.SetFloat("_SpotLightAngle", 30f);

        // Desactivar las otras
        mat.SetFloat("_DirLightIntensity", 0f);
        mat.SetFloat("_PointLightIntensity", 0f);
    }
}
