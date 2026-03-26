Shader "Custom/DoorDitherStandard"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo", 2D) = "white" {}
        _Metallic ("Metallic", Range(0,1)) = 0
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _BumpMap ("Normal Map", 2D) = "bump" {}
        _BumpScale ("Normal Scale", Range(0,2)) = 1

        _DoorCenter ("Door Center", Vector) = (0,0,0,0)
        _DoorForward ("Door Forward", Vector) = (0,0,1,0)
        _FadeWidth ("Fade Width", Float) = 0.5
        _FadeOffset ("Fade Offset", Float) = 0
        _DitherStrength ("Dither Strength", Range(0,1)) = 1

        _MaskEnable ("Enable Door Fade", Float) = 0
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

        float4 _DoorCenter;
        float4 _DoorForward;
        float _FadeWidth;
        float _FadeOffset;
        float _DitherStrength;
        float _MaskEnable;

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
                float3 forwardDir = normalize(_DoorForward.xyz);
                float3 toPixel = IN.worldPos - _DoorCenter.xyz;

                // d < 0 代表还在门外
                // d > 0 代表已经进入门内
                float d = dot(toPixel, forwardDir) + _FadeOffset;

                // 0 到 1：进入越深，fade越强
                float fade = saturate(d / max(_FadeWidth, 0.0001));

                // 平滑一点
                fade = smoothstep(0.0, 1.0, fade);

                // 屏幕像素坐标
                float2 screenUV = IN.screenPos.xy / max(IN.screenPos.w, 0.0001);
                float2 pixelPos = screenUV * _ScreenParams.xy;

                float threshold = Bayer4x4(pixelPos);

                // fade越大，越容易被裁掉
                float clipValue = (1.0 - fade * _DitherStrength) - threshold;

                clip(clipValue);
            }
        }
        ENDCG
    }

    FallBack "Standard"
}