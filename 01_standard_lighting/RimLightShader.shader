// リムライト
Shader "Custom/RimLightShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        // リムライト
        _RimColor ("Rim Color", Color) = (1, 1, 1, 1)
        _RimPower ("Rim Power", Range(0.0, 5.0)) = 2.0
    }
    SubShader
    {
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
                float3 vertexWorld : TEXCOORD1;
                float3 normal : NORMAL;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            fixed4 _RimColor;
            float _RimPower;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.vertexWorld = mul(unity_ObjectToWorld, v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = mul(unity_ObjectToWorld, v.normal);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 法線とカメラからオブジェクトへの向きが垂直な部分を強くする
                const float3 n = normalize(i.normal);
                const float3 v = normalize(_WorldSpaceCameraPos - i.vertexWorld);
                const float3 nv = saturate(dot(n, v));
                const float rimPower = 1.0 - nv;

                // 絞りも入れた最終的な反射光
                const float3 rimColor = _RimColor * pow(rimPower, _RimPower);

                // 環境光も足す
                const half3 ambient = ShadeSH9(half4(i.normal, 1));
                const float3 finalLight = ambient + rimColor;

                // 最終的なカラーに乗算
                fixed4 col = tex2D(_MainTex, i.uv);
                col.xyz *= finalLight;
                return col;
            }
            ENDCG
        }
    }
}