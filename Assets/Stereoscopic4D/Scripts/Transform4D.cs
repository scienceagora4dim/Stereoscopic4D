using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Stereoscopic4D {

	/// <summary>
	/// This class extends GameObject to 4D transform
	/// </summary>
	public class Transform4D : MonoBehaviour {

		/// <summary>
		/// w position.
		/// </summary>
		public float w;

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