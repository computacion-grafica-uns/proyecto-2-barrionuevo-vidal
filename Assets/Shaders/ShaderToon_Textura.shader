Shader "ShaderToon_Textura"
{
    Properties
    {
        _MainTex                    ("Diffuse Texture",       2D)    = "white" {}
        _SpecularColor              ("Specular Color",        Color) = (1,1,1,1)
        _CoefMaterialSpecular       ("Coef Specular",         Range(0,1)) = 0.5
        _CoefMaterialDiffuse        ("Coef Diffuse",          Range(0,1)) = 0.5
        _Outline                    ("Outline Width",         Range(0,1)) = 0.05

        // Ambient
        _AmbientLightColor          ("Ambient Light Color",   Color) = (0.2,0.2,0.2,1)
        _AmbientLightIntensity      ("Ambient Intensity",     Range(0,1)) = 0.5

        // Directional
        _DirLightDirection          ("Directional Light Dir", Vector)= (0,-1,0,0)
        _DirLightColor              ("Directional Light Col", Color)  = (1,1,1,1)
        _DirLightIntensity          ("Directional Intensity", Range(0,5)) = 1

        // Point
        _PointLightPosition         ("Point Light Position",  Vector)= (0,1,0,1)
        _PointLightColor            ("Point Light Color",     Color)  = (1,1,1,1)
        _PointLightIntensity        ("Point Light Intensity", Range(0,10))= 1
        _PointLightRange            ("Point Light Range",     Range(0.1,50))= 10

        // Spot
        _SpotLightPosition_w        ("Spot Light Position",   Vector)= (0,1,0,1)
        _SpotLightDirection_w       ("Spot Light Direction",  Vector)= (0,-1,0,0)
        _SpotLightColor             ("Spot Light Color",      Color)  = (1,1,1,1)
        _SpotLightIntensity         ("Spot Light Intensity",  Range(0,10))= 1
        _SpotLightRange             ("Spot Light Range",      Range(0.1,50))= 15
        _SpotLightAngle             ("Spot Light Half-Angle", Range(0,90)) = 30
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        // Contorno
        Pass
        {
            Cull Front
            CGPROGRAM
            #pragma vertex vertOutline
            #pragma fragment fragOutline
            #include "UnityCG.cginc"

            float _Outline;
            struct appdataO { float4 vertex : POSITION; float3 normal : NORMAL; };
            struct v2fO    { float4 position : SV_POSITION; };

            v2fO vertOutline(appdataO v)
            {
                v.vertex.xyz += v.normal * _Outline;
                v2fO o; o.position = UnityObjectToClipPos(v.vertex);
                return o;
            }

            fixed4 fragOutline(v2fO i) : SV_Target
            {
                return float4(0,0,0,1);
            }
            ENDCG
        }

        // Toon shading con textura
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            // Textura
            sampler2D _MainTex;
            float4   _MainTex_ST;

            // Toon parameters
            float4 _SpecularColor;
            float  _CoefMaterialSpecular;
            float  _CoefMaterialDiffuse;

            float4 _AmbientLightColor;
            float  _AmbientLightIntensity;

            float4 _DirLightDirection;
            float4 _DirLightColor;
            float  _DirLightIntensity;

            float4 _PointLightPosition_w;
            float4 _PointLightColor;
            float  _PointLightIntensity;
            float  _PointLightRange;

            float4 _SpotLightPosition_w;
            float4 _SpotLightDirection_w;
            float4 _SpotLightColor;
            float  _SpotLightIntensity;
            float  _SpotLightRange;
            float  _SpotLightAngle;

            struct appdata
            {
                float4 position : POSITION;
                float3 normal   : NORMAL;
                float2 uv       : TEXCOORD0;
            };
            struct v2f
            {
                float4 position  : SV_POSITION;
                float3 worldPos  : TEXCOORD0;
                float3 worldNorm : TEXCOORD1;
                float2 uv        : TEXCOORD2;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.position   = UnityObjectToClipPos(v.position);
                o.worldPos   = mul(unity_ObjectToWorld, v.position).xyz;
                o.worldNorm  = normalize(UnityObjectToWorldNormal(v.normal));
                o.uv         = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float ComputeAttenuation(float3 lightPos, float3 worldPos, float range)
            {
                float d = distance(lightPos, worldPos);
                return saturate(1 - (d*d)/(range*range));
            }

            float ToonStep(float x, float threshold)
            {
                return x > threshold ? 1.0 : 0.0;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // Albedo desde textura
                float3 albedo = tex2D(_MainTex, i.uv).rgb;

                float3 N = normalize(i.worldNorm);
                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);

                // Ambient
                float3 color = _AmbientLightColor.rgb * _AmbientLightIntensity * albedo;
                float diffAmt = 0;
                float specAmt = 0;

                // Directional
                {
                    float3 L = normalize(-_DirLightDirection.xyz);
                    float  Nl = max(dot(N, L), 0);
                    diffAmt += ToonStep(Nl * _DirLightIntensity, _CoefMaterialDiffuse);
                    float3 H = normalize(L + V);
                    float Nh = max(dot(N, H), 0);
                    specAmt += ToonStep(Nh * _DirLightIntensity, _CoefMaterialSpecular);
                }

                // Point
                {
                    float3 toP = _PointLightPosition_w.xyz - i.worldPos;
                    float3 L   = normalize(toP);
                    float  Nl  = max(dot(N, L), 0);
                    float  att = ComputeAttenuation(_PointLightPosition_w.xyz, i.worldPos, _PointLightRange);
                    diffAmt += ToonStep(Nl * _PointLightIntensity * att, _CoefMaterialDiffuse);
                    float3 H = normalize(L + V);
                    float Nh = max(dot(N, H), 0);
                    specAmt += ToonStep(Nh * _PointLightIntensity * att, _CoefMaterialSpecular);
                }

                // Spot
                {
                    float3 toS = _SpotLightPosition_w.xyz - i.worldPos;
                    float3 L   = normalize(toS);
                    float  Nl  = max(dot(N, L), 0);
                    float  cosA= dot(normalize(-_SpotLightDirection_w.xyz), L);
                    float  sp  = step(cos(radians(_SpotLightAngle)), cosA);
                    float  att = ComputeAttenuation(_SpotLightPosition_w.xyz, i.worldPos, _SpotLightRange) * sp;
                    diffAmt += ToonStep(Nl * _SpotLightIntensity * att, _CoefMaterialDiffuse);
                    float3 H = normalize(L + V);
                    float Nh = max(dot(N, H), 0);
                    specAmt += ToonStep(Nh * _SpotLightIntensity * att, _CoefMaterialSpecular);
                }

                // Combine
                color += diffAmt * albedo;
                color += specAmt * _SpecularColor.rgb;

                return float4(color,1);
            }
            ENDCG
        }
    }
}
