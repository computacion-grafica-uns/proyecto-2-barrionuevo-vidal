Shader "ShaderMultitextura"
{
    Properties
    {
        // --------------------------------------------------------
        // 1) Texturas PBR
        // --------------------------------------------------------
        _AlbedoTex    ("Albedo (RGB)",      2D) = "white" {}
        _MetallicTex  ("Metallic (R)",      2D) = "white" {}
        _RoughnessTex ("Roughness (R)",     2D) = "white" {}
        _NormalMap    ("Normal Map (RGB)",  2D) = "bump"  {}
        _AOTex        ("Ambient Occlusion (R)", 2D) = "white" {}
        _HeightMap    ("Height Map (R)",    2D) = "black" {}

        // --------------------------------------------------------
        // 2) Escala del parallax (Height)
        // --------------------------------------------------------
        _HeightScale  ("Height Scale", Range(0,0.1)) = 0.02

        // --------------------------------------------------------
        // 3) Color Tint (tinte global que multiplica el Albedo)
        // --------------------------------------------------------
        _ColorTint    ("Color Tint", Color) = (1,1,1,1)

        // --------------------------------------------------------
        // 4) Parámetros de iluminación
        //    • Ambiente
        //    • Direccional
        //    • Puntual
        //    • Spot
        // --------------------------------------------------------
        _AmbientColor         ("Ambient Light Color",        Color) = (0.2, 0.2, 0.2, 1)

        _DirLightDirection    ("Directional Light Dir",     Vector) = (2, -1, 0, 0)
        _DirLightColor        ("Directional Light Color",   Color)  = (1, 1, 1, 1)
        _DirLightIntensity    ("Directional Intensity",     Range(0,5)) = 1

        _PointLightPosition_w ("Point Light Position",      Vector) = (0, 3, 0, 1)
        _PointLightColor      ("Point Light Color",         Color) = (1, 1, 1, 1)
        _PointLightIntensity  ("Point Light Intensity",     Range(0,10)) = 1
        _PointLightRange      ("Point Light Range",         Range(0.1,50)) = 20

        _SpotLightPosition_w  ("Spot Light Position",       Vector) = (0, 4, 0, 1)
        _SpotLightDirection   ("Spot Light Direction",      Vector) = (0, -1, 0, 0)
        _SpotLightColor       ("Spot Light Color",          Color) = (1, 1, 1, 1)
        _SpotLightIntensity   ("Spot Light Intensity",      Range(0,10)) = 1
        _SpotLightRange       ("Spot Light Range",          Range(0.1,50)) = 20
        _SpotLightAngle       ("Spot Light Half-Angle",     Range(0,90)) = 25
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 400

        Pass
        {
            Name "ForwardManualPBR"
            Tags { "LightMode" = "ForwardBase" }

            Cull Back
            ZWrite On

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #include "UnityCG.cginc"

            // --------------------------------------------------------
            //  1) Samplers (texturas) y parámetros globales
            // --------------------------------------------------------
            sampler2D _AlbedoTex;
            sampler2D _MetallicTex;
            sampler2D _RoughnessTex;
            sampler2D _NormalMap;
            sampler2D _AOTex;
            sampler2D _HeightMap;

            half    _HeightScale;
            fixed4  _ColorTint;

            fixed4  _AmbientColor;          // luz ambiental

            float4  _DirLightDirection;
            fixed4  _DirLightColor;
            float   _DirLightIntensity;

            float4  _PointLightPosition_w;
            fixed4  _PointLightColor;
            float   _PointLightIntensity;
            float   _PointLightRange;

            float4  _SpotLightPosition_w;
            float4  _SpotLightDirection;
            fixed4  _SpotLightColor;
            float   _SpotLightIntensity;
            float   _SpotLightRange;
            float   _SpotLightAngle;

            // --------------------------------------------------------
            //  2) Datos de vértice → fragment
            // --------------------------------------------------------
            struct v2f
            {
                float4 pos       : SV_POSITION;
                float3 worldPos  : TEXCOORD0;
                float3 worldNorm : TEXCOORD1;
                float2 uvAlbedo  : TEXCOORD2;
                float2 uvMetal   : TEXCOORD3;
                float2 uvRough   : TEXCOORD4;
                float2 uvNormal  : TEXCOORD5;
                float2 uvAO      : TEXCOORD6;
                float2 uvHeight  : TEXCOORD7;
                float3 viewDir   : TEXCOORD8; // dirección de cámara en espacio mundo
            };

            // --------------------------------------------------------
            //  3) Vertex shader: calculamos posición, normal y UVs
            // --------------------------------------------------------
            v2f vert(appdata_full v)
            {
                v2f o;

                // Posición en clip space
                o.pos = UnityObjectToClipPos(v.vertex);

                // Posición y normal en espacio mundo
                o.worldPos  = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNorm = UnityObjectToWorldNormal(v.normal);

                // UVs (asumimos que todas las texturas usan UV0)
                o.uvAlbedo = v.texcoord;
                o.uvMetal  = v.texcoord;
                o.uvRough  = v.texcoord;
                o.uvNormal = v.texcoord;
                o.uvAO     = v.texcoord;
                o.uvHeight = v.texcoord;

                // Dirección de vista (cámara) en espacio mundo
                float3 worldCamPos = _WorldSpaceCameraPos;
                o.viewDir = normalize(worldCamPos - o.worldPos);

                return o;
            }

            // --------------------------------------------------------
            //  4) Función de parallax (height) muy simple
            // --------------------------------------------------------
            inline void ApplyParallax(inout float2 uv, float heightSample, float scale, float3 viewDirection)
            {
                // heightSample ∈ [0..1], lo centramos en 0: (h - 0.5)
                float h = (heightSample - 0.5) * scale;
                // offset proporcional a la proyección XY de viewDir
                float2 offset = normalize(viewDirection.xy) * h;
                uv += offset;
            }

            // --------------------------------------------------------
            //  5) Funciones de PBR (Cook-Torrance simplificado)
            // --------------------------------------------------------
            // Fresnel Schlick aproximado
            float3 FresnelSchlick(float3 F0, float cosTheta)
            {
                return F0 + (1 - F0) * pow(1 - cosTheta, 5);
            }

            // GGX Normal Distribution (NDF)
            float D_GGX(float NdotH, float roughness)
            {
                float a    = roughness * roughness;
                float a2   = a * a;
                float denom = (NdotH * NdotH) * (a2 - 1) + 1;
                return a2 / (UNITY_PI * denom * denom);
            }

            // Schlick-GGX geometric term
            float G_SchlickGGX(float NdotV, float roughness)
            {
                float r = (roughness + 1);
                float k = (r * r) / 8.0;
                return NdotV / (NdotV * (1 - k) + k);
            }

            // Attrueno de iluminación puntual/spot
            float ComputeAttenuation(float3 lightPos, float3 worldPos, float range)
            {
                float d = distance(lightPos, worldPos);
                return saturate(1.0 - (d * d) / (range * range));
            }

            // --------------------------------------------------------
            //  6) Fragment shader: aquí combinamos todo 
            // --------------------------------------------------------
            fixed4 frag(v2f i) : SV_Target
            {
                // --- 6.1) Parallax: movemos UV del Albedo ---
                float hSample    = tex2D(_HeightMap, i.uvHeight).r;
                float2 uvParallax = i.uvAlbedo;
                ApplyParallax(uvParallax, hSample, _HeightScale, i.viewDir);

                // --- 6.2) Muestreo de texturas PBR ---
                fixed4  albedoSample   = tex2D(_AlbedoTex,   uvParallax) * _ColorTint;
                float   metallicSample = tex2D(_MetallicTex, i.uvMetal).r;
                float   roughnessSample= tex2D(_RoughnessTex,i.uvRough).r;
                fixed3  normalSample   = UnpackNormal(tex2D(_NormalMap, i.uvNormal));
                float   aoSample       = tex2D(_AOTex,       i.uvAO).r;

                // Clamping por seguridad
                metallicSample  = saturate(metallicSample);
                roughnessSample = saturate(roughnessSample);
                aoSample        = saturate(aoSample);

                // Normal en espacio mundo (ya desempaquetada)
                float3 N = normalize(normalSample);
                // Vector de vista
                float3 V = normalize(i.viewDir);
                // Base F0: mezcla _ColorTint y un valor no metálico de ~0.04
                float3 F0 = lerp(float3(0.04, 0.04, 0.04), albedoSample.rgb, metallicSample);

                // Resultado acumulado RGB
                float3 result = 0;

                // --- 6.3) Componente ambiental PBR simplificada (occlusion) ---
                float3 ambient = _AmbientColor.rgb * albedoSample.rgb * aoSample;
                result += ambient;

                // --- 6.4) Luz DIRECCIONAL ---
                {
                    float3 Ld   = normalize(-_DirLightDirection.xyz); 
                    float3 H    = normalize(V + Ld);
                    float NdotL = max(dot(N, Ld), 0);
                    float NdotV = max(dot(N, V), 0.001);
                    float NdotH = max(dot(N, H), 0);
                    float VdotH = max(dot(V, H), 0);

                    // Fresnel
                    float3 F = FresnelSchlick(F0, VdotH);
                    // Distribución
                    float D = D_GGX(NdotH, roughnessSample);
                    // Geometría
                    float G = G_SchlickGGX(NdotV, roughnessSample) * G_SchlickGGX(NdotL, roughnessSample);

                    // Especular Cook-Torrance
                    float3 spec = (D * G * F) / max(4 * NdotV * NdotL, 0.001);

                    // Difuso (Lambertiano)
                    float3 diff = (1 - F) * albedoSample.rgb / UNITY_PI;

                    float3 ambientContribution   = 0; // ya agregado arriba
                    float3 directionalContribution = _DirLightColor.rgb * _DirLightIntensity * NdotL * (diff + spec);

                    result += directionalContribution;
                }

                // --- 6.5) Luz PUNTUAL ---
                {
                    float3 toP   = _PointLightPosition_w.xyz - i.worldPos;
                    float3 Lp    = normalize(toP);
                    float  NdotL = max(dot(N, Lp), 0);

                    float  attP  = ComputeAttenuation(_PointLightPosition_w.xyz, i.worldPos, _PointLightRange);

                    float3 H = normalize(V + Lp);
                    float  NdotV = max(dot(N, V), 0.001);
                    float  VdotH = max(dot(V, H), 0);

                    float3 F = FresnelSchlick(F0, VdotH);
                    float  D = D_GGX(max(dot(N, H), 0), roughnessSample);
                    float  G = G_SchlickGGX(NdotV, roughnessSample) * G_SchlickGGX(NdotL, roughnessSample);

                    float3 spec = (D * G * F) / max(4 * NdotV * NdotL, 0.001);
                    float3 diff = (1 - F) * albedoSample.rgb / UNITY_PI;

                    float3 pointContribution = _PointLightColor.rgb * _PointLightIntensity * attP * NdotL * (diff + spec);
                    result += pointContribution;
                }

                // --- 6.6) Luz SPOT ---
                {
                    float3 toS   = _SpotLightPosition_w.xyz - i.worldPos;
                    float3 Ls    = normalize(toS);
                    float  NdotL = max(dot(N, Ls), 0);

                    // Cálculo del “cutoff” angular
                    float  cosA  = dot(normalize(-_SpotLightDirection.xyz), Ls);
                    float  cutoff= cos(radians(_SpotLightAngle));
                    float  spotF = step(cutoff, cosA); // 1 si dentro del ángulo, 0 fuera

                    float  attS  = ComputeAttenuation(_SpotLightPosition_w.xyz, i.worldPos, _SpotLightRange) * spotF;

                    float3 H = normalize(V + Ls);
                    float   NdotV = max(dot(N, V), 0.001);
                    float   VdotH = max(dot(V, H), 0);

                    float3 F = FresnelSchlick(F0, VdotH);
                    float  D = D_GGX(max(dot(N, H), 0), roughnessSample);
                    float  G = G_SchlickGGX(NdotV, roughnessSample) * G_SchlickGGX(NdotL, roughnessSample);

                    float3 spec = (D * G * F) / max(4 * NdotV * NdotL, 0.001);
                    float3 diff = (1 - F) * albedoSample.rgb / UNITY_PI;

                    float3 spotContribution = _SpotLightColor.rgb * _SpotLightIntensity * attS * NdotL * (diff + spec);
                    result += spotContribution;
                }

                // --------------------------------------------------------
                //  6.7) Color final
                // --------------------------------------------------------
                return float4(result, 1);
            }
            ENDCG
        }
    }

    FallBack "Diffuse"
}
