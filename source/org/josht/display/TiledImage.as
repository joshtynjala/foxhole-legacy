/*
Copyright (c) 2012 Josh Tynjala

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
*/
package org.josht.display
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;

	/**
	 * Tiles a texture to fill, and possibly overflow, the specified bounds. May
	 * be clipped.
	 */
	public class TiledImage extends Sprite
	{
		/**
		 * Constructor.
		 */
		public function TiledImage(texture:BitmapData, textureScale:Number = 1)
		{
			super();
			this.textureScale = textureScale;
			this.texture = texture;
			this.initializeWidthAndHeight();
			this.mouseChildren = false;
		}
		
		/**
		 * @private
		 */
		private var _width:Number = NaN;
		
		/**
		 * @inheritDoc
		 */
		override public function get width():Number
		{
			return this._width;
		}
		
		/**
		 * @private
		 */
		override public function set width(value:Number):void
		{
			if(this._width == value)
			{
				return;
			}
			this._width = value;
			this.redraw();
		}
		
		/**
		 * @private
		 */
		private var _height:Number = NaN;
		
		/**
		 * @inheritDoc
		 */
		override public function get height():Number
		{
			return this._height;
		}
		
		/**
		 * @private
		 */
		override public function set height(value:Number):void
		{
			if(this._height == value)
			{
				return;
			}
			this._height = value;
			this.redraw();
		}
		
		/**
		 * @private
		 */
		private var _texture:BitmapData;
		
		/**
		 * The texture to tile.
		 */
		public function get texture():BitmapData
		{
			return this._texture;
		}
		
		/**
		 * @private
		 */
		public function set texture(value:BitmapData):void 
		{ 
			if(value == null)
			{
				throw new ArgumentError("Texture cannot be null");
			}
			else if(value != this._texture)
			{
				this._texture = value;
				this.redraw();
			}
		}
		
		/**
		 * @private
		 */
		private var _smoothing:Boolean = true;
		
		/**
		 * The smoothing value to pass to the tiled images.
		 */
		public function get smoothing():Boolean
		{
			return this._smoothing;
		}
		
		/**
		 * @private
		 */
		public function set smoothing(value:Boolean):void 
		{
			if(this._smoothing == value)
			{
				return;
			}
			this._smoothing = value;
		}
		
		/**
		 * @private
		 */
		private var _matrix:Matrix = new Matrix();
		
		/**
		 * The amount to scale the texture. Useful for DPI changes.
		 */
		public function get textureScale():Number
		{
			return this._matrix.a;
		}
		
		/**
		 * @private
		 */
		public function set textureScale(value:Number):void
		{
			if(this._matrix.a == value)
			{
				return;
			}
			this._matrix.identity();
			this._matrix.scale(value, value);
			this.redraw();
		}
		
		/**
		 * Set both the width and height in one call.
		 */
		public function setSize(width:Number, height:Number):void
		{
			this._width = width;
			this._height = height;
			this.redraw();
		}
		
		/**
		 * @private
		 */
		private function redraw():void
		{
			this.graphics.clear();
			this.graphics.beginBitmapFill(this.texture, this._matrix, true, this._smoothing);
			this.graphics.drawRect(0, 0, this._width, this._height);
			this.graphics.endFill();
		}
		
		/**
		 * @private
		 */
		private function initializeWidthAndHeight():void
		{
			this.width = this._texture.width * this.textureScale;
			this.height = this._texture.height * this.textureScale;
		}
	}
}