Shader "ShaderPhong"
{
    Properties
    {
        _MaterialColor ("Material Color", Color) = (1,1,1,1)
        _CoefMaterialReflexion("Coef_Material_reflexion", Range(0,1)) = 0.5
        _CoefMaterialDifusse("Coef_Material_difusse", Range(0,1)) = 0.5
        _CoefMaterialSpecular("Coef_Material_specular", Range(0,1)) = 0.5
        _CoefMaterialBrightness("Coef_Material_Brightness", Range(1,100)) = 1

        _PointLightPosition_w("Light Position", Vector) = (0,1,0,1)
        _PointLightColor("PointLight", Color) = (1,1,1,1)
        _PointLightIntensity("Point Light Intensity", Range(0,10)) = 1.0

        _WorldLightColor("World Light", Color) = (1,1,1,1)
        _WorldLightIntensity("World Light Intensity", Range(0,1)) = 0.5
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

            struct appdata {
                float4 position : POSITION;
                float3 normal : NORMAL; // espacio del objeto
            };

            struct v2f {
                float4 position : SV_POSITION;
                float diffCoef: TEXCOORD1;// coeficiente difuso: espacio del mundo
                float ambCoef: TEXCOORD2;// coeficiente ambiente: espacio del mundo
                float specCoef: TEXCOORD3;// coeficiente especular: espacio del mundo
            };

            float4 _PointLightPosition_w;
            float _PointLightIntensity;
            float _WorldLightIntensity;
            float _CoefMaterialReflexion;
            float _CoefMaterialSpecular;
            float _CoefMaterialDifusse;
            float _CoefMaterialBrightness;

            v2f vert(appdata v)
            {
                v2f output;
                float4 position_w = mul(unity_ObjectToWorld, v.position); 
                float3 normal_w = normalize(UnityObjectToWorldNormal(v.normal));

                // propiedad ambiente
                float coefAmb = _WorldLightIntensity * _CoefMaterialReflexion;  
                //propiedad difusa
                float3 L = normalize(_PointLightPosition_w.xyz - position_w.xyz); 
                float3 N = normal_w;
                float coefDif = _PointLightIntensity * _CoefMaterialDifusse * max(0,dot(N,L));
                // propiedad especular
                float3 R = reflect(-L, N);
                float3 V = normalize(_WorldSpaceCameraPos - position_w.xyz);
                float specDot = max(0, dot(R, V));
                float coefSpec = _PointLightIntensity * _CoefMaterialSpecular * pow(specDot, _CoefMaterialBrightness); 
                
                output.ambCoef = coefAmb;
                output.diffCoef = coefDif;
                output.specCoef = coefSpec;

                output.position = UnityObjectToClipPos(v.position);
                
                return output;
            }

            float4 _PointLightColor;
            float4 _WorldLightColor;
            float4 _MaterialColor;

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 col = 0;
                /*col.rgb = i.ambCoef * _WorldLightColor.rgb * _MaterialColor.rgb +
                        i.diffCoef * _PointLightColor.rgb * _MaterialColor.rgb +
                        i.specCoef * _PointLightColor.rgb;*/
                col.rgb = (i.ambCoef + i.diffCoef + i.specCoef) * _MaterialColor.rgb;
                return col;                
            }
            
            ENDCG
        }
    }
}
