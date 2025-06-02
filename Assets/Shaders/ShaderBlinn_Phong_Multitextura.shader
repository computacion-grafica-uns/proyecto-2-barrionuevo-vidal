Shader "ShaderBlinn_Phong_Multitextura"
{
    Properties
    {
        // Texturas
        _AlbedoMap ("Albedo (RGB)", 2D) = "white" {}
        _MetallicMap ("Metallic (R)", 2D) = "white" {}
        _AOMap ("Ambient Occlusion (R)", 2D) = "white" {}
        _HeightMap ("Height Map (R)", 2D) = "black" {}

        // Propiedades del material
        _MaterialKa ("Material Ka (Ambient)", Vector) = (0.2,0.2,0.2,1)
        _MaterialKd ("Material Kd (Diffuse)", Vector) = (1.0,1.0,1.0,1)
        _MaterialKs ("Material Ks (Specular)", Vector) = (1.0,1.0,1.0,1)
        _Shininess ("Shininess (Gloss)", Range(1,500)) = 32

        // Ambiente
        _AmbientColor ("Ambient Light Color", Color) = (0.2,0.2,0.2,1)

        // Direccional
        _DirLightDirection ("Directional Light Dir", Vector) = (2,-1,0,0)
        _DirLightColor ("Directional Light Color", Color)  = (1,1,1,1)
        _DirLightIntensity ("Directional Intensity", Range(0,5)) = 1

        // Puntual
        _PointLightPosition_w ("Point Light Position", Vector) = (0,1,0,1)
        _PointLightColor ("Point Light Color", Color) = (1,1,1,1)
        _PointLightIntensity ("Point Light Intensity", Range(0,10)) = 1
        _PointLightRange ("Point Light Range", Range(0.1,50)) = 10

        // Spot
        _SpotLightPosition_w ("Spot Light Position", Vector) = (0,1,0,1)
        _SpotLightDirection ("Spot Light Direction", Vector) = (0,-1,0,0)
        _SpotLightColor ("Spot Light Color", Color) = (1,1,1,1)
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

            sampler2D _AlbedoMap;
            sampler2D _MetallicMap;
            sampler2D _AOMap;
            sampler2D _HeightMap;

            float4 _MaterialKa;  
            float4 _MaterialKd;    
            float4 _MaterialKs;    
            float  _Shininess;     

            float4 _AmbientColor;

            float4 _DirLightDirection;
            float4 _DirLightColor;
            float  _DirLightIntensity;

            float4 _PointLightPosition_w;
            float4 _PointLightColor;
            float  _PointLightIntensity;
            float  _PointLightRange;

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
                // sin Normal Map, usamos normal del vértice
                float3 surfNormal = normalize(i.worldNorm);

                // Height Map para UVs
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                float  heightSample = tex2D(_HeightMap, i.uv).r;
                float  heightScale = 0.05;
                // Ajustamos el factor de parallax en base a viewDir.z
                float  parallaxOffset = (heightSample - 0.5) * heightScale / viewDir.z;
                float2 uvOffset = i.uv + viewDir.xy * parallaxOffset;

                // UVs desplazadas para Albedo, Metallic, AO
                float2 uvAlbedo = uvOffset;
                float2 uvMetallic = uvOffset;
                float2 uvAO = uvOffset;

                // Muestreo multitextura
                float3 albedoSample = tex2D(_AlbedoMap, uvAlbedo).rgb;   // color base difuso
                float  metallicSample = tex2D(_MetallicMap, uvMetallic).r; // canal rojo como metallic
                float  aoSample = tex2D(_AOMap, uvAO).r;            // canal rojo como occlusion

                // Componente ambiental: Ka * Ia * AO
                float3 ambientTerm = _AmbientColor.rgb * _MaterialKa.rgb * aoSample;
                float3 colorOut    = ambientTerm;

                // Vector vista
                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);

                // Luz direccional
                {
                    float3 L = normalize(-_DirLightDirection.xyz);
                    float NdotL = max(dot(surfNormal, L), 0);

                    if (NdotL > 0)
                    {
                        // Difuso
                        float3 diff = _DirLightColor.rgb * _DirLightIntensity * NdotL * albedoSample * _MaterialKd.rgb * (1.0 - metallicSample);

                        // Especular
                        float3 H = normalize(L + V);
                        float NdotH = max(dot(surfNormal, H), 0);
                        float specFac = pow(NdotH, _Shininess);

                        // El color especular se interpola entre _MaterialKs y el albedo en base a metallic
                        float3 specCol = lerp(_MaterialKs.rgb, albedoSample, metallicSample);
                        float3 spec = _DirLightColor.rgb * _DirLightIntensity * specFac * specCol * metallicSample;

                        colorOut += diff + spec;
                    }
                }

                // Luz puntual
                {
                    float3 toP = _PointLightPosition_w.xyz - i.worldPos;
                    float3 L = normalize(toP);
                    float  distAtt = ComputeAttenuation(_PointLightPosition_w.xyz, i.worldPos, _PointLightRange);
                    float  NdotL = max(dot(surfNormal, L), 0);

                    if (NdotL > 0)
                    {
                        // Difuso
                        float3 diff = _PointLightColor.rgb * _PointLightIntensity * distAtt * NdotL * albedoSample * _MaterialKd.rgb * (1.0 - metallicSample);

                        // Especular
                        float3 H = normalize(L + V);
                        float  NdotH = max(dot(surfNormal, H), 0);
                        float  specFac = pow(NdotH, _Shininess);
                        float3 specCol = lerp(_MaterialKs.rgb, albedoSample, metallicSample);
                        float3 spec = _PointLightColor.rgb * _PointLightIntensity * distAtt * specFac * specCol * metallicSample;

                        colorOut += diff + spec;
                    }
                }

                // Luz spot
                {
                    float3 toS = _SpotLightPosition_w.xyz - i.worldPos;
                    float3 L = normalize(toS);
                    float distAtt = ComputeAttenuation(_SpotLightPosition_w.xyz, i.worldPos, _SpotLightRange);

                    // Filtrado de ángulo del spot
                    float cosAngle = dot(normalize(-_SpotLightDirection.xyz), L);
                    float cutoff = cos(radians(_SpotLightAngle));
                    float spotFac = step(cutoff, cosAngle);

                    float NdotL = max(dot(surfNormal, L), 0);
                    if (NdotL > 0 && spotFac > 0)
                    {
                        // Difuso
                        float3 diff = _SpotLightColor.rgb * _SpotLightIntensity * distAtt * spotFac * NdotL * albedoSample * _MaterialKd.rgb * (1.0 - metallicSample);

                        // Especular
                        float3 H = normalize(L + V);
                        float  NdotH = max(dot(surfNormal, H), 0);
                        float  specFac = pow(NdotH, _Shininess);
                        float3 specCol = lerp(_MaterialKs.rgb, albedoSample, metallicSample);
                        float3 spec = _SpotLightColor.rgb * _SpotLightIntensity * distAtt * spotFac * specFac * specCol * metallicSample;

                        colorOut += diff + spec;
                    }
                }

                return float4(colorOut, 1);
            }
            ENDCG
        }
    }
}
