using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;

namespace ShadowsSample.Components
{
    public class GameSettingsComponent : DrawableGameComponent
    {
        private static readonly int[] KernelSizes = { 2, 3, 5, 7 };

        private IGuiService _guiService;
        private KeyboardState _lastKeyboardState;

        public bool AnimateLight;
        public Vector3 LightDirection;
        public Vector3 LightColor;
        public FixedFilterSize FixedFilterSize;
        public bool VisualizeCascades;
        public bool StabilizeCascades;
        public bool FilterAcrossCascades;
        public float SplitDistance0;
        public float SplitDistance1;
        public float SplitDistance2;
        public float SplitDistance3;
        public float Bias;
        public float OffsetScale;

        public int FixedFilterKernelSize
        {
            get { return KernelSizes[(int) FixedFilterSize]; }
        }

        public GameSettingsComponent(Game game)
            : base(game)
        {
            LightDirection = Vector3.Normalize(new Vector3(1, 1, -1));
            LightColor = new Vector3(3, 3, 3);
            Bias = 0.002f;
            OffsetScale = 0.0f;

            StabilizeCascades = false;
            VisualizeCascades = false;

            SplitDistance0 = 0.05f;
            SplitDistance1 = 0.15f;
            SplitDistance2 = 0.50f;
            SplitDistance3 = 1.0f;
        }

        public override void Initialize()
        {
            _guiService = Game.Services.GetService<IGuiService>();
            base.Initialize();
        }

        public override void Update(GameTime gameTime)
        {
            var keyboardState = Keyboard.GetState();

            if (keyboardState.IsKeyDown(Keys.L) && !_lastKeyboardState.IsKeyDown(Keys.L))
                AnimateLight = !AnimateLight;

            if (keyboardState.IsKeyDown(Keys.F) && !_lastKeyboardState.IsKeyDown(Keys.F))
            {
                FixedFilterSize++;
                if (FixedFilterSize > FixedFilterSize.Filter7x7)
                    FixedFilterSize = FixedFilterSize.Filter2x2;
            }

            if (keyboardState.IsKeyDown(Keys.C) && !_lastKeyboardState.IsKeyDown(Keys.C))
                StabilizeCascades = !StabilizeCascades;

            if (keyboardState.IsKeyDown(Keys.V) && !_lastKeyboardState.IsKeyDown(Keys.V))
                VisualizeCascades = !VisualizeCascades;

            if (keyboardState.IsKeyDown(Keys.K) && !_lastKeyboardState.IsKeyDown(Keys.K))
                FilterAcrossCascades = !FilterAcrossCascades;

            if (keyboardState.IsKeyDown(Keys.B) && !_lastKeyboardState.IsKeyDown(Keys.B))
            {
                if (keyboardState.IsKeyDown(Keys.LeftShift) || keyboardState.IsKeyDown(Keys.RightShift))
                {
                    Bias += 0.001f;
                }
                else
                {
                    Bias -= 0.001f;
                    Bias = Math.Max(Bias, 0.0f);
                }
                Bias = (float) Math.Round(Bias, 3);
            }

            if (keyboardState.IsKeyDown(Keys.O) && !_lastKeyboardState.IsKeyDown(Keys.O))
            {
                if (keyboardState.IsKeyDown(Keys.LeftShift) || keyboardState.IsKeyDown(Keys.RightShift))
                {
                    OffsetScale += 0.1f;
                }
                else
                {
                    OffsetScale -= 0.1f;
                    OffsetScale = Math.Max(OffsetScale, 0.0f);
                }
                OffsetScale = (float) Math.Round(OffsetScale, 1);
            }

            _lastKeyboardState = keyboardState;
        }

        public override void Draw(GameTime gameTime)
        {
            _guiService.DrawLabels(new[]
            {
                new GuiComponent.GuiLabelData { Name = "Animate light? (L)", Value = AnimateLight.ToString() }, 
                new GuiComponent.GuiLabelData { Name = "Filter size (F)", Value = FixedFilterSize.ToString() },
                new GuiComponent.GuiLabelData { Name = "Stabilize cascades? (C)", Value = StabilizeCascades.ToString() }, 
                new GuiComponent.GuiLabelData { Name = "Visualize cascades? (V)", Value = VisualizeCascades.ToString() },
                new GuiComponent.GuiLabelData { Name = "Filter across cascades? (K)", Value = FilterAcrossCascades.ToString() }, 
                new GuiComponent.GuiLabelData { Name = "Bias (b / B)", Value = Bias.ToString() },
                new GuiComponent.GuiLabelData { Name = "Normal offset (o / O)", Value = OffsetScale.ToString() }
            }, Color.FromNonPremultiplied(100, 0, 0, 150));
        }
    }

    public enum FixedFilterSize
    {
        Filter2x2,
        Filter3x3,
        Filter5x5,
        Filter7x7
    }
}