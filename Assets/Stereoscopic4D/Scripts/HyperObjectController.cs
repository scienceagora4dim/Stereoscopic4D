using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Stereoscopic4D {

	/// <summary>
	/// 4D Hyper object controller.
	/// </summary>
	[RequireComponent(typeof(Transform4D)), RequireComponent(typeof(MeshFilter)), DisallowMultipleComponent]
	public class HyperObjectController : MonoBehaviour {

		/// <summary>
		/// The hyper object JSON data.
		/// </summary>
		public TextAsset hyperObjectJson;

		// loaded object.
		private HyperObject hyperObject_;

		// object mesh.
		private Mesh hyperObjectMesh_;

		// initializing at GameObject construction.
		void Awake() {
			// load a hyper object from JSON asset.
			hyperObject_ = JsonUtility.FromJson<HyperObject>(hyperObjectJson.text);
			hyperObjectMesh_ = hyperObject_.MakeMesh ();
		}

		// Use this for initialization
		void Start () {
			GetComponent<MeshFilter> ().mesh = hyperObjectMesh_;
		}
		
		// Update is called once per frame
		void Update () {
			
		}
	}
}