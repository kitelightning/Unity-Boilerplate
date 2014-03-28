using UnityEditor;

public class AtlasSize_512 : EditorWindow
{
    [MenuItem("LightmapSize/AtlasSize_512")]
    static void Init()
    {
        LightmapEditorSettings.maxAtlasHeight = 512;
        LightmapEditorSettings.maxAtlasWidth = 512;
    }
}

public class AtlasSize_1K : EditorWindow
{
    [MenuItem("LightmapSize/AtlasSize_1K")]
    static void Init()
    {
        LightmapEditorSettings.maxAtlasHeight = 1024;
        LightmapEditorSettings.maxAtlasWidth = 1024;
    }
}

public class AtlasSize_2K : EditorWindow
{
    [MenuItem("LightmapSize/AtlasSize_2K")]
    static void Init()
    {
        LightmapEditorSettings.maxAtlasHeight = 2048;
        LightmapEditorSettings.maxAtlasWidth = 2048;
    }
}

public class AtlasSize_4K : EditorWindow
{
    [MenuItem("LightmapSize/AtlasSize_4K")]
    static void Init()
    {
        LightmapEditorSettings.maxAtlasHeight = 4096;
        LightmapEditorSettings.maxAtlasWidth = 4096;
    }
}
