using Microsoft.Xna.Framework.Graphics;

namespace ShadowsSample.Util
{
    public static class RasterizerStateUtility
    {
        public static readonly RasterizerState CreateShadowMap = new RasterizerState
        {
            CullMode = CullMode.None,
            DepthClipEnable = false
        };
    }
}