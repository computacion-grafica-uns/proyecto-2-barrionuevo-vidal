Shader "Blinn_Phong_Multitextura"
{
    Properties
    {
        // Mapas de texturas
        _AlbedoMap ("Albedo (RGB)", 2D) = "white" {}
        _MetallicMap ("Metallic (R)", 2D) = "white" {}
        _AOMap ("Ambient Occlusion (R)",2D) = "white" {}

        // Parametros Blinn-Phong
        _MaterialKa ("Material Ka (Ambient)", Vector) = (0.2,0.2,0.2,1)
        _MaterialKd ("Material Kd (Diffuse)", Vector) = (0.6,0.6,0.6,1)
        _MaterialKs ("Material Ks (Specular)", Vector) = (1.0,1.0,1.0,1)
        _Shininess ("Shininess (Gloss)", Range(1,500)) = 32

        // Luz ambiental
        _AmbientColor  ("Ambient Light Color", Color) = (0.2,0.2,0.2,1)

        // Luz direccional
        _DirLightDirection ("Directional Light Dir", Vector) = (2,-1,0,0)
        _DirLightColor ("Directional Light Color", Color)  = (1,1,1,1)
        _DirLightIntensity ("Directional Intensity", Range(0,5)) = 1

        // Luz puntual
        _PointLightPosition_w ("Point Light Position", Vector) = (0,1,0,1)
        _PointLightColor ("Point Light Color", Color)  = (1,1,1,1)
        _PointLightIntensity ("Point Light Intensity", Range(0,10)) = 1
        _PointLightRange ("Point Light Range", Range(0.1,50)) = 10

        // Luz spot
        _SpotLightPosition_w ("Spot Light Position", Vector) = (0,1,0,1)
        _SpotLightDirection ("Spot Light Direction", Vector) = (0,-1,0,0)
        _SpotLightColor ("Spot Light Color", Color)  = (1,1,1,1)
        _SpotLightIntensity ("Spot Light Intensity", Range(0,10)) = 1
        _SpotLightRange ("Spot Light Range", Range(0.1,50)) = 15
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

            // Samplers multitextura
            sampler2D _AlbedoMap;
            sampler2D _MetallicMap;
            sampler2D _AOMap;

            // Coeficientes Blinn-Phong
            float4 _MaterialKa;  
            float4 _MaterialKd;  
            float4 _MaterialKs;  
            float  _Shininess;   

            // Luz ambiental
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
                float3 worldNorm: TEXCOORD1;
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

            // Atenuación simple
            float ComputeAttenuation(float3 lightPos, float3 worldPos, float range)
            {
                float d = distance(lightPos, worldPos);
                return saturate(1.0 - (d * d) / (range * range));
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // Muestreamos texturas
                float3 albedoSample = tex2D(_AlbedoMap, i.uv).rgb;     // color base
                float metallicSample = tex2D(_MetallicMap, i.uv).r;     // cuánto “metálico” 
                float aoSample = tex2D(_AOMap, i.uv).r;           // oclusión ambiental

                // Normal “por vértice” (sin NormalMap)
                float3 N = normalize(i.worldNorm);
                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);

                // Término ambiental (Ka * AmbientColor * AO)
                float3 ambientTerm = _AmbientColor.rgb * _MaterialKa.rgb * aoSample;
                float3 colorOut = ambientTerm;

                // Luz Direccional
                {
                    float3 L = normalize(-_DirLightDirection.xyz);
                    float NdotL = max(dot(N, L), 0);

                    if (NdotL > 0)
                    {
                        //  Difuso (Lambert)
                        // (Kd * albedo) modulado por (1 - metallic)
                        float3 kdAlbedo  = _MaterialKd.rgb * albedoSample;
                        float3 diffuseD = _DirLightColor.rgb * _DirLightIntensity * NdotL * kdAlbedo * (1 - metallicSample);

                        // Especular (Blinn-Phong)
                        float3 H = normalize(L + V);
                        float  NdotH = max(dot(N, H), 0);
                        float  specFac = pow(NdotH, _Shininess);

                        // Queremos interpolar entre Ks puro o albedo según metallic
                        float3 ksColor = _MaterialKs.rgb;
                        // Si es muy “metálico” tomamos albedoSample, si no, tomamos Ks
                        float3 specCol = lerp(ksColor, albedoSample, metallicSample);

                        float3 specD = _DirLightColor.rgb * _DirLightIntensity * specFac * specCol * metallicSample;

                        colorOut += diffuseD + specD;
                    }
                }

                // Luz Puntual
                {
                    float3 toP = _PointLightPosition_w.xyz - i.worldPos;
                    float3 L = normalize(toP);
                    float  atten = ComputeAttenuation(_PointLightPosition_w.xyz, i.worldPos, _PointLightRange);
                    float  NdotL = max(dot(N, L), 0);
                    float  NdotV = max(dot(N, V), 0.001);

                    if (NdotL > 0)
                    {
                        // Difuso
                        float3 kdAlbedo  = _MaterialKd.rgb * albedoSample;
                        float3 diffuseP = _PointLightColor.rgb * _PointLightIntensity * atten * NdotL * kdAlbedo * (1 - metallicSample);

                        // Especular
                        float3 H = normalize(L + V);
                        float NdotH = max(dot(N, H), 0);
                        float specFac = pow(NdotH, _Shininess);
                        float3 specCol = lerp(_MaterialKs.rgb, albedoSample, metallicSample);
                        float3 specP = _PointLightColor.rgb * _PointLightIntensity * atten * specFac * specCol * metallicSample;

                        colorOut += diffuseP + specP;
                    }
                }

                // Luz Spot
                {
                    float3 toS = _SpotLightPosition_w.xyz - i.worldPos;
                    float3 L = normalize(toS);
                    float  atten = ComputeAttenuation(_SpotLightPosition_w.xyz, i.worldPos, _SpotLightRange);
                    float  NdotL = max(dot(N, L), 0);
                    float  NdotV = max(dot(N, V), 0.001);

                    // Verificamos el ángulo de corte
                    float  cosAngle = dot(normalize(-_SpotLightDirection.xyz), L);
                    float  cutoff = cos(radians(_SpotLightAngle));
                    float  spotFac = step(cutoff, cosAngle);

                    if (NdotL > 0 && spotFac > 0)
                    {
                        // Difuso
                        float3 kdAlbedo = _MaterialKd.rgb * albedoSample;
                        float3 diffuseS = _SpotLightColor.rgb * _SpotLightIntensity * atten * spotFac * NdotL * kdAlbedo * (1 - metallicSample);

                        // Especular
                        float3 H = normalize(L + V);
                        float  NdotH = max(dot(N, H), 0);
                        float  specFac = pow(NdotH, _Shininess);
                        float3 specCol = lerp(_MaterialKs.rgb, albedoSample, metallicSample);
                        float3 specS = _SpotLightColor.rgb * _SpotLightIntensity * atten * spotFac * specFac * specCol * metallicSample;

                        colorOut += diffuseS + specS;
                    }
                }

                return float4(colorOut, 1);
            }
            ENDCG
        }
    }
}
