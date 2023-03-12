// 法線マップシェーダー
// ライト、カメラを接空間に変換して計算する方法
Shader "Unlit/NormalMapFromTangentSpace"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" {}
        _NormalMap ("Normal Map", 2D) = "bump" {}
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
                half3 normal : NORMAL;
                half4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normalWorld : NORMAL;
                // ライト、カメラの接空間情報
                half3 lightTangentDir : TEXCOORD1;
                half3 viewTangentDir : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _NormalMap;
            float _SpecularLevel;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normalWorld = mul(unity_ObjectToWorld, v.normal);

                // ライト、カメラの方向ベクトルを接空間に変換
                TANGENT_SPACE_ROTATION; // 接空間の行列を取得してrotationに格納
                o.lightTangentDir = normalize(mul(rotation, ObjSpaceLightDir(v.vertex)));
                o.viewTangentDir = normalize(mul(rotation, ObjSpaceViewDir(v.vertex)));
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 拡散反射(Lambert)
                const float3 normalTangent = UnpackNormal(tex2D(_NormalMap, i.uv)); // -1〜1に変換して取得
                const float3 diffuse = saturate(dot(normalTangent, i.lightTangentDir)) * _LightColor0;

                // 鏡面反射(Blinn-Phong)
                const float h = normalize(i.lightTangentDir + i.viewTangentDir);
                const float3 specular = pow(saturate(dot(normalTangent, h)), _SpecularLevel);

                // 環境光
                const half3 ambient = ShadeSH9(half4(i.normalWorld, 1));

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
