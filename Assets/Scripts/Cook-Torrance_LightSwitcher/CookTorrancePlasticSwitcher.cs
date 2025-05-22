using UnityEngine;

public class CookTorrancePlasticSwitcher : MonoBehaviour
{
    public Renderer teteraRenderer;

    private Material mat;

    void Start()
    {
        if (teteraRenderer == null)
            teteraRenderer = GetComponent<Renderer>();
        mat = teteraRenderer.material;

        // Base Plástico Satinado
        mat.SetColor("_MaterialColor", new Color(0.20f, 0.50f, 1.00f, 1f));  // celeste
        mat.SetFloat("_Metallic", 0.00f);    // plástico no metálico
        mat.SetFloat("_Roughness", 0.25f);    // satinado, algo de rugosidad
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
        // Luz ambiental suave
        mat.SetColor("_AmbientLightColor", new Color(0.5f, 0.5f, 0.5f, 1f));

        // Luz puntual sobre (3,0,3) — algo elevada
        mat.SetVector("_PointLightPosition", new Vector4(3f, 4f, 3f, 1f));
        mat.SetColor("_PointLightColor", Color.white);
        mat.SetFloat("_PointLightIntensity", 3.0f);
        mat.SetFloat("_PointLightRange", 12f);

        // Apagar direccional y spot
        mat.SetFloat("_DirLightIntensity", 0f);
        mat.SetFloat("_SpotLightIntensity", 0f);
    }

    void SetPlasticDir()
    {
        // Luz ambiental tenue para plástico
        mat.SetColor("_AmbientLightColor", new Color(0.15f, 0.15f, 0.15f, 1f));

        // Luz direccional
        mat.SetVector("_DirLightDirection", new Vector4(45f, -30f,  0f, 0f));
        mat.SetColor("_DirLightColor", Color.white);
        mat.SetFloat("_DirLightIntensity", 2.0f);

        // Apagar puntal y spot
        mat.SetFloat("_PointLightIntensity", 0f);
        mat.SetFloat("_SpotLightIntensity", 0f);
    }

    void SetPlasticSpot()
    {
        // Luz ambiental suave
        mat.SetColor("_AmbientLightColor", new Color(0.08f, 0.08f, 0.10f, 1f));

        // Luz spot sobre (3,0,3)
        mat.SetVector("_SpotLightPosition", new Vector4(3f, 4f, 3f, 1f));
        mat.SetVector("_SpotLightDirection", new Vector4(0f, -1f, 0f,  0f));
        mat.SetColor("_SpotLightColor", Color.white);
        mat.SetFloat("_SpotLightIntensity", 2.5f);
        mat.SetFloat("_SpotLightRange", 15f);
        mat.SetFloat("_SpotLightAngle", 25f);

        // Apagar direccional y puntual
        mat.SetFloat("_DirLightIntensity", 0f);
        mat.SetFloat("_PointLightIntensity", 0f);
    }
}
