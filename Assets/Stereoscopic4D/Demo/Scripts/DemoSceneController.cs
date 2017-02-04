using System.Collections;
using System;
using System.Collections.Generic;
using UnityEngine;

namespace Stereoscopic4D.Demo {

	public class DemoSceneController : MonoBehaviour {

		public enum InputDevice {Keyboard, Joystick, OculusTouch}
		public enum InputMode {Rotation, PolarMove}
		public InputDevice inputDevice;
		public InputMode inputMode;

		// Oculus Touch
		public OVRInput.Controller RTouch;
		public OVRInput.Controller LTouch;

		public Camera4D camera4D;
		public Transform4D cameraTransform;

		public const float THRESH_SQUINT = 30f;
		// The threshold of the Oculus Touch trigger
		public const float THRESH_TOUCH_TRIGGER = 0.55f;

		// One can move one of the target objects.
		public Transform4D[] targetObjects;
		public int target = 0;



		void Update () {

			// Need to call for button matching of Oculus Touch
			OVRInput.Update();
			float h = Input.GetAxis("Horizontal");
			float v = Input.GetAxis("Vertical");

			// Select the target object by Z-button
			if (Input.GetButtonDown("TargetSelect")) target = (target + 1) % targetObjects.Length;
			// Select the input mode by X-button
			if (Input.GetButtonDown("ModeSelect")) inputMode = (InputMode)Enum.ToObject(typeof(InputMode), ((int)inputMode + 1) % 2);

      // 4D Stereoscopic (Space)
			switch(inputDevice){
					case InputDevice.Keyboard:
					case InputDevice.Joystick:
						
        		if(Input.GetButton("LIndexTrigger") || Input.GetAxis("LIndexTrigger") > THRESH_TOUCH_TRIGGER){
          		if(camera4D.squintFactor <= THRESH_SQUINT) camera4D.squintFactor = Mathf.Min(camera4D.squintFactor + 3.0f, THRESH_SQUINT);                
          	} else {
           		if(camera4D.squintFactor >= 0f) camera4D.squintFactor = Mathf.Max(camera4D.squintFactor - 0.5f, 0f);
     				}
						break;
						
					case InputDevice.OculusTouch:

						float lIndex = OVRInput.Get(OVRInput.Axis1D.PrimaryIndexTrigger, LTouch);
						if(lIndex > THRESH_TOUCH_TRIGGER){
							if(camera4D.squintFactor <= THRESH_SQUINT) camera4D.squintFactor += 3.0f * lIndex;
						} else {
							if(camera4D.squintFactor >= 0f) camera4D.squintFactor = Mathf.Max(camera4D.squintFactor - 0.5f, 0f);
						}
						break;
			}

			
			switch(inputMode){

				// In the rotation mode, 3D and 4D rotations of the target object is performed.
				case InputMode.Rotation:
					
					switch(inputDevice){
						case InputDevice.Keyboard:

							// 4D rotation with Left-CTRL
							if (Input.GetButton("L-CTRL")) {
								targetObjects[target].Rotate4D (v, -h, 0.0f);
							} else {
								targetObjects[target].transform.Rotate (new Vector3(v, -h, 0.0f));
							}
							break;
						
						case InputDevice.Joystick:

							float h2 = Input.GetAxis("Horizontal2");
							float v2 = Input.GetAxis("Vertical2");
							targetObjects[target].transform.Rotate (new Vector3(v, -h, 0.0f));
							targetObjects[target].Rotate4D (v2, -h2, 0.0f);
							break;

						case InputDevice.OculusTouch:
							
							Vector2 rThumb = OVRInput.Get(OVRInput.Axis2D.PrimaryThumbstick, RTouch);
							Vector2 lThumb = OVRInput.Get(OVRInput.Axis2D.PrimaryThumbstick, LTouch);
							targetObjects[target].transform.Rotate (new Vector3(rThumb.y, -rThumb.x, 0.0f));
							targetObjects[target].Rotate4D (lThumb.y, -lThumb.x, 0.0f);
							break;
					}
					break;


				// In the polar move mode, the moving of the target object along a ray is performed.
				case InputMode.PolarMove:
					
					if(v > 0 || (targetObjects[target].position - cameraTransform.position).sqrMagnitude > 0.01f){
          	targetObjects[target].position += 0.05f * v * Vector4.Normalize(targetObjects[target].position - cameraTransform.position);
					}
					break;
			}

		}
	}
}
