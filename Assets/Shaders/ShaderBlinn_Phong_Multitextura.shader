Shader "ShaderBlinn_Phong_Multitextura"
{
    Properties
    {
        // Mapas multitextura (PBR)
        _AlbedoMap ("Albedo (RGB)", 2D) = "white" {}
        _NormalMap ("Normal Map", 2D) = "bump"  {}
        _MetallicMap ("Metallic (R)", 2D) = "white" {}
        _AOMap ("Ambient Occlusion (R)",2D) = "white" {}
        _HeightMap ("Height Map (R)", 2D) = "black" {} 

        // Parámetros Blinn-Phong “tradicionales”
        _SpecularColor ("Specular Color", Color) = (1,1,1,1)
        _Shininess ("Shininess (Gloss)", Range(1,500)) = 32

        // Ambiente 
        _AmbientColor ("Ambient Light Color", Color) = (0.2,0.2,0.2,1)

        // Directional
        _DirLightDirection ("Directional Light Dir", Vector) = (2,-1,0,0)
        _DirLightColor ("Directional Light Color", Color) = (1,1,1,1)
        _DirLightIntensity ("Directional Intensity", Range(0,5)) = 1

        // Point
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
            sampler2D _NormalMap;
            sampler2D _MetallicMap;
            sampler2D _AOMap;
            sampler2D _HeightMap;

            float4 _SpecularColor;
            float  _Shininess;

            // Ambiente 
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
                float2 uv     : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos       : SV_POSITION;
                float3 worldPos  : TEXCOORD0;
                float3 worldNorm : TEXCOORD1;
                float2 uv        : TEXCOORD2;
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
                float3 normalT = tex2D(_NormalMap, i.uv).xyz * 2 - 1; 
                normalT.xy *= float2(1,1); 
                normalT = normalize(normalT);

                float3 dp1 = ddx(i.worldPos);
                float3 dp2 = ddy(i.worldPos);
                float2 duv1 = ddx(i.uv);
                float2 duv2 = ddy(i.uv);
                float3 T = normalize(dp1 * duv2.y - dp2 * duv1.y);
                float3 B = normalize(cross(i.worldNorm, T));
                float3 Nw = normalize(i.worldNorm);
                float3x3 TBN = float3x3(T, B, Nw);
                float3 surfNormal = normalize(mul(normalT, TBN));

                // Height:
                // Desplaza las UV en función del ángulo de vista y del canal de altura
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                float h        = tex2D(_HeightMap, i.uv).r; 
                float heightScale = 0.05;
                float parallaxAmount = h * heightScale * viewDir.z;
                float2 uvOffset = i.uv + viewDir.xy * parallaxAmount;

                // Usaremos uvOffset para albedo, metallic y AO
                float2 uvAlbedo   = uvOffset;
                float2 uvMetallic = uvOffset;
                float2 uvAO       = uvOffset;

                // Muestreo multitextura:
                float3 albedo   = tex2D(_AlbedoMap, uvAlbedo).rgb;
                float  metallic = tex2D(_MetallicMap, uvMetallic).r;
                float  ao       = tex2D(_AOMap, uvAO).r;

                // Vector de vista
                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);

                // Componente ambiental atenuada por AO
                float3 ambientTerm = _AmbientColor.rgb * albedo * ao;
                float3 colorOut = ambientTerm;

                // Luz Direccional
                {
                    float3 L = normalize(-_DirLightDirection.xyz);
                    float  NdotL = max(dot(surfNormal, L), 0);
                    if (NdotL > 0)
                    {
                        // Difuso (Lambert) atenuado por (1 – metallic)
                        float3 diff = _DirLightColor.rgb 
                                      * _DirLightIntensity 
                                      * NdotL 
                                      * albedo 
                                      * (1 - metallic);

                        // Especular (Blinn-Phong)
                        float3 H       = normalize(L + V);
                        float  NdotH   = max(dot(surfNormal, H), 0);
                        float  specFac = pow(NdotH, _Shininess);

                        // Color especular depende de metallic:
                        // – Si metallic == 1: usamos albedo como color especular.
                        // – Si metallic == 0: usamos _SpecularColor.
                        float3 specCol = lerp(_SpecularColor.rgb, albedo, metallic);

                        float3 spec = _DirLightColor.rgb 
                                      * _DirLightIntensity 
                                      * specFac 
                                      * specCol 
                                      * metallic;

                        colorOut += diff + spec;
                    }
                }

                // Luz Puntual
                {
                    float3 toP     = _PointLightPosition_w.xyz - i.worldPos;
                    float3 L       = normalize(toP);
                    float  distAtt = ComputeAttenuation(_PointLightPosition_w.xyz, i.worldPos, _PointLightRange);
                    float  NdotL   = max(dot(surfNormal, L), 0);
                    if (NdotL > 0)
                    {
                        // Difuso
                        float3 diff = _PointLightColor.rgb 
                                      * _PointLightIntensity 
                                      * distAtt 
                                      * NdotL 
                                      * albedo 
                                      * (1 - metallic);

                        // Especular
                        float3 H       = normalize(L + V);
                        float  NdotH   = max(dot(surfNormal, H), 0);
                        float  specFac = pow(NdotH, _Shininess);
                        float3 specCol = lerp(_SpecularColor.rgb, albedo, metallic);
                        float3 spec    = _PointLightColor.rgb 
                                         * _PointLightIntensity 
                                         * distAtt 
                                         * specFac 
                                         * specCol 
                                         * metallic;

                        colorOut += diff + spec;
                    }
                }

                // Luz Spot
                {
                    float3 toS = _SpotLightPosition_w.xyz - i.worldPos;
                    float3 L = normalize(toS);
                    float distAtt = ComputeAttenuation(_SpotLightPosition_w.xyz, i.worldPos, _SpotLightRange);

                    // Filtrado del ángulo del spot
                    float cosAngle = dot(normalize(-_SpotLightDirection.xyz), L);
                    float cutoff = cos(radians(_SpotLightAngle));
                    float spotFac = step(cutoff, cosAngle);

                    float  NdotL = max(dot(surfNormal, L), 0);
                    if (NdotL > 0 && spotFac > 0)
                    {
                        // Difuso
                        float3 diff = _SpotLightColor.rgb 
                                      * _SpotLightIntensity 
                                      * distAtt 
                                      * spotFac 
                                      * NdotL 
                                      * albedo 
                                      * (1 - metallic);

                        // Especular
                        float3 H       = normalize(L + V);
                        float  NdotH   = max(dot(surfNormal, H), 0);
                        float  specFac = pow(NdotH, _Shininess);
                        float3 specCol = lerp(_SpecularColor.rgb, albedo, metallic);
                        float3 spec    = _SpotLightColor.rgb 
                                         * _SpotLightIntensity 
                                         * distAtt 
                                         * spotFac 
                                         * specFac 
                                         * specCol 
                                         * metallic;

                        colorOut += diff + spec;
                    }
                }

                return float4(colorOut, 1);
            }
            ENDCG
        }
    }
}
