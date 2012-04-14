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
	 * Scales an image like a "pill" shape with three regions, either
	 * horizontally or vertically. The edge regions scale while maintaining
	 * aspect ratio, and the middle region stretches to fill the remaining
	 * space.
	 */
	public class Scale3Bitmap extends FoxholeControl
	{
		private static const HELPER_MATRIX:Matrix = new Matrix();
		private static const HELPER_POINT:Point = new Point();
		private static const HELPER_RECT:Rectangle = new Rectangle();
		
		/**
		 * If the direction is horizontal, the layout will start on the left and continue to the right.
		 */
		public static const DIRECTION_HORIZONTAL:String = "horizontal";
		
		/**
		 * If the direction is vertical, the layout will start on the top and continue to the bottom.
		 */
		public static const DIRECTION_VERTICAL:String = "vertical";
		
		/**
		 * Constructor.
		 */
		public function Scale3Bitmap(texture:BitmapData, firstRegionSize:Number, secondRegionSize:Number, direction:String = DIRECTION_HORIZONTAL, textureScale:Number = 1)
		{
			super();
			
			this._texture = texture;
			this._firstRegionSize = firstRegionSize;
			this._secondRegionSize = secondRegionSize;
			this._direction = direction;
			this._textureScale = textureScale;
			this.initializeWidthAndHeight();
			this.mouseChildren = false;
		}
		
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
		 * The smoothing value to pass to the images.
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
		
		private var _firstRegionSize:Number;
		private var _secondRegionSize:Number;
		private var _thirdRegionSize:Number;
		private var _oppositeEdgeSize:Number;
		private var _direction:String;
		
		private var _texture:BitmapData;
		private var _first:BitmapData;
		private var _second:BitmapData;
		private var _third:BitmapData;
		
		/**
		 * @private
		 */
		override protected function initialize():void
		{
			//const textureFrame:Rectangle = this._texture.frame;
			if(this._direction == DIRECTION_VERTICAL)
			{
				this._thirdRegionSize = this._texture.height - this._firstRegionSize - this._secondRegionSize;
				this._oppositeEdgeSize = this._texture.width;
			}
			else
			{
				this._thirdRegionSize = this._texture.width - this._firstRegionSize - this._secondRegionSize;
				this._oppositeEdgeSize = this._texture.height;
			}
			
			if(this._direction == DIRECTION_VERTICAL)
			{
				HELPER_POINT.x = HELPER_POINT.y = 0;
				if(this._firstRegionSize > 0)
				{
					HELPER_RECT.x = 0;
					HELPER_RECT.y = 0;
					HELPER_RECT.width = this._oppositeEdgeSize;
					HELPER_RECT.height = this._firstRegionSize;
					this._first = new BitmapData(this._oppositeEdgeSize, this._firstRegionSize, this._texture.transparent);
					this._first.copyPixels(this._texture, HELPER_RECT, HELPER_POINT);
				}
				if(this._secondRegionSize > 0)
				{
					HELPER_RECT.x = 0;
					HELPER_RECT.y = this._firstRegionSize;
					HELPER_RECT.width = this._oppositeEdgeSize;
					HELPER_RECT.height = this._secondRegionSize;
					this._second = new BitmapData(this._oppositeEdgeSize, this._secondRegionSize, this._texture.transparent);
					this._second.copyPixels(this._texture, HELPER_RECT, HELPER_POINT);
				}
				if(this._thirdRegionSize > 0)
				{
					HELPER_RECT.x = 0;
					HELPER_RECT.y = this._firstRegionSize + this._secondRegionSize;
					HELPER_RECT.width = this._oppositeEdgeSize;
					HELPER_RECT.height = this._thirdRegionSize;
					this._third = new BitmapData(this._oppositeEdgeSize, this._thirdRegionSize, this._texture.transparent);
					this._third.copyPixels(this._texture, HELPER_RECT, HELPER_POINT);
				}
			}
			else //horizontal
			{
				HELPER_POINT.x = HELPER_POINT.y = 0;
				if(this._firstRegionSize > 0)
				{
					HELPER_RECT.x = 0;
					HELPER_RECT.y = 0;
					HELPER_RECT.width = this._firstRegionSize;
					HELPER_RECT.height = this._oppositeEdgeSize;
					this._first = new BitmapData(this._firstRegionSize, this._oppositeEdgeSize, this._texture.transparent);
					this._first.copyPixels(this._texture, HELPER_RECT, HELPER_POINT);
				}
				if(this._secondRegionSize > 0)
				{
					HELPER_RECT.x = this._firstRegionSize;
					HELPER_RECT.y = 0;
					HELPER_RECT.width = this._secondRegionSize;
					HELPER_RECT.height = this._oppositeEdgeSize;
					this._second = new BitmapData(this._secondRegionSize, this._oppositeEdgeSize, this._texture.transparent);
					this._second.copyPixels(this._texture, HELPER_RECT, HELPER_POINT);
				}
				if(this._thirdRegionSize > 0)
				{
					HELPER_RECT.x = this._firstRegionSize + this._secondRegionSize;
					HELPER_RECT.y = 0;
					HELPER_RECT.width = this._thirdRegionSize;
					HELPER_RECT.height = this._oppositeEdgeSize;
					this._third = new BitmapData(this._thirdRegionSize, this._oppositeEdgeSize, this._texture.transparent);
					this._third.copyPixels(this._texture, HELPER_RECT, HELPER_POINT);
				}
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
			
			if(this._direction == DIRECTION_VERTICAL)
			{
				var scaledOppositeEdgeSize:Number = this.actualWidth;
				var oppositeEdgeScale:Number = scaledOppositeEdgeSize / this._oppositeEdgeSize;
				var scaledFirstRegionSize:Number = this._firstRegionSize * oppositeEdgeScale;
				var scaledThirdRegionSize:Number = this._thirdRegionSize * oppositeEdgeScale;
				var scaledSecondRegionSize:Number = this.actualHeight - scaledFirstRegionSize - scaledSecondRegionSize;
				var secondRegionScale:Number = Math.max(0, scaledSecondRegionSize / this._secondRegionSize);
				
				HELPER_MATRIX.identity();
				HELPER_MATRIX.scale(oppositeEdgeScale, oppositeEdgeScale);
				if(this._first)
				{
					this.graphics.beginBitmapFill(this._first, HELPER_MATRIX, false, this._smoothing);
					this.graphics.drawRect(0, 0, scaledOppositeEdgeSize, scaledFirstRegionSize);
					this.graphics.endFill();
				}
				if(this._third)
				{
					HELPER_MATRIX.ty = this.actualHeight - scaledThirdRegionSize
					this.graphics.beginBitmapFill(this._third, HELPER_MATRIX, false, this._smoothing);
					this.graphics.drawRect(0, HELPER_MATRIX.ty, scaledOppositeEdgeSize, scaledThirdRegionSize);
					this.graphics.endFill();
				}
				if(this._second)
				{
					HELPER_MATRIX.identity();
					HELPER_MATRIX.scale(oppositeEdgeScale, secondRegionScale);
					HELPER_MATRIX.ty = scaledFirstRegionSize;
					this.graphics.beginBitmapFill(this._second, HELPER_MATRIX, false, this._smoothing);
					this.graphics.drawRect(0, HELPER_MATRIX.ty, scaledOppositeEdgeSize, scaledSecondRegionSize);
					this.graphics.endFill();
				}
			}
			else //horizontal
			{
				scaledOppositeEdgeSize = this.actualHeight;
				oppositeEdgeScale = scaledOppositeEdgeSize / this._oppositeEdgeSize;
				scaledFirstRegionSize = this._firstRegionSize * oppositeEdgeScale;
				scaledThirdRegionSize = this._thirdRegionSize * oppositeEdgeScale;
				scaledSecondRegionSize = this.actualWidth - scaledFirstRegionSize - scaledThirdRegionSize;
				secondRegionScale = Math.max(0, scaledSecondRegionSize / this._secondRegionSize);
				
				HELPER_MATRIX.identity();
				HELPER_MATRIX.scale(oppositeEdgeScale, oppositeEdgeScale);
				if(this._first)
				{
					this.graphics.beginBitmapFill(this._first, HELPER_MATRIX, false, this._smoothing);
					this.graphics.drawRect(0, 0, scaledFirstRegionSize, scaledOppositeEdgeSize);
					this.graphics.endFill();
				}
				if(this._third)
				{
					HELPER_MATRIX.tx = this.actualWidth - scaledThirdRegionSize;
					this.graphics.moveTo(this.actualWidth - scaledThirdRegionSize, 0);
					this.graphics.beginBitmapFill(this._third, HELPER_MATRIX, false, this._smoothing);
					this.graphics.drawRect(HELPER_MATRIX.tx, 0, scaledThirdRegionSize, scaledOppositeEdgeSize);
					this.graphics.endFill();
				}
				if(this._second)
				{
					HELPER_MATRIX.identity();
					HELPER_MATRIX.scale(secondRegionScale, oppositeEdgeScale);
					HELPER_MATRIX.tx = scaledFirstRegionSize;
					this.graphics.beginBitmapFill(this._second, HELPER_MATRIX, true, this._smoothing);
					this.graphics.drawRect(HELPER_MATRIX.tx, 0, scaledSecondRegionSize, scaledOppositeEdgeSize);
					this.graphics.endFill();
				}
			}
		}
		
		/**
		 * @private
		 */
		private function initializeWidthAndHeight():void
		{
			var width:Number;
			var height:Number;
			if(this._direction == DIRECTION_VERTICAL)
			{
				width = this._oppositeEdgeSize * this._textureScale;
				height = (this._firstRegionSize + this._secondRegionSize + this._thirdRegionSize) * this._textureScale;
			}
			else //horizontal
			{
				width = (this._firstRegionSize + this._secondRegionSize + this._thirdRegionSize) * this._textureScale;
				height = this._oppositeEdgeSize * this._textureScale;
			}
			this.setSizeInternal(width, height, true);
		}
	}
}
