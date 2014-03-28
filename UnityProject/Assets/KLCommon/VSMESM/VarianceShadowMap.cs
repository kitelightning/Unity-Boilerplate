using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class VarianceShadowMap : MonoBehaviour {

    public enum ShadowMappingMethod
    {
        KL_SHADOWMODE_VSM,
        KL_SHADOWMODE_ESM,
        KL_SHADOWMODE_ESMLOG,
        KL_SHADOWMODE_EVSM,
        KL_SHADOWMODE_EVSMLOG
    }

    [SerializeField, HideInInspector]
    ShadowMappingMethod _shadowMethod;

    public Camera ShadowMappedLight;
    public int ShadowMapLength;

    public RenderTexture vsmShadowMap;

    [SerializeField, HideInInspector]
    private BlurType blurType = BlurType.SgxGauss;

    Shader vsmShader;
    Shader blurShader;
    Material blurMaterial;

    //Shadow map parameters
    //TODO: ikrimae: Figure out how to clamp the range to 0-40 for non-log blurred shadow mapping techniques that are depth rescaled to [-1,1]
    //               Clamp to [0,80] if depth is scaled to [0,1]
    public Vector2 _EVSMExponents = new Vector2(20, 10);

    [ExposeProperty]
    public ShadowMappingMethod shadowMethod
    {
        get { return _shadowMethod; }
        set
        {
            _shadowMethod = value;
            this.blurType = _shadowMethod == ShadowMappingMethod.KL_SHADOWMODE_ESMLOG || _shadowMethod == ShadowMappingMethod.KL_SHADOWMODE_EVSMLOG ? BlurType.SgxLogGauss : BlurType.SgxGauss;

            foreach (var keyword in System.Enum.GetValues(typeof(ShadowMappingMethod)))
                Shader.DisableKeyword(keyword.ToString());
            Shader.EnableKeyword(value.ToString());
        }
    }
    //Filtering parameters
    public int downsample = 1;
    public float blurSize = 3.0f;
    public int blurIterations = 2;

    public LayerMask StaticCasterMask = -1;
    public LayerMask DynamicCastersMask = -1;
    

    public enum BlurType
    {
        SgxGauss = 0,
        SgxLogGauss = 1
    }

    private static Material CreateMaterial(Shader shader)
    {
        if (!shader)
            return null;
        Material m = new Material(shader);
        m.hideFlags = HideFlags.HideAndDontSave;
        return m;
    }

    private static void DestroyMaterial(Material mat)
    {
        if (mat)
        {
            DestroyImmediate(mat);
            mat = null;
        }
    }

    void Setup()
    {
        #region Create Shadow Mapping render target and Shadow Mapping camera for scene lights
        if (!this.vsmShadowMap)
        {
            this.vsmShadowMap = new RenderTexture(this.ShadowMapLength, this.ShadowMapLength, 16, RenderTextureFormat.RGFloat, RenderTextureReadWrite.Linear);
            this.vsmShadowMap.filterMode = FilterMode.Bilinear;
            this.vsmShadowMap.antiAliasing = 2;
            this.vsmShadowMap.wrapMode = TextureWrapMode.Clamp;
            this.vsmShadowMap.generateMips = true;
            this.vsmShadowMap.useMipMap = true;
            this.vsmShadowMap.anisoLevel = 1;
        }

        this.ShadowMappedLight.camera.enabled = false;
        this.ShadowMappedLight.backgroundColor = new Color(1, 1, 1, 1);
        this.ShadowMappedLight.clearFlags = CameraClearFlags.Color;
        this.ShadowMappedLight.targetTexture = this.vsmShadowMap;
        this.ShadowMappedLight.depthTextureMode = DepthTextureMode.None;
        this.ShadowMappedLight.aspect = 1.0f;
        this.ShadowMappedLight.ResetAspect();
        #endregion

        #region Create Shaders for rendering shadow map and generating maps
        this.vsmShader = Shader.Find("KnL/VSMCaster");

        this.blurShader = Shader.Find("Hidden/ShadowMapGaussBlur");
        if (!this.blurMaterial)
        {
            this.blurMaterial = CreateMaterial(this.blurShader);
        }
        #endregion
    }
    void DestroyMaterials()
    {
        VarianceShadowMap.DestroyMaterial(this.blurMaterial);
    }

    void Start() {
        
        this.Setup();
    }

    void Awake()
    {
        this.Setup();
    }

    void OnEnable()
    {
        this.Setup();
    }

    void OnDisable()
    {
        this.DestroyMaterials();
    }

    void OnPreCull() {

        Shader.SetGlobalMatrix("_LightViewTransform", this.ShadowMappedLight.worldToCameraMatrix);
        Shader.SetGlobalMatrix("_LightProjTransform", GL.GetGPUProjectionMatrix(this.ShadowMappedLight.projectionMatrix, true));
        Shader.SetGlobalVector("_LightNearFarPlane", new Vector4(this.ShadowMappedLight.nearClipPlane, this.ShadowMappedLight.farClipPlane));
        Shader.SetGlobalVector("_EVSMExponents", new Vector4(this._EVSMExponents.x, this._EVSMExponents.y));
        Shader.SetGlobalTexture("_LightShadowMap", this.vsmShadowMap);
        this.ShadowMappedLight.cullingMask = this.DynamicCastersMask;
        this.ShadowMappedLight.RenderWithShader(this.vsmShader, null);


        #region Filter the shadow map
        if (blurIterations > 0)
        {
            var widthMod = 1.0f / (1.0f * (1 << downsample));

            blurMaterial.SetVector("_Parameter", new Vector4(blurSize * widthMod, -blurSize * widthMod, 0.0f, 0.0f));
            this.vsmShadowMap.filterMode = FilterMode.Bilinear;

            var rtW = this.vsmShadowMap.width >> downsample;
            var rtH = this.vsmShadowMap.height >> downsample;

            // downsample
            var rt = RenderTexture.GetTemporary(rtW, rtH, 0, this.vsmShadowMap.format);

            rt.filterMode = FilterMode.Bilinear;
            Graphics.Blit(this.vsmShadowMap, rt, blurMaterial, 0);

            var passOffs = blurType == BlurType.SgxGauss ? 0 : 2;

            for (int i = 0; i < blurIterations; i++)
            {
                var iterationOffs = (i * 1.0f);
                blurMaterial.SetVector("_Parameter", new Vector4(blurSize * widthMod + iterationOffs, -blurSize * widthMod - iterationOffs, 0.0f, 0.0f));

                // vertical blur
                var rt2 = RenderTexture.GetTemporary(rtW, rtH, 0, this.vsmShadowMap.format);
                rt2.filterMode = FilterMode.Bilinear;
                Graphics.Blit(rt, rt2, blurMaterial, 1 + passOffs);
                RenderTexture.ReleaseTemporary(rt);
                rt = rt2;

                // horizontal blur
                rt2 = RenderTexture.GetTemporary(rtW, rtH, 0, this.vsmShadowMap.format);
                rt2.filterMode = FilterMode.Bilinear;
                Graphics.Blit(rt, rt2, blurMaterial, 2 + passOffs);
                RenderTexture.ReleaseTemporary(rt);
                rt = rt2;
            }

            Graphics.Blit(rt, this.vsmShadowMap);   //TODO: ikrimae: Optionally figure out how to turn on mipmapping after the blur on the render texture

            RenderTexture.ReleaseTemporary(rt);

        }
        #endregion

    }
}
