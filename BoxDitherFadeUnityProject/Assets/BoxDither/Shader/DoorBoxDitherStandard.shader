Shader "Custom/DoorBoxDitherStandard"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo", 2D) = "white" {}
        _Metallic ("Metallic", Range(0,1)) = 0
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _BumpMap ("Normal Map", 2D) = "bump" {}
        _BumpScale ("Normal Scale", Range(0,2)) = 1

        _BoxSize ("Box Size", Vector) = (1,2,1,0)
        _FadeWidth ("Fade Width", Float) = 0.3
        _FadeStart ("Fade Start Z", Float) = -0.5
        _DitherStrength ("Dither Strength", Range(0,1)) = 1
        _MaskEnable ("Enable Fade", Float) = 0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="AlphaTest" }
        LOD 300

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows addshadow
        #pragma target 3.0

        sampler2D _MainTex;
        sampler2D _BumpMap;

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        half _BumpScale;

        float4 _BoxSize;
        float _FadeWidth;
        float _FadeStart;
        float _DitherStrength;
        float _MaskEnable;

        float4x4 _WorldToDoor;

        struct Input
        {
            float2 uv_MainTex;
            float2 uv_BumpMap;
            float3 worldPos;
            float4 screenPos;
        };

        inline float Bayer4x4(float2 pixelPos)
        {
            int x = ((int)pixelPos.x) & 3;
            int y = ((int)pixelPos.y) & 3;

            const float bayer[16] =
            {
                0.0 / 16.0,  8.0 / 16.0,  2.0 / 16.0, 10.0 / 16.0,
                12.0 / 16.0, 4.0 / 16.0, 14.0 / 16.0,  6.0 / 16.0,
                3.0 / 16.0, 11.0 / 16.0,  1.0 / 16.0,  9.0 / 16.0,
                15.0 / 16.0, 7.0 / 16.0, 13.0 / 16.0,  5.0 / 16.0
            };

            return bayer[y * 4 + x];
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;

            fixed4 n = tex2D(_BumpMap, IN.uv_BumpMap);
            o.Normal = UnpackScaleNormal(n, _BumpScale);

            if (_MaskEnable > 0.5)
            {
                float3 localPos = mul(_WorldToDoor, float4(IN.worldPos, 1.0)).xyz;
                float3 halfSize = _BoxSize.xyz * 0.5;

                // 判断是否在 box 内
                bool insideBox =
                    abs(localPos.x) <= halfSize.x &&
                    abs(localPos.y) <= halfSize.y &&
                    abs(localPos.z) <= halfSize.z;

                if (insideBox)
                {
                    // 只沿局部 Z 方向渐隐
                    // _FadeStart 是 box 内开始渐隐的位置
                    // 例如 box 前面是 -halfSize.z，后面是 +halfSize.z
                    float d = localPos.z - _FadeStart;

                    float fade = saturate(d / max(_FadeWidth, 0.0001));
                    fade = smoothstep(0.0, 1.0, fade);

                    // 足够深时完全隐藏
                    if (fade >= 0.999)
                    {
                        clip(-1);
                    }

                    float2 screenUV = IN.screenPos.xy / max(IN.screenPos.w, 0.0001);
                    float2 pixelPos = screenUV * _ScreenParams.xy;
                    float threshold = Bayer4x4(pixelPos);

                    float clipValue = (1.0 - fade * _DitherStrength) - threshold - 0.001;
                    clip(clipValue);
                }
            }
        }
        ENDCG
    }

    FallBack "Standard"
}