using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;

namespace ShadowsSample
{
    public class ShadowsGame : Game
    {
        GraphicsDeviceManager graphics;
        SpriteBatch spriteBatch;

        private FirstPersonCamera _camera;
        private Model _model;
        private Matrix[] _modelTransforms;

        public ShadowsGame()
            : base()
        {
            graphics = new GraphicsDeviceManager(this);
            graphics.PreferredBackBufferWidth = 1280;
            graphics.PreferredBackBufferHeight = 800;

            Content.RootDirectory = "Content";
        }

        protected override void Initialize()
        {
            _camera = new FirstPersonCamera(MathHelper.PiOver4 * 0.75f,
                Window.ClientBounds.Width / (float) Window.ClientBounds.Height,
                0.25f, 250.0f);

            _camera.Position = new Vector3(40.0f, 5.0f, 5.0f);
            _camera.YRotation = MathHelper.PiOver2;
            _camera.XRotation = 0;

            Mouse.SetPosition(Window.ClientBounds.Width / 2, Window.ClientBounds.Height / 2);

            base.Initialize();
        }

        /// <summary>
        /// LoadContent will be called once per game and is the place to load
        /// all of your content.
        /// </summary>
        protected override void LoadContent()
        {
            // Create a new SpriteBatch, which can be used to draw textures.
            spriteBatch = new SpriteBatch(GraphicsDevice);

            _model = Content.Load<Model>("models/Street environment_V01");

            _modelTransforms = new Matrix[_model.Bones.Count];
            _model.CopyAbsoluteBoneTransformsTo(_modelTransforms);
        }

        /// <summary>
        /// UnloadContent will be called once per game and is the place to unload
        /// all content.
        /// </summary>
        protected override void UnloadContent()
        {
            
        }

        /// <summary>
        /// Allows the game to run logic such as updating the world,
        /// checking for collisions, gathering input, and playing audio.
        /// </summary>
        /// <param name="gameTime">Provides a snapshot of timing values.</param>
        protected override void Update(GameTime gameTime)
        {
            if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed || Keyboard.GetState().IsKeyDown(Keys.Escape))
                Exit();

            // Apply keyboard input.

            var keyboardState = Keyboard.GetState();

            var deltaSeconds = (float) gameTime.ElapsedGameTime.TotalSeconds;
            float moveSpeed = 15.0f * deltaSeconds;

            if (keyboardState.IsKeyDown(Keys.LeftShift))
                moveSpeed *= 0.25f;

            var cameraPosition = _camera.Position;
            if (keyboardState.IsKeyDown(Keys.W))
                cameraPosition += _camera.Forward * moveSpeed;
            else if (keyboardState.IsKeyDown(Keys.S))
                cameraPosition += _camera.Backward * moveSpeed;
            if (keyboardState.IsKeyDown(Keys.A))
                cameraPosition += _camera.Left * moveSpeed;
            else if (keyboardState.IsKeyDown(Keys.D))
                cameraPosition += _camera.Right * moveSpeed;
            if (keyboardState.IsKeyDown(Keys.Q))
                cameraPosition += _camera.Up * moveSpeed;
            else if (keyboardState.IsKeyDown(Keys.E))
                cameraPosition += _camera.Down * moveSpeed;

            _camera.Position = cameraPosition;

            // Apply mouse input.

            var mouseState = Mouse.GetState();
            float rotationSpeed = 0.180f * deltaSeconds;
            if (mouseState.RightButton == ButtonState.Pressed)
            {
                var xRot = _camera.XRotation;
                var yRot = _camera.YRotation;
                xRot += ((Window.ClientBounds.Height / 2) - mouseState.Y) * rotationSpeed;
                yRot += ((Window.ClientBounds.Width / 2) - mouseState.X) * rotationSpeed;
                _camera.XRotation = xRot;
                _camera.YRotation = yRot;
            }

            Mouse.SetPosition(Window.ClientBounds.Width / 2, Window.ClientBounds.Height / 2);

            base.Update(gameTime);
        }

        /// <summary>
        /// This is called when the game should draw itself.
        /// </summary>
        /// <param name="gameTime">Provides a snapshot of timing values.</param>
        protected override void Draw(GameTime gameTime)
        {
            GraphicsDevice.Clear(Color.CornflowerBlue);

            foreach (var mesh in _model.Meshes)
            {
                foreach (BasicEffect effect in mesh.Effects)
                {
                    effect.World = _modelTransforms[mesh.ParentBone.Index];
                    effect.View = _camera.View;
                    effect.Projection = _camera.Projection;
                }

                mesh.Draw();
            }

            base.Draw(gameTime);
        }
    }
}
