Shader "Blinn_Phong_Procedural"
{
    Properties
    {
        // Propiedades del material
        _Shininess("Shininess (Gloss)", Range(1,500)) = 32
        _MaterialKa("Material Ka", Vector) = (0,0,0,0)
        _MaterialKd("Material Kd", Vector) = (0,0,0,0)
        _MaterialKs("Material Ks", Vector) = (0,0,0,0)
        _ColorBase ("Color Base", Color) = (1,1,1,1)
        _CantBurbujas("Bubbles Count", Range(0,20)) = 14
        _SizeBurbujas("Bubble Size", Range(0.01,.5)) = 1.0
        _BubbleCenterColor("Bubble Center Color", Color) = (1,0,0,1)
        _BubbleEdgeColor("Bubble Edge Color", Color) = (0.2,0,0,1)

        // Ambiente
        _AmbientColor("Ambient Light", Color) = (1,1,1,1)  
        
        // Luz puntual
        _PointLightPosition_w("Point Light Position", Vector) = (0,2,0,1)
        _PointLightColor("PointLight", Color) = (1,1,1,1)
        _PointLightIntensity("Point Light Intensity", Range(0,10)) = 1.0
        _PointLightRange    ("Point Light Range", Range(0.1,50)) = 10
        
        // Luz direccional
        _DirLightDirection("Dir Light Direction",Vector) = (0,-1,0,0)
        _DirLightColor("Dir Light Color",Color) = (1,1,1,1)
        _DirLightIntensity("Dir Light Intensity",Range(0,5)) = 1
        
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
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            
            // Variables del material
            float  _Shininess;
            float3 _MaterialKa;
            float3 _MaterialKd;
            float3 _MaterialKs;
            float4 _ColorBase;
            float _CantBurbujas, _SizeBurbujas;
            float4 _BubbleCenterColor,_BubbleEdgeColor;
            //variables luces
            float4 _AmbientColor;

            float4 _DirLightDirection; 
            float4 _DirLightColor;
            float  _DirLightIntensity;

            float4 _PointLightPosition_w;
            float4 _PointLightColor;
            float  _PointLightIntensity;
            float  _PointLightRange;

            float4 _SpotLightPosition_w;
            float4 _SpotLightDirection;
            float4 _SpotLightColor;
            float  _SpotLightIntensity;
            float  _SpotLightRange;
            float  _SpotLightAngle;

            struct appdata {
                
                float4 position : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0; // Añadido para rayas
            };

            struct v2f {

                float4 position : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float2 uv : TEXCOORD2; // Añadido para rayas
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.position = UnityObjectToClipPos(v.position);
                o.worldPos = mul(unity_ObjectToWorld, v.position).xyz;
                o.worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
                o.uv = v.uv; // Pasar UV para rayas
                return o;
            }

            float ComputeAttenuation(float3 lightPos, float3 worldPos, float range)
            {
                float dist = distance(lightPos, worldPos);
                return saturate(1.0 - (dist * dist) / (range * range));
            }

            float3 LavaLampPattern(float2 uv, float time)
            {
                float2 p = (uv - 0.5) * 3.0;

                float lavaMask = 0.0;
                float3 finalColor = float3(0, 0, 0);

                for (int i = 0; i < _CantBurbujas; i++)
                {
                    float angle = time * 0.6 + i * 2.0;
                    float2 center = float2(cos(angle + i), sin(angle * 0.75 + i)) * 1.2;

                    float size = _SizeBurbujas + 0.1 * sin(time * 2.0 + i * 3.0);
                    float2 offset = float2(sin(time + i * 1.5), cos(time + i * 2.3)) * 0.1;
                    float2 delta = p - center + offset;
                    float dist = length(delta);

                    float drop = smoothstep(size + 0.1, size, dist);

                    float3 dropColor = _BubbleCenterColor.rgb;

                    float r = saturate(1.5 - dist / size);
                    float radial = pow(r, 2.0);

                    float3 shadedColor = lerp(dropColor * 0.2, dropColor, radial);

                    finalColor += drop * shadedColor;
                    lavaMask += drop;
                }

                lavaMask = saturate(lavaMask);

                // Máscara para borde, activa solo en zona delgada
                float borderMask = smoothstep(0.5, 0.1, lavaMask) - smoothstep(0.1, 0.0, lavaMask);

                // Borde energético que no se mezcla con el centro
                float edgeFactor = pow(borderMask, 2.0);

                float3 glow = _BubbleEdgeColor.rgb * edgeFactor * 3.0;

                float3 color = lerp(_ColorBase.rgb, finalColor, lavaMask);

                color += glow;

                return color;
            }


            fixed4 frag(v2f i) : SV_Target
            {
                float3 N = normalize(i.worldNormal);
                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);

                // Procedural stripes (ejemplo: 10 rayas, colores blanco y negro)
                float3 lava = LavaLampPattern(i.uv, _Time.y);
    
                // ------------------ Luz ambiental ------------------
                
                float3 ambient = _AmbientColor;

                // ------------------ Luz direccional ------------------
                float3 Ld = normalize(-_DirLightDirection.xyz);
                float  Nld = max(0, dot(N, Ld));
                float3 Rld = reflect(-Ld, N);
                float  Sld = pow(max(dot(Rld, V), 0), _Shininess);
                float3 diffD = _DirLightColor.rgb * _DirLightIntensity * Nld * lava;
                float3 specD = _DirLightColor.rgb * _DirLightIntensity * Sld * _MaterialKs.rgb;

                // ------------------ Luz puntual ------------------
                float3 toP = _PointLightPosition_w.xyz - i.worldPos;
                float3 Lp  = normalize(toP);
                float  Nlp = max(0, dot(N, Lp));
                float3 Rlp = reflect(-Lp, N);
                float  Slp = pow(max(dot(Rlp, V), 0), _Shininess);
                float  attP = ComputeAttenuation(_PointLightPosition_w.xyz, i.worldPos, _PointLightRange);
                float3 diffP = _PointLightColor.rgb * _PointLightIntensity * attP * Nlp * lava;
                float3 specP = _PointLightColor.rgb * _PointLightIntensity * attP * Slp * _MaterialKs.rgb;

                // ------------------ Luz spot ------------------
                float3 toS = _SpotLightPosition_w.xyz - i.worldPos;
                float3 Ls  = normalize(toS);
                float Nls = max(0, dot(N, Ls));
                float3 Rls = reflect(-Ls, N);
                float Sls = pow(max(dot(Rls, V), 0), _Shininess);
                float cosAngle = dot(normalize(-_SpotLightDirection.xyz), Ls);
                float cutoff = cos(radians(_SpotLightAngle));
                float inner = cos(radians(_SpotLightAngle * 0.8));
                float outer = cos(radians(_SpotLightAngle));
                float spotFactor = smoothstep(outer, inner, cosAngle);
                float  attS = ComputeAttenuation(_SpotLightPosition_w.xyz, i.worldPos, _SpotLightRange) * spotFactor;
                float3 diffS = _SpotLightColor.rgb * _SpotLightIntensity * attS * Nls * lava;
                float3 specS = _SpotLightColor.rgb * _SpotLightIntensity * attS * Sls * _MaterialKs.rgb;
                
                float3 col = ambient + diffD + specD + diffP + specP + diffS + specS;
                return float4(col, 1); 
            }
            ENDCG
        }
    }
}
