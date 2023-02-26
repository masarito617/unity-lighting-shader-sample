// Lambert拡散反射モデル
Shader "Custom/LambertShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        // 環境色
        _Ka ("Ka", Range(0.01, 1)) = 0.8
        // 拡散反射色
        _DiffuseColor ("Diffuse Color", Color) = (0.8, 0.8, 0.8, 1)
        _Kd ("Kd", Range(0.01, 1)) = 1.0
    }
    SubShader
    {
        // フォワードレンダリングパイプラインのベースパスであることを示す
        // ディレクショナルライト 方向: _WorldSpaceLightPos0
        Tags { "LightMode"="ForwardBase" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _Ka;
            fixed4 _DiffuseColor;
            float _Kd;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = mul(unity_ObjectToWorld, v.normal);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 拡散反射光
                const float3 l = normalize(_WorldSpaceLightPos0.xyz);
                const float3 n = normalize(i.normal);
                const float3 nl = saturate(dot(n, l));
                const float3 diffuse = _Kd * _DiffuseColor.xyz * nl; // ライトの色を使う場合は_LightColor0を指定すればよい

                // 環境光
                const half3 ambient = _Ka * ShadeSH9(half4(i.normal, 1));

                // 環境光+拡散反射光
                const float3 lambert = ambient + diffuse;

                // 最終的なカラーに乗算
                fixed4 col = tex2D(_MainTex, i.uv);
                col.xyz *= lambert;
                return col;
            }
            ENDCG
        }
    }
}