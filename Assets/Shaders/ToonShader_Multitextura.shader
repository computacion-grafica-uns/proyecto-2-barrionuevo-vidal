Shader "Custom/Toon_MultiTexture2"
{
    Properties
    {
        // ====================================================
        // TEXTURAS MULTI: al menos dos mapas de color
        // ====================================================
        _MainTex       ("Albedo Texture 1",   2D)    = "white" {}
        _MainTex_ST    ("",                   Vector) = (1,1,0,0)

        _SecondTex     ("Albedo Texture 2",   2D)    = "white" {}
        _SecondTex_ST  ("",                   Vector) = (1,1,0,0)

        // Si quisieras controlar la mezcla con un parámetro:
        // _BlendFactor   ("Blend Factor (0=Solo1, 1=Solo2)", Range(0,1)) = 0.5

        // Especular (Toon-highlight)
        _SpecColor     ("Specular Color",    Color) = (1,1,1,1)

        // Umbral toon
        _Threshold     ("Toon Threshold",    Range(0,1)) = 0.5

        // Grosor de contorno
        _OutlineWidth  ("Outline Width",     Range(0.0,0.2)) = 0.05

        // Luz Ambiental (constante)
        _AmbientColor  ("Ambient Light Color", Color) = (0.2,0.2,0.2,1)

        // === Luz Direccional ===
        _DirLightDirection  ("Directional Light Dir",    Vector) = (2,-1,0,0)
        _DirLightColor      ("Directional Light Color",  Color)  = (1,1,1,1)
        _DirLightIntensity  ("Directional Intensity",    Range(0,5)) = 1

        // === Luz Puntual ===
        _PointLightPosition_w  ("Point Light Position", Vector) = (0,1,0,1)
        _PointLightColor       ("Point Light Color",    Color)  = (1,1,1,1)
        _PointLightIntensity   ("Point Light Intensity", Range(0,10)) = 1
        _PointLightRange       ("Point Light Range",    Range(0.1,50)) = 20

        // === Luz Spot ===
        _SpotLightPosition_w   ("Spot Light Position",  Vector) = (0,1,0,1)
        _SpotLightDirection    ("Spot Light Direction", Vector) = (0,-1,0,0)
        _SpotLightColor        ("Spot Light Color",     Color)  = (1,1,1,1)
        _SpotLightIntensity    ("Spot Light Intensity", Range(0,10)) = 1
        _SpotLightRange        ("Spot Light Range",     Range(0.1,50)) = 20
        _SpotLightAngle        ("Spot Light Half-Angle",Range(0,90)) = 25
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        LOD 200

        // ====================================================
        // PASS 1: OUTLINE (contorno negro)
        // ====================================================
        Pass
        {
            Name "Outline"
            Tags { "LightMode"="Always" }

            Cull Front                // Cull front para que el desplazamiento genere contorno
            ZWrite On
            ColorMask RGB             // Sólo escribimos RGB (no modificamos alpha)

            CGPROGRAM
            #pragma vertex vertOutline
            #pragma fragment fragOutline
            #include "UnityCG.cginc"

            float _OutlineWidth;

            struct appdata_outline
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f_outline
            {
                float4 pos : SV_POSITION;
            };

            v2f_outline vertOutline(appdata_outline v)
            {
                v2f_outline o;
                float3 worldN = UnityObjectToWorldNormal(v.normal);
                float3 displaced = v.vertex.xyz + worldN * _OutlineWidth;
                o.pos = UnityObjectToClipPos(float4(displaced,1.0));
                return o;
            }

            fixed4 fragOutline(v2f_outline i) : SV_Target
            {
                return float4(0,0,0,1);   // Contorno negro puro
            }
            ENDCG
        }

        // ====================================================
        // PASS 2: TOON SHADING + 2 TEXTURAS
        // ====================================================
        Pass
        {
            Name "ToonShading"
            Tags { "LightMode"="ForwardBase" }

            Cull Back
            ZWrite On

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            // ----- Texturas -----
            sampler2D _MainTex;
            float4   _MainTex_ST;

            sampler2D _SecondTex;
            float4   _SecondTex_ST;

            // Si quisieras un parámetro de mezcla:
            // float _BlendFactor;

            // Especular toon
            float4   _SpecColor;
            float    _Threshold;
            float    _OutlineWidth_UNUSED;

            // Ambient
            float4   _AmbientColor;

            // Directional
            float4   _DirLightDirection;
            float4   _DirLightColor;
            float    _DirLightIntensity;

            // Point
            float4   _PointLightPosition_w;
            float4   _PointLightColor;
            float    _PointLightIntensity;
            float    _PointLightRange;

            // Spot
            float4   _SpotLightPosition_w;
            float4   _SpotLightDirection;
            float4   _SpotLightColor;
            float    _SpotLightIntensity;
            float    _SpotLightRange;
            float    _SpotLightAngle;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv     : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos      : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 worldNorm: TEXCOORD1;
                float2 uv       : TEXCOORD2;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos       = UnityObjectToClipPos(v.vertex);
                o.worldPos  = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNorm = normalize(UnityObjectToWorldNormal(v.normal));
                o.uv        = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            // Atenuación punto/spot
            float ComputeAttenuation(float3 lightPos, float3 worldPos, float range)
            {
                float d = distance(lightPos, worldPos);
                return saturate(1 - (d * d) / (range * range));
            }

            // Toon step para difuso
            float ToonDiffuseStep(float NdotL, float threshold)
            {
                return (NdotL > threshold) ? 1.0 : 0.3;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // Normal y vector “view”
                float3 N = normalize(i.worldNorm);
                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);

                // --- 1) OBTENER COLOR COMBINADO DE LAS 2 TEXTURAS ---
                // Sample de ambas texturas
                float3 color1 = tex2D(_MainTex, i.uv).rgb;
                float3 color2 = tex2D(_SecondTex, i.uv).rgb;

                // Simple mezcla multiplicativa (puedes cambiarlo a un LERP si quieres)
                float3 albedo = color1 * color2;
                // Ejemplo alternativo (LERP):
                // float3 albedo = lerp(color1, color2, _BlendFactor);

                // --- 2) AMBIENTAL ---
                float3 ambient = _AmbientColor.rgb * albedo;
                float3 colorOut = ambient;

                // ======================
                // --- LUZ DIRECCIONAL ---
                // ======================
                {
                    float3 Ld = normalize(-_DirLightDirection.xyz);
                    float  NdotL = max(dot(N, Ld), 0);
                    // Difuso toon
                    float  diffFactor = ToonDiffuseStep(NdotL * _DirLightIntensity, _Threshold);

                    // Especular toon (destello simple)
                    float3 H = normalize(Ld + V);
                    float  NdotH = max(dot(N, H), 0);
                    float  specFactor = ((NdotH * _DirLightIntensity) > _Threshold) ? 1.0 : 0.0;

                    float3 diffD = _DirLightColor.rgb * _DirLightIntensity * diffFactor * albedo;
                    float3 specD = _DirLightColor.rgb * _DirLightIntensity * specFactor * _SpecColor.rgb;

                    colorOut += diffD + specD;
                }

                // ======================
                // --- LUZ PUNTUAL ---
                // ======================
                {
                    float3 toP = _PointLightPosition_w.xyz - i.worldPos;
                    float3 Lp  = normalize(toP);
                    float  NdotL = max(dot(N, Lp), 0);

                    float  attP = ComputeAttenuation(_PointLightPosition_w.xyz, i.worldPos, _PointLightRange);
                    float  diffFactorP = ToonDiffuseStep(NdotL * _PointLightIntensity * attP, _Threshold);

                    float3 H = normalize(Lp + V);
                    float  NdotH = max(dot(N, H), 0);
                    float  specFactorP = ((NdotH * _PointLightIntensity * attP) > _Threshold) ? 1.0 : 0.0;

                    float3 diffP = _PointLightColor.rgb * _PointLightIntensity * attP * diffFactorP * albedo;
                    float3 specP = _PointLightColor.rgb * _PointLightIntensity * attP * specFactorP * _SpecColor.rgb;

                    colorOut += diffP + specP;
                }

                // ======================
                // --- LUZ SPOT ---
                // ======================
                {
                    float3 toS    = _SpotLightPosition_w.xyz - i.worldPos;
                    float3 Ls     = normalize(toS);
                    float  NdotL  = max(dot(N, Ls), 0);

                    // Cálculo de “corte” angular del spot
                    float cosAngle = dot(normalize(-_SpotLightDirection.xyz), Ls);
                    float cutoff  = cos(radians(_SpotLightAngle));
                    float spotF  = step(cutoff, cosAngle);

                    float attS = ComputeAttenuation(_SpotLightPosition_w.xyz, i.worldPos, _SpotLightRange) * spotF;
                    float diffFactorS = ToonDiffuseStep(NdotL * _SpotLightIntensity * attS, _Threshold);

                    float3 H = normalize(Ls + V);
                    float  NdotH = max(dot(N, H), 0);
                    float  specFactorS = ((NdotH * _SpotLightIntensity * attS) > _Threshold) ? 1.0 : 0.0;

                    float3 diffS = _SpotLightColor.rgb * _SpotLightIntensity * attS * diffFactorS * albedo;
                    float3 specS = _SpotLightColor.rgb * _SpotLightIntensity * attS * specFactorS * _SpecColor.rgb;

                    colorOut += diffS + specS;
                }

                return float4(colorOut, 1.0);
            }
            ENDCG
        }
    }
}
