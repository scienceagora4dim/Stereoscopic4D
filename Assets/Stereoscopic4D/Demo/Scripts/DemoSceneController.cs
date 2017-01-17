using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Stereoscopic4D.Demo {

	public class DemoSceneController : MonoBehaviour {

		public Camera4D camera4D;
		public const float THRESH_SQUINT = 30f;
		public const float THRESH_SQUINT_CTRL = 0.55f;

		// One can move the target object.
		public Transform4D targetObject;

		// Oculus Touch
		public OVRInput.Controller RTouch;
		public OVRInput.Controller LTouch;

		void Update () {

			// Need to call for button matching of Oculus Touch
			OVRInput.Update();

			// Control via keyboard or joystick
			float h = Input.GetAxis("Horizontal");
			float v = Input.GetAxis("Vertical");
			if (Input.GetButton ("Fire1")) {
				targetObject.Rotate4D (v, -h, 0.0f);
			} else {
				targetObject.transform.Rotate (new Vector3(v, -h, 0.0f));
			}

			// Control via Oculus Touch
			Vector2 rThumb = OVRInput.Get(OVRInput.Axis2D.PrimaryThumbstick, RTouch);
			Vector2 lThumb = OVRInput.Get(OVRInput.Axis2D.PrimaryThumbstick, LTouch);
			float lIndex = OVRInput.Get(OVRInput.Axis1D.PrimaryIndexTrigger, LTouch);

			// Rotate targetObject
			targetObject.transform.Rotate (new Vector3(rThumb.y, -rThumb.x, 0.0f));
			targetObject.Rotate4D (lThumb.y, -lThumb.x, 0.0f);
			
			Debug.Log(lIndex);
			// Change squintFactor
			if(lIndex > THRESH_SQUINT_CTRL){
				if(camera4D.squintFactor <= THRESH_SQUINT){
					camera4D.squintFactor += 0.5f * lIndex;
				}
			}else{
				if(camera4D.squintFactor >= 0f){
					camera4D.squintFactor -= 0.5f;
				}
			}
		}
	}
}
