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

        // Material barro
        mat.SetColor("_MaterialColor", new Color(0.60f, 0.30f, 0.15f, 1f));
        mat.SetColor("_SpecularColor", new Color(0.10f, 0.10f, 0.10f, 1f));
        mat.SetFloat("_Shininess", 8f);
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
        // Ambiente
        mat.SetColor("_AmbientLightColor",  new Color(0.2f, 0.15f, 0.1f, 1f));

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
        // Ambiente
        mat.SetColor("_AmbientLightColor", new Color(0.25f, 0.20f, 0.18f, 1f));

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
        // Ambiente
        mat.SetColor("_AmbientLightColor", new Color(0.25f, 0.20f, 0.18f, 1f));

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
