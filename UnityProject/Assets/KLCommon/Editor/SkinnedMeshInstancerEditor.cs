using UnityEngine;
using System.Collections;
using UnityEditor;
using System.IO;
using System.Collections.Generic;

[CustomEditor(typeof(SkinnedMeshTemplate))]
class SkinnedMeshInstancerEditor : Editor
{
    public override void OnInspectorGUI()
    {
        var skinnedMeshInstancer = (this.target as SkinnedMeshTemplate);

        EditorGUILayout.BeginVertical();
        if (GUILayout.Button(new GUIContent("Bake", "Bake the skinned mesh instance data.")))
        {
            skinnedMeshInstancer.BakeAllClips();
            EditorUtility.SetDirty(skinnedMeshInstancer);
        }        
        EditorGUILayout.EndVertical();
    }
}