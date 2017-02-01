using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Stereoscopic4D.Demo {

	public class DemoSceneController : MonoBehaviour {

		public Camera4D camera4D;
		public Transform4D cameraTransform;
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
			
			// 3D ratation
			float h = Input.GetAxis("Horizontal");
			float v = Input.GetAxis("Vertical");

			// 4D rotation (Left-CTRL)
			if (Input.GetButton ("Fire1")) {
				targetObject.Rotate4D (v, -h, 0.0f);
			} else {
				targetObject.transform.Rotate (new Vector3(v, -h, 0.0f));
			}

			// Change distance (Left-ALT) 
			if (Input.GetButton ("Fire2")) {
				targetObject.position += 
						0.05f * v * Vector4.Normalize(targetObject.position - cameraTransform.position);
			}

			// 4D Stereoscopic (Space)
			if(Input.GetButton ("Jump")){
				if(camera4D.squintFactor <= THRESH_SQUINT){
					camera4D.squintFactor = Mathf.Min(camera4D.squintFactor + 3.0f, THRESH_SQUINT);				
				}
			} else {
				if(camera4D.squintFactor >= 0f){
					camera4D.squintFactor = Mathf.Max(camera4D.squintFactor - 0.5f, 0f);
				}
			}


			// Control via Oculus Touch
			Vector2 rThumb = OVRInput.Get(OVRInput.Axis2D.PrimaryThumbstick, RTouch);
			Vector2 lThumb = OVRInput.Get(OVRInput.Axis2D.PrimaryThumbstick, LTouch);
			float lIndex = OVRInput.Get(OVRInput.Axis1D.PrimaryIndexTrigger, LTouch);

			// Rotate targetObject
			targetObject.transform.Rotate (new Vector3(rThumb.y, -rThumb.x, 0.0f));
			targetObject.Rotate4D (lThumb.y, -lThumb.x, 0.0f);
			
			// Change squintFactor
			if(lIndex > THRESH_SQUINT_CTRL){
				if(camera4D.squintFactor <= THRESH_SQUINT){
					camera4D.squintFactor += 3.0f * lIndex;
				}
			}else{
				if(camera4D.squintFactor >= 0f){
					//camera4D.squintFactor = Mathf.Max(camera4D.squintFactor - 0.5f, 0f);
				}
			}
		}
	}
}
