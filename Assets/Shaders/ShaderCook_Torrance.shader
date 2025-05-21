Shader "ShaderCook_Torrance"
{
    Properties
    {
        _MaterialColor ("Material Color", Color) = (1,1,1,1)
        _Metallic("Metallic", Range(0,1)) = 0.5
        _Roughness("Roughness", Range(0,1)) = 0.5

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

            v2f vert(appdata v)
            {
                v2f o;
                o.position = UnityObjectToClipPos(v.position);
                o.worldPos = mul(unity_ObjectToWorld, v.position).xyz;
                o.worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
                return o;
            }

            float3 fresnelSchlick(float3 F0, float cosTheta)
            {
                return F0 + (1 - F0) * pow(1.0 - cosTheta, 5.0);
            }

            float D(float3 N, float3 H, float roughness)
            {
                float a = roughness * roughness;
                float a2 = a * a;
                float NdotH = max(dot(N, H), 0.0);
                float denom = (NdotH * NdotH) * (a2 - 1.0) + 1.0;
                return a2 / (3.14159265 * denom * denom);
            }

            float G1(float3 N, float3 V, float roughness)
            {
                float k = pow(roughness + 1.0, 2.0) / 8.0;
                float NdotV = max(dot(N, V), 0.0);
                return NdotV / (NdotV * (1.0 - k) + k);
            }

            float4 _MaterialColor;
            float _Metallic;
            float _Roughness;

            float4 _PointLightPosition_w;
            float _PointLightIntensity;
            float _WorldLightIntensity;

            float4 _PointLightColor;
            float4 _WorldLightColor;

            fixed4 frag(v2f i) : SV_Target
            {
                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);
                float3 L = normalize(_PointLightPosition_w.xyz - i.worldPos);
                float3 H = normalize(V + L);
                float3 N = normalize(i.worldNormal);

                float NdotL = max(dot(N, L), 0.0);
                float NdotV = max(dot(N, V), 0.001); // evita división por cero
                float3 F0 = lerp(float3(0.04, 0.04, 0.04), _MaterialColor.rgb, _Metallic);
                float3 F = fresnelSchlick(F0, max(dot(H, V), 0.0));
                float Dval = D(N, H, _Roughness);
                float Gval = G1(N, V, _Roughness) * G1(N, L, _Roughness);

                // en la ambient se puede hacer cosas locas (se eligió la más básica UmU )
                float3 ambient = _WorldLightColor.rgb * _WorldLightIntensity * _MaterialColor.rgb;

                //float3 ambient = _WorldLightColor.rgb * _WorldLightIntensity * _MaterialColor.rgb * (0.3 + 0.7 * ambientFactor);


                //float3 specular = (Dval * Gval * F) / (4.0 * NdotV * NdotL);
                float denom = max(4.0 * NdotV * NdotL, 0.001);
                float3 specular = (Dval * Gval * F) / denom;

                
                float3 diffuse = (1.0 - F) * (_MaterialColor.rgb / 3.14159265);

                float3 color = ambient + (_PointLightColor.rgb * _PointLightIntensity) * (diffuse + specular) * NdotL;
                //return float4(specular * NdotL, 1);
                return float4(color,1);
                
                //return float4(color, 1.0);
            }

            ENDCG
        }
    }
}
