using System;
using UnityEditor;
using UnityEngine;

static class TakeScreenshot
{
	/// <summary>
	/// Saves a screenshot of the game view.
	/// </summary>
	[MenuItem ("Tools/Take Screenshot")]
	static void Screenshot ()
	{
		// Generate a filename-friendly timestamp.
		var timestamp = DateTime.Now.ToString(@"yyyy-MM-dd \a\t hh.mm.ss tt");

		// Prompt user with destination to save file.
		var defaultName = PlayerSettings.productName + " Screenshot " + timestamp + ".png";
		var path = EditorUtility.SaveFilePanel(
			"Save Screenshot",
			"",
			defaultName,
			"png");

		if (path.Length != 0) {
			Application.CaptureScreenshot(path);
			Debug.Log("Captured screenshot.");
		}
	}

	/// <summary>
	/// Enables "Take Screenshot" menu item when the game view is in focus.
	/// </summary>
	[MenuItem ("Tools/Take Screenshot", true)]
	static bool ValidateScreenshot ()
	{
		return EditorWindow.focusedWindow.ToString().Contains("GameView");
	}
}

