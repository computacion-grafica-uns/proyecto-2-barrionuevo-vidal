using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MaterialLightController : MonoBehaviour
{
    [Header("Light Transforms")]
    public Vector3 posPointLight        = new Vector3(6f, 10f, 2f);
    public Vector3 posSpotLight         = new Vector3(6f, 10f, 2f);
    public Vector3 dirSpotLight         = new Vector3(0f, -1f, 0f);
    public Vector3 dirDirectionalLight  = new Vector3(0f, -1f, 0f);

    [Header("Intensities & Ranges")]
    public float intensityPointLight        = 1f;
    public float intensitySpotLight         = 0f;
    public float intensityDirectionalLight  = 0f;
    public float pointLightRange            = 12f;
    public float spotLightRange             = 15f;
    public float spotLightAngle             = 30f;

    [Header("Colors")]
    public Color colorPointLight       = Color.white;
    public Color colorSpotLight        = Color.white;
    public Color colorDirectionalLight = Color.white;
    public Color ambientLightColor     = new Color(0.2f, 0.2f, 0.2f, 1f);
    
    [Header("Target Materials")]
    public Material[] materials;

    void Start()
    {
        ApplyDefaultsToAll();
    }

    void Update()
    {
        // Always push updated transforms/intensities/colors every frame
        PushAllValues();

        // Switch active light mode on key press
        if (Input.GetKeyDown(KeyCode.P)) SetActiveLight(LightMode.Point);
        else if (Input.GetKeyDown(KeyCode.L)) SetActiveLight(LightMode.Directional);
        else if (Input.GetKeyDown(KeyCode.O)) SetActiveLight(LightMode.Spot);
    }

    enum LightMode { Point, Directional, Spot }

    void SetActiveLight(LightMode mode)
    {
        switch (mode)
        {
            case LightMode.Point:
                intensityPointLight       = 1f;
                intensitySpotLight        = 0f;
                intensityDirectionalLight = 0f;
                break;
            case LightMode.Directional:
                intensityPointLight       = 0f;
                intensitySpotLight        = 0f;
                intensityDirectionalLight = 1f;
                break;
            case LightMode.Spot:
                intensityPointLight       = 0f;
                intensitySpotLight        = 1f;
                intensityDirectionalLight = 0f;
                break;
        }
        
        // Write the updated intensities back to materials immediately
        foreach (var mat in materials)
        {
            mat.SetFloat("_PointLightIntensity",       intensityPointLight);
            mat.SetFloat("_SpotLightIntensity",        intensitySpotLight);
            mat.SetFloat("_DirLightIntensity",         intensityDirectionalLight);
        }
    }

    void PushAllValues()
    {
        foreach (var mat in materials)
        {
            // Ambient
            mat.SetColor("_AmbientLightColor", ambientLightColor);
            mat.SetFloat("_AmbientLightIntensity", ambientLightColor.a); // if shader uses a separate intensity

            // Point
            mat.SetVector("_PointLightPosition_w",   posPointLight);
            mat.SetColor("_PointLightColor",         colorPointLight);
            mat.SetFloat("_PointLightRange",         pointLightRange);
            mat.SetFloat("_PointLightIntensity",     intensityPointLight);

            // Directional
            mat.SetVector("_DirLightDirection",      dirDirectionalLight);
            mat.SetColor("_DirLightColor",           colorDirectionalLight);
            mat.SetFloat("_DirLightIntensity",       intensityDirectionalLight);

            // Spot
            mat.SetVector("_SpotLightPosition_w",    posSpotLight);
            mat.SetVector("_SpotLightDirection",     dirSpotLight);
            mat.SetColor("_SpotLightColor",          colorSpotLight);
            mat.SetFloat("_SpotLightRange",          spotLightRange);
            mat.SetFloat("_SpotLightAngle",          spotLightAngle);
            mat.SetFloat("_SpotLightIntensity",      intensitySpotLight);
        }
    }

    void ApplyDefaultsToAll()
    {
        // Ensures that on Start, everything is written at least once
        PushAllValues();
    }
}
