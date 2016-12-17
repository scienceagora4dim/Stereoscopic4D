using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Stereoscopic4D {

	/// <summary>
	/// 4D vertex attributes
	/// </summary>
	[Serializable]
	public struct Vertex4D {
		public Vector4 position;
		public Color color;
	}

	/// <summary>
	/// 4D facet.
	/// </summary>
	[Serializable]
	public struct Facet {
		public int i1;
		public int i2;
		public int i3;
	}

	/// <summary>
	/// Hyper object.
	/// </summary>
	[Serializable]
	public class HyperObject {
		/// <summary>
		/// object name
		/// </summary>
		public string name {
			get;
			set;
		}

		/// <summary>
		/// object vertice data.
		/// </summary>
		public Vertex4D[] vertices {
			get;
			set;
		}

		/// <summary>
		/// object facet data.
		/// </summary>
		public Facet[] facets {
			get;
			set;
		}
	}
}