// 法線マップシェーダー
// 法線情報をワールド座標空間に変換して計算する方法
Shader "Unlit/NormalMapFromWorldSpace"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" {}
        _NormalMap ("Normal Map", 2D) = "bump" {}
        _SpecularLevel ("Specular Level", Range(0.1, 50)) = 30 // 鏡面反射指数 a
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
                float4 vertexWorld : TEXCOORD1;
                // 法線のワールド座標情報
                half3 normalWorld : TEXCOORD2;   // 法線
                half3 tangentWorld : TEXCOORD3;  // 接線
                half3 biNormalWorld : TEXCOORD4; // 従法線
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _NormalMap;
            float _SpecularLevel;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.vertexWorld = mul(unity_ObjectToWorld, v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                // 法線情報をワールド座標に変換
                // 法線、接線
                o.normalWorld = mul(unity_ObjectToWorld, v.normal);
                o.tangentWorld = normalize(mul(unity_ObjectToWorld, v.tangent)).xyz;
                // 従法線
                // w成分は通常は-1だが、uv座標のいずれかが逆にマッピングされた場合には+1になるため乗算している
                const float3 biNormal = cross(normalize(v.normal), normalize(v.tangent.xyz)) * v.tangent.w;
                o.biNormalWorld = normalize(mul(unity_ObjectToWorld, biNormal));
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 法線マップの情報からワールド座標の法線を計算
                const float3 normalTangent = UnpackNormal(tex2D(_NormalMap, i.uv)); // -1〜1に変換して取得
                const float3 normalWorld = normalize(i.tangentWorld * normalTangent.x + i.biNormalWorld * normalTangent.y + i.normalWorld * normalTangent.z);

                // 拡散反射光(Lambert)
                const float3 l = normalize(_WorldSpaceLightPos0.xyz);
                const float3 diffuse = saturate(dot(normalWorld, l)) * _LightColor0;

                // 鏡面反射光(Blinn-Phong)
                const float3 v = normalize(_WorldSpaceCameraPos - i.vertexWorld);
                const float3 h = normalize(l+v);
                const float3 specular = pow(saturate(dot(normalWorld, h)), _SpecularLevel);

                // 環境光
                const half3 ambient = ShadeSH9(half4(normalWorld, 1));

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
