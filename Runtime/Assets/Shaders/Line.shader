Shader "GoodLines/Line"
{
    Properties
    {
        _Thickness("Thickness", Range(0, 10)) = 1
        _ThicknessMultiplier("Thickness Multiplier", Float) = 1
        _Color("Color", Color) = (1,1,1,1)
        _MainTex("Texture", 2D) = "white" {}
        _MiterThreshold("Miter Threshold", Range(-1,1)) = 0.8
        _Perspective("Perspective", Range(0,1)) = 0
    }
    SubShader
    {
        Tags {"Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Lighting Off
        Fog { Mode Off }
        LOD 100

        Pass
        {
            Cull Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

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
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4 _Color;
            float _Thickness;
            float _ThicknessMultiplier;
            float _MiterThreshold;
            float _Perspective;

            v2f vert(appdata v)
            {
                v2f o;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                float4 current = UnityObjectToClipPos(v.vertex);
                float4 prev = UnityObjectToClipPos(v.prev);
                float4 next = UnityObjectToClipPos(v.next);

                float2 current_screen = current.xy / current.w * _ScreenParams.xy;
                float2 prev_screen = prev.xy / prev.w * _ScreenParams.xy;
                float2 next_screen = next.xy / next.w * _ScreenParams.xy;

                float len = _Thickness * _ThicknessMultiplier;
                float2 dir = float2(0,0);

                if (v.orientation.y == 1.0) {
                    dir = normalize(next_screen - current_screen);
                }
                else if (v.orientation.y == 2.0) {
                    dir = normalize(current_screen - prev_screen);
                }
                else {
                    float2 dirA = normalize(current_screen - prev_screen);
                    float2 dirB = normalize(next_screen - current_screen);

                    float flip = sign(.1 + sign(dot(dirA,dirB) + _MiterThreshold));

                    dirB *= flip;

                    float2 tangent = (dirA + dirB) / 2; //Divide by two normalizes since len is 2.
                    float2 perp_dirA = float2(-dirA.y, dirA.x);
                    float2 perp_tangent = float2(-tangent.y, tangent.x);

                    dir = tangent;
                    len /= dot(perp_tangent, perp_dirA);
                }

                float2 normal = (float2(-dir.y, dir.x));
                // One might think that we should "extrude" only half of the length,
                // since the other point will also be moved away from this point by the same distance.
                // However, we are actually only moving half of len pixels since the space we are working in
                // is twice as large as the screen: (-width, +width) rather than (0, width) and same for the height.
                // Essentially there are two factor of two which cancel each other out.
                normal *= len;
                normal *= _ScreenParams.zw - 1; // Equivalent to `normal /= _ScreenParams.xy` but with less division.

                float2 offset = normal * v.orientation.x;
                o.vertex = current + float4(offset * pow(current.w, 1 - _Perspective), 0, 0);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // Set the color
                fixed4 col = tex2D(_MainTex, i.uv);
                col *= _Color;
                return col;
            }
            ENDCG
        }
    }
}
