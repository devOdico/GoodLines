using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(MeshFilter))]
public class LineMesh : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
       
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void SetLineFromPoints(IList<Vector3> points) {
        MeshFilter mf = GetComponent<MeshFilter>();

        mf.mesh = new Mesh();
        // TODO assert points.Count > 1

        //Vertices, prev, next, direction, triangles
        Vector3[] verticies = new Vector3[points.Count*2];
        Vector3[] prevs = new Vector3[points.Count*2];
        Vector3[] nexts = new Vector3[points.Count*2];
        Vector2[] direction = new Vector2[points.Count*2];

        int[] triangles = new int[(points.Count - 1)*6];

        //Set first element
        verticies[0] = points[0];
        verticies[1] = points[0];
        prevs[0] = points[0];
        prevs[1] = points[0];
        nexts[0] = points[1];
        nexts[1] = points[1];
        direction[0] = new Vector2(1, 1);
        direction[1] = new Vector2(-1, 1);

        //Set last element
        int lp = points.Count - 1;
        int l = 2*lp;
        verticies[l+0] = points[lp];
        verticies[l+1] = points[lp];
        prevs[l+0] = points[lp-1];
        prevs[l+1] = points[lp-1];
        nexts[l+0] = points[lp];
        nexts[l+1] = points[lp];
        direction[l+0] = new Vector2(1, 2);
        direction[l+1] = new Vector2(-1, 2);

        //Set all but first and last
        for (int i = 1; i < points.Count - 1; ++i) {
            int b = i*2;

            verticies[b+0] = points[i];
            verticies[b+1] = points[i];
  
            prevs[b+0] = points[i-1];
            prevs[b+1] = points[i-1];

            nexts[b+0] = points[i+1];
            nexts[b+1] = points[i+1];

            direction[b+0] = new Vector2(1, 0);
            direction[b+1] = new Vector2(-1, 0);
        }

        for (int i = 0; i < points.Count - 1; ++i) {
            int b = i*6;
            int t = i*2;

            triangles[b+0] = t+3;
            triangles[b+1] = t+1;
            triangles[b+2] = t+0;

            triangles[b+3] = t+0;
            triangles[b+4] = t+2;
            triangles[b+5] = t+3;
        }

        mf.mesh.SetVertices(verticies);
        mf.mesh.SetUVs(1, prevs);
        mf.mesh.SetUVs(2, nexts);
        mf.mesh.SetUVs(3, direction);
        mf.mesh.SetTriangles(triangles, 0);
    }
}

/// <summary>
/// Edit a line shaped mesh in place as a list of points, while maintaining the line shape.
/// </summary>
public class LinePoints : IList<Vector3>
{
    private Mesh mesh;

    public LinePoints(Mesh mesh) {
        // TODO: Assert that mesh is line shaped.
        this.mesh = mesh;
    }

    public void SetPoints(IList<Vector3> points) {
    }

    public Vector3 this[int index] {
        get {
            // TODO: Does this create a copy of the entire array?
            return mesh.vertices[index*2];
        }
        set { 
            mesh.vertices[index*2] = value;
            mesh.vertices[index*2+1] = value;
        }
    }

    public int Count => mesh.vertexCount/2;

    public bool IsReadOnly => throw new System.NotImplementedException();

    public void Add(Vector3 item)
    {
        throw new System.NotImplementedException();
    }

    public void Clear()
    {
        mesh.Clear();
    }

    public bool Contains(Vector3 item)
    {
        throw new System.NotImplementedException();
    }

    public void CopyTo(Vector3[] array, int arrayIndex)
    {
        throw new System.NotImplementedException();
    }

    public IEnumerator<Vector3> GetEnumerator()
    {
        throw new System.NotImplementedException();
    }

    public int IndexOf(Vector3 item)
    {
        throw new System.NotImplementedException();
    }

    public void Insert(int index, Vector3 item)
    {
        throw new System.NotImplementedException();
    }

    public bool Remove(Vector3 item)
    {
        throw new System.NotImplementedException();
    }

    public void RemoveAt(int index)
    {
        throw new System.NotImplementedException();
    }

    IEnumerator IEnumerable.GetEnumerator()
    {
        throw new System.NotImplementedException();
    }
}