Shader "ShaderToon"
{
    Properties
    {
        _MaterialColor ("Material Color", Color) = (1,1,1,1)
        _SpecularColor ("Specular Color", Color) = (1,1,1,1)
        _CoefMaterialSpecular("Coef_specular", Range(0,1)) = 0.5
        _CoefMaterialDiffuse("Coef_diffuse", Range(0,1)) = 0.5
        _Outline("Outline", Range(0,1)) = 0.5
        
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
            Cull Front
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 position : SV_POSITION;
            };

            float _Outline;

            v2f vert(appdata v)
            { 
                v2f o;
                v.vertex.xyz += v.normal * _Outline;
                o.position = UnityObjectToClipPos(v.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                return float4(0,0,0,1.0);
            }

            ENDCG
        }

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

            v2f vert(appdata v)
            {
                v2f o;
                o.position = UnityObjectToClipPos(v.position);
                o.worldPos = mul(unity_ObjectToWorld, v.position).xyz;
                o.worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
                return o;
            }
            
            float4 _PointLightPosition_w;
            float _PointLightIntensity;
            float _WorldLightIntensity;
            float4 _PointLightColor;
            float4 _WorldLightColor;
            float4 _MaterialColor;
            float4 _SpecularColor;
            float _CoefMaterialSpecular;
            float _CoefMaterialDiffuse;
            float _Threshold;

            fixed4 frag(v2f i) : SV_Target
            {
                // Normalizar vectores
                float3 N = normalize(i.worldNormal);
                float3 L = normalize(_PointLightPosition_w.xyz - i.worldPos);
                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);
                float3 H = normalize(L + V); // vector medio

                // Coeficientes
                float coefAmb = _WorldLightIntensity;
                float coefDiff = max(dot(N, L), 0.0) * _PointLightIntensity;
                
                if(coefDiff > _CoefMaterialDiffuse)
                    coefDiff = 1;
                else
                    coefDiff = 0;
                
                float coefSpec = max(dot(N, H), 0.0);
                float3 specular;
                
                if(coefSpec >_CoefMaterialSpecular)
                    specular = _SpecularColor;
                else
                    specular = float3(0,0,0);

                // Componentes de iluminación
                float3 color = (coefAmb  + coefDiff) * _WorldLightColor.rgb * _MaterialColor.rgb + specular;

                return float4(color, 1.0);
            }
            ENDCG
        }
    }
}
