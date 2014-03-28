using UnityEngine;
using System.Collections;

[RequireComponent(typeof(MeshFilter)), 
 RequireComponent(typeof(MeshRenderer)),
 ExecuteInEditMode]
public class SkinnedMeshInstance : MonoBehaviour
{

    #region Configuration
    public SkinnedMeshTemplate SkinnedTemplate;
    public int InitialFrameOffset = -1;
    public AnimationClip ClipToPlay = null;
    #endregion

    #region Internal State
    uint startMeshFrameIndex = 0;
    uint clipToPlayIndex = 0;
    float timeSinceAnimStart = 0;

    MeshFilter meshFilter;
    #endregion

    // Use this for initialization
    void Start () {
        
        if (this.SkinnedTemplate == null ) {
            Debug.LogWarning(string.Format("There are no attached Skinned Mesh Templates attached to this Skinned Mesh Instancer: {0}", this.name));
            return;
        }

        //Each SkinnedMeshInstance can play it's own clip starting at its own time. If these are not set, we randomly assign them
        this.SkinnedTemplate.SkinnedMeshBakedData.InitializeAnimationState(this.ClipToPlay, this.InitialFrameOffset, ref this.clipToPlayIndex, ref this.startMeshFrameIndex);

        {
            //Initialize our Mesh filter for this node
            this.meshFilter = this.GetComponent<MeshFilter>();
            this.meshFilter.sharedMesh = this.SkinnedTemplate.SkinnedMeshBakedData.GetNextMeshFrame(0, this.clipToPlayIndex, this.startMeshFrameIndex);

            //Does not need to be cached
            var meshRenderer = this.GetComponent<MeshRenderer>();
            //meshRenderer.sharedMaterials = this.SkinnedTemplate.GetSharedMaterials();
            this.timeSinceAnimStart = 0;
        }


    }
    
    // Update is called once per frame
    void Update () {
        this.timeSinceAnimStart += Time.deltaTime;
        this.meshFilter.sharedMesh = this.SkinnedTemplate.SkinnedMeshBakedData.GetNextMeshFrame(this.timeSinceAnimStart, this.clipToPlayIndex, this.startMeshFrameIndex);
    }
}
