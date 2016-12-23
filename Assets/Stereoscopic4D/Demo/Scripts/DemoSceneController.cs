using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Stereoscopic4D.Demo {

	/// <summary>
	/// Demo scene controller.
	/// </summary>
	public class DemoSceneController : MonoBehaviour {

		/// <summary>
		/// The rotation target object.
		/// </summary>
		public Transform4D targetObject;

		// Update is called once per frame
		void FixedUpdate () {
			float h = Input.GetAxis("Horizontal");
			float v = Input.GetAxis("Vertical");
			if (Input.GetButton ("Fire1")) {
				targetObject.Rotate4D (v, -h, 0.0f);
			} else {
				targetObject.transform.Rotate (new Vector3(v, -h, 0.0f));
			}
		}
	}
}
