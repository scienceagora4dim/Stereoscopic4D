using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Stereoscopic4D {

	/// <summary>
	/// 4D Hyper object controller.
	/// </summary>
	[RequireComponent(typeof(Transform4D)),
		RequireComponent(typeof(MeshFilter)),
		RequireComponent(typeof(MeshRenderer)),
		DisallowMultipleComponent]
	public class HyperObjectController : MonoBehaviour {

		// The hyper-object JSON data:
		// Read the object name, vertices, facets, etc.
		// from a JSON format file.
		public TextAsset hyperObjectJson;

		// The hyper-object material:
		//
		public Material hyperObjectMaterial;

		// loaded object.
		private HyperObject hyperObject_;

		// object mesh.
		private Mesh hyperObjectMesh_;

		// object transform 4D
		private Transform4D transform4D_;

		// shader attributes
		private int positionId_;
		private int scaleId_;
		private int rotationId_;
		private int rotationXZ_;
		private int rotationYZ_;
		private int rotationXY_;
		private int cameraPositionId_;
		private int cameraRotationId_;
		private int cameraRotationXZ_;
		private int cameraRotationYZ_;
		private int cameraRotationXY_;
		private int cameraStereoSeparation_;
		private int cameraStereoConvergence_;
		private int cameraSquint_;
		private int enable4DStereo_;

		// initializing at GameObject construction.
		void Awake() {
			// load a hyper object from JSON asset.
			hyperObject_ = JsonUtility.FromJson<HyperObject>(hyperObjectJson.text);
			hyperObjectMesh_ = hyperObject_.MakeMesh ();
			transform4D_ = GetComponent<Transform4D> ();

			// set up shader attributes.
			GetComponent<MeshRenderer>().material = hyperObjectMaterial;
			positionId_ = Shader.PropertyToID("_Position");
			scaleId_ = Shader.PropertyToID("_Scale");
			rotationId_ = Shader.PropertyToID("_Rotation");
			rotationXZ_ = Shader.PropertyToID("_RotationXZ");
			rotationYZ_ = Shader.PropertyToID("_RotationYZ");
			rotationXY_ = Shader.PropertyToID("_RotationXY");
			cameraPositionId_ = Shader.PropertyToID("_CameraPosition");
			cameraRotationId_ = Shader.PropertyToID("_CameraRotation");
			cameraRotationXZ_ = Shader.PropertyToID("_CameraRotationXZ");
			cameraRotationYZ_ = Shader.PropertyToID("_CameraRotationYZ");
			cameraRotationXY_ = Shader.PropertyToID("_CameraRotationXY");
			cameraStereoSeparation_ = Shader.PropertyToID("_CameraStereoSeparation");
			cameraStereoConvergence_ = Shader.PropertyToID("_CameraStereoConvergence");
			cameraSquint_ = Shader.PropertyToID("_CameraSquint");
			enable4DStereo_ = Shader.PropertyToID("_Enable4DStereo");
		}

		// Use this for initialization
		void Start () {
			GetComponent<MeshFilter> ().mesh = hyperObjectMesh_;
		}
		
		// before render setting up.
		void OnWillRenderObject() {
			// setting up object transform.
			hyperObjectMaterial.SetVector (positionId_, transform4D_.position);
			hyperObjectMaterial.SetVector (scaleId_, transform4D_.scale);
			hyperObjectMaterial.SetVector (rotationId_, transform4D_.eulerAngles3D);
			hyperObjectMaterial.SetFloat (rotationXZ_, transform4D_.xz);
			hyperObjectMaterial.SetFloat (rotationYZ_, transform4D_.yz);
			hyperObjectMaterial.SetFloat (rotationXY_, transform4D_.xy);

			// setting up transform by camera view.
			Camera cam = Camera.current;
			Transform4D camTransform4D = cam.gameObject.GetComponent<Transform4D> ();
			if (camTransform4D != null) {
				hyperObjectMaterial.SetVector (cameraPositionId_, camTransform4D.position);
				hyperObjectMaterial.SetVector (cameraRotationId_, camTransform4D.eulerAngles3D);
				hyperObjectMaterial.SetFloat (cameraRotationXZ_, camTransform4D.xz);
				hyperObjectMaterial.SetFloat (cameraRotationYZ_, camTransform4D.yz);
				hyperObjectMaterial.SetFloat (cameraRotationXY_, camTransform4D.xy);
			} else {
				hyperObjectMaterial.SetVector (cameraPositionId_, cam.transform.position);
				hyperObjectMaterial.SetVector (cameraRotationId_, cam.transform.localRotation.eulerAngles);
				hyperObjectMaterial.SetFloat (cameraRotationXZ_, 0.0f);
				hyperObjectMaterial.SetFloat (cameraRotationYZ_, 0.0f);
				hyperObjectMaterial.SetFloat (cameraRotationXY_, 0.0f);
			}

			// Stereoscopic attributes.
			bool left = (StereoTargetEyeMask.Left == cam.stereoTargetEye);
			float stereoSeparation = left ? -cam.stereoSeparation : cam.stereoSeparation;
			float stereoConvergence = cam.stereoConvergence;
			hyperObjectMaterial.SetFloat (cameraStereoSeparation_, stereoSeparation);
			hyperObjectMaterial.SetFloat (cameraStereoConvergence_, stereoConvergence);

			Camera4D cam4d = cam.gameObject.GetComponentInParent<Camera4D> ();
			float squint = 0.0f;
			bool enable4DStereo = false;
			if (cam4d != null) {
				squint = cam4d.squintFactor;
				enable4DStereo = cam4d.enable4DStereoscopic;
			}
			hyperObjectMaterial.SetFloat (cameraSquint_, squint);
			hyperObjectMaterial.SetInt (enable4DStereo_, enable4DStereo ? 1 : 0);
		}
	}
}
