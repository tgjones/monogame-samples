using System.Linq;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace ShadowsSample.Components
{
    public abstract class GuiComponent : DrawableGameComponent
    {
        private readonly int _yOffset;
        private readonly Color _backgroundColor;

        protected struct LabelData
        {
            public string Name;
            public string Value;
        }

        private Texture2D _whiteTexture;
        private SpriteBatch _spriteBatch;
        private SpriteFont _spriteFont;

        protected GuiComponent(Game game, int yOffset, Color backgroundColor)
            : base(game)
        {
            _yOffset = yOffset;
            _backgroundColor = backgroundColor;
        }

        protected override void LoadContent()
        {
            _spriteBatch = new SpriteBatch(GraphicsDevice);
            _spriteFont = Game.Content.Load<SpriteFont>("GameFont");

            _whiteTexture = new Texture2D(GraphicsDevice, 1, 1);
            _whiteTexture.SetData(new[] { Color.White });
        }

        protected void DrawLabels(LabelData[] labels)
        {
            _spriteBatch.Begin(blendState: BlendState.AlphaBlend);

            var itemHeight = (int) (_spriteFont.MeasureString(labels.First().Name).Y + 5);
            var height = itemHeight * labels.Count() + 5;

            _spriteBatch.Draw(_whiteTexture,
                new Rectangle(10, _yOffset, 400, height),
                _backgroundColor);

            const int nameWidth = 260;

            var y = _yOffset + 10;
            foreach (var label in labels)
            {
                _spriteBatch.DrawString(_spriteFont, label.Name, new Vector2(20, y), Color.White);
                _spriteBatch.DrawString(_spriteFont, label.Value, new Vector2(30 + nameWidth, y), Color.White);
                y += itemHeight;
            }

            _spriteBatch.End();
        }
    }
}