using UnityEngine;

public class TexturedPhongLightingSwitcher : MonoBehaviour
{
    public Renderer teteraRenderer;
    private Material mat;

    void Start()
    {
        if (teteraRenderer == null)
            teteraRenderer = GetComponent<Renderer>();

        mat = teteraRenderer.material;

        // Color base como tinte para la textura
        mat.SetColor("_MaterialColor", Color.white);
        mat.SetFloat("_DiffuseCoef", 1.0f);
        mat.SetColor("_SpecularColor", new Color(0.3f, 0.3f, 0.3f, 1f));
        mat.SetFloat("_Shininess", 64f);
    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.P))
            SetPointLight();
        else if (Input.GetKeyDown(KeyCode.L))
            SetDirectionalLight();
        else if (Input.GetKeyDown(KeyCode.O))
            SetSpotLight();
    }

    void SetPointLight()
    {
        mat.SetColor("_AmbientLightColor", new Color(0.4f, 0.4f, 0.4f, 1f));

        mat.SetVector("_PointLightPosition_w", new Vector4(9f, 4f, 0f, 1f));
        mat.SetColor("_PointLightColor", Color.white);
        mat.SetFloat("_PointLightIntensity", 2.5f);
        mat.SetFloat("_PointLightRange", 12f);

        mat.SetFloat("_DirLightIntensity", 0f);
        mat.SetFloat("_SpotLightIntensity", 0f);
    }

    void SetDirectionalLight()
    {
        mat.SetColor("_AmbientLightColor", new Color(0.3f, 0.3f, 0.3f, 1f));

        mat.SetVector("_DirLightDirection", new Vector4(45f, -30f, -0.3f, 0f));
        mat.SetColor("_DirLightColor", new Color(1f, 0.95f, 0.9f, 1f));
        mat.SetFloat("_DirLightIntensity", 1.0f);

        mat.SetFloat("_PointLightIntensity", 0f);
        mat.SetFloat("_SpotLightIntensity", 0f);
    }

    void SetSpotLight()
    {
        mat.SetColor("_AmbientLightColor", new Color(0.3f, 0.3f, 0.3f, 1f));

        mat.SetVector("_SpotLightPosition", new Vector4(9f, 4f, 0f, 1f));
        mat.SetVector("_SpotLightDirection", new Vector4(0f, -1f, 0.4f, 0f));
        mat.SetColor("_SpotLightColor", Color.white);
        mat.SetFloat("_SpotLightIntensity", 3.0f);
        mat.SetFloat("_SpotLightRange", 15f);
        mat.SetFloat("_SpotLightAngle", 30f);

        mat.SetFloat("_DirLightIntensity", 0f);
        mat.SetFloat("_PointLightIntensity", 0f);
    }
}
