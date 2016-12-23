Shader "Unlit/Stereoscopic4D"
{
	Properties
	{
		_Position ("Position", Vector) = (0, 0, 0, 0)
		_Scale ("Scale", Vector) = (1.0, 1.0, 1.0, 1.0)
		_Rotation ("Rotation", Vector) = (0, 0, 0)
		_RotationXZ ("Rotation XZ", Float) = 0.0
		_RotationYZ ("Rotation YZ", Float) = 0.0
		_RotationXY ("Rotation XY", Float) = 0.0

		_CameraPosition ("Camera Position", Vector) = (0, 0, 0, 0)
		_CameraRotation ("Camera Rotation", Vector) = (0, 0, 0)
		_CameraRotationXZ ("Camera Rotation XZ", Float) = 0.0
		_CameraRotationYZ ("Camera Rotation YZ", Float) = 0.0
		_CameraRotationXY ("Camera Rotation XY", Float) = 0.0
		_CameraStereoSeparation ("Camera Stereo Separation", Float) = 0.0
		_CameraStereoConvergence ("Camera Stereo Convergence", Float) = 0.0
		_CameraSquint ("Camera Squint", Float) = 0.0
		_Enable4DStereo ("Enable 4D Stereo", Int) = 0
	}
	SubShader
	{
		Tags { 
			"Queue" = "Transparent"
			"RenderType"="Transparent"
		}
		LOD 100
		ZWrite Off

		Pass
		{
			Cull Off // enable double shaded
			Blend SrcAlpha OneMinusSrcAlpha // enable alpha blending

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			float4 _Position;
			float4 _Scale;
			float4 _Rotation;
			float _RotationXZ;
			float _RotationYZ;
			float _RotationXY;

			float4 _CameraPosition;
			float4 _CameraScale;
			float4 _CameraRotation;
			float _CameraRotationXZ;
			float _CameraRotationYZ;
			float _CameraRotationXY;
			float _CameraStereoSeparation;
			float _CameraStereoConvergence;
			float _CameraSquint;
			int _Enable4DStereo;

			struct float5x5 {
				float values[5][5];
			};

			struct float5 {
				float values[5];
			};

			/// 5x5単位行列
			static const float5x5 IDENTITY_5x5 = { {
				{ 1.0f, 0.0f, 0.0f, 0.0f, 0.0f },
				{ 0.0f, 1.0f, 0.0f, 0.0f, 0.0f },
				{ 0.0f, 0.0f, 1.0f, 0.0f, 0.0f },
				{ 0.0f, 0.0f, 0.0f, 1.0f, 0.0f },
				{ 0.0f, 0.0f, 0.0f, 0.0f, 1.0f },
			} };

			/// 5x5ゼロ行列
			static const float5x5 ZERO_5x5 = { {
				{ 0.0f, 0.0f, 0.0f, 0.0f, 0.0f },
				{ 0.0f, 0.0f, 0.0f, 0.0f, 0.0f },
				{ 0.0f, 0.0f, 0.0f, 0.0f, 0.0f },
				{ 0.0f, 0.0f, 0.0f, 0.0f, 0.0f },
				{ 0.0f, 0.0f, 0.0f, 0.0f, 0.0f }
			} };

			/// ゼロベクトル
			static const float5 ZERO_5x1 = { {0.0f, 0.0f, 0.0f, 0.0f, 0.0f} };
			static const float4 ONE_4x1 = float4(1.0f, 1.0f, 1.0f, 1.0f);

			/// 5次元ベクトルに変換する
			float5 toFloat5(const float4 v)
			{
				const float5 result = { {v.x, v.y, v.z, v.w, 1.0f} };
				return result;
			}

			/// 4次元ベクトルに変換する
			float4 toFloat4(const float5 v)
			{
				return float4(v.values[0], v.values[1], v.values[2], v.values[3]);
			}

			/// 5x5行列の乗算
			float5x5 mul5x5(const float5x5 lhs, const float5x5 rhs)
			{
				float5x5 result;
				for (int rhsCol = 0; rhsCol < 5; ++rhsCol)
				{
					for (int i = 0; i < 5; ++i)
					{
						float sum = 0.0f;
						for (int j = 0; j < 5; ++j)
						{
							sum += (lhs.values[i][j] * rhs.values[j][rhsCol]);
						}
						result.values[i][rhsCol] = sum;
					}
				}
				return result;
			}

			/// ベクトルと5x5行列の乗算
			float5 mul1x5(const float5 lhs, const float5x5 rhs)
			{
				float5 result;
				for (int rhsCol = 0; rhsCol < 5; ++rhsCol)
				{
					for (int j = 0; j < 5; ++j)
					{
						result.values[rhsCol] += (lhs.values[j] * rhs.values[j][rhsCol]);
					}
				}
				return result;
			}

			/// 5x5行列とベクトルの乗算
			float5 mul5x1(float5x5 lhs, float5 rhs)
			{
				float5 result = ZERO_5x1;
				for (int i = 0; i < 5; ++i)
				{
					for (int j = 0; j < 5; ++j)
					{
						result.values[i] += (lhs.values[i][j] * rhs.values[j]);
					}
				}
				return result;
			}

			/// スケーリング行列を生成する
			float5x5 makeScale(float4 value)
			{
				const float5x5 result =
				{ {
					{ value.x,    0.0f,    0.0f,    0.0f, 0.0f },
					{    0.0f, value.y,    0.0f,    0.0f, 0.0f },
					{    0.0f,    0.0f, value.z,    0.0f, 0.0f },
					{    0.0f,    0.0f,    0.0f, value.w, 0.0f },
					{    0.0f,    0.0f,    0.0f,    0.0f, 1.0f },
					} };
				return result;
			}

			/// 平行移動行列を生成する
			float5x5 makeTranslation(float4 value)
			{
				const float5x5 result =
				{ {
					{ 1.0f, 0.0f, 0.0f, 0.0f, value.x },
					{ 0.0f, 1.0f, 0.0f, 0.0f, value.y },
					{ 0.0f, 0.0f, 1.0f, 0.0f, value.z },
					{ 0.0f, 0.0f, 0.0f, 1.0f, value.w },
					{ 0.0f, 0.0f, 0.0f, 0.0f,    1.0f },
				} };
				return result;
			}

			/// ZW平面回転行列を生成する(XY座標が変化)
			float5x5 makeRotateZW(float theta)
			{
				float c = cos(theta);
				float s = sin(theta);
				const float5x5 result =
				{ {
					{    c,   -s, 0.0f, 0.0f, 0.0f },
					{    s,    c, 0.0f, 0.0f, 0.0f },
					{ 0.0f, 0.0f, 1.0f, 0.0f, 0.0f },
					{ 0.0f, 0.0f, 0.0f, 1.0f, 0.0f },
					{ 0.0f, 0.0f, 0.0f, 0.0f, 1.0f },
				} };
				return result;
			}

			/// YW平面回転行列を生成する(XZ座標が変化)
			float5x5 makeRotateYW(float theta)
			{
				float c = cos(theta);
				float s = sin(theta);
				const float5x5 result =
				{ {
					{    c, 0.0f,    s, 0.0f, 0.0f },
					{ 0.0f, 1.0f, 0.0f, 0.0f, 0.0f },
					{   -s, 0.0f,    c, 0.0f, 0.0f },
					{ 0.0f, 0.0f, 0.0f, 1.0f, 0.0f },
					{ 0.0f, 0.0f, 0.0f, 0.0f, 1.0f },
				} };
				return result;
			}

			/// YZ平面回転行列を生成する(XW座標が変化)
			float5x5 makeRotateYZ(float theta)
			{
				float c = cos(theta);
				float s = sin(theta);
				const float5x5 result =
				{ {
					{    c, 0.0f, 0.0f,   -s, 0.0f },
					{ 0.0f, 1.0f, 0.0f, 0.0f, 0.0f },
					{ 0.0f, 0.0f, 1.0f, 0.0f, 0.0f },
					{    s, 0.0f, 0.0f,    c, 0.0f },
					{ 0.0f, 0.0f, 0.0f, 0.0f, 1.0f },
				} };
				return result;
			}

			/// XW平面回転行列を生成する(YZ座標が変化)
			float5x5 makeRotateXW(float theta)
			{
				float c = cos(theta);
				float s = sin(theta);
				const float5x5 result =
				{ {
					{ 1.0f, 0.0f, 0.0f, 0.0f, 0.0f },
					{ 0.0f,    c,   -s, 0.0f, 0.0f },
					{ 0.0f,    s,    c, 0.0f, 0.0f },
					{ 0.0f, 0.0f, 0.0f, 1.0f, 0.0f },
					{ 0.0f, 0.0f, 0.0f, 0.0f, 1.0f },
				} };
				return result;
			}

			/// XZ平面回転行列を生成する(YW座標が変化)
			float5x5 makeRotateXZ(float theta)
			{
				float c = cos(theta);
				float s = sin(theta);
				const float5x5 result =
				{ {
					{ 1.0f, 0.0f, 0.0f, 0.0f, 0.0f },
					{ 0.0f,    c, 0.0f,   -s, 0.0f },
					{ 0.0f, 0.0f, 1.0f, 0.0f, 0.0f },
					{ 0.0f,    s, 0.0f,    c, 0.0f },
					{ 0.0f, 0.0f, 0.0f, 0.0f, 1.0f },
				} };
				return result;
			}

			/// XY平面回転行列を生成する(ZW座標が変化)
			float5x5 makeRotateXY(float theta)
			{
				float c = cos(theta);
				float s = sin(theta);
				const float5x5 result =
				{ {
					{ 1.0f, 0.0f, 0.0f, 0.0f, 0.0f },
					{ 0.0f, 1.0f, 0.0f, 0.0f, 0.0f },
					{ 0.0f, 0.0f,    c,   -s, 0.0f },
					{ 0.0f, 0.0f,    s,    c, 0.0f },
					{ 0.0f, 0.0f, 0.0f, 0.0f, 1.0f },
				} };
				return result;
			}

			/// モデル行列の生成
			float5x5 makeModelMatrix(
					float4 scale,
					float4 rotation,
					float rotationXZ,
					float rotationYZ,
					float rotationXY,
					float4 translation)
			{
				const float5x5 xw = makeRotateXW(radians(-rotation.x));
				const float5x5 yw = makeRotateYW(radians(-rotation.y));
				const float5x5 zw = makeRotateZW(radians( rotation.z));
				const float5x5 xz = makeRotateXZ(radians( rotationXZ));
				const float5x5 yz = makeRotateYZ(radians( rotationYZ));
				const float5x5 xy = makeRotateXY(radians( rotationXY));
				const float5x5 r1 = mul5x5(xw, zw);
				const float5x5 r2 = mul5x5(yw, r1);
				const float5x5 r3 = mul5x5(xz, r2);
				const float5x5 r4 = mul5x5(yz, r3);
				const float5x5 rot = mul5x5(xy, r4);
				const float5x5 s = makeScale(scale);
				const float4 t = float4(translation.x, translation.y, -translation.z, translation.w); // z軸は反転する。(前が負の方向)
				const float5x5 tr = makeTranslation(t);
				const float5x5 rots = mul5x5(rot, s);
				return mul5x5(tr, rots);
			}

			// モデル行列
			static const float5x5 M = makeModelMatrix(
				_Scale, _Rotation, _RotationXZ, _RotationYZ, _RotationXY, _Position);

			/// ビュー行列の生成
			float5x5 makeViewMatrix(
					float4 rotation,
					float rotationXZ,
					float rotationYZ,
					float rotationXY,
					float4 translation,
					float separation,
					float convergence,
					float squint,
					int enable4d)
			{
				const float4 t = float4(-translation.x, -translation.y, translation.z, -translation.w); // z軸は反転する。(前が負の方向)
				const float5x5 tr = makeTranslation(t);
				const float5x5 xw = makeRotateXW(radians( rotation.x));
				const float5x5 yw = makeRotateYW(radians( rotation.y));
				const float5x5 zw = makeRotateZW(radians(-rotation.z));
				const float5x5 xz = makeRotateXZ(radians(-rotationXZ));
				const float5x5 yz = makeRotateYZ(radians(-rotationYZ));
				const float5x5 xy = makeRotateXY(radians(-rotationXY));
				const float5x5 r1 = mul5x5(yz, xy);
				const float5x5 r2 = mul5x5(xz, r1);
				const float5x5 r3 = mul5x5(yw, r2);
				const float5x5 r4 = mul5x5(xw, r3);
				const float5x5 rot = mul5x5(zw, r4);
				const float5x5 worldView = mul5x5(rot, tr); // 移動してから回転
								
				// 右目の場合 tan = +sep / convで atan > 0 になる。
				// 左目の場合 tan = -sep / convで atan < 0 になる。
				// 眼球を回転させる代わりに世界を逆回転させるため、符号が反転したままでOK
				const float eyeRad = atan(separation / convergence);

				// 視差分の移動
				if (enable4d)
				{
					// 4D描画
					const float4 eyeT = float4(-separation, 0.0f, 0.0f, 0.0f);
					const float5x5 eyeTr = makeTranslation(eyeT);
					const float5x5 eyeRotYW = makeRotateYW(eyeRad);
					const float5x5 eyeRotYZ = makeRotateYZ(eyeRad * squint);
					const float5x5 e2 = mul5x5(eyeRotYW, eyeTr);
					const float5x5 e3 = mul5x5(eyeRotYZ, e2);
					return mul5x5(e3, worldView);
				}
				else
				{
					// 通常の3D描画
					const float4 eyeT = float4(-separation, 0.0f, 0.0f, 0.0f);
					const float5x5 eyeTr = makeTranslation(eyeT);
					const float5x5 eyeRot = makeRotateYW(eyeRad);
					const float5x5 e2 = mul5x5(eyeRot, eyeTr);
					return mul5x5(e2, worldView);
				}
			}

			// カメラ行列
			static const float5x5 V = makeViewMatrix(
				_CameraRotation,
				_CameraRotationXZ,
				_CameraRotationYZ,
				_CameraRotationXY,
				_CameraPosition,
				_CameraStereoSeparation,
				_CameraStereoConvergence,
				_CameraSquint,
				_Enable4DStereo);

			/**
			 *	頂点データ構造体
			 *
			 *	スクリプトで設定したvertices・colors・uvの値が設定される。
			 */
			struct appdata
			{
				float4 vertex : POSITION;
				float4 color : COLOR0;
				float2 uv : TEXCOORD0;
			};

			/**
			 *	頂点シェーダーからフラグメントシェーダーに渡す中間データの構造体
			 *
			 *	フラグメントシェーダーでは、頂点からの距離に応じて補完された値が設定される。
			 */
			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 color : COLOR0;
			};

			/**
			 *	頂点シェーダー
			 *
			 *	スクリプトで設定したvertices・colors・uvの値が渡される。
			 *	頂点毎に呼び出される。
			 *	頂点を座標変換し、フラグメントシェーダーに渡す。
			 */
			v2f vert(appdata v)
			{
				v2f o;
				const float5 vertex = { {v.vertex.x, v.vertex.y, v.vertex.z, v.uv.x, 1.0f} };
				const float5 mv = mul5x1(M, vertex);
				const float5 vmv = mul5x1(V, mv);
				float4 movedVertex4 = toFloat4(vmv);
				movedVertex4.w = 1.0f;

				o.color = v.color;
				o.vertex = mul(UNITY_MATRIX_P, movedVertex4);
				return o;
			}
			
			/**
			 *	フラグメントシェーダー
			 *
			 *	頂点シェーダーの出力結果をもとに、画素毎の色の計算を行う。
			 *	頂点シェーダーの出力結果を画素毎に線型補完した値が渡される。
			 */
			float4 frag(v2f i) : SV_Target
			{
				// 頂点色をそのまま返す。
				return i.color;
			}
			ENDCG
		}
	}
}
