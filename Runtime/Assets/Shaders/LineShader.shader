Shader "GoodLines/ScreenWidth"
{
    Properties
    {
        _Thickness ("Thickness", Range (0, 20)) = 1
        _Color ("Color", Color) = (1,1,1,1)
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

            v2f vert (appdata v)
            {
                v2f o;
                float4 current = UnityObjectToClipPos(v.vertex);
                float4 prev = UnityObjectToClipPos(v.prev);
                float4 next = UnityObjectToClipPos(v.next);

                float2 current_screen = current.xy / current.w * _ScreenParams.xy;
                float2 prev_screen = prev.xy / prev.w * _ScreenParams.xy;
                float2 next_screen = next.xy / next.w * _ScreenParams.xy;

                float len = _Thickness;
                float2 dir = float2(0,0);

                if(v.orientation.y == 1.0) {
                    dir = normalize(next_screen - current_screen);
                }
                else if(v.orientation.y == 2.0) {
                    dir = normalize(current_screen - prev_screen);
                }
                else {
                    float2 dirA = normalize(current_screen - prev_screen);
                    float2 dirB = normalize(next_screen - current_screen);

                    float2 tangent = (dirA+dirB)/2; //Divide by two normalizes since len is 2.
                    float2 perp_dirA = float2(-dirA.y, dirA.x);
                    float2 perp_tangent = float2(-tangent.y, tangent.x);

                    dir = tangent;
                    len = _Thickness / dot(perp_tangent, perp_dirA);
                }

                float2 normal = (float2(-dir.y, dir.x));
                normal *= len/2.0;
                normal *= _ScreenParams.zw - 1; // Equivalent to `normal /= _ScreenParams.xy` but with less division.

                float2 offset = normal * v.orientation.x;
                o.vertex = current + float4(offset*current.w, 0, 0)

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
