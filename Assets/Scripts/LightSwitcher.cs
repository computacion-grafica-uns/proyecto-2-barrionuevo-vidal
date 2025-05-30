using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LightSwitcher : MonoBehaviour
{
    public Vector3 posPointLight, posSpotLight, dirSpotLight, dirDirectionalLight;
    public float intensityPointLight, intensitySpotLight, intensityDirectionalLight,
                pointLightRange, spotLightRange,spotLightAngle;
    public Color colorPointLight, colorSpotLight, colorDirectionalLight, AmbientLightColor;
    public Material[] materials;

    public void Start()
    {
        SetValueDefaultLight();
    }

    public void Update()
    {
        ChangedValueSpotLight();
        ChangedValuePointLight();
        ChangedValueDirectionalLight();
        ChangedValueAmbientLight();
        CheckControls();
    }

    private void ChangedValueAmbientLight()
    {
        foreach (Material material in materials)
        {
            material.SetColor("_AmbientColor", AmbientLightColor);
        }
    }

    private void ChangedValuePointLight()
    {
        foreach (Material material in materials)
        {
            material.SetVector("_AmbientColor", posPointLight);
            material.SetColor("_PointLightColor", colorPointLight);
            material.SetFloat("_PointLightIntensity", intensityPointLight);
            material.SetFloat("_PointLightRange", pointLightRange);
            material.SetVector("_PointLightPosition_w", posPointLight);
        }
    }

    private void ChangedValueSpotLight()
    {
        foreach (Material material in materials)
        {
            material.SetColor("_SpotLightColor", colorSpotLight);
            material.SetFloat("_SpotLightIntensity", intensitySpotLight);
            material.SetFloat("_SpotLightRange", spotLightRange);
            material.SetFloat("_SpotLightAngle", spotLightAngle);
            material.SetVector("_SpotLightDirection", dirSpotLight);
            material.SetVector("_SpotLightPosition_w", posSpotLight);
            material.SetColor("_AmbientLightColor", AmbientLightColor);
        }
    }

    private void ChangedValueDirectionalLight()
    {
        foreach (Material material in materials)
        {
            material.SetColor("_DirLightColor", colorDirectionalLight);
            material.SetVector("_DirLightDirection", dirDirectionalLight);
            material.SetFloat("_DirLightIntensity", intensityDirectionalLight);
        }
    }

    private void CheckControls()
    {
        if (Input.GetKeyDown(KeyCode.P))
            ChangedLightPoint();
        else if (Input.GetKeyDown(KeyCode.L))
            ChangedLightDirectional();
        else if (Input.GetKeyDown(KeyCode.O))
            ChangedLightSpot();
    }

    private void ChangedLightPoint()
    {
        intensityPointLight = 1;
        intensitySpotLight = 0;
        intensityDirectionalLight = 0;

        foreach (Material material in materials)
        {
            material.SetFloat("_PointLightIntensity", 1);
            material.SetFloat("_SpotLightIntensity", 0);
            material.SetFloat("_DirLightIntensity", 0);
        }
    }

    private void ChangedLightSpot()
    {
        intensityPointLight = 0;
        intensitySpotLight = 1;
        intensityDirectionalLight = 0;

        foreach (Material material in materials)
        {
            material.SetFloat("_PointLightIntensity", 0);
            material.SetFloat("_SpotLightIntensity", 1);
            material.SetFloat("_DirLightIntensity", 0);
        }
    }

    private void ChangedLightDirectional()
    {
        intensityPointLight = 0;
        intensitySpotLight = 0;
        intensityDirectionalLight = 1;

        foreach (Material material in materials)
        {
            material.SetFloat("_PointLightIntensity", 0);
            material.SetFloat("_SpotLightIntensity", 0);
            material.SetFloat("_DirLightIntensity", 1);
        }
    }

    private void SetValueDefaultLight()
    {
        foreach (Material material in materials)
        {
            material.SetFloat("_PointLightIntensity", intensityPointLight);
            material.SetFloat("_SpotLightIntensity", intensitySpotLight);
            material.SetFloat("_DirLightIntensity", intensityDirectionalLight);
            material.SetFloat("_PointLightRange", pointLightRange);
            material.SetFloat("_SpotLightRange", spotLightRange);
            material.SetFloat("_SpotLightAngle", spotLightAngle);
            material.SetVector("_PointLightPosition_w", posPointLight);
            material.SetVector("_SpotLightPosition_w", posSpotLight);
            material.SetVector("_SpotLightDirection", dirSpotLight);
            material.SetVector("_DirLightDirection", dirDirectionalLight);
        }
    }
}
