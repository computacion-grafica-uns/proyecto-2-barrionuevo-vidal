Shader "ShaderCook_Torrance_Multitextura"
{
    Properties
    {
        // Base Color (Albedo)
        _BaseColorMap ("Base Color (Albedo)", 2D) = "white" {}
        // Metallic Map
        _MetallicMap ("Metallic Map (R)", 2D) = "white" {}
        // Roughness fija
        _Roughness ("Roughness (uniforme)", Range(0.01,1)) = 0.5
        
        _F0 ("F0 fallback (RGB)", Vector) = (0.04,0.04,0.04,1)

        // Ambiente 
        _AmbientColor ("Ambient Light Color", Color) = (0.2,0.2,0.2,1)

        // Dirección de la luz direccional
        _DirLightDirection ("Directional Light Dir",  Vector) = (2,-1,0,0)
        _DirLightColor ("Directional Light Color",Color)  = (1,1,1,1)
        _DirLightIntensity ("Directional Intensity", Range(0,5)) = 1

        // Luz puntual
        _PointLightPosition_w ("Point Light Position", Vector)  = (0,1,0,1)
        _PointLightColor ("Point Light Color", Color) = (1,1,1,1)
        _PointLightIntensity ("Point Light Intensity", Range(0,10)) = 1
        _PointLightRange ("Point Light Range", Range(0.1,50)) = 20

        // Luz spot
        _SpotLightPosition_w ("Spot Light Position", Vector) = (0,1,0,1)
        _SpotLightDirection ("Spot Light Direction", Vector) = (0,-1,0,0)
        _SpotLightColor ("Spot Light Color", Color) = (1,1,1,1)
        _SpotLightIntensity ("Spot Light Intensity", Range(0,10)) = 1
        _SpotLightRange ("Spot Light Range", Range(0.1,50)) = 20
        _SpotLightAngle ("Spot Light Half‐Angle", Range(0,90))   = 25
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 300

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            // Mapas
            sampler2D _BaseColorMap;
            sampler2D _MetallicMap;

            // Parámetro Roughness (fallback)
            float  _Roughness;
            float4 _F0;

            // Luz ambiente
            float4 _AmbientColor;

            // Luz direccional
            float4 _DirLightDirection;
            float4 _DirLightColor;
            float  _DirLightIntensity;

            // Luz puntual
            float4 _PointLightPosition_w;
            float4 _PointLightColor;
            float  _PointLightIntensity;
            float  _PointLightRange;

            // Luz spot
            float4 _SpotLightPosition_w;
            float4 _SpotLightDirection;
            float4 _SpotLightColor;
            float  _SpotLightIntensity;
            float  _SpotLightRange;
            float  _SpotLightAngle;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 worldNorm : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNorm = normalize(UnityObjectToWorldNormal(v.normal));
                o.uv = v.uv;
                return o;
            }

            float ComputeAttenuation(float3 lightPos, float3 worldPos, float range)
            {
                float d = distance(lightPos, worldPos);
                return saturate(1.0 - (d * d) / (range * range));
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 albedo = tex2D(_BaseColorMap, i.uv).rgb;

                float metallic = tex2D(_MetallicMap, i.uv).r;

                float3 N = normalize(i.worldNorm);
                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);

                float3 baseF0 = _F0.rgb;
                float3 F0col  = lerp(baseF0, albedo, metallic);

                float3 ambientTerm = _AmbientColor.rgb * albedo;

                float3 result = ambientTerm;

                // Luz direccional
                {
                    float3 L = normalize(-_DirLightDirection.xyz);
                    float3 H = normalize(V + L);
                    float  NdotL = max(dot(N, L), 0);
                    float  NdotV = max(dot(N, V), 0.001);
                    float  NdotH = max(dot(N, H), 0);
                    float  VdotH = max(dot(V, H), 0);

                    // Fresnel Schlick
                    float3 F = baseF0 + (1 - baseF0) * pow(1 - VdotH, 5);

                    // GGX Normal Distribution
                    float a  = _Roughness * _Roughness;
                    float a2 = a * a;
                    float denom = (NdotH * NdotH) * (a2 - 1) + 1;
                    float D = a2 / (UNITY_PI * denom * denom);

                    // Geometry Schlick‐GGX
                    float k  = (a + 1) * (a + 1) / 8.0;
                    float G  = (NdotV / (NdotV * (1 - k) + k)) * (NdotL / (NdotL * (1 - k) + k));

                    // Especular Cook‐Torrance
                    float denomSpec = max(4 * NdotV * NdotL, 0.001);
                    float3 specular = (D * G * F) / denomSpec;

                    // Difuso Lambertiano (albedo / π)
                    float3 diff = albedo / UNITY_PI;

                    // Atenuamos difuso por (1 – metallic)
                    float3 diffuseTerm = diff * (1 - metallic);

                    result += _DirLightColor.rgb * _DirLightIntensity * NdotL * (diffuseTerm + specular);
                }

                // Luz puntual
                {
                    float3 toP = _PointLightPosition_w.xyz - i.worldPos;
                    float3 L = normalize(toP);
                    float  invDist = ComputeAttenuation(_PointLightPosition_w.xyz, i.worldPos, _PointLightRange);
                    float  NdotL = max(dot(N, L), 0);
                    float  NdotV = max(dot(N, V), 0.001);

                    if (NdotL > 0)
                    {
                        float3 H = normalize(V + L);
                        float  NdotH = max(dot(N, H), 0);
                        float  VdotH = max(dot(V, H), 0);

                        // Fresnel
                        float3 F = baseF0 + (1 - baseF0) * pow(1 - VdotH, 5);

                        // GGX D
                        float a  = _Roughness * _Roughness;
                        float a2 = a * a;
                        float denom = (NdotH * NdotH) * (a2 - 1) + 1;
                        float D = a2 / (UNITY_PI * denom * denom);

                        // GGX G
                        float k  = (a + 1) * (a + 1) / 8.0;
                        float G  = (NdotV / (NdotV * (1 - k) + k)) * (NdotL / (NdotL * (1 - k) + k));

                        // Especular
                        float3 spec = (D * G * F) / max(4 * NdotV * NdotL, 0.001);

                        // Difuso
                        float3 diff = albedo / UNITY_PI;
                        float3 diffuseTerm = diff * (1 - metallic);

                        result += _PointLightColor.rgb * _PointLightIntensity * invDist * NdotL * (diffuseTerm + spec);
                    }
                }

                // Luz Spot
                {
                    float3 toS = _SpotLightPosition_w.xyz - i.worldPos;
                    float3 Ls = normalize(toS);
                    float invDist = ComputeAttenuation(_SpotLightPosition_w.xyz, i.worldPos, _SpotLightRange);
                    float NdotL = max(dot(N, Ls), 0);
                    float NdotV = max(dot(N, V), 0.001);

                    // Verificamos ángulo del spot
                    float cosAngle = dot(normalize(-_SpotLightDirection.xyz), Ls);
                    float cutoff = cos(radians(_SpotLightAngle));
                    float spotFac = step(cutoff, cosAngle);

                    if (NdotL > 0 && spotFac > 0)
                    {
                        float3 H = normalize(V + Ls);
                        float NdotH = max(dot(N, H), 0);
                        float VdotH = max(dot(V, H), 0);

                        // Fresnel
                        float3 F = baseF0 + (1 - baseF0) * pow(1 - VdotH, 5);

                        // GGX D
                        float a  = _Roughness * _Roughness;
                        float a2 = a * a;
                        float denom = (NdotH * NdotH) * (a2 - 1) + 1;
                        float D = a2 / (UNITY_PI * denom * denom);

                        // GGX G
                        float k  = (a + 1) * (a + 1) / 8.0;
                        float G  = (NdotV / (NdotV * (1 - k) + k)) * (NdotL / (NdotL * (1 - k) + k));

                        // Especular
                        float3 spec = (D * G * F) / max(4 * NdotV * NdotL, 0.001);

                        // Difuso
                        float3 diff = albedo / UNITY_PI;
                        float3 diffuseTerm = diff * (1 - metallic);

                        result += _SpotLightColor.rgb * _SpotLightIntensity * invDist * spotFac * NdotL * (diffuseTerm + spec);
                    }
                }

                return float4(result, 1);
            }
            ENDCG
        }
    }
}
