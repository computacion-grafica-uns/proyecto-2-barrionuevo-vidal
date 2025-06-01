Shader "ToonShader"
{
    Properties
    {
        // Color base del material
        _Color ("Base Color", Color) = (0.40, 0.60, 1.00, 1)
        _SpecColor ("Specular Color", Color) = (1, 1, 1, 1)

        // Umbral para separar zona clara / zona oscura
        _Threshold ("Toon_Threshold", Range(0,1)) = 0.5

        // Grosor del contorno
        _OutlineWidth ("Outline Width", Range(0.0,0.1)) = 0

        // Luz ambiental
        _AmbientColor ("Ambient Light Color", Color) = (0.20, 0.20, 0.20, 1)

        // Directional
        _DirLightDirection("Directional Light Dir",Vector) = (2,-1,0,0)
        _DirLightColor("Directional Light Color",  Color)  = (1,1,1,1)
        _DirLightIntensity("Directional Intensity",Range(0,5)) = 1

        // Point
        _PointLightPosition_w("Point Light Position",Vector) = (6,8,2,1)
        _PointLightColor("Point Light Color",Color)  = (1,1,1,1)
        _PointLightIntensity("Point Light Intensity",Range(0,10)) = 1
        _PointLightRange("Point Light Range",Range(0.1,50))= 15

        // Spot
        _SpotLightPosition_w("Spot Light Position",Vector) = (6,10,2,1)
        _SpotLightDirection("Spot Light Direction",Vector) = (0,-1,0,0)
        _SpotLightColor("Spot Light Color",Color)  = (1,1,1,1)
        _SpotLightIntensity("Spot Light Intensity",Range(0,10)) = 1
        _SpotLightRange("Spot Light Range",Range(0.1,50))= 15
        _SpotLightAngle("Spot Light Half-Angle",Range(0,90)) = 30

    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
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
            float4 _Color;

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
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 offsetPos   = v.vertex.xyz + worldNormal * _OutlineWidth;
                o.pos = UnityObjectToClipPos(float4(offsetPos, 1.0));
                return o;
            }

            fixed4 fragOutline(v2f_outline i) : SV_Target
            {
                // Contorno NEGRO
                return float4(0, 0, 0, 1);
            }
            ENDCG
        }

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

            float4 _Color;           // Color base del material
            float4 _SpecColor;       // Color del “highlight” especular
            float  _Threshold;       // Umbral toon (0..1)
            float  _OutlineWidth;    // (no se usa en este pase, solo en el pase Outline)

            // Luz ambiente (fija para toda la escena)
            float4 _AmbientColor;

            // ==== Luz direccional ====
            float4 _DirLightDirection;     
            float4 _DirLightColor;   
            float  _DirLightIntensity;   

            // ==== Luz puntual ====
            float4 _PointLightPosition_w;    
            float4 _PointLightColor; 
            float  _PointLightIntensity;     
            float  _PointLightRange;   

            // ==== Luz spot ====
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
            };

            struct v2f
            {
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

            float ComputeAttenuation(float3 lightPos, float3 worldPos, float range)
            {
                float d = distance(lightPos, worldPos);
                return saturate(1 - (d * d) / (range * range));
            }

            // Función para “escalar” a dos niveles 
            // (difusa clara / difusa oscura)
            float ToonDiffuseStep(float NdotL, float threshold)
            {
                // Si está por encima del umbral --> 1, sino 0.3
                return (NdotL > threshold) ? 1.0 : 0.3;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // Normal y Vector “view”
                float3 N = normalize(i.worldNorm);
                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);

                float3 ambient = _AmbientColor.rgb * _Color.rgb;
                float3 colorOut = ambient;

                {
                    float3 Ld = normalize(-_DirLightDirection.xyz);
                    float  NdotL = max(dot(N, Ld), 0);
                    float  diffFactor = ToonDiffuseStep(NdotL, _Threshold);

                    float3 H = normalize(Ld + V);
                    float  NdotH = max(dot(N, H), 0);
                    // Zona especular (destello circular)
                    float  specFactor = (NdotH > _Threshold) ? 1.0 : 0.0;

                    float3 diffD = _DirLightColor.rgb * _DirLightIntensity * diffFactor * _Color.rgb;
                    float3 specD = _DirLightColor.rgb * _DirLightIntensity * specFactor * _SpecColor.rgb;

                    colorOut += diffD + specD;
                }

                {
                    float3 toP = _PointLightPosition_w.xyz - i.worldPos;
                    float3 Lp = normalize(toP);
                    float  NdotL = max(dot(N, Lp), 0);

                    float  attP = ComputeAttenuation(_PointLightPosition_w.xyz, i.worldPos, _PointLightRange);
                    float  diffFactor = ToonDiffuseStep(NdotL * attP, _Threshold);

                    float3 H = normalize(Lp + V);
                    float  NdotH = max(dot(N, H), 0);
                    float  specFactor = ((NdotH * attP) > _Threshold) ? 1.0 : 0.0;

                    float3 diffP = _PointLightColor.rgb * _PointLightIntensity * attP * diffFactor * _Color.rgb;
                    float3 specP = _PointLightColor.rgb * _PointLightIntensity * attP * specFactor * _SpecColor.rgb;

                    colorOut += diffP + specP;
                }

                {
                    float3 toS = _SpotLightPosition_w.xyz - i.worldPos;
                    float3 Ls = normalize(toS);
                    float  NdotL = max(dot(N, Ls), 0);

                    // Cálculo del corte de ángulo
                    float cosAngle = dot(normalize(-_SpotLightDirection.xyz), Ls);
                    float cutoff  = cos(radians(_SpotLightAngle));
                    float  spotFactor = step(cutoff, cosAngle);

                    float  attS = ComputeAttenuation(_SpotLightPosition_w.xyz, i.worldPos, _SpotLightRange) * spotFactor;
                    float  diffFactor = ToonDiffuseStep(NdotL * attS, _Threshold);

                    float3 H = normalize(Ls + V);
                    float  NdotH = max(dot(N, H), 0);
                    float  specFactor = ((NdotH * attS) > _Threshold) ? 1.0 : 0.0;

                    float3 diffS = _SpotLightColor.rgb * _SpotLightIntensity * attS * diffFactor * _Color.rgb;
                    float3 specS = _SpotLightColor.rgb * _SpotLightIntensity * attS * specFactor * _SpecColor.rgb;

                    colorOut += diffS + specS;
                }

                return float4(colorOut, 1);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
