Shader "ShaderPhong"
{
    Properties
    {
        _MaterialColor ("Material Color", Color) = (1,1,1,1)
        _CoefMaterialReflexion("Coef_Material_reflexion", Range(0,1)) = 0.5
        _CoefMaterialDifusse("Coef_Material_difusse", Range(0,1)) = 0.5
        _CoefMaterialSpecular("Coef_Material_specular", Range(0,1)) = 0.5
        _CoefMaterialBrightness("Coef_Material_Brightness", Range(1,100)) = 32

        _PointLightPosition_w("Light Position", Vector) = (0,1,0,1)
        _PointLightColor("PointLight", Color) = (1,1,1,1)
        _PointLightIntensity("Point Light Intensity", Range(0,10)) = 1.0

        _WorldLightColor("World Light", Color) = (1,1,1,1)
        _WorldLightIntensity("World Light Intensity", Range(0,1)) = 0.5
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata {
                float4 position : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 position : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
            };

            float4 _PointLightPosition_w;
            float _PointLightIntensity;
            float _WorldLightIntensity;
            float _CoefMaterialReflexion;
            float _CoefMaterialSpecular;
            float _CoefMaterialDifusse;
            float _CoefMaterialBrightness;

            float4 _PointLightColor;
            float4 _WorldLightColor;
            float4 _MaterialColor;

            v2f vert(appdata v)
            {
                v2f o;
                o.position = UnityObjectToClipPos(v.position);
                o.worldPos = mul(unity_ObjectToWorld, v.position).xyz;
                o.worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // Normalizar vectores
                float3 N = normalize(i.worldNormal);
                float3 L = normalize(_PointLightPosition_w.xyz - i.worldPos);
                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);
                //float3 R = reflect(-L, N);
                float3 H = normalize(L + V); // vector medio
                
                // Coeficientes
                float amb = _WorldLightIntensity * _CoefMaterialReflexion;
                float diff = _PointLightIntensity * _CoefMaterialDifusse * max(0, dot(N, L));
                //float spec = _PointLightIntensity * _CoefMaterialSpecular * pow(max(dot(R, V), 0.0), _CoefMaterialBrightness);
                float spec = _PointLightIntensity * _CoefMaterialSpecular * pow(max(dot(N, H), 0.0), _CoefMaterialBrightness);

                // Componentes de iluminación
                float3 ambient = amb * _WorldLightColor.rgb * _MaterialColor.rgb;
                float3 diffuse = diff * _PointLightColor.rgb * _MaterialColor.rgb;
                float3 specular = spec * _PointLightColor.rgb;

                return float4(ambient + diffuse + specular, 1.0);
            }
            ENDCG
        }
    }
}
