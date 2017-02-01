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
		// Disable the hidden face removal
		ZWrite Off

		Pass
		{
			Cull Off // Disable culling, all sides of faces are drawn
			Blend SrcAlpha OneMinusSrcAlpha // Enable regular alpha blending

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

			/// 5x5 identity matrix
			static const float5x5 IDENTITY_5x5 = { {
				{ 1.0f, 0.0f, 0.0f, 0.0f, 0.0f },
				{ 0.0f, 1.0f, 0.0f, 0.0f, 0.0f },
				{ 0.0f, 0.0f, 1.0f, 0.0f, 0.0f },
				{ 0.0f, 0.0f, 0.0f, 1.0f, 0.0f },
				{ 0.0f, 0.0f, 0.0f, 0.0f, 1.0f },
			} };

			/// 5x5 zero matrix
			static const float5x5 ZERO_5x5 = { {
				{ 0.0f, 0.0f, 0.0f, 0.0f, 0.0f },
				{ 0.0f, 0.0f, 0.0f, 0.0f, 0.0f },
				{ 0.0f, 0.0f, 0.0f, 0.0f, 0.0f },
				{ 0.0f, 0.0f, 0.0f, 0.0f, 0.0f },
				{ 0.0f, 0.0f, 0.0f, 0.0f, 0.0f }
			} };

			/// zero vector
			static const float5 ZERO_5x1 = { {0.0f, 0.0f, 0.0f, 0.0f, 0.0f} };
			/// all-one vector
			static const float4 ONE_4x1 = float4(1.0f, 1.0f, 1.0f, 1.0f);

			/// Lift an affine 4D vector to a homogeneous 5D vector
			float5 toFloat5(const float4 v)
			{
				const float5 result = { {v.x, v.y, v.z, v.w, 1.0f} };
				return result;
			}

			/// Project a homogeneous 5D vector to an affine 4D vector
			float4 toFloat4(const float5 v)
			{
				return float4(v.values[0]/v.values[4], v.values[1]/v.values[4], v.values[2]/v.values[4], v.values[3]/v.values[4]);
				///return float4(v.values[0], v.values[1], v.values[2], v.values[3]);
			}

			/// Multiplication of 5-by-5 matrices
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

			/// Right action of a 5-by-5 matrix on the 5-space
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

			/// Left action of a 5-by-5 matrix on the 5-space
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

			/// Make the scaling matrix
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

			/// Make the translation matrix
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

			/// Make the rotation matrix along ZW axis
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

			/// Make the rotation matrix along YW axis
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

			/// Make the rotation matrix along YZ axis
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

			/// Make the rotation matrix along XW axis
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

			/// Make the rotation matrix along XZ axis
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

			/// Make the rotation matrix along XY axis
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

			/// Make the Model matrix
			float5x5 makeModelMatrix(
					float4 scale,
					float4 rotation,
					float rotationXZ,
					float rotationYZ,
					float rotationXY,
					float4 translation)
			{
				// Note the signs of x and y rotation
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
				// Note the sign of the z-coordinate
				const float4 t = float4(translation.x, translation.y, -translation.z, translation.w);
				const float5x5 tr = makeTranslation(t);
				const float5x5 rots = mul5x5(rot, s);
				return mul5x5(tr, rots);
			}

			// The Model matrix
			static const float5x5 M = makeModelMatrix(
				_Scale, _Rotation, _RotationXZ, _RotationYZ, _RotationXY, _Position);

			/// Make the View matrix
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
				// Note the sign of the z-coordinate
				const float4 t = float4(-translation.x, -translation.y, translation.z, -translation.w);
				const float5x5 tr = makeTranslation(t);
				// Note the signs of x and y rotation
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
				// Rotation comes after the translation
				const float5x5 worldView = mul5x5(rot, tr);

				// Rotation by stereoscopic views
				const float eyeRad = atan(separation / convergence);

				if (enable4d)
				{
					// 4D stereoscopic!
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
					// 3D stereoscopic
					const float4 eyeT = float4(-separation, 0.0f, 0.0f, 0.0f);
					const float5x5 eyeTr = makeTranslation(eyeT);
					const float5x5 eyeRot = makeRotateYW(eyeRad);
					const float5x5 e2 = mul5x5(eyeRot, eyeTr);
					return mul5x5(e2, worldView);
				}
			}

			// View matrix
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

			/// vertex data.
			struct appdata
			{
				float4 vertex : POSITION;
				float4 color : COLOR0;
				float2 uv : TEXCOORD0;
			};

			/// fragment shader input.
			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 color : COLOR0;
			};

			/// vertex shader function.
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
			
			/// fragment shader function.
			float4 frag(v2f i) : SV_Target
			{
				return i.color;
			}
			ENDCG
		}
	}
}
