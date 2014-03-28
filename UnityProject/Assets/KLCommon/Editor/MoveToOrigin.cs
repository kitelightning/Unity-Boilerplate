using UnityEditor;
using UnityEngine;

static class MoveToOrigin
{
	/// <summary>
	/// Moves selected game object(s) to (0, 0, 0).
	/// Keyboard shortcut: shift-cmd-0 (Mac), shift-ctrl-0 (Windows).
	/// <summary>
	[MenuItem ("GameObject/Move To Origin #%0")]
	static void MenuMoveToOrigin ()
	{
		foreach (var t in Selection.transforms) {
			Undo.RegisterUndo(t, "Move " + t.name);
			t.position = Vector3.zero;
			Debug.Log("Moving " + t.name + " to origin.");
		}
	}

	/// <summary>
	/// Enables "Move To Origin" menu item when a transform is selected.
	/// </summary>
	[MenuItem ("GameObject/Move To Origin #%0", true)]
	static bool ValidateMoveToOrigin ()
	{
		return Selection.activeTransform != null;
	}
}

