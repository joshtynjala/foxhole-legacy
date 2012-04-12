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
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import org.josht.foxhole.core.FoxholeControl;
	
	/**
	 * Scales an image with nine regions to maintain the aspect ratio of the
	 * corners regions. The top and bottom regions stretch horizontally, and the
	 * left and right regions scale vertically. The center region stretches in
	 * both directions to fill the remaining space.
	 */
	public class Scale9Bitmap extends FoxholeControl
	{
		private static const HELPER_MATRIX:Matrix = new Matrix();
		private static const HELPER_POINT:Point = new Point();
		private static const HELPER_RECT:Rectangle = new Rectangle();
		
		/**
		 * Constructor.
		 */
		public function Scale9Bitmap(texture:BitmapData, scale9Grid:Rectangle)
		{
			super();
			this._texture = texture
			this._scale9Grid = scale9Grid;
			this.mouseChildren = false;
		}
		
		private var _texture:BitmapData;
		
		private var _scale9Grid:Rectangle;
		
		private var _leftWidth:Number;
		private var _centerWidth:Number;
		private var _rightWidth:Number;
		private var _topHeight:Number;
		private var _middleHeight:Number;
		private var _bottomHeight:Number;
		
		private var _topLeft:BitmapData;
		private var _topCenter:BitmapData;
		private var _topRight:BitmapData;
		
		private var _middleLeft:BitmapData;
		private var _middleCenter:BitmapData;
		private var _middleRight:BitmapData;
		
		private var _bottomLeft:BitmapData;
		private var _bottomCenter:BitmapData;
		private var _bottomRight:BitmapData;
		
		/**
		 * @private
		 */
		private var _textureScale:Number = 1;
		
		/**
		 * The amount to scale the texture. Useful for DPI changes.
		 */
		public function get textureScale():Number
		{
			return this._textureScale;
		}
		
		/**
		 * @private
		 */
		public function set textureScale(value:Number):void
		{
			if(this._textureScale == value)
			{
				return;
			}
			this._textureScale = value;
			this.invalidate();
		}
		
		/**
		 * @private
		 */
		private var _smoothing:Boolean = true;
		
		/**
		 * The smoothing value to pass to the subtextures.
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
			this.invalidate();
		}
		
		/**
		 * @private
		 */
		override protected function initialize():void
		{
			this._leftWidth = this._scale9Grid.x;
			this._centerWidth = this._scale9Grid.width;
			this._rightWidth = this._texture.width - this._scale9Grid.width - this._scale9Grid.x;
			this._topHeight = this._scale9Grid.y;
			this._middleHeight = this._scale9Grid.height;
			this._bottomHeight = this._texture.height - this._scale9Grid.height - this._scale9Grid.y;
			
			HELPER_POINT.x = HELPER_POINT.y = 0;
			if(this._leftWidth > 0 && this._topHeight > 0)
			{
				HELPER_RECT.x = 0;
				HELPER_RECT.y = 0;
				HELPER_RECT.width = this._leftWidth;
				HELPER_RECT.height = this._topHeight;
				this._topLeft = new BitmapData(this._leftWidth, this._topHeight, this._texture.transparent);
				this._topLeft.copyPixels(this._texture, HELPER_RECT, HELPER_POINT);
			}
			
			if(this._centerWidth > 0 && this._topHeight > 0)
			{
				HELPER_RECT.x = this._leftWidth;
				HELPER_RECT.y = 0;
				HELPER_RECT.width = this._centerWidth;
				HELPER_RECT.height = this._topHeight;
				this._topCenter = new BitmapData(this._centerWidth, this._topHeight, this._texture.transparent);
				this._topCenter.copyPixels(this._texture, HELPER_RECT, HELPER_POINT);
			}
			
			if(this._rightWidth > 0 && this._topHeight > 0)
			{
				HELPER_RECT.x = this._leftWidth + this._centerWidth;
				HELPER_RECT.y = 0;
				HELPER_RECT.width = this._rightWidth;
				HELPER_RECT.height = this._topHeight;
				this._topRight = new BitmapData(this._rightWidth, this._topHeight, this._texture.transparent);
				this._topRight.copyPixels(this._texture, HELPER_RECT, HELPER_POINT);
			}
			
			if(this._leftWidth > 0 && this._middleHeight > 0)
			{
				HELPER_RECT.x = 0;
				HELPER_RECT.y = this._topHeight;
				HELPER_RECT.width = this._leftWidth;
				HELPER_RECT.height = this._middleHeight;
				this._middleLeft = new BitmapData(this._leftWidth, this._middleHeight, this._texture.transparent);
				this._middleLeft.copyPixels(this._texture, HELPER_RECT, HELPER_POINT);
			}
			
			if(this._centerWidth > 0 && this._middleHeight > 0)
			{
				HELPER_RECT.x = this._leftWidth;
				HELPER_RECT.y = this._topHeight;
				HELPER_RECT.width = this._centerWidth;
				HELPER_RECT.height = this._middleHeight;
				this._middleCenter = new BitmapData(this._centerWidth, this._middleHeight, this._texture.transparent);
				this._middleCenter.copyPixels(this._texture, HELPER_RECT, HELPER_POINT);
			}
			
			if(this._rightWidth > 0 && this._middleHeight > 0)
			{
				HELPER_RECT.x = this._leftWidth + this._centerWidth;
				HELPER_RECT.y = this._topHeight;
				HELPER_RECT.width = this._rightWidth;
				HELPER_RECT.height = this._middleHeight;
				this._middleRight = new BitmapData(this._rightWidth, this._middleHeight, this._texture.transparent);
				this._middleRight.copyPixels(this._texture, HELPER_RECT, HELPER_POINT);
			}
			
			if(this._leftWidth > 0 && this._bottomHeight > 0)
			{
				HELPER_RECT.x = 0;
				HELPER_RECT.y = this._topHeight + this._middleHeight;
				HELPER_RECT.width = this._leftWidth;
				HELPER_RECT.height = this._bottomHeight;
				this._bottomLeft = new BitmapData(this._leftWidth, this._bottomHeight, this._texture.transparent);
				this._bottomLeft.copyPixels(this._texture, HELPER_RECT, HELPER_POINT);
			}
			
			if(this._centerWidth > 0 && this._bottomHeight > 0)
			{
				HELPER_RECT.x = this._leftWidth;
				HELPER_RECT.y = this._topHeight + this._middleHeight;
				HELPER_RECT.width = this._centerWidth;
				HELPER_RECT.height = this._bottomHeight;
				this._bottomCenter = new BitmapData(this._centerWidth, this._bottomHeight, this._texture.transparent);
				this._bottomCenter.copyPixels(this._texture, HELPER_RECT, HELPER_POINT);
			}
			
			if(this._rightWidth > 0 && this._bottomHeight > 0)
			{
				HELPER_RECT.x = this._leftWidth + this._centerWidth;
				HELPER_RECT.y = this._topHeight + this._middleHeight;
				HELPER_RECT.width = this._rightWidth;
				HELPER_RECT.height = this._bottomHeight;
				this._bottomRight = new BitmapData(this._rightWidth, this._bottomHeight, this._texture.transparent);
				this._bottomRight.copyPixels(this._texture, HELPER_RECT, HELPER_POINT);
			}
		}
		
		/**
		 * @private
		 */
		override protected function draw():void
		{
			this.graphics.clear();
			if(!this._texture)
			{
				return;
			}
			
			const scaledLeftWidth:Number = this._leftWidth * this._textureScale;
			const scaledTopHeight:Number = this._topHeight * this._textureScale;
			const scaledRightWidth:Number = this._rightWidth * this._textureScale;
			const scaledBottomHeight:Number = this._bottomHeight * this._textureScale;
			if(isNaN(this._width))
			{
				this._width = this._leftWidth + this._centerWidth + this._rightWidth * this._textureScale;
			}
			
			if(isNaN(this._height))
			{
				this._height = this._topHeight + this._middleHeight + this._bottomHeight * this._textureScale;
			}
			
			const scaledCenterWidth:Number = Math.max(0, this._width - scaledLeftWidth - scaledRightWidth);
			const scaledMiddleHeight:Number = Math.max(0, this._height - scaledTopHeight - scaledBottomHeight);
			const centerScale:Number = scaledCenterWidth / this._centerWidth;
			const middleScale:Number = scaledMiddleHeight / this._middleHeight;
			
			HELPER_MATRIX.identity();
			HELPER_MATRIX.scale(this._textureScale, this._textureScale);
			
			if(this._topLeft)
			{
				this.graphics.beginBitmapFill(this._topLeft, HELPER_MATRIX, false, this._smoothing);
				this.graphics.drawRect(0, 0, scaledLeftWidth, scaledTopHeight);
				this.graphics.endFill();
			}
			
			if(this._topRight)
			{
				HELPER_MATRIX.tx = scaledLeftWidth + scaledCenterWidth;
				this.graphics.beginBitmapFill(this._topRight, HELPER_MATRIX, false, this._smoothing);
				this.graphics.drawRect(HELPER_MATRIX.tx, 0, scaledRightWidth, scaledTopHeight);
				this.graphics.endFill();
			}
			
			if(this._bottomLeft)
			{
				HELPER_MATRIX.tx = 0;
				HELPER_MATRIX.ty = scaledTopHeight + scaledMiddleHeight;
				this.graphics.beginBitmapFill(this._bottomLeft, HELPER_MATRIX, false, this._smoothing);
				this.graphics.drawRect(0, HELPER_MATRIX.ty, scaledLeftWidth, scaledBottomHeight);
				this.graphics.endFill();
			}
			
			if(this._bottomRight)
			{
				HELPER_MATRIX.tx = scaledLeftWidth + scaledCenterWidth;
				HELPER_MATRIX.ty = scaledTopHeight + scaledMiddleHeight;
				this.graphics.beginBitmapFill(this._bottomRight, HELPER_MATRIX, false, this._smoothing);
				this.graphics.drawRect(HELPER_MATRIX.tx, HELPER_MATRIX.ty, scaledRightWidth, scaledBottomHeight);
				this.graphics.endFill();
			}
			
			HELPER_MATRIX.identity();
			HELPER_MATRIX.scale(this._textureScale * centerScale, this._textureScale);
			
			if(this._topCenter)
			{
				HELPER_MATRIX.tx = scaledLeftWidth;
				this.graphics.beginBitmapFill(this._topCenter, HELPER_MATRIX, false, this._smoothing);
				this.graphics.drawRect(HELPER_MATRIX.tx, 0, scaledCenterWidth, scaledTopHeight);
				this.graphics.endFill();
			}
			
			if(this._bottomCenter)
			{
				HELPER_MATRIX.tx = scaledLeftWidth;
				HELPER_MATRIX.ty = scaledTopHeight + scaledMiddleHeight
				this.graphics.beginBitmapFill(this._bottomCenter, HELPER_MATRIX, false, this._smoothing);
				this.graphics.drawRect(HELPER_MATRIX.tx, HELPER_MATRIX.ty, scaledCenterWidth, scaledBottomHeight);
				this.graphics.endFill();
			}
			
			HELPER_MATRIX.identity();
			HELPER_MATRIX.scale(this._textureScale, this._textureScale * middleScale);
			
			if(this._middleLeft)
			{
				HELPER_MATRIX.ty = scaledTopHeight;
				this.graphics.beginBitmapFill(this._middleLeft, HELPER_MATRIX, false, this._smoothing);
				this.graphics.drawRect(0, HELPER_MATRIX.ty, scaledLeftWidth, scaledMiddleHeight);
				this.graphics.endFill();
			}
			
			if(this._middleRight)
			{
				HELPER_MATRIX.tx = scaledLeftWidth + scaledCenterWidth;
				HELPER_MATRIX.ty = scaledTopHeight;
				this.graphics.beginBitmapFill(this._middleRight, HELPER_MATRIX, false, this._smoothing);
				this.graphics.drawRect(HELPER_MATRIX.tx, HELPER_MATRIX.ty, scaledRightWidth, scaledMiddleHeight);
				this.graphics.endFill();
			}
			
			if(this._middleCenter)
			{
				HELPER_MATRIX.identity();
				HELPER_MATRIX.scale(this._textureScale * centerScale, this._textureScale * middleScale);
				HELPER_MATRIX.tx = scaledLeftWidth;
				HELPER_MATRIX.ty = scaledTopHeight;
				this.graphics.beginBitmapFill(this._middleCenter, HELPER_MATRIX, false, this._smoothing);
				this.graphics.drawRect(HELPER_MATRIX.tx, HELPER_MATRIX.ty, scaledCenterWidth, scaledMiddleHeight);
				this.graphics.endFill();
			}
		}
	}
}