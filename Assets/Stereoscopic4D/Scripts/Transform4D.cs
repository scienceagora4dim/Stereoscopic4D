﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Stereoscopic4D {

	/// <summary>
	/// This class extends GameObject to 4D transform
	/// </summary>
	[DisallowMultipleComponent]
	public class Transform4D : MonoBehaviour {

		/// <summary>
		/// w position.
		/// </summary>
		public float w;

		[Header("Scale with W")]

		/// <summary>
		/// The scale w.
		/// </summary>
		public float scaleW;

		[Header("Rotation with W")]

		/// <summary>
		/// The XZ rotation.
		/// </summary>
		public float xz;

		/// <summary>
		/// The YZ rotation.
		/// </summary>
		public float yz;

		/// <summary>
		/// The XY rotation.
		/// </summary>
		public float xy;

		/// <summary>
		/// Gets or sets the 4D position.
		/// </summary>
		/// <value>The 4D position.</value>
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

		/// <summary>
		/// Gets or sets the 4D scale.
		/// </summary>
		/// <value>The 4D scale.</value>
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
		/// Gets the euler angles 3D.
		/// </summary>
		/// <value>The euler angles 3D.</value>
		public Vector3 eulerAngles3D {
			get {
				return transform.localRotation.eulerAngles;
			}
		}

		/// <summary>
		/// Gets or sets the world rotation with w.
		/// </summary>
		/// <value>The local rotation with w.</value>
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
	}
}