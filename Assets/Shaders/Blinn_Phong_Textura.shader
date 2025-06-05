Shader "Blinn_Phong_Textura"
{
    Properties
    {
        _MainTex ("Diffuse Texture", 2D) = "white" {}
        _MaterialKa ("Material Ka", Color) = (1,1,1,1)
        _MaterialKd ("Material Kd", Color) = (1,1,1,1)
        _MaterialKs ("Material Ks", Color) = (1,1,1,1)
        _Shininess ("Shininess (Gloss)", Range(1,500)) = 32

        // Ambiente
        _AmbientColor("Ambient Light Color", Color) = (1,1,1,1)  
             
        // Luz puntual
        _PointLightPosition_w("Point Light Position", Vector) = (0,2,0,1)
        _PointLightColor("Point Light Color", Color) = (1,1,1,1)
        _PointLightIntensity("Point Light Intensity", Range(0,10)) = 1.0
        _PointLightRange ("Point Light Range", Range(0.1,50)) = 10
        
        // Luz direccional
        _DirLightDirection("Directional Light Dir",Vector) = (0,-1,0,0)
        _DirLightColor("Directional Light Color",Color) = (1,1,1,1)
        _DirLightIntensity("Directional Intensity",Range(0,5)) = 1
        
        // Luz spot
        _SpotLightPosition_w("Spot Light Position", Vector) = (0,3,0,1)
        _SpotLightDirection("Spot Light Direction", Vector) = (0,-1,0,0)
        _SpotLightColor("Spot Light Color",Color) = (1,1,1,1)
        _SpotLightIntensity("Spot Light Intensity", Range(0,10)) = 1
        _SpotLightRange("Spot Light Range", Range(0.1,50))= 15
        _SpotLightAngle("Spot Light Half-Angle", Range(0,90)) = 30
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

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _MaterialKa, _MaterialKd, _MaterialKs;
            float _Shininess;

            float4 _AmbientColor;

            float4 _PointLightPosition_w;
            float4 _PointLightColor;
            float _PointLightIntensity;
            float _PointLightRange;

            float4 _DirLightDirection;
            float4 _DirLightColor;
            float _DirLightIntensity;

            float4 _SpotLightPosition_w;
            float4 _SpotLightDirection;
            float4 _SpotLightColor;
            float _SpotLightIntensity;
            float _SpotLightRange;
            float _SpotLightAngle;

            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
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
                float3 albedo = tex2D(_MainTex, i.uv).rgb;
                float3 N = normalize(i.worldNorm);
                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);

                // Luz ambiental
                float3 ambient = _AmbientColor.rgb * (_MaterialKa.rgb);

                // Luz direccional
                float3 Ld = normalize(-_DirLightDirection.xyz);
                float Nld = max(0, dot(N, Ld));
                float3 Rld = reflect(-Ld, N);
                float Sld = pow(max(dot(Rld, V), 0), _Shininess);
                float3 diffD = _DirLightColor.rgb * _DirLightIntensity * Nld * (_MaterialKd.rgb * albedo);
                float3 specD = _DirLightColor.rgb * _DirLightIntensity * Sld * _MaterialKs.rgb;

                // Luz puntual
                float3 toP = _PointLightPosition_w.xyz - i.worldPos;
                float3 Lp = normalize(toP);
                float Nlp = max(0, dot(N, Lp));
                float3 Rlp = reflect(-Lp, N);
                float Slp = pow(max(dot(Rlp, V), 0), _Shininess);
                float attP = ComputeAttenuation(_PointLightPosition_w.xyz, i.worldPos, _PointLightRange);
                float3 diffP = _PointLightColor.rgb * _PointLightIntensity * attP * Nlp * (_MaterialKd.rgb * albedo);
                float3 specP = _PointLightColor.rgb * _PointLightIntensity * attP * Slp * _MaterialKs.rgb;

                // Luz spot
                float3 toS = _SpotLightPosition_w.xyz - i.worldPos;
                float3 Ls = normalize(toS);
                float Nls = max(0, dot(N, Ls));
                float3 Rls = reflect(-Ls, N);
                float Sls = pow(max(dot(Rls, V), 0), _Shininess);
                float cosAngle = dot(normalize(-_SpotLightDirection.xyz), Ls);
                float cutoff = cos(radians(_SpotLightAngle));
                float inner = cos(radians(_SpotLightAngle * 0.8));
                float outer = cos(radians(_SpotLightAngle));
                float spotFactor = smoothstep(outer, inner, cosAngle);
                float attS = ComputeAttenuation(_SpotLightPosition_w.xyz, i.worldPos, _SpotLightRange) * spotFactor;
                float3 diffS = _SpotLightColor.rgb * _SpotLightIntensity * attS * Nls * (_MaterialKd.rgb * albedo);
                float3 specS = _SpotLightColor.rgb * _SpotLightIntensity * attS * Sls * _MaterialKs.rgb;

                float3 col = ambient + diffD + specD + diffP + specP + diffS + specS;
                return float4(col, 1);
            }
            ENDCG
        }
    }
}
