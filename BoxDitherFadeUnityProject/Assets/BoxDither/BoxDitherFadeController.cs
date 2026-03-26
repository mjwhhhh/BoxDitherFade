using UnityEngine;

public class BoxDitherFadeController : MonoBehaviour
{
    public Transform volumeTransform;

    [Header("Box")]
    public Vector3 boxSize = new Vector3(1f, 2f, 1f);

    [Header("Fade")]
    [Tooltip("相对前表面的偏移")]
    public float fadeStartOffset = 0f;

    [Tooltip("渐隐带宽度")]
    public float fadeWidth = 0.3f;

    public float ditherStrength = 1f;

    [Header("Debug")]
    public Renderer targetRenderer;

    private static readonly int WorldToDoorID = Shader.PropertyToID("_WorldToDoor");
    private static readonly int BoxSizeID = Shader.PropertyToID("_BoxSize");
    private static readonly int FadeStartID = Shader.PropertyToID("_FadeStart");
    private static readonly int FadeWidthID = Shader.PropertyToID("_FadeWidth");
    private static readonly int DitherStrengthID = Shader.PropertyToID("_DitherStrength");
    private static readonly int MaskEnableID = Shader.PropertyToID("_MaskEnable");

    private void Reset()
    {
        volumeTransform = transform;
    }
    
    public void Start()
    {
        if (volumeTransform == null)
            volumeTransform = transform;

        // 👉 调试用：直接让某个 Renderer 生效
        if (targetRenderer != null)
            ApplyToRenderer(targetRenderer, true);
    }

    public void ApplyToRenderer(Renderer renderer, bool enable)
    {
        if (renderer == null) return;

        Matrix4x4 worldToLocal = volumeTransform.worldToLocalMatrix;

        float fadeStart = -boxSize.z * 0.5f + fadeStartOffset;

        foreach (var mat in renderer.materials)
        {
            if (mat == null) continue;

            mat.SetMatrix(WorldToDoorID, worldToLocal);
            mat.SetVector(BoxSizeID, boxSize);
            mat.SetFloat(FadeStartID, fadeStart);
            mat.SetFloat(FadeWidthID, fadeWidth);
            mat.SetFloat(DitherStrengthID, ditherStrength);
            mat.SetFloat(MaskEnableID, enable ? 1f : 0f);
        }
    }

    private void OnDrawGizmos()
    {
        if (volumeTransform == null)
            volumeTransform = transform;

        Matrix4x4 oldMatrix = Gizmos.matrix;

        Gizmos.matrix = Matrix4x4.TRS(
            volumeTransform.position,
            volumeTransform.rotation,
            volumeTransform.lossyScale
        );

        // Box 填充
        Gizmos.color = new Color(0f, 1f, 1f, 0.12f);
        Gizmos.DrawCube(Vector3.zero, boxSize);

        // Box 边框
        Gizmos.color = Color.cyan;
        Gizmos.DrawWireCube(Vector3.zero, boxSize);

        float frontZ = -boxSize.z * 0.5f;
        float fadeStart = frontZ + fadeStartOffset;
        float fadeEnd = fadeStart + fadeWidth;

        // 前表面（进入位置）
        Gizmos.color = Color.green;
        DrawRectZ(frontZ, boxSize);

        // 渐隐开始
        Gizmos.color = Color.yellow;
        DrawRectZ(fadeStart, boxSize);

        // 渐隐结束（完全消失）
        Gizmos.color = Color.red;
        DrawRectZ(fadeEnd, boxSize);

        // 方向（Z+）
        Gizmos.color = Color.blue;
        Gizmos.DrawLine(Vector3.zero, Vector3.forward * (boxSize.z * 0.5f + 0.3f));

        Gizmos.matrix = oldMatrix;
    }

    private void DrawRectZ(float z, Vector3 size)
    {
        float hx = size.x * 0.5f;
        float hy = size.y * 0.5f;

        Vector3 p1 = new Vector3(-hx, -hy, z);
        Vector3 p2 = new Vector3(hx, -hy, z);
        Vector3 p3 = new Vector3(hx, hy, z);
        Vector3 p4 = new Vector3(-hx, hy, z);

        Gizmos.DrawLine(p1, p2);
        Gizmos.DrawLine(p2, p3);
        Gizmos.DrawLine(p3, p4);
        Gizmos.DrawLine(p4, p1);
    }
}