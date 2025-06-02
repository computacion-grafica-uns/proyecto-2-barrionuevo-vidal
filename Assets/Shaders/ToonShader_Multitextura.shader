Shader "ToonShader_Multitextura"
{
    Properties
    {
        _BaseTex ("Base (Albedo) Texture", 2D) = "white" {}
        _DetailTex ("Detail/Mix Texture (R = máscara)", 2D) = "white" {}
        _DetailMaskUV ("Detail UV Tiling", Vector)  = (1, 1, 0, 0)

        // Color Tint (modula albedo resultante)
        _ColorTint ("Tint Color", Color) = (1, 1, 1, 1)

        // Umbral Toon (0..1)
        _Threshold ("Toon Threshold", Range(0,1)) = 0.6

        // Color especular “toon”:
        _SpecColor ("Specular Color", Color) = (1, 1, 1, 1)

        // Grosor del contorno:
        _OutlineWidth ("Outline Width", Range(0,0.1)) = 0.02

        // Ambiente
        _AmbientColor ("Ambient Light Color", Color) = (0.2, 0.2, 0.2, 1)

        // Direccional
        _DirLightDirection ("Directional Light Dir", Vector) = (2, -1, 0, 0)
        _DirLightColor ("Directional Light Color", Color)  = (1, 1, 1, 1)
        _DirLightIntensity ("Directional Intensity", Range(0,5)) = 1

        // Puntual
        _PointLightPosition_w("Point Light Position", Vector) = (0, 3, 0, 1)
        _PointLightColor ("Point Light Color", Color) = (1, 1, 1, 1)
        _PointLightIntensity ("Point Light Intensity", Range(0,10)) = 1
        _PointLightRange ("Point Light Range", Range(0.1,50)) = 20

        // Spot
        _SpotLightPosition_w ("Spot Light Position", Vector) = (0, 4, 0, 1)
        _SpotLightDirection ("Spot Light Direction", Vector) = (0, -1, 0, 0)
        _SpotLightColor ("Spot Light Color", Color) = (1, 1, 1, 1)
        _SpotLightIntensity ("Spot Light Intensity", Range(0,10)) = 1
        _SpotLightRange ("Spot Light Range", Range(0.1,50)) = 20
        _SpotLightAngle ("Spot Light Half-Angle", Range(0,90)) = 25
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 200

        Pass
        {
            Name "Outline"
            Tags { "LightMode" = "Always" }

            Cull Front
            ZWrite On
            ColorMask RGB

            CGPROGRAM
            #pragma vertex vertOutline
            #pragma fragment fragOutline
            #include "UnityCG.cginc"

            float _OutlineWidth;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f_outline
            {
                float4 pos : SV_POSITION;
            };

            v2f_outline vertOutline(appdata v)
            {
                v2f_outline o;
                // Expande el vértice hacia fuera usando la normal en espacio mundo
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 offsetPos   = v.vertex.xyz + worldNormal * _OutlineWidth;
                o.pos = UnityObjectToClipPos(float4(offsetPos, 1));
                return o;
            }

            fixed4 fragOutline(v2f_outline i) : SV_Target
            {
                // Dibujamos contorno negro siempre
                return float4(0, 0, 0, 1);
            }
            ENDCG
        }

        Pass
        {
            Name "ToonShading"
            Tags { "LightMode" = "ForwardBase" }

            Cull Back
            ZWrite On

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            // Texturas y sus coordenadas
            sampler2D _BaseTex;

            sampler2D _DetailTex;
            float4  _DetailMaskUV;     // x = tiling U, y = tiling V

            float4 _ColorTint; // multiplica albedo final

            float  _Threshold;
            float4 _SpecColor;

            // Ambiente
            float4 _AmbientColor;

            // Direccional
            float4 _DirLightDirection;
            float4 _DirLightColor;
            float  _DirLightIntensity;

            // Puntual
            float4 _PointLightPosition_w;
            float4 _PointLightColor;
            float  _PointLightIntensity;
            float  _PointLightRange;

            // Spot
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
                float2 uvBase : TEXCOORD0;  // UV para BaseTex
                float2 uvDetail: TEXCOORD1;  // UV para DetailTex
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 worldNorm : TEXCOORD1;
                float2 uvBase : TEXCOORD2;
                float2 uvDetail : TEXCOORD3;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos  = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNorm = normalize(UnityObjectToWorldNormal(v.normal));
                o.uvBase = v.uvBase;
                // reescala las UV de la segunda textura con _DetailMaskUV.xy
                o.uvDetail  = v.uvDetail * _DetailMaskUV.xy;
                return o;
            }

            // Función de attenuación (igual para punto y spot)
            float ComputeAttenuation(float3 lightPos, float3 worldPos, float range)
            {
                float dist = distance(lightPos, worldPos);
                return saturate(1 - (dist * dist) / (range * range));
            }

            // Función Toon para el componente difuso (dos niveles: clara u oscura)
            float ToonDiffuseStep(float x, float threshold)
            {
                return (x > threshold) ? 1.0 : 0.3;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 colBase = tex2D(_BaseTex, i.uvBase).rgb;
                float3 colDetail = tex2D(_DetailTex, i.uvDetail).rgb;

                float  maskValue = colDetail.r;

                // Color final del albedo antes de iluminación:
                // mezcla colBase y colDetail.
                float3 albedo = lerp(colBase, colDetail, maskValue);

                // Aplica el tint general
                albedo *= _ColorTint.rgb;

                // vectores normales y view
                float3 N = normalize(i.worldNorm);
                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);

                float3 colorOut = _AmbientColor.rgb * albedo;

                // Luz Direccional
                {
                    float3 Ld   = normalize(-_DirLightDirection.xyz);
                    float  NdotL = max(dot(N, Ld), 0);

                    // obtengo “blanco u oscuro” dependiendo del umbral
                    float diffFactor = ToonDiffuseStep(NdotL * _DirLightIntensity, _Threshold);

                    // specular “toon”
                    float3 H = normalize(Ld + V);
                    float  NdotH = max(dot(N, H), 0);
                    float  specFactor = (NdotH * _DirLightIntensity > _Threshold) ? 1.0 : 0.0;

                    float3 diffD = _DirLightColor.rgb * _DirLightIntensity * diffFactor * albedo;
                    float3 specD = _DirLightColor.rgb * _DirLightIntensity * specFactor * _SpecColor.rgb;
                    colorOut += diffD + specD;
                }

                // Luz puntual
                {
                    float3 toP   = _PointLightPosition_w.xyz - i.worldPos;
                    float3 Lp    = normalize(toP);
                    float  NdotL = max(dot(N, Lp), 0);

                    float  attP = ComputeAttenuation(_PointLightPosition_w.xyz, i.worldPos, _PointLightRange);
                    float  diffFactor = ToonDiffuseStep(NdotL * _PointLightIntensity * attP, _Threshold);

                    float3 H = normalize(Lp + V);
                    float  NdotH = max(dot(N, H), 0);
                    float  specFactor = ((NdotH * _PointLightIntensity * attP) > _Threshold) ? 1.0 : 0.0;

                    float3 diffP = _PointLightColor.rgb * _PointLightIntensity * attP * diffFactor * albedo;
                    float3 specP = _PointLightColor.rgb * _PointLightIntensity * attP * specFactor * _SpecColor.rgb;
                    colorOut += diffP + specP;
                }

                // Luz Spot
                {
                    float3 toS = _SpotLightPosition_w.xyz - i.worldPos;
                    float3 Ls  = normalize(toS);
                    float  NdotL = max(dot(N, Ls), 0);

                    // corte angular
                    float  cosA  = dot(normalize(-_SpotLightDirection.xyz), Ls);
                    float  cutoff= cos(radians(_SpotLightAngle));
                    float  spotF = step(cutoff, cosA);

                    float  attS = ComputeAttenuation(_SpotLightPosition_w.xyz, i.worldPos, _SpotLightRange) * spotF;
                    float  diffFactor = ToonDiffuseStep(NdotL * _SpotLightIntensity * attS, _Threshold);

                    float3 H = normalize(Ls + V);
                    float  NdotH = max(dot(N, H), 0);
                    float  specFactor = ((NdotH * _SpotLightIntensity * attS) > _Threshold) ? 1.0 : 0.0;

                    float3 diffS = _SpotLightColor.rgb * _SpotLightIntensity * attS * diffFactor * albedo;
                    float3 specS = _SpotLightColor.rgb * _SpotLightIntensity * attS * specFactor * _SpecColor.rgb;
                    colorOut += diffS + specS;
                }

                return float4(colorOut, 1);
            }
            ENDCG
        }
    }

}
