Shader "GoodLines/PixelPerfect"
{
    Properties
    {
        _Thickness ("Thickness", Range (0, 10)) = 1
        _ThicknessMultiplier ("Thickness Multiplier", Float) = 1
        _Color ("Color", Color) = (1,1,1,1)
        _MiterThreshold ("Miter Threshold", Range(-1,1)) = 0.8
        _Perspective ("Perspective", Range(0,1)) = 0
        _PixelAlignment ("Pixel Alignment", Range(-1, 1)) = 0
        _PixelAlignThreshold ("Pixel Align Threshold", Range(0,10)) = 0.01
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Cull Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;

                float4 prev : TEXCOORD1;
                float4 next : TEXCOORD2;
                float2 orientation : TEXCOORD3;
            };

            struct v2f
            {
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4 _Color;
            float _Thickness;
            float _ThicknessMultiplier;
            float _MiterThreshold;
            float _Perspective;
            float _PixelAlignment;
            float _PixelAlignThreshold;

            v2f vert (appdata v)
            {
                v2f o;
                float4 current = UnityObjectToClipPos(v.vertex);
                float4 prev = UnityObjectToClipPos(v.prev);
                float4 next = UnityObjectToClipPos(v.next);

                float2 half_screen = _ScreenParams.xy / 2;

                float2 current_screen = current.xy / current.w * half_screen + half_screen;
                float2 prev_screen = prev.xy / prev.w * half_screen + half_screen;
                float2 next_screen = next.xy / next.w * half_screen + half_screen;

                float len = _Thickness * _ThicknessMultiplier;
                float2 dir = float2(0,0);

                float pp = 0;

                if(v.orientation.y == 1.0) {
                    float2 d = next_screen - current_screen;
                    if (abs(d.x) < _PixelAlignThreshold || abs(d.y) < _PixelAlignThreshold) {
                        //Close to a cardinal direction, we round off.
                        current_screen = floor(current_screen);
                        prev_screen = floor(prev_screen);
                        next_screen = floor(next_screen);
                        pp = 1;
                    }
                    dir = normalize(d);
                }
                else {
                    float2 d = current_screen - prev_screen;
                    if (abs(d.x) < _PixelAlignThreshold || abs(d.y) < _PixelAlignThreshold) {
                        //Close to a cardinal direction, we round off.
                        current_screen = floor(current_screen);
                        prev_screen = floor(prev_screen);
                        next_screen = floor(next_screen);
                        pp = 1;
                    }
                    if(v.orientation.y == 2.0) {
                        dir = normalize(d);
                    }
                    else {
                        float2 dirA = normalize(d);
                        float2 dirB = normalize(next_screen - current_screen);

                        float flip = sign(.1 + sign(dot(dirA,dirB) + _MiterThreshold));

                        dirB *= flip;

                        float2 tangent = (dirA+dirB)/2; //Divide by two normalizes since len is 2.
                        float2 perp_dirA = float2(-dirA.y, dirA.x);
                        float2 perp_tangent = float2(-tangent.y, tangent.x);

                        dir = tangent;
                        len /= dot(perp_tangent, perp_dirA);
                    }
                }
                

                float2 normal = (float2(-dir.y, dir.x));
                normal *= len;
                normal *= _ScreenParams.zw - 1; // Equivalent to `normal /= _ScreenParams.xy` but with less division.

                float2 offset = normal * v.orientation.x;
                float pixel_align = (_PixelAlignment*.5 + .5)*pp; // Only do the pixel align of pp is enabled.
                float4 current_pixel_perfect = float4(((current_screen + pixel_align - half_screen) / half_screen) * current.w, 0, current.w);

                o.vertex = current_pixel_perfect + float4(offset*pow(current.w, 1 - _Perspective), 0, 0)

                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Set the color
                fixed4 col = _Color;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
