Shader "ShaderCook_Torrance"
{
    Properties
    {
        // Propiedades del material
        _Roughness ("Roughness", Range(0.01,1)) = 0.5
        _MaterialKa ("Material Ka (Ambient)", Vector) = (0.2,0.2,0.2,1)
        _MaterialKd ("Material Kd (Diffuse)", Vector) = (1,1,1,1)
        _MaterialKs ("Material Ks (Specular)",Vector) = (1,1,1,1)

        // Ambiente
        _AmbientColor ("Ambient Light Color", Color) = (0.2,0.2,0.2,1)

        // Directional
        _DirLightDirection ("Directional Light Dir", Vector)= (0,-1,0,0)
        _DirLightColor ("Directional Light Color", Color) = (1,1,1,1)
        _DirLightIntensity ("Directional Intensity", Range(0,5)) = 1

        // Point
        _PointLightPosition_w ("Point Light Position", Vector)= (0,1,0,1)
        _PointLightColor ("Point Light Color", Color) = (1,1,1,1)
        _PointLightIntensity ("Point Light Intensity", Range(0,10))= 1
        _PointLightRange ("Point Light Range", Range(0.1,50))= 10

        // Spot
        _SpotLightPosition_w ("Spot Light Position", Vector)= (0,1,0,1)
        _SpotLightDirection ("Spot Light Direction", Vector)= (0,-1,0,0)
        _SpotLightColor ("Spot Light Color", Color) = (1,1,1,1)
        _SpotLightIntensity ("Spot Light Intensity", Range(0,10)) = 1
        _SpotLightRange ("Spot Light Range", Range(0.1,50))= 15
        _SpotLightAngle ("Spot Light Half-Angle", Range(0,90)) = 30
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            // Material coefficients
            float _Roughness;
            float4 _MaterialKa;
            float4 _MaterialKd;
            float4 _MaterialKs;

            // Ambient Light
            float4 _AmbientColor;

            // Directional Light
            float4 _DirLightDirection;
            float4 _DirLightColor;
            float _DirLightIntensity;

            // Point Light
            float4 _PointLightPosition_w;
            float4 _PointLightColor;
            float _PointLightIntensity;
            float _PointLightRange;

            // Spot Light
            float4 _SpotLightPosition_w;
            float4 _SpotLightDirection;
            float4 _SpotLightColor;
            float _SpotLightIntensity;
            float _SpotLightRange;
            float _SpotLightAngle;

            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 worldNorm : TEXCOORD1;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNorm = normalize(UnityObjectToWorldNormal(v.normal));
                return o;
            }

            // Fresnel Schlick
            float3 fresnelSchlick(float3 F0, float cosTheta)
            {
                return F0 + (1 - F0) * pow(1 - cosTheta, 5);
            }

            // GGX Normal Distribution
            float D_GGX(float NdotH, float roughness)
            {
                float a    = roughness * roughness;
                float a2   = a * a;
                float denom = (NdotH * NdotH) * (a2 - 1) + 1;
                return a2 / (UNITY_PI * denom * denom);
            }

            // Schlick–GGX Geometry 
            float G_SchlickGGX(float NdotV, float roughness)
            {
                float r = (roughness + 1);
                float k = (r * r) / 8.0;
                return NdotV / (NdotV * (1 - k) + k);
            }

            // Attenuation (Point & Spot)
            float ComputeAttenuation(float3 lightPos, float3 worldPos, float range)
            {
                float d = distance(lightPos, worldPos);
                return saturate(1 - (d * d) / (range * range));
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // Normal y view
                float3 N = normalize(i.worldNorm);
                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);

                // Base F0 = ks
                float3 F0 = _MaterialKs.rgb;

                // === Ambient term ===
                float3 ambient = _AmbientColor.rgb * _MaterialKa.rgb;
                float3 result = ambient;

                // --- Directional Light ---
                {
                    float3 Ld = normalize(-_DirLightDirection.xyz);
                    float3 H  = normalize(V + Ld);
                    float NdotL = max(dot(N, Ld), 0);
                    float NdotV = max(dot(N, V), 0.001);
                    float NdotH = max(dot(N, H), 0);
                    float VdotH = max(dot(V, H), 0);

                    float3 F = fresnelSchlick(F0, VdotH);
                    float D = D_GGX(NdotH, _Roughness);
                    float G = G_SchlickGGX(NdotV, _Roughness) * G_SchlickGGX(NdotL, _Roughness);

                    float3 spec = (D * G * F) / max(4 * NdotV * NdotL, 0.001);
                    float3 diff = _MaterialKd.rgb / UNITY_PI;

                    result += _DirLightColor.rgb * _DirLightIntensity * NdotL * (diff + spec);
                }

                // --- Point Light ---
                {
                    float3 toP = _PointLightPosition_w.xyz - i.worldPos;
                    float3 Lp  = normalize(toP);
                    float NdotL = max(dot(N, Lp), 0);
                    float3 H   = normalize(V + Lp);
                    float NdotV = max(dot(N, V), 0.001);

                    float3 F = fresnelSchlick(F0, max(dot(V, H), 0));
                    float D = D_GGX(max(dot(N, H), 0), _Roughness);
                    float G = G_SchlickGGX(NdotV, _Roughness) * G_SchlickGGX(NdotL, _Roughness);
                    float att = ComputeAttenuation(_PointLightPosition_w.xyz, i.worldPos, _PointLightRange);

                    float3 spec = (D * G * F) / max(4 * NdotV * NdotL, 0.001);
                    float3 diff = _MaterialKd.rgb / UNITY_PI;

                    result += _PointLightColor.rgb * _PointLightIntensity * att * NdotL * (diff + spec);
                }

                // --- Spot Light ---
                {
                    float3 toS = _SpotLightPosition_w.xyz - i.worldPos;
                    float3 Ls  = normalize(toS);
                    float NdotL = max(dot(N, Ls), 0);
                    float3 H = normalize(V + Ls);
                    float cosAngle = dot(normalize(-_SpotLightDirection.xyz), Ls);
                    float cutoff = cos(radians(_SpotLightAngle));
                    float spot = step(cutoff, cosAngle);
                    float att = ComputeAttenuation(_SpotLightPosition_w.xyz, i.worldPos, _SpotLightRange) * spot;
                    float NdotV = max(dot(N, V), 0.001);

                    float3 F = fresnelSchlick(F0, max(dot(V, H), 0));
                    float D = D_GGX(max(dot(N, H), 0), _Roughness);
                    float G = G_SchlickGGX(NdotV, _Roughness) * G_SchlickGGX(NdotL, _Roughness);
                    float3 spec = (D * G * F) / max(4 * NdotV * NdotL, 0.001);
                    float3 diff = _MaterialKd.rgb / UNITY_PI;

                    result += _SpotLightColor.rgb * _SpotLightIntensity * att * NdotL * (diff + spec);
                }

                return float4(result, 1);
            }
            ENDCG
        }
    }
}
