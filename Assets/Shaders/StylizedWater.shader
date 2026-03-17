Shader "Custom/StylizedWater_Unlit"
{
    Properties
    {
        [HDR]_Color ("Color", Color) = (1,1,1,1)
        [HDR]_FogColor("Fog Color", Color) = (1,1,1,1)
        [HDR]_IntersectionColor("Intersection color", Color) = (1,1,1,1)

        _IntersectionThreshold("Intersection threshold", float) = 1
        _FogThreshold("Fog threshold", float) = 1
        _FoamThreshold("Foam threshold", float) = 1

        [Normal]_NormalA("Normal A", 2D) = "bump" {} 
        [Normal]_NormalB("Normal B", 2D) = "bump" {}
        _NormalStrength("Normal strength", float) = 1
        _NormalPanningSpeeds("Normal panning speeds", Vector) = (0,0,0,0)

        _FoamTexture("Foam texture", 2D) = "white" {} 
        _FoamTextureSpeedX("Foam texture speed X", float) = 0
        _FoamTextureSpeedY("Foam texture speed Y", float) = 0
        _FoamLinesSpeed("Foam lines speed", float) = 0
        _FoamIntensity("Foam intensity", float) = 1

        _FresnelPower("Fresnel power", float) = 3
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _CameraDepthTexture;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 screenPos : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
            };

            fixed4 _Color;
            fixed4 _FogColor;
            fixed4 _IntersectionColor;

            float _IntersectionThreshold;
            float _FogThreshold;
            float _FoamThreshold;

            sampler2D _NormalA;
            sampler2D _NormalB;
            float4 _NormalA_ST;
            float4 _NormalB_ST;
            float _NormalStrength;
            float4 _NormalPanningSpeeds;

            sampler2D _FoamTexture;
            float4 _FoamTexture_ST;
            float _FoamTextureSpeedX;
            float _FoamTextureSpeedY;
            float _FoamLinesSpeed;
            float _FoamIntensity;

            float _FresnelPower;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.screenPos = ComputeScreenPos(o.pos);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.viewDir = WorldSpaceViewDir(v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float depth = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPos));
                depth = LinearEyeDepth(depth);

                float surfaceDepth = i.screenPos.w;

                float fogDiff = saturate((depth - surfaceDepth) / _FogThreshold);
                float intersectionDiff = saturate((depth - surfaceDepth) / _IntersectionThreshold);
                float foamDiff = saturate((depth - surfaceDepth) / _FoamThreshold);

                fixed4 col = lerp(lerp(_IntersectionColor, _Color, intersectionDiff), _FogColor, fogDiff);

                // Normals animées
                float3 normalA = UnpackNormal(tex2D(_NormalA,
                    i.worldPos.xz * _NormalA_ST.xy +
                    _Time.y * _NormalPanningSpeeds.xy));

                float3 normalB = UnpackNormal(tex2D(_NormalB,
                    i.worldPos.xz * _NormalB_ST.xy +
                    _Time.y * _NormalPanningSpeeds.zw));

                float3 normal = normalize(normalA + normalB);

                // Fresnel manuel
                float3 viewDir = normalize(i.viewDir);
                float fresnel = pow(1.0 - saturate(dot(normal, viewDir)), _FresnelPower);

                // Foam
                float foamTex = tex2D(_FoamTexture,
                    i.worldPos.xz * _FoamTexture_ST.xy +
                    _Time.y * float2(_FoamTextureSpeedX, _FoamTextureSpeedY));

                float foam = step(foamDiff, foamTex);

                float alpha = lerp(col.a * fresnel, 1.0, foam);
                alpha = lerp(alpha, _FogColor.a, fogDiff);

                float3 emission = foam * _FoamIntensity;

                return fixed4(col.rgb + emission, alpha);
            }

            ENDCG
        }
    }
}