using UnityEngine;

public class PhongMetalPulidoSwitcher : MonoBehaviour
{
    public Renderer teteraRenderer;

    private Material mat;

    void Start()
    {
        if (teteraRenderer == null)
            teteraRenderer = GetComponent<Renderer>();

        mat = teteraRenderer.material;

        mat.SetColor("_MaterialColor", new Color(0.7f, 0.7f, 0.7f, 1f));
        mat.SetColor("_SpecularColor", Color.white);
        mat.SetFloat("_Shininess", 200f);
        mat.SetFloat("Diffuse Coef", 1f);
        
        // Ambiental
        mat.SetColor("_AmbientLightColor", new Color(0.5f, 0.5f, 0.5f, 1f));
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
        // Luz Puntual
        mat.SetVector("_PointLightPosition", new Vector4(0f, 4f, 6f, 1f));
        mat.SetColor("_PointLightColor", Color.white);
        mat.SetFloat("_PointLightIntensity", 3.0f);
        mat.SetFloat("_PointLightRange", 12f);

        // Apagar las otras
        mat.SetFloat("_DirLightIntensity", 0f);
        mat.SetFloat("_SpotLightIntensity", 0f);
    }

    void SetMetalPulidoDir()
    {
        // Luz Direccional
        mat.SetVector("_DirLightDirection", new Vector4(45f, -30f, 0f, 0f));
        mat.SetColor("_DirLightColor", Color.white);
        mat.SetFloat("_DirLightIntensity",  1.5f);

        // Apagar las otras
        mat.SetFloat("_PointLightIntensity", 0f);
        mat.SetFloat("_SpotLightIntensity",  0f);
    }

    void SetMetalPulidoSpot()
    {
        // Luz Spot
        mat.SetVector("_SpotLightPosition",  new Vector4(0f, 4f, 6f, 1f));
        mat.SetVector("_SpotLightDirection", new Vector4(0f, -1f, 0f, 0f));
        mat.SetColor("_SpotLightColor",      Color.white);
        mat.SetFloat("_SpotLightIntensity",  2.5f);
        mat.SetFloat("_SpotLightRange",      15f);
        mat.SetFloat("_SpotLightAngle",      20f);

        // Apagar las otras
        mat.SetFloat("_DirLightIntensity",   0f);
        mat.SetFloat("_PointLightIntensity", 0f);
    }
}
