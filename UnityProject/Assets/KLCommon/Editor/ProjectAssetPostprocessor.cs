// Drop this script in the Editor directory in your project (creating the Editor directory if it's not there yet)
// Then re-import the assets in the directories covered by this script (right click and reimport)
//
// I would replace my path checking with the path checking from this gist:
//   https://gist.github.com/1842177
//
// The texture settings for icons might want to use some of his settings combined with mine as well


using UnityEngine;
using UnityEditor;
using System.Collections;


class ProjectAssetPostprocessor : AssetPostprocessor
{
    // audio asset preprocessor
    void OnPreprocessAudio()
    {
        // check if it's a music file
        if( assetPath.StartsWith( "Assets/Music" ) )
        {
            PreprocessMusic();
        }
    }
    
    // texture asset preprocessor
    void OnPreprocessTexture()
    {
        //TODO: ikrimae: Customize later for K&L Pipeline
        // check if it's a platform image (icons, splash, etc.)
        if( assetPath.StartsWith( "Assets/Platform" ) )
        {
            //PreprocessPlatformImages();
        }
            
        // check if it's a sprite source image
        if( assetPath.StartsWith( "Assets/Sprites/Sources" ) )
        {
            //PreprocessSpriteSource();
        }
        
        // check if it's a sprite texture atlas
        if( assetPath.StartsWith( "Assets/Sprites/Atlases" ) )
        {
            //PreprocessSpriteAtlas();
        }
    }

    
    // preprocess music (2D, stream from disc, hardware decoding)
    void PreprocessMusic()
    {
        AudioImporter importer = (AudioImporter)assetImporter;
        
        importer.threeD = false;
        importer.loadType = AudioImporterLoadType.StreamFromDisc;
        importer.hardware = true;
    }

        
    // preprocess platform icons, etc.
    void PreprocessPlatformImages()
    {
        TextureImporter importer = (TextureImporter)assetImporter;
        
        importer.textureType = TextureImporterType.Advanced;
        importer.maxTextureSize = 4096;
        importer.npotScale = TextureImporterNPOTScale.None;
        importer.mipmapEnabled = false;
        importer.isReadable = true;
        importer.textureFormat = TextureImporterFormat.ARGB32;
    }

    
    // preprocess sprite source images (uncompressed, no mips, non-pow2, etc.)
    void PreprocessSpriteSource()
    {
        TextureImporter importer = (TextureImporter)assetImporter;
        
        importer.textureType = TextureImporterType.Advanced;
        importer.maxTextureSize = 4096;
        importer.npotScale = TextureImporterNPOTScale.None;
        importer.mipmapEnabled = false;
        importer.isReadable = true;
        importer.textureFormat = TextureImporterFormat.ARGB32;
    }


    // preprocess sprite texture atlases (uncompressed, mips, POT, filter, etc.)
    void PreprocessSpriteAtlas()
    {
        TextureImporter importer = (TextureImporter)assetImporter;
        
        importer.textureType = TextureImporterType.Advanced;
        importer.maxTextureSize = 4096;
        importer.mipmapEnabled = true;
    //	importer.mipmapFilter = TextureImporterMipFilter.BoxFilter;//.KaiserFilter;
        importer.isReadable = false;
    //	importer.filterMode = FilterMode.Bilinear;
        importer.textureFormat = TextureImporterFormat.ARGB32;
        importer.anisoLevel = 0;
        importer.wrapMode = TextureWrapMode.Clamp;
        importer.mipMapBias = -0.5f;
    }
}
