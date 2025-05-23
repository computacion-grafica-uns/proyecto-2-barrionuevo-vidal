using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LigthControlAux : MonoBehaviour
{
    public Vector3 posPointLight, posSpotLight, dirSpotLight, dirDirectionalLight;
    public float intensityPointLight, intensitySpotLight, intensityDirectionalLight,pointLightRange, spotLightRange,spotLightAngle;
    public Color colorPointLight, colorSpotLight, colorDirectionalLight;
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
        CheckControls();
    }

    private void ChangedValuePointLight()
    {
        foreach (Material material in materials)
        {
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
        foreach (Material material in materials)
        {
            material.SetFloat("_PointLightIntensity", 1);
            material.SetFloat("_SpotLightIntensity", 0);
            material.SetFloat("_DirLightIntensity", 0);
        }
    }

    private void ChangedLightSpot()
    {
        foreach (Material material in materials)
        {
            material.SetFloat("_PointLightIntensity", 0);
            material.SetFloat("_SpotLightIntensity", 1);
            material.SetFloat("_DirLightIntensity", 0);
        }
    }

    private void ChangedLightDirectional()
    {
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
