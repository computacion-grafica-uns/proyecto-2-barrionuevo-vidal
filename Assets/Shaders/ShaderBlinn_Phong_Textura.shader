Shader "Custom/ShaderBlinn_Phong_Texture"
{
    Properties
    {
        _MainTex ("Diffuse Texture", 2D) = "white" {}
        _MaterialColor ("Material Tint", Color) = (1,1,1,1)
        _DiffuseCoef ("Diffuse Coef", Range(0,1)) = 1

        _SpecularColor ("Specular Color", Color) = (1,1,1,1)
        _Shininess ("Shininess (Gloss)", Range(1,500)) = 32

        // Ambiente
        _AmbientLightColor("Ambient Light Color", Color) = (0.1,0.1,0.1,1)

        // Luz puntual
        _PointLightPosition_w ("Light Position", Vector) = (0,2,0,1)
        _PointLightColor ("Point Light Color", Color)  = (1,1,1,1)
        _PointLightIntensity ("Point Light Intensity", Range(0,10))= 1.0
        _PointLightRange ("Point Light Range", Range(0.1,50)) = 10

        // Luz direccional
        _DirLightDirection ("Dir Light Direction", Vector) = (0,-1,0,0)
        _DirLightColor ("Dir Light Color", Color)  = (1,1,1,1)
        _DirLightIntensity ("Dir Light Intensity", Range(0,5))  = 1

        // Luz spot
        _SpotLightPosition ("Spot Light Position", Vector) = (0,3,0,1)
        _SpotLightDirection ("Spot Light Direction", Vector) = (0,-1,0,0)
        _SpotLightColor ("Spot Light Color", Color)  = (1,1,1,1)
        _SpotLightIntensity ("Spot Light Intensity", Range(0,10)) = 1
        _SpotLightRange ("Spot Light Range", Range(0.1,50))= 15
        _SpotLightAngle ("Spot Light Half-Angle", Range(0,90))  = 30
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

            // Textura
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _MaterialColor;
            float  _DiffuseCoef;

            // Especular
            float4 _SpecularColor;
            float _Shininess;

            // Ambiente
            float4 _AmbientLightColor;

            // Direccional
            float4 _DirLightDirection;
            float4 _DirLightColor;
            float _DirLightIntensity;

            // Puntual
            float4 _PointLightPosition_w;
            float4 _PointLightColor;
            float _PointLightIntensity;
            float _PointLightRange;

            // Spot
            float4 _SpotLightPosition;
            float4 _SpotLightDirection;
            float4 _SpotLightColor;
            float _SpotLightIntensity;
            float _SpotLightRange;
            float _SpotLightAngle;

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
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float ComputeAttenuation(float3 lightPos, float3 worldPos, float range)
            {
                float d = distance(lightPos, worldPos);
                return saturate(1 - (d * d) / (range * range));
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // Albedo desde textura + tint
                float3 albedo = tex2D(_MainTex, i.uv).rgb * _MaterialColor.rgb;

                float3 N = normalize(i.worldNorm);
                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);

                // Ambiental
                float3 ambient = _AmbientLightColor.rgb * albedo;

                // Luz Direccional
                float3 Ld = normalize(-_DirLightDirection.xyz);
                float NdotL_d = max(dot(N, Ld), 0);
                float3 H_d = normalize(Ld + V);
                float NdotH_d = max(dot(N, H_d), 0);
                float3 diffD = _DirLightColor.rgb * _DirLightIntensity * NdotL_d * _DiffuseCoef * albedo;
                float3 specD = _DirLightColor.rgb * _DirLightIntensity * pow(NdotH_d, _Shininess) * _SpecularColor.rgb;

                // Luz Puntual
                float3 toP = _PointLightPosition_w.xyz - i.worldPos;
                float3 Lp = normalize(toP);
                float NdotL_p = max(dot(N, Lp), 0);
                float3 H_p = normalize(Lp + V);
                float NdotH_p = max(dot(N, H_p), 0);
                float attP = ComputeAttenuation(_PointLightPosition_w.xyz, i.worldPos, _PointLightRange);
                float3 diffP = _PointLightColor.rgb * _PointLightIntensity * attP * NdotL_p * _DiffuseCoef * albedo;
                float3 specP = _PointLightColor.rgb * _PointLightIntensity * attP * pow(NdotH_p, _Shininess) * _SpecularColor.rgb;

                // Luz Spot
                float3 toS = _SpotLightPosition.xyz - i.worldPos;
                float3 Ls = normalize(toS);
                float NdotL_s = max(dot(N, Ls), 0);
                float3 H_s = normalize(Ls + V);
                float NdotH_s = max(dot(N, H_s), 0);
                float cosAng = dot(normalize(-_SpotLightDirection.xyz), Ls);
                float outer = cos(radians(_SpotLightAngle));
                float inner = cos(radians(_SpotLightAngle * 0.8));
                float spotF = smoothstep(outer, inner, cosAng);
                float attS = ComputeAttenuation(_SpotLightPosition.xyz, i.worldPos, _SpotLightRange) * spotF;
                float3 diffS = _SpotLightColor.rgb * _SpotLightIntensity * attS * NdotL_s * _DiffuseCoef * albedo;
                float3 specS = _SpotLightColor.rgb * _SpotLightIntensity * attS * pow(NdotH_s, _Shininess) * _SpecularColor.rgb;

                float3 color = ambient + diffD + specD + diffP + specP + diffS + specS;
                return float4(color, 1);
            }
            ENDCG
        }
    }
}
