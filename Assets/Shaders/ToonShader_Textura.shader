Shader "ToonShader_Textura"
{
    Properties
    {
        // ====================================================
        // 1) Textura principal (Albedo)
        _MainTex       ("Albedo Texture",    2D)    = "white" {}
        _MainTex_ST    ("",                  Vector) = (1,1,0,0) 

        // 2) Colores especulares / base (se usarán junto a la textura)
        _SpecColor     ("Specular Color",    Color) = (1,1,1,1) 

        // 3) Umbral toon para difuso/especular (0..1)
        _Threshold     ("Toon Threshold",    Range(0,1)) = 0.5

        // 4) Grosor del contorno
        _OutlineWidth  ("Outline Width",     Range(0,0.2)) = 0.05

        // 5) Luz ambiental: siempre misma
        _AmbientColor  ("Ambient Light Color", Color) = (0.2,0.2,0.2,1)

        // 6) Luz direccional
        _DirLightDirection  ("Directional Light Dir",    Vector) = (2,-1,0,0)
        _DirLightColor      ("Directional Light Color",  Color)  = (1,1,1,1)
        _DirLightIntensity  ("Directional Intensity",    Range(0,5)) = 1

        // 7) Luz puntual
        _PointLightPosition_w  ("Point Light Position", Vector) = (0,1,0,1)
        _PointLightColor       ("Point Light Color",    Color)  = (1,1,1,1)
        _PointLightIntensity   ("Point Light Intensity", Range(0,10)) = 1
        _PointLightRange       ("Point Light Range",    Range(0.1,50)) = 20

        // 8) Luz spot
        _SpotLightPosition_w   ("Spot Light Position",  Vector) = (0,1,0,1)
        _SpotLightDirection   ("Spot Light Direction",  Vector) = (0,-1,0,0)
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
        // PASO 1: Dibujar el contorno (“outline”)
        // ====================================================
        Pass
        {
            Name "Outline"
            Tags { "LightMode"="Always" }

            Cull Front                // Rellenar la parte de atrás para generar contorno negro
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
                // Sacamos la normal en espacio mundo (para empujar los vértices)
                float3 worldN = UnityObjectToWorldNormal(v.normal);
                // Empujamos el vértice hacia fuera (en dirección normal) para obtener el grosor del contorno
                float3 displaced = v.vertex.xyz + worldN * _OutlineWidth;
                o.pos = UnityObjectToClipPos(float4(displaced, 1.0));
                return o;
            }

            fixed4 fragOutline(v2f_outline i) : SV_Target
            {
                // El contorno siempre negro puro
                return float4(0,0,0,1);
            }
            ENDCG
        }

        // ====================================================
        // PASO 2: Toon shading + Textura
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

            // ––––––––––––––––––––––––––––––––––––––––––––––––––––––
            // Variables (equivalentes a las Properties)
            // ––––––––––––––––––––––––––––––––––––––––––––––––––––––
            sampler2D _MainTex;
            float4   _MainTex_ST;

            float4   _SpecColor;      // Color del highlight especular
            float    _Threshold;      // Umbral para difuso / especular
            float4   _Color_UNUSED;   // (no se usa, puesto que tomamos color de _MainTex)

            float _OutlineWidth;      // (no se usa en este pase)

            // — Luz Ambiental —
            float4 _AmbientColor;

            // — Luz Direccional —
            float4 _DirLightDirection;     
            float4 _DirLightColor;  
            float  _DirLightIntensity;

            // — Luz Puntual —
            float4 _PointLightPosition_w;     
            float4 _PointLightColor;   
            float  _PointLightIntensity;     
            float  _PointLightRange;    

            // — Luz Spot —
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
                float4 pos      : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 worldNorm: TEXCOORD1;
                float2 uv       : TEXCOORD2;
            };

            // ––– VERTEX: calculamos posiciones / normales / UVs –
            v2f vert(appdata v)
            {
                v2f o;
                o.pos       = UnityObjectToClipPos(v.vertex);
                o.worldPos  = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNorm = normalize(UnityObjectToWorldNormal(v.normal));
                o.uv        = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            // Función auxiliar para atenuación de punto/spot
            float ComputeAttenuation(float3 lightPos, float3 worldPos, float range)
            {
                float d = distance(lightPos, worldPos);
                return saturate(1 - (d * d) / (range * range));
            }

            // Función Toon para pasos difuso (alto/bajo)
            float ToonDiffuseStep(float NdotL, float threshold)
            {
                // Si supera el umbral → 1.0, sino → 0.3 (o cualquier valor base)
                return (NdotL > threshold) ? 1.0 : 0.3;
            }

            // ––– FRAGMENT: calculamos el color toon basado en textura + luces –––
            fixed4 frag(v2f i) : SV_Target
            {
                // 1) Normalizamos vectores
                float3 N = normalize(i.worldNorm);
                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);

                // 2) Tomamos el color base desde la textura
                float3 albedo = tex2D(_MainTex, i.uv).rgb;

                // 3) Componente ambiental
                float3 ambient = _AmbientColor.rgb * albedo;
                float3 colorOut = ambient;

                // ======================
                // --- Directional Light ---
                // ======================
                {
                    float3 Ld = normalize(-_DirLightDirection.xyz);
                    float  NdotL = max(dot(N, Ld), 0);
                    float  diffFactor = ToonDiffuseStep(NdotL * _DirLightIntensity, _Threshold);

                    // Cálculo especular toon (destello circular)
                    float3 H = normalize(Ld + V);
                    float  NdotH = max(dot(N, H), 0);
                    float  specFactor = (NdotH * _DirLightIntensity > _Threshold) ? 1.0 : 0.0;

                    float3 diffD = _DirLightColor.rgb  * _DirLightIntensity * diffFactor * albedo;
                    float3 specD = _DirLightColor.rgb  * _DirLightIntensity * specFactor * _SpecColor.rgb;

                    colorOut += diffD + specD;
                }

                // ======================
                // --- Point Light ---
                // ======================
                {
                    float3 toP = _PointLightPosition_w.xyz - i.worldPos;
                    float3 Lp = normalize(toP);
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
                // --- Spot Light ---
                // ======================
                {
                    float3 toS = _SpotLightPosition_w.xyz - i.worldPos;
                    float3 Ls   = normalize(toS);
                    float  NdotL = max(dot(N, Ls), 0);

                    // Cálculo del corte angular de spot
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
