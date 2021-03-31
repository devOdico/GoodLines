using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Linq;

public class LineMeshData {
    private Vector3[] verticies;
    private Vector3[] prevs;
    private Vector3[] nexts;
    private Vector2[] data;

    private int[] triangles;

    private Mesh mesh;

    public LineMeshData(Mesh mesh) {
        this.mesh = mesh;
    }

    public Vector3 this[int i] {
        get {
            return verticies[i*2];
        }
        set {
            if (i == 0) {
                verticies[0] = value;
                verticies[1] = value;

                prevs[2] = value;
                prevs[3] = value;
            }
            else if (i * 2 == verticies.Length - 2) {
                int b = i*2;
                int b_prev = (i - 1)*2;

                verticies[b+0] = value;
                verticies[b+1] = value;

                nexts[b_prev+0] = value;
                nexts[b_prev+1] = value;
            }
            else {
                int b = i*2;
                int b_prev = (i - 1)*2;
                int b_next = (i + 1)*2;

                verticies[b+0] = value;
                verticies[b+1] = value;

                nexts[b_prev+0] = value;
                nexts[b_prev+1] = value;

                prevs[b_next+0] = value;
                prevs[b_next+1] = value;
            }
            UpdateMesh();
        }
    }

    public void SetLinesFromPoints(List<List<Vector3>> lines) {
        int totalCount = lines.Select(points => points.Count).Sum();

        //Vertices, prev, next, direction, triangles
        verticies = new Vector3[totalCount*2];
        prevs = new Vector3[totalCount*2];
        nexts = new Vector3[totalCount*2];
        data = new Vector2[totalCount*2];

        triangles = new int[(totalCount - 1)*9]; // This over allocates I think?

        int lineStart = 0;

        foreach (var points in lines) {
            int lineIndex = lineStart * 2;
            //Set first element
            verticies[lineIndex + 0] = points[0];
            verticies[lineIndex + 1] = points[0];
            prevs[lineIndex + 0] = points[0];
            prevs[lineIndex + 1] = points[0];
            nexts[lineIndex + 0] = points[1];
            nexts[lineIndex + 1] = points[1];
            data[lineIndex + 0] = new Vector2(1, 1);
            data[lineIndex + 1] = new Vector2(-1, 1);

            //Set last element
            int lp = points.Count - 1;
            int l = lineIndex + 2*lp;
            verticies[l+0] = points[lp];
            verticies[l+1] = points[lp];
            prevs[l+0] = points[lp-1];
            prevs[l+1] = points[lp-1];
            nexts[l+0] = points[lp];
            nexts[l+1] = points[lp];
            data[l+0] = new Vector2(1, 2);
            data[l+1] = new Vector2(-1, 2);

            //Set all but first and last
            for (int i = 1; i < points.Count - 1; ++i) {
                int b = lineIndex + i*2;

                verticies[b+0] = points[i];
                verticies[b+1] = points[i];
    
                prevs[b+0] = points[i-1];
                prevs[b+1] = points[i-1];

                nexts[b+0] = points[i+1];
                nexts[b+1] = points[i+1];

                data[b+0] = new Vector2(1, 0);
                data[b+1] = new Vector2(-1, 0);
            }

            for (int i = 0; i < points.Count - 1; ++i) {
                int b = (lineStart + i)*9;
                int t = lineIndex + i*2;

                triangles[b+0] = t+3;
                triangles[b+1] = t+1;
                triangles[b+2] = t+0;

                triangles[b+3] = t+2;
                triangles[b+4] = t+1;
                triangles[b+5] = t+0;

                triangles[b+6] = t+0;
                triangles[b+7] = t+2;
                triangles[b+8] = t+3;
            }

            lineStart += points.Count;

        }

       
        mesh.Clear();
        UpdateMesh();
    }

    private void UpdateMesh() {
        mesh.SetVertices(verticies);
        mesh.SetUVs(1, prevs);
        mesh.SetUVs(2, nexts);
        mesh.SetUVs(3, data);
        mesh.SetTriangles(triangles, 0);
        //mesh.RecalculateBounds();
    }
}

[RequireComponent(typeof(MeshFilter))]
[ExecuteAlways]
public class LineMesh : MonoBehaviour
{
    public List<List<Vector3>> Positions = new List<List<Vector3>>() {new List<Vector3>() {new Vector3(), new Vector3(1,0,0)}};

    private LineMeshData _meshData;
    public LineMeshData MeshData {
        get {
            if (_meshData == null) {
                var mf = GetComponent<MeshFilter>();
                mf.sharedMesh = new Mesh();
                _meshData = new LineMeshData(mf.sharedMesh);
            }
            return _meshData;
        }
    }
    // Start is called before the first frame update
    void Start()
    {
        if (Positions.Count < 1) {
            Positions.Add(new List<Vector3>());
        }
        while (Positions[0].Count < 2) {
            Positions[0].Add(new Vector3(0,0,0));
        }
        MeshData.SetLinesFromPoints(Positions);
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    void OnValidate() {
        if (_meshData != null) {
            if (Positions.Count < 1) {
                Positions.Add(new List<Vector3>());
            }
            while (Positions[0].Count < 2) {
                Positions[0].Add(new Vector3(0,0,0));
            }
            MeshData.SetLinesFromPoints(Positions);
        }
    }

    public void SetLinesFromPoints(List<List<Vector3>> lines) {
        this.Positions = lines;
        MeshData.SetLinesFromPoints(Positions);
    }

}