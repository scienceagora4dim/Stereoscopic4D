using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Stereoscopic4D {

	// Transform4D class extends Transform class of UnityEngine
	// and handles the position, the rotation and the scale of 4D-objects.
	// All 4D-objects in the scene, including cameras, need to have a Transform4D component.
	
	[DisallowMultipleComponent]
	public class Transform4D : MonoBehaviour {

		[Header("Position (W-coordinate)")]
		public float w = 0.0f;
		// Accessor	
		public Vector4 position {
			get {
				Vector3 pos = transform.position;
				return new Vector4 (pos.x, pos.y, pos.z, w);
			}
			set {
				transform.position = new Vector3 (value.x, value.y, value.z);
				w = value.w;
			}
		}

		[Header("Rotation (Axis is orthogonal to W-direction)")]
		// Axis is XZ, YZ and XY, respectively
		public float xz = 0.0f;
		public float yz = 0.0f;
		public float xy = 0.0f;
		// Accessor	
		// Getter for the Euler angles of 3D-rotation
		public Vector3 eulerAngles3D {
			get {
				return transform.localRotation.eulerAngles;
			}
		}
		// Getter and Setter for the 4D-rotation whose axis is orthogonal to W-direction
		public Quaternion rotationWithW {
			get {
				return Quaternion.Euler (xz, yz, xy);
			}
			set {
				Vector3 angles = value.eulerAngles;
				xz = angles.x;
				yz = angles.y;
				xy = angles.z;
			}
		}


		[Header("Scale (W-coordinate)")]
		public float scaleW = 1.0f;
		// Accessor
		public Vector4 scale {
			get {
				Vector3 scale = transform.localScale;
				return new Vector4 (scale.x, scale.y, scale.z, scaleW);
			}
			set {
				transform.localScale = new Vector3 (value.x, value.y, value.z);
				scaleW = value.w;
			}
		}
		
		/// <summary>
		/// 4D Rotate.
		/// </summary>
		/// <param name="dxz">delta xz.</param>
		/// <param name="dyz">delta yz.</param>
		/// <param name="dxy">delta xy.</param>
		public void Rotate4D(float dxz, float dyz, float dxy) {
			Quaternion nextAngles = Quaternion.Euler (dxz, dyz, dxy) * Quaternion.Euler (xz, yz, xy);
			Vector3 angles = nextAngles.eulerAngles;
			xz = angles.x;
			yz = angles.y;
			xy = angles.z;
		}
	}
}
