using UnityEngine;

public class PhongPlasticMaterialSwitcher : MonoBehaviour
{
    [Tooltip("El Renderer de la tetera a modificar")]
    public Renderer teteraRenderer;

    private Material mat;

    void Start()
    {
        if (teteraRenderer == null)
            teteraRenderer = GetComponent<Renderer>();

        mat = teteraRenderer.material;
        mat.SetColor("_MaterialColor", new Color(0.20f, 0.50f, 1f, 1f));
        mat.SetColor("_SpecularColor", new Color(1f, 1f, 1f, 1f));
        mat.SetFloat("_Shininess", 64f);
    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.P))
            SetPlasticPointLight();
        else if (Input.GetKeyDown(KeyCode.L))
            SetPlasticDirLight();
        else if (Input.GetKeyDown(KeyCode.O))
            SetPlasticSpotLight();
    }

    void SetPlasticPointLight()
    {
        // Ambiental
        mat.SetColor("_AmbientLightColor", new Color(0.5f, 0.5f, 0.5f, 1f));

        // Luz Puntual
        mat.SetVector("_PointLightPosition", new Vector4(0f, 4f, 3f, 1f));
        mat.SetColor("_PointLightColor",     new Color(1f, 1f, 1f, 1f));
        mat.SetFloat("_PointLightIntensity", 2.0f);
        mat.SetFloat("_PointLightRange",     10f);

        // Apagar las otras
        mat.SetFloat("_DirLightIntensity",   0f);
        mat.SetFloat("_SpotLightIntensity",  0f);
    }

    void SetPlasticDirLight()
    {
        // Ambiental
        mat.SetColor("_AmbientLightColor", new Color(0.15f, 0.15f, 0.15f, 1f));

        // Luz Direccional
        mat.SetVector("_DirLightDirection", new Vector4(45f, -30f, 0f, 0f));
        mat.SetColor("_DirLightColor",      new Color(1f, 1f, 1f, 1f));
        mat.SetFloat("_DirLightIntensity",  1.2f);

        // Apagar las otras
        mat.SetFloat("_PointLightIntensity", 0f);
        mat.SetFloat("_SpotLightIntensity",  0f);
    }

    void SetPlasticSpotLight()
    {
        // Ambiental
        mat.SetColor("_AmbientLightColor", new Color(0.15f, 0.15f, 0.15f, 1f));

        // Luz Spot
        mat.SetVector("_SpotLightPosition",  new Vector4(0f, 4f, 3f, 1f));
        mat.SetVector("_SpotLightDirection", new Vector4(0f, -1f, 0f, 0f));
        mat.SetColor("_SpotLightColor",      new Color(1f,1f,1f,1f));
        mat.SetFloat("_SpotLightIntensity",  2.0f);
        mat.SetFloat("_SpotLightRange",      12f);
        mat.SetFloat("_SpotLightAngle",      25f);

        // Apagar las otras
        mat.SetFloat("_DirLightIntensity",   0f);
        mat.SetFloat("_PointLightIntensity", 0f);
    }
}
