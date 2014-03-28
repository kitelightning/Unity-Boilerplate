using UnityEngine;
using System.Collections;
using System;

[ExecuteInEditMode]
public class KLElectricWipe : MonoBehaviour {

    public Transform StartWipePosition;
    public Transform EndWipePosition;
    public float Wipe1Duration = 2;
    public float Wipe2Delay = 1;
    public float Wipe2Duration = 2;
    public float RingWidth = 0.25f;

    public MeshFilter[] ComponentsToDissolve;
    public MeshFilter[] ComponentsToWipeOn;
    public Shader DissolveShader;

    void Start()
    {
        Shader.SetGlobalFloat("_EnableDissolve", 0);
    }

    void Update()
    {
    }

    public void ActivateClearView()
    {
        //Wipe Dissolve for train
        // 1. Swap Shaders for wipe dissolve
        // 2. Register routine to disable train base objects after wipe duration
        // 3. Register routine after T seconds to begin wipe of new base object

        //*******************************************************************************************************************
        // 1. Swap Shaders for wipe dissolve & begin Wipe
        //*******************************************************************************************************************
        foreach (MeshFilter dissolvingComponent in ComponentsToDissolve)
        {
            dissolvingComponent.renderer.material.shader = DissolveShader;
        }

        //Have to change shader parameters at end of frame to prevent glitch
        StartCoroutine(BeginDissolve());

        //*******************************************************************************************************************
        // 2. Register routine to disable train base objects after wipe duration
        //*******************************************************************************************************************
        StartCoroutine(DisableDissolvedComponents());

        //*******************************************************************************************************************
        // 3. Register routine after T seconds to begin wipe of new base object
        //*******************************************************************************************************************
        StartCoroutine(WipeOnComponents());
    }
    
    #region TrainTiming
    IEnumerator BeginDissolve()
    {
        yield return new WaitForEndOfFrame();

        foreach (MeshFilter dissolvingComponent in ComponentsToDissolve)
        {
            dissolvingComponent.renderer.material.shader = DissolveShader;

            dissolvingComponent.renderer.material.SetFloat("_EnableDissolve", 1);

            //Set minimum/maximum extents in object space
            var startWipeOPos = this.transform.InverseTransformPoint(this.StartWipePosition.position);
            var endWipeOPos = this.transform.InverseTransformPoint(this.EndWipePosition.position);
            dissolvingComponent.renderer.material.SetVector("_StartWipeOPos", startWipeOPos);
            dissolvingComponent.renderer.material.SetVector("_EndWipeOPos", endWipeOPos);

            //set _StartingTime to current time
            dissolvingComponent.renderer.material.SetFloat("_StartingTime", Time.time);
            dissolvingComponent.renderer.material.SetFloat("_WipeDuration", this.Wipe1Duration);

            dissolvingComponent.renderer.material.SetFloat("_RingWidth", RingWidth / (endWipeOPos - startWipeOPos).magnitude);
            dissolvingComponent.renderer.material.DisableKeyword("WIPE_ON");
        }
    }
    IEnumerator DisableDissolvedComponents()
    {
        yield return new WaitForSeconds(2 * this.Wipe1Duration);
        foreach (MeshFilter dissolvedComponent in this.ComponentsToDissolve)
        {
            dissolvedComponent.renderer.enabled = false;
        }
    }

    private IEnumerator WipeOnComponents()
    {
        yield return new WaitForSeconds(this.Wipe2Delay);

        yield return new WaitForEndOfFrame();
        foreach (MeshFilter wipeOnComponent in this.ComponentsToWipeOn)
        {
            wipeOnComponent.renderer.material.shader = DissolveShader;
            wipeOnComponent.renderer.enabled = true;
        }

        foreach (MeshFilter wipeOnComponent in this.ComponentsToWipeOn)
        {
            wipeOnComponent.renderer.material.SetFloat("_EnableDissolve", 1);

            //Set minimum/maximum extents in object space
            var startWipeOPos = this.transform.InverseTransformPoint(this.StartWipePosition.position);
            var endWipeOPos = this.transform.InverseTransformPoint(this.EndWipePosition.position);

            //NOTE: Reversing the start & begin positions on purpose
            wipeOnComponent.renderer.material.SetVector("_StartWipeOPos", endWipeOPos);
            wipeOnComponent.renderer.material.SetVector("_EndWipeOPos", startWipeOPos);

            //set _StartingTime to current time
            wipeOnComponent.renderer.material.SetFloat("_StartingTime", Time.time);
            wipeOnComponent.renderer.material.SetFloat("_WipeDuration", this.Wipe2Duration);

            wipeOnComponent.renderer.material.SetFloat("_RingWidth", RingWidth / (endWipeOPos - startWipeOPos).magnitude);

            wipeOnComponent.renderer.material.EnableKeyword("WIPE_ON"); 
        }

        yield return new WaitForSeconds(this.Wipe2Duration);

        //Swap original shaders
        foreach (MeshFilter wipeOnComponent in this.ComponentsToWipeOn)
        {
            wipeOnComponent.renderer.material = wipeOnComponent.renderer.sharedMaterial;
        }
    }
    #endregion



}