using UnityEngine;
using System.Collections;

public class KLManager : MonoBehaviour {

#if (DEBUG || UNITY_EDITOR)
    bool displayConsole = false;

    // Use this for initialization
    void Start () {
    
    }
    
    // Update is called once per frame
    void Update () {
        if (Input.GetKeyUp(KeyCode.BackQuote))
        {
            displayConsole = !displayConsole;
            DebugConsole.IsOpen = displayConsole;
        }
    }
#endif

}
