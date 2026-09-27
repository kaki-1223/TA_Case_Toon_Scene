using UnityEngine;
using System.Collections;
using System.IO;

public class PortfolioCapture : MonoBehaviour
{
    [Header("2 = 1080p -> 4K")]
    public int superSize = 2;

    public string fileName = "Portfolio_Render.png";

    [ContextMenu("Capture Portfolio PNG")]
    public void Capture()
    {
        StartCoroutine(CaptureCoroutine());
    }

    IEnumerator CaptureCoroutine()
    {
        // 等这一帧的 Camera、URP、后处理全部画完
        yield return new WaitForEndOfFrame();

        string path = Path.Combine(
            Application.dataPath,
            "../" + fileName
        );

        ScreenCapture.CaptureScreenshot(path, superSize);

        Debug.Log(
            "作品图保存到：" + Path.GetFullPath(path)
        );
    }
}
