Shader "ShaderBlinn_Phong_Multitextura"
{
    Properties
    {
        // --- Multitexture maps ---
        _AlbedoMap        ("Albedo (RGB)",           2D) = "white" {}
        _HeightMap        ("Height (R)",             2D) = "black" {}
        _NormalMap        ("Normal (XYZ)",           2D) = "bump"  {}
        _RoughnessMap     ("Roughness (R)",          2D) = "white" {}
        _MetallicMap      ("Metallic (R)",           2D) = "black" {}
        _OcclusionMap     ("Occlusion (R)",          2D) = "white" {}

        // --- Base material coefs (fallbacks) ---
        _BaseShininess    ("Shininess (Gloss)",      Range(1,500)) = 32
        _BaseKa           ("Ambient Coef",           Range(0,1))   = 0.1
        _BaseKs           ("Specular Coef",          Range(0,1))   = 0.5

        // --- Lights ---
        _AmbientColor     ("Ambient Light Color",    Color)        = (1,1,1,1)
        _DirLightDirection("Dir Light Direction",    Vector)       = (0,-1,0,0)
        _DirLightColor    ("Dir Light Color",        Color)        = (1,1,1,1)
        _DirLightIntensity("Dir Light Intensity",    Range(0,5))   = 1
        _PointLightPosition("Point Light Position",  Vector)       = (0,2,0,1)
        _PointLightColor  ("Point Light Color",      Color)        = (1,1,1,1)
        _PointLightIntensity("Point Light Intensity",Range(0,10)) = 1
        _PointLightRange  ("Point Light Range",      Range(0.1,50))= 10
        _SpotLightPosition("Spot Light Position",    Vector)       = (0,3,0,1)
        _SpotLightDirection("Spot Light Direction",  Vector)       = (0,-1,0,0)
        _SpotLightColor   ("Spot Light Color",       Color)        = (1,1,1,1)
        _SpotLightIntensity("Spot Light Intensity",  Range(0,10)) = 1
        _SpotLightRange   ("Spot Light Range",       Range(0.1,50))= 15
        _SpotLightAngle   ("Spot Light Half-Angle",  Range(0,90))  = 30
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 300

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            // --- Textura y coordenadas ---
            sampler2D _AlbedoMap, _HeightMap, _NormalMap;
            sampler2D _RoughnessMap, _MetallicMap, _OcclusionMap;
            float4   _AlbedoMap_ST, _HeightMap_ST, _NormalMap_ST;
            float4   _RoughnessMap_ST, _MetallicMap_ST, _OcclusionMap_ST;

            // --- Material fallback ---
            float    _BaseShininess;
            float    _BaseKa;
            float    _BaseKs;

            // --- Luces ---
            float4 _AmbientColor;
            float4 _DirLightDirection, _DirLightColor;
            float  _DirLightIntensity;
            float4 _PointLightPosition, _PointLightColor;
            float  _PointLightIntensity, _PointLightRange;
            float4 _SpotLightPosition, _SpotLightDirection, _SpotLightColor;
            float  _SpotLightIntensity, _SpotLightRange, _SpotLightAngle;

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
                float2 uvAlbedo  : TEXCOORD2;
                float2 uvHeight  : TEXCOORD3;
                float2 uvNormal  : TEXCOORD4;
                float2 uvRough   : TEXCOORD5;
                float2 uvMetal   : TEXCOORD6;
                float2 uvOcc     : TEXCOORD7;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos       = UnityObjectToClipPos(v.vertex);
                o.worldPos  = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNorm = UnityObjectToWorldNormal(v.normal);
                o.uvAlbedo  = TRANSFORM_TEX(v.uv, _AlbedoMap);
                o.uvHeight  = TRANSFORM_TEX(v.uv, _HeightMap);
                o.uvNormal  = TRANSFORM_TEX(v.uv, _NormalMap);
                o.uvRough   = TRANSFORM_TEX(v.uv, _RoughnessMap);
                o.uvMetal   = TRANSFORM_TEX(v.uv, _MetallicMap);
                o.uvOcc     = TRANSFORM_TEX(v.uv, _OcclusionMap);
                return o;
            }

            // Parallax simple
            float2 ParallaxOffset(float2 uv, sampler2D hmap, float heightScale)
            {
                float h = tex2D(hmap, uv).r;
                return uv + (h * heightScale) * normalize(float2(uv.x-0.5, uv.y-0.5));
            }

            float ComputeAttenuation(float3 lp, float3 wp, float range)
            {
                float d = distance(lp, wp);
                return saturate(1 - (d*d)/(range*range));
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // --- Parallax on UVs ---
                float2 uvP = ParallaxOffset(i.uvHeight, _HeightMap, 0.05);

                // --- Albedo + Occlusion ---
                float3 albedo    = tex2D(_AlbedoMap, uvP).rgb;
                float  occ       = tex2D(_OcclusionMap, i.uvOcc).r;
                albedo *= occ;

                // --- Normal map TBN (simple object -> world) ---
                float3 nmap     = tex2D(_NormalMap, i.uvNormal).xyz * 2 - 1;
                float3 N        = normalize(mul((float3x3)unity_ObjectToWorld, nmap));
                float3 V        = normalize(_WorldSpaceCameraPos - i.worldPos);

                // --- Roughness & Metallic ---
                float roughness = tex2D(_RoughnessMap, i.uvRough).r;
                float metallic  = tex2D(_MetallicMap, i.uvMetal).r;

                // --- Compute phong coefs ---
                float kd = 1 - metallic;            // approximated diffuse
                float ks = lerp(_BaseKs, 1.0, metallic);
                float shin = lerp(_BaseShininess, 8.0, roughness); 

                // --- Ambient ---
                float3 ambient = _AmbientColor.rgb * _BaseKa * albedo;

                // --- Directional ---
                float3 Ld = normalize(-_DirLightDirection.xyz);
                float Nld = max(dot(N, Ld), 0);
                float3 Rld = reflect(-Ld, N);
                float Sld  = pow(max(dot(Rld, V), 0), shin);
                float3 diffD = _DirLightColor.rgb * _DirLightIntensity * Nld * kd * albedo;
                float3 specD = _DirLightColor.rgb * _DirLightIntensity * Sld * ks;

                // --- Point ---
                float3 toP  = _PointLightPosition.xyz - i.worldPos;
                float3 Lp   = normalize(toP);
                float Nlp   = max(dot(N, Lp), 0);
                float3 Rlp  = reflect(-Lp, N);
                float Slp   = pow(max(dot(Rlp, V), 0), shin);
                float attP  = ComputeAttenuation(_PointLightPosition.xyz, i.worldPos, _PointLightRange);
                float3 diffP= _PointLightColor.rgb * _PointLightIntensity * attP * Nlp * kd * albedo;
                float3 specP= _PointLightColor.rgb * _PointLightIntensity * attP * Slp * ks;

                // --- Spot ---
                float3 toS   = _SpotLightPosition.xyz - i.worldPos;
                float3 Ls    = normalize(toS);
                float Nls    = max(dot(N, Ls), 0);
                float3 Rls   = reflect(-Ls, N);
                float Sls    = pow(max(dot(Rls, V), 0), shin);
                float cosA   = dot(normalize(-_SpotLightDirection.xyz), Ls);
                float outer  = cos(radians(_SpotLightAngle));
                float inner  = cos(radians(_SpotLightAngle * 0.8));
                float spotF  = smoothstep(outer, inner, cosA);
                float attS   = ComputeAttenuation(_SpotLightPosition.xyz, i.worldPos, _SpotLightRange) * spotF;
                float3 diffS = _SpotLightColor.rgb * _SpotLightIntensity * attS * Nls * kd * albedo;
                float3 specS = _SpotLightColor.rgb * _SpotLightIntensity * attS * Sls * ks;

                // --- Final color ---
                float3 col = ambient + diffD + specD + diffP + specP + diffS + specS;
                return float4(col,1);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
