using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace Stereoscopic4D {

	/// <summary>
	/// 4D vertex attributes
	/// </summary>
	[Serializable]
	public struct Vertex4D {
		public Vector4 position { get{ return new Vector4(p[0], p[1], p[2], p[3]); } }
		public Color color { get{ return new Color(c[0], c[1], c[2], c[3]); } }

		[SerializeField]
		private float[] p;

		[SerializeField]
		private float[] c;
	}

	/// <summary>
	/// 4D facet.
	/// </summary>
	[Serializable]
	public struct Facet {
		public int i1 { get { return i [0]; } }
		public int i2 { get { return i [1]; } }
		public int i3 { get { return i [2]; } }

		[SerializeField]
		private int[] i;
	}

	/// <summary>
	/// 4D line.
	/// </summary>
	[Serializable]
	public struct Line {
		public int i1 { get { return i [0]; } }
		public int i2 { get { return i [1]; } }

		[SerializeField]
		private int[] i;
	}

	/// <summary>
	/// Hyper object.
	/// </summary>
	[Serializable]
	public class HyperObject {
		/// <summary>
		/// object name
		/// </summary>
		public string name;

		/// <summary>
		/// object vertice data.
		/// </summary>
		public Vertex4D[] vertices;

		/// <summary>
		/// object facet data.
		/// </summary>
		public Facet[] facets;

		/// <summary>
		/// object line data.
		/// </summary>
		public Line[] lines;

		/// <summary>
		/// Makes the mesh from 4D object data.
		/// </summary>
		/// <returns>The mesh.</returns>
		public Mesh MakeMesh() {
			Mesh mesh = new Mesh ();
			Vector3[] varray = new Vector3[vertices.Length];
			Vector2[] uvarray = new Vector2[vertices.Length];
			Color[] carray = new Color[vertices.Length];

			for (int i = 0; i < vertices.Length; ++i) {
				Vector4 pos = vertices [i].position;
				Color color = vertices [i].color;
				varray [i] = new Vector3 (pos.x, pos.y, pos.z);
				uvarray [i] = new Vector2 (pos.w, 0.0f);
				carray [i] = color;
			}

			mesh.vertices = varray;
			mesh.uv = uvarray;
			mesh.colors = carray;

			if (facets.Length > 0) {
				int[] iarray = new int[facets.Length * 3];
				for (int i = 0; i < facets.Length; ++i) {
					iarray [i * 3 + 0] = facets [i].i1;
					iarray [i * 3 + 1] = facets [i].i2;
					iarray [i * 3 + 2] = facets [i].i3;
				}
				mesh.SetIndices (iarray, MeshTopology.Triangles, 0);
			} else {
				int[] iarray = new int[lines.Length * 2];
				for (int i = 0; i < lines.Length; ++i) {
					iarray [i * 2 + 0] = lines [i].i1;
					iarray [i * 2 + 1] = lines [i].i2;
				}
				mesh.SetIndices (iarray, MeshTopology.Lines, 0);
			}

			mesh.RecalculateNormals ();
			mesh.RecalculateBounds ();
			mesh.bounds = new Bounds(Vector3.zero, new Vector3(500.0f, 500.0f, 500.0f));
			return mesh;
		}
	}
}
