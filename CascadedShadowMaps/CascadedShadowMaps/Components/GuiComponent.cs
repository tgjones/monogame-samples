using System.Collections.Generic;
using System.Linq;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace ShadowsSample.Components
{
    public interface IGuiService
    {
        void DrawLabels(GuiComponent.GuiLabelData[] labels, Color backgroundColor);
    }

    public class GuiComponent : DrawableGameComponent, IGuiService
    {
        public struct GuiLabelData
        {
            public string Name;
            public string Value;
        }

        private readonly List<GuiLabelData[]> _labels;
        private readonly List<Color> _backgroundColors;

        private Texture2D _whiteTexture;
        private SpriteBatch _spriteBatch;
        private SpriteFont _spriteFont;

        public GuiComponent(Game game)
            : base(game)
        {
            _labels = new List<GuiLabelData[]>();
            _backgroundColors = new List<Color>();
        }

        protected override void LoadContent()
        {
            _spriteBatch = new SpriteBatch(GraphicsDevice);
            _spriteFont = Game.Content.Load<SpriteFont>("GameFont");

            _whiteTexture = new Texture2D(GraphicsDevice, 1, 1);
            _whiteTexture.SetData(new[] { Color.White });
        }

        public override void Update(GameTime gameTime)
        {
            _labels.Clear();
            _backgroundColors.Clear();
            base.Update(gameTime);
        }

        public void DrawLabels(GuiLabelData[] labels, Color backgroundColor)
        {
            _labels.Add(labels);
            _backgroundColors.Add(backgroundColor);
        }

        public override void Draw(GameTime gameTime)
        {
            _spriteBatch.Begin(blendState: BlendState.AlphaBlend);

            var nameWidth = _labels.Max(x => x.Max(y => _spriteFont.MeasureString(y.Name).X)) + 10;

            var yOffset = 10;
            for (int i = 0; i < _labels.Count; i++)
            {
                var labelGroup = _labels[i];

                var itemHeight = (int) (_spriteFont.MeasureString(labelGroup[0].Name).Y + 5);
                var height = itemHeight * labelGroup.Count() + 5;

                _spriteBatch.Draw(_whiteTexture,
                    new Rectangle(10, yOffset, 400, height),
                    _backgroundColors[i]);

                var y = yOffset + 10;
                foreach (var label in labelGroup)
                {
                    _spriteBatch.DrawString(_spriteFont, label.Name, new Vector2(20, y), Color.White);
                    _spriteBatch.DrawString(_spriteFont, label.Value, new Vector2(30 + nameWidth, y), Color.White);
                    y += itemHeight;
                }

                yOffset += height;
            }

            _spriteBatch.End();

            base.Draw(gameTime);
        }
    }
}