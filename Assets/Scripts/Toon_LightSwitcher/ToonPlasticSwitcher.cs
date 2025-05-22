using UnityEngine;

public class ToonPlasticSwitcher : MonoBehaviour
{
    public Renderer teteraRenderer;

    private Material mat;

    void Start()
    {
        if (teteraRenderer == null)
            teteraRenderer = GetComponent<Renderer>();
        mat = teteraRenderer.material;

        // Base Plástico Satinado (celeste)
        mat.SetColor("_MaterialColor", new Color(0.20f, 0.50f, 1.00f, 1f));
        mat.SetColor("_SpecularColor", Color.white);
        mat.SetFloat("_CoefMaterialDiffuse",  0.6f);
        mat.SetFloat("_CoefMaterialSpecular", 0.8f);
    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.P))
            SetPlasticPoint();
        else if (Input.GetKeyDown(KeyCode.L))
            SetPlasticDir();
        else if (Input.GetKeyDown(KeyCode.O))
            SetPlasticSpot();
    }

    void SetPlasticPoint()
    {
        // Ambiente suave para plástico
        mat.SetColor("_AmbientLightColor", new Color(0.10f, 0.10f, 0.12f, 1f));
        mat.SetFloat("_AmbientLightIntensity", 0.5f);

        // Luz puntual por encima de (6,0,3)
        mat.SetVector("_PointLightPosition", new Vector4(6f, 4f, 3f, 1f));
        mat.SetColor("_PointLightColor", Color.white);
        mat.SetFloat("_PointLightIntensity", 1.5f);
        mat.SetFloat("_PointLightRange", 12f);

        // Apagar direccional y spot
        mat.SetFloat("_DirLightIntensity", 0f);
        mat.SetFloat("_SpotLightIntensity", 0f);
    }

    void SetPlasticDir()
    {
        // Ambiente tenue
        mat.SetColor("_AmbientLightColor", new Color(0.05f, 0.05f, 0.06f, 1f));
        mat.SetFloat("_AmbientLightIntensity", 0.4f);

        // Luz direccional suave
        mat.SetVector("_DirLightDirection", new Vector4(45f, -30f, 0f, 0f));
        mat.SetColor("_DirLightColor", Color.white);
        mat.SetFloat("_DirLightIntensity", 1.5f);

        // Apagar puntual y spot
        mat.SetFloat("_PointLightIntensity", 0f);
        mat.SetFloat("_SpotLightIntensity", 0f);
    }

    void SetPlasticSpot()
    {
        // Ambiente medio
        mat.SetColor("_AmbientLightColor", new Color(0.08f, 0.08f, 0.10f, 1f));
        mat.SetFloat("_AmbientLightIntensity", 0.45f);

        // Luz spot centrada en (6,0,3)
        mat.SetVector("_SpotLightPosition", new Vector4(6f, 4f, 3f, 1f));
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
