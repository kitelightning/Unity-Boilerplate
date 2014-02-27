using UnityEditor;
using UnityEditor.Macros;
using UnityEngine;

/// <summary>
/// Allows use of the undocumented MacroEvaluator class to run arbitrary code
/// in the editor. This can be very useful for ad-hoc operations on game
/// objects and for experimentation.
/// </summary>
public class Macros : EditorWindow
{
	static readonly GUIContent executeLabel = new GUIContent(
		"Execute", "Run this code.");
	string macro = "";

	/// <summary>
	/// Adds "Macros" to the Window menu.
	/// </summary>
	[MenuItem ("Window/Macros")]
	static void Init ()
	{
		CreateInstance<Macros>().ShowUtility();
	}

	void OnGUI ()
	{
		macro = EditorGUILayout.TextArea(macro, GUILayout.ExpandHeight(true));

		if (GUILayout.Button(executeLabel)) {
			MacroEvaluator.Eval(macro);
		}
	}
}

