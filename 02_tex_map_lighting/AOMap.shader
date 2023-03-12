// AOマップシェーダー
Shader "Unlit/AOMap"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _AOMap ("AO Map", 2D) = "white" {}
        _SpecularLevel ("Specular Level", Range(0.1, 2)) = 0.8 // 鏡面反射指数 a
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
            #include "UnityLightingCommon.cginc"

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
            sampler2D _AOMap;
            float _SpecularLevel;

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
                // 拡散反射光
                const float3 l = normalize(_WorldSpaceLightPos0.xyz);
                const float3 n = normalize(i.normal);
                const float3 diffuse =  saturate(dot(n, l)) * _LightColor0;

                // 鏡面反射光
                const float3 v = normalize(_WorldSpaceCameraPos - i.vertexWorld);
                const float3 h = normalize(l+v);
                const float3 specular = pow(saturate(dot(n, h)), _SpecularLevel);

                // 環境光
                const float aoMask = tex2D(_AOMap, i.uv).r; // AOマップからmask値を取得
                const half3 ambient = ShadeSH9(half4(i.normal, 1)) * aoMask; // mask値を乗算する

                // 最終的なカラーに乗算
                const float3 finalColor = ambient + diffuse + specular;
                fixed4 col = tex2D(_MainTex, i.uv);
                col.xyz *= finalColor;
                return col;
            }
            ENDCG
        }
    }
}
