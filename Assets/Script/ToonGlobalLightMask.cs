using UnityEngine;

[ExecuteAlways]
public class ToonGlobalLightMask : MonoBehaviour
{
    [Header("Global Painted Window Light")]
    public Texture2D paintedLightMask;

    [Range(0f, 1f)]
    public float paintedLightStrength = 0.35f;


    static readonly int MaskID =
        Shader.PropertyToID("_PaintedLightMask");

    static readonly int StrengthID =
        Shader.PropertyToID("_PaintedLightStrength");


    void OnEnable()
    {
        Apply();
    }


#if UNITY_EDITOR
    void OnValidate()
    {
        Apply();
    }
#endif


    [ContextMenu("Apply Global Toon Mask")]
    public void Apply()
    {
        // 没有 Mask 时使用黑色，而不是白色。
        // 黑色 = 不添加任何 Painted Light。
        Texture mask =
            paintedLightMask != null
            ? paintedLightMask
            : Texture2D.blackTexture;

        Shader.SetGlobalTexture(MaskID, mask);
        Shader.SetGlobalFloat(
            StrengthID,
            paintedLightStrength
        );

        Debug.Log(
    $"Apply Painted Light | Mask = {mask.name} | Strength = {paintedLightStrength}"
);

    }


    void OnDisable()
    {
        // 禁用组件后恢复“不加窗光”
        Shader.SetGlobalTexture(
            MaskID,
            Texture2D.blackTexture
        );

        Shader.SetGlobalFloat(
            StrengthID,
            0f
        );
    }
}
