using UnityEngine;
using System.Collections;
using System.Collections.Generic;

[ExecuteInEditMode]
[RequireComponent(typeof(Animation))]
public class SkinnedMeshTemplate : MonoBehaviour {
    
    [System.Serializable]
    public class SkinnedTemplateBakedData
    {
        //Boxing of an array is necessary because of Unity's serialization shortcomings (can't do nested lists or multidimensional arrays)
        [System.Serializable]
        public class MeshSequence
        {
            public MeshSequence(uint capacity)
            {
                this.MeshFrames = new Mesh[capacity];
            }

            public Mesh this[uint i]
            {
                get
                {
                    return this.MeshFrames[i];
                }
                set
                {
                    this.MeshFrames[i] = value;
                }
            }

            public Mesh[] MeshFrames;
        }

        public MeshSequence[] BakedClips;
        public AnimationClip[] AnimationClipsToBake;
        public string name;

        public SkinnedTemplateBakedData(string meshName, int clipCount, SkinnedMeshRenderer skinMeshRenderer, Animation animation)
        {
            this.name = meshName;
            this.BakedClips = new MeshSequence[clipCount];
            this.AnimationClipsToBake = new AnimationClip[clipCount];

            this.BakeSkinnedMesh(animation, skinMeshRenderer);
        }

        private void BakeSkinnedMesh(Animation animation, SkinnedMeshRenderer skinnedMeshRenderer)
        {
            int clipIndex = 0;

            foreach (AnimationState clipState in animation)
            {
                //Prep animation clip for sampling
                var curClip = this.AnimationClipsToBake[clipIndex] = animation.GetClip(clipState.name);
                animation.Play(clipState.name, PlayMode.StopAll);
                clipState.time = 0;
                clipState.wrapMode = WrapMode.Clamp;

                //Calculate number of meshes to bake in this clip sequence based on the clip's sampling framerate
                uint numberOfFrames = (uint)Mathf.RoundToInt(curClip.frameRate * curClip.length);
                var curBakedMeshSequence = this.BakedClips[clipIndex] = new MeshSequence(numberOfFrames);

                for (uint frameIndex = 0; frameIndex < numberOfFrames; frameIndex++)
                {
                    //Bake sequence of meshes 
                    var curMeshFrame = curBakedMeshSequence[frameIndex] = new Mesh();
                    curMeshFrame.name = string.Format(@"{0}_Baked_{1}_{2}", this.name, clipIndex, frameIndex);
                    animation.Sample();
                    skinnedMeshRenderer.BakeMesh(curMeshFrame);

                    clipState.time += (1.0f / curClip.frameRate);
                }

                animation.Stop();
                clipIndex++;
            }
        }

        public Mesh GetNextMeshFrame(float timeSinceAnimStart, uint clipToPlayIndex, uint startMeshFrameIndex)
        {
            int deltaFrame = Mathf.RoundToInt(timeSinceAnimStart * this.AnimationClipsToBake[clipToPlayIndex].frameRate);
            uint currentMeshFrameIndex = (uint)((startMeshFrameIndex + deltaFrame) % this.BakedClips[clipToPlayIndex].MeshFrames.Length);
            return this.BakedClips[clipToPlayIndex][currentMeshFrameIndex];
        }

        public void InitializeAnimationState(AnimationClip clipToPlay, int initialFrameOffset, ref uint clipToPlayIndex, ref uint currentMeshFrameIndex)
        {
            //Set the clipToPlayIndex to random in-case clipToPlay is not-null but it can't be found
            int numClips = this.AnimationClipsToBake.Length;
            var randomClipIndex = (uint)Random.Range(0, numClips);

            if (clipToPlay != null) {
                //We need to find the index into the Skinned Mesh Template that corresponds to this clip
                clipToPlayIndex = (uint)this.AnimationClipsToBake.Length;
                for (uint i = 0; i < this.AnimationClipsToBake.Length; i++) {
                    if (this.AnimationClipsToBake[i] == clipToPlay) {
                        clipToPlayIndex = i;
                        break;
                    }
                }

                if (clipToPlayIndex == this.AnimationClipsToBake.Length) {
                    Debug.LogWarning(string.Format("Could not find Clip: {0} in the Skinned Mesh Template: {1}", clipToPlay.name, this.name));
                    clipToPlayIndex = randomClipIndex;
                }
            }
            else {
                clipToPlayIndex = randomClipIndex;
            }

            if (initialFrameOffset == -1) {
                int clipFrameLength = this.BakedClips[clipToPlayIndex].MeshFrames.Length;
                initialFrameOffset = Random.Range(0, clipFrameLength - 1);
                currentMeshFrameIndex = (uint)initialFrameOffset;
            }
        }
    }

    public SkinnedTemplateBakedData SkinnedMeshBakedData;

    [SerializeField]
    SkinnedMeshRenderer skinnedMeshRenderer;

    void Start()
    {
        this.gameObject.SetActive(true);
    }

    public Material[] GetSharedMaterials()
    {
        return this.skinnedMeshRenderer.sharedMaterials;
    }

    public void BakeAllClips()
    {
        if (this.animation == null || this.animation.GetClipCount() == 0)
        {
            Debug.LogWarning("SkinnedMeshInstancer has no animation clips to instance.");
            return;
        }

        this.skinnedMeshRenderer = this.GetComponentInChildren<SkinnedMeshRenderer>();
        if (this.skinnedMeshRenderer == null)
        {
            Debug.LogError("This GameObject is not a Skinned Mesh.");
            return;
        }


        //Initialize array of baked animation sequences
        this.SkinnedMeshBakedData = new SkinnedTemplateBakedData(this.name, this.animation.GetClipCount(), this.skinnedMeshRenderer, this.animation);
        //int clipIndex = 0;


        //foreach (AnimationState clipState in this.animation)
        //{
        //    //Prep animation clip for sampling
        //    var curClip = this.AnimationClipsToBake[clipIndex] = this.animation.GetClip(clipState.name);
        //    this.animation.Play(clipState.name, PlayMode.StopAll);
        //    clipState.time = 0;
        //    clipState.wrapMode = WrapMode.Clamp;

        //    //Calculate number of meshes to bake in this clip sequence based on the clip's sampling framerate
        //    uint numberOfFrames = (uint)Mathf.RoundToInt(curClip.frameRate * curClip.length);
        //    this.BakedMeshAnimations.Add(new Mesh[numberOfFrames]);
        //    var curBakedMeshSequence = this.BakedMeshAnimations[clipIndex];

        //    for (uint frameIndex = 0; frameIndex < numberOfFrames; frameIndex++)
        //    {
        //        //Bake sequence of meshes 
        //        var curMeshFrame = curBakedMeshSequence[frameIndex] = new Mesh();
        //        curMeshFrame.name = string.Format(@"{0}_Baked_{1}_{2}", this.skinnedMeshRenderer.name, clipIndex, frameIndex);
        //        this.animation.Sample();
        //        this.skinnedMeshRenderer.BakeMesh(curMeshFrame);

        //        clipState.time += (1.0f / curClip.frameRate);
        //    }

        //    this.animation.Stop();
        //    clipIndex++;
        //}
    }
}
