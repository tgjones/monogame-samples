using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace ShadowsSample.Components
{
    public class FramesPerSecondComponent : DrawableGameComponent
    {
        private SpriteBatch _spriteBatch;
        private SpriteFont _spriteFont;

        private double _accumulatedTime;
        private int _frames;
        private double _timeLeft;

        private string _fpsString;
        private string _frameTimeString;

        public FramesPerSecondComponent(Game game)
            : base(game)
        {
            _timeLeft = 1.0;
        }

        protected override void LoadContent()
        {
            _spriteBatch = new SpriteBatch(GraphicsDevice);
            _spriteFont = Game.Content.Load<SpriteFont>("GameFont");
        }

        public override void Update(GameTime gameTime)
        {
            _timeLeft -= gameTime.ElapsedGameTime.TotalSeconds;
            _accumulatedTime += gameTime.ElapsedGameTime.TotalSeconds;
            ++_frames;

            if (_timeLeft <= 0.0)
            {
                var fps = _frames / _accumulatedTime;
                _fpsString = string.Format("{0:F0} FPS", fps);
                _frameTimeString = string.Format("{0:F1} ms", gameTime.ElapsedGameTime.TotalMilliseconds);

                _timeLeft = 1.0;
                _accumulatedTime = 0.0;
                _frames = 0;
            }
        }

        public override void Draw(GameTime gameTime)
        {
            _spriteBatch.Begin();
            _spriteBatch.DrawString(_spriteFont, "Frames per second: " + _fpsString,
                new Vector2(10, 10),
                Color.Black);
            _spriteBatch.DrawString(_spriteFont, "Frame time: " + _frameTimeString,
                new Vector2(10, 30),
                Color.Black);
            _spriteBatch.End();
        }
    }
}