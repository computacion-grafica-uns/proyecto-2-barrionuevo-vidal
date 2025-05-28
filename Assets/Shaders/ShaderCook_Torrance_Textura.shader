Shader "ShaderCook_Torrance_Textura"
{
    Properties
    {
        _MainTex               ("Albedo (RGB)",          2D)    = "white" {}
        _MaterialTint          ("Material Tint",         Color) = (1,1,1,1)
        _Metallic              ("Metallic",              Range(0,1)) = 0.5
        _Roughness             ("Roughness",             Range(0,1)) = 0.5

        // Ambiente
        _AmbientColor          ("Ambient Light Color",   Color) = (0.2,0.2,0.2,1)

        // Direccional
        _DirLightDirection     ("Directional Light Dir", Vector)= (0,-1,0,0)
        _DirLightColor         ("Directional Light Col", Color) = (1,1,1,1)
        _DirLightIntensity     ("Directional Intensity", Range(0,5)) = 1

        // Puntual
        _PointLightPosition_w  ("Point Light Position",  Vector)= (0,1,0,1)
        _PointLightColor       ("Point Light Color",     Color) = (1,1,1,1)
        _PointLightIntensity   ("Point Light Intensity", Range(0,10)) = 1
        _PointLightRange       ("Point Light Range",     Range(0.1,50)) = 10

        // Spot
        _SpotLightPosition_w   ("Spot Light Position",   Vector)= (0,1,0,1)
        _SpotLightDirection    ("Spot Light Direction",  Vector)= (0,-1,0,0)
        _SpotLightColor        ("Spot Light Color",      Color) = (1,1,1,1)
        _SpotLightIntensity    ("Spot Light Intensity",  Range(0,10)) = 1
        _SpotLightRange        ("Spot Light Range",      Range(0.1,50)) = 15
        _SpotLightAngle        ("Spot Light Half-Angle", Range(0,90))   = 30
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

            //  Textura + Tin­t
            sampler2D _MainTex;
            float4   _MainTex_ST;
            float4   _MaterialTint;

            //  PBR
            float    _Metallic;
            float    _Roughness;

            //  Ambient
            float4   _AmbientColor;

            //  Direccional
            float4   _DirLightDirection;
            float4   _DirLightColor;
            float    _DirLightIntensity;

            // Puntual
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
                float4 pos       : SV_POSITION;
                float3 worldPos  : TEXCOORD0;
                float3 worldNorm : TEXCOORD1;
                float2 uv        : TEXCOORD2;
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

            float3 fresnelSchlick(float3 F0, float cosTheta)
            {
                return F0 + (1 - F0) * pow(1 - cosTheta, 5);
            }

            float D_GGX(float NdotH, float roughness)
            {
                float a   = roughness * roughness;
                float a2  = a * a;
                float num = a2;
                float denom = (NdotH * NdotH) * (a2 - 1) + 1;
                return num / (UNITY_PI * denom * denom);
            }

            float G_SchlickGGX(float NdotV, float roughness)
            {
                float k = (roughness + 1);
                k = (k * k) / 8;
                return NdotV / (NdotV * (1 - k) + k);
            }

            float ComputeAttenuation(float3 lp, float3 wp, float range)
            {
                float d = distance(lp, wp);
                return saturate(1 - (d * d) / (range * range));
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // Albedo desde textura * tinte
                float3 albedo = tex2D(_MainTex, i.uv).rgb * _MaterialTint.rgb;

                // Vectores básicos
                float3 N = normalize(i.worldNorm);
                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);

                // F0 base
                float3 F0 = lerp(float3(0.04,0.04,0.04), albedo, _Metallic);

                // Ambient
                float3 result = _AmbientColor.rgb * albedo;

                // Direccional
                {
                    float3 Ld = normalize(-_DirLightDirection.xyz);
                    float3 H  = normalize(V + Ld);

                    float Nl = max(dot(N, Ld), 0);
                    float Nv = max(dot(N, V), 0.001);
                    float Nh = max(dot(N, H), 0);

                    float3 F = fresnelSchlick(F0, dot(H, V));
                    float  D = D_GGX(Nh, _Roughness);
                    float  G = G_SchlickGGX(Nv, _Roughness) * G_SchlickGGX(Nl, _Roughness);

                    float3 spec = (D * G * F) / max(4 * Nv * Nl, 0.001);
                    float3 diff = (1 - F) * (albedo / UNITY_PI);

                    result += _DirLightColor.rgb * _DirLightIntensity * Nl * (diff + spec);
                }

                // Puntual
                {
                    float3 toP = _PointLightPosition_w.xyz - i.worldPos;
                    float3 Lp  = normalize(toP);
                    float3 H   = normalize(V + Lp);

                    float Nl = max(dot(N, Lp), 0);
                    float Nv = max(dot(N, V), 0.001);
                    float Nh = max(dot(N, H), 0);

                    float3 F = fresnelSchlick(F0, dot(H, V));
                    float  D = D_GGX(Nh, _Roughness);
                    float  G = G_SchlickGGX(Nv, _Roughness) * G_SchlickGGX(Nl, _Roughness);

                    float att = ComputeAttenuation(_PointLightPosition_w.xyz, i.worldPos, _PointLightRange);
                    float3 spec = (D * G * F) / max(4 * Nv * Nl, 0.001);
                    float3 diff = (1 - F) * (albedo / UNITY_PI);

                    result += _PointLightColor.rgb * _PointLightIntensity * att * Nl * (diff + spec);
                }

                // Spot
                {
                    float3 toS = _SpotLightPosition_w.xyz - i.worldPos;
                    float3 Ls  = normalize(toS);
                    float3 H   = normalize(V + Ls);

                    float Nl = max(dot(N, Ls), 0);
                    float Nv = max(dot(N, V), 0.001);
                    float Nh = max(dot(N, H), 0);

                    float cosA = dot(normalize(-_SpotLightDirection.xyz), Ls);
                    float cutoff = cos(radians(_SpotLightAngle));
                    float spotF = step(cutoff, cosA);

                    float att = ComputeAttenuation(_SpotLightPosition_w.xyz, i.worldPos, _SpotLightRange) * spotF;
                    float3 F  = fresnelSchlick(F0, dot(H, V));
                    float  D  = D_GGX(Nh, _Roughness);
                    float  G  = G_SchlickGGX(Nv, _Roughness) * G_SchlickGGX(Nl, _Roughness);

                    float3 spec = (D * G * F) / max(4 * Nv * Nl, 0.001);
                    float3 diff = (1 - F) * (albedo / UNITY_PI);

                    result += _SpotLightColor.rgb * _SpotLightIntensity * att * Nl * (diff + spec);
                }

                return float4(result, 1);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
