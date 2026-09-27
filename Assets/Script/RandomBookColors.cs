using UnityEngine;
using System;

[ExecuteAlways]
public class RandomBookColors : MonoBehaviour
{
    [Serializable]
    public struct BookPalette
    {
        public Color baseColor;
        public Color midColor;
        public Color shadowColor;
    }

    [Header("Book Color Palettes")]
    public BookPalette[] palettes;

    [Header("Random Settings")]
    [SerializeField] private int seed = 12345;

    [Tooltip("尽量避免连续两本出现完全相同的颜色")]
    public bool avoidSameColorNextToEachOther = true;

    [Tooltip("如果合并 Mesh 有多个 Material Slot，是否让每个 Slot 独立随机")]
    public bool randomizeMaterialSlots = true;

    private static readonly int BaseColorID =
        Shader.PropertyToID("_BaseColor");

    private static readonly int MidColorID =
        Shader.PropertyToID("_MidColor");

    private static readonly int ShadowColorID =
        Shader.PropertyToID("_ShadowColor");


    private void OnEnable()
    {
        ApplyColors();
    }


    [ContextMenu("Randomize Books")]
    public void RandomizeBooks()
    {
        seed = UnityEngine.Random.Range(0, int.MaxValue);

        ApplyColors();
    }


    [ContextMenu("Apply Current Seed")]
    public void ApplyColors()
    {
        if (palettes == null || palettes.Length == 0)
            return;

        Renderer[] renderers =
            GetComponentsInChildren<Renderer>(true);

        System.Random random =
            new System.Random(seed);

        int lastPalette = -1;

        foreach (Renderer renderer in renderers)
        {
            int materialCount = renderer.sharedMaterials.Length;

            // 独立书 / 只有一个 Material Slot
            if (!randomizeMaterialSlots || materialCount <= 1)
            {
                int paletteIndex =
                    GetPaletteIndex(random, lastPalette);

                lastPalette = paletteIndex;

                ApplyPalette(
                    renderer,
                    palettes[paletteIndex]
                );
            }

            // 合并 Mesh，但拥有多个 Material Slot
            else
            {
                for (int materialIndex = 0;
                     materialIndex < materialCount;
                     materialIndex++)
                {
                    int paletteIndex =
                        GetPaletteIndex(random, lastPalette);

                    lastPalette = paletteIndex;

                    ApplyPalette(
                        renderer,
                        materialIndex,
                        palettes[paletteIndex]
                    );
                }
            }
        }
    }


    private int GetPaletteIndex(
        System.Random random,
        int lastPalette)
    {
        if (palettes.Length == 1)
            return 0;

        int index = random.Next(palettes.Length);

        if (avoidSameColorNextToEachOther &&
            index == lastPalette)
        {
            index =
                (lastPalette +
                 1 +
                 random.Next(palettes.Length - 1))
                % palettes.Length;
        }

        return index;
    }


    private void ApplyPalette(
        Renderer renderer,
        BookPalette palette)
    {
        MaterialPropertyBlock block =
            new MaterialPropertyBlock();

        renderer.GetPropertyBlock(block);

        block.SetColor(BaseColorID, palette.baseColor);
        block.SetColor(MidColorID, palette.midColor);
        block.SetColor(ShadowColorID, palette.shadowColor);

        renderer.SetPropertyBlock(block);
    }


    private void ApplyPalette(
        Renderer renderer,
        int materialIndex,
        BookPalette palette)
    {
        MaterialPropertyBlock block =
            new MaterialPropertyBlock();

        renderer.GetPropertyBlock(
            block,
            materialIndex
        );

        block.SetColor(BaseColorID, palette.baseColor);
        block.SetColor(MidColorID, palette.midColor);
        block.SetColor(ShadowColorID, palette.shadowColor);

        renderer.SetPropertyBlock(
            block,
            materialIndex
        );
    }
}
