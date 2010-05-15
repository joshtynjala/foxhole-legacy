/*
Copyright (c) 2010 Josh Tynjala

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
package org.josht.foxhole.controls
{
	import fl.controls.ScrollPolicy;
	import fl.core.InvalidationType;
	import fl.core.UIComponent;
	import fl.video.ReconnectClient;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	
	import org.josht.foxhole.core.FrameTicker;
	
	public class TouchScroller extends UIComponent
	{
		private static const DEFAULT_FRICTION:Number = 0.4;
		
		public function TouchScroller()
		{
			super();
			this.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
		}
		
		private var _clipContent:Boolean = true;

		public function get clipContent():Boolean
		{
			return this._clipContent;
		}

		public function set clipContent(value:Boolean):void
		{
			this._clipContent = value;
			this.invalidate(InvalidationType.SCROLL);
			this.invalidate(InvalidationType.SIZE);
		}

		private var _contentContainer:Sprite;
		
		private var _content:DisplayObject;

		public function get content():DisplayObject
		{
			return this._content;
		}

		public function set content(value:DisplayObject):void
		{
			if(this._content == value)
			{
				return;
			}
			
			if(this._content)
			{
				this._contentContainer.removeChild(this._content);
			}
			this._content = value;
			if(this._content)
			{
				this._contentContainer.addChild(this._content);
			}
			this.invalidate(InvalidationType.SCROLL);
			this.invalidate(InvalidationType.SIZE);
		}
		
		private var _startTime:int;
		private var _startMouseX:Number;
		private var _startMouseY:Number;
		private var _startHorizontalScrollPosition:Number;
		private var _startVerticalScrollPosition:Number;
		private var _targetHorizontalScrollPosition:Number;
		private var _targetVerticalScrollPosition:Number;
		private var _autoScrolling:Boolean = false;
		
		private var _verticalScrollPosition:Number = 0;
		
		public function get verticalScrollPosition():Number
		{
			return this._verticalScrollPosition;
		}
		
		public function set verticalScrollPosition(value:Number):void
		{
			if(this._verticalScrollPosition == value)
			{
				return;
			}
			this._verticalScrollPosition = value;
			this.invalidate(InvalidationType.SCROLL);
		}
		
		private var _maxVerticalScrollPosition:Number = 0;
		
		public function get maxVerticalScrollPosition():Number
		{
			return this._maxVerticalScrollPosition;
		}
		
		private var _verticalScrollPolicy:String = ScrollPolicy.AUTO;
		
		public function get verticalScrollPolicy():String
		{
			return this._verticalScrollPolicy;
		}
		
		public function set verticalScrollPolicy(value:String):void
		{
			this._verticalScrollPolicy = value;
		}
		
		private var _horizontalScrollPosition:Number = 0;

		public function get horizontalScrollPosition():Number
		{
			return this._horizontalScrollPosition;
		}

		public function set horizontalScrollPosition(value:Number):void
		{
			if(this._horizontalScrollPosition == value)
			{
				return;
			}
			this._horizontalScrollPosition = value;
			this.invalidate(InvalidationType.SCROLL);
		}

		private var _maxHorizontalScrollPosition:Number = 0;

		public function get maxHorizontalScrollPosition():Number
		{
			return this._maxHorizontalScrollPosition;
		}

		private var _horizontalScrollPolicy:String = ScrollPolicy.ON;

		public function get horizontalScrollPolicy():String
		{
			return this._horizontalScrollPolicy;
		}

		public function set horizontalScrollPolicy(value:String):void
		{
			this._horizontalScrollPolicy = value;
		}
		
		private var _scrollFriction:Number = DEFAULT_FRICTION;

		public function get scrollFriction():Number
		{
			return this._scrollFriction;
		}

		public function set scrollFriction(value:Number):void
		{
			this._scrollFriction = value;
		}


		override protected function configUI():void
		{
			super.configUI();
			
			this._contentContainer = new Sprite();
			this.addChild(this._contentContainer);
		}
		
		override protected function draw():void
		{
			var scrollInvalid:Boolean = this.isInvalid(InvalidationType.SCROLL);
			var sizeInvalid:Boolean = this.isInvalid(InvalidationType.SIZE);
			
			if(sizeInvalid)
			{
				if(this.clipContent)
				{
					var scrollRect:Rectangle = this._contentContainer.scrollRect;
					if(!scrollRect)
					{
						scrollRect = new Rectangle();
					}
					scrollRect.width = this._width;
					scrollRect.height = this._height;
					this._contentContainer.scrollRect = scrollRect;
				}
				else if(this._contentContainer.scrollRect)
				{
					this._contentContainer.scrollRect = null;
				}
				
				this.graphics.clear();
				this.graphics.beginFill(0xff00ff, 0);
				this.graphics.drawRect(0, 0, this._width, this._height);
				this.graphics.endFill();
			}
			
			if(this._content && (scrollInvalid || sizeInvalid))
			{
				this._maxHorizontalScrollPosition = Math.max(0, this._content.width - this._width);
				this._maxVerticalScrollPosition = Math.max(0, this._content.height - this._height);
				if(this.clipContent)
				{
					scrollRect = this._contentContainer.scrollRect;
					if(!scrollRect)
					{
						scrollRect = new Rectangle();
					}
					scrollRect.x = this._horizontalScrollPosition;
					scrollRect.y = this._verticalScrollPosition;
					this._contentContainer.scrollRect = scrollRect;
				}
				else
				{
					this._content.x = -this._horizontalScrollPosition;
					this._content.y = -this._verticalScrollPosition;
				}
			}
			
			super.draw();
		}
		
		private function updateScrollFromMousePosition():void
		{
			var oldHorizontalScrollPosition:Number = this._horizontalScrollPosition;
			if(this._horizontalScrollPolicy != ScrollPolicy.OFF)
			{
				var offsetX:Number = this._startMouseX - this.mouseX;
				var positionX:Number = this._startHorizontalScrollPosition + offsetX;
				if(this._horizontalScrollPosition < 0)
				{
					positionX /= 2;
				}
				else if(positionX > this._maxHorizontalScrollPosition)
				{
					positionX -= (positionX - this._maxHorizontalScrollPosition) / 2;
				}
				this.horizontalScrollPosition = positionX;
			}
			
			var oldVerticalScrollPosition:Number = this._verticalScrollPosition;
			if(this._verticalScrollPolicy != ScrollPolicy.OFF)
			{
				var offsetY:Number = this._startMouseY - this.mouseY;
				var positionY:Number = this._startVerticalScrollPosition + offsetY;
				if(this._verticalScrollPosition < 0)
				{
					positionY /= 2;
				}
				else if(positionY > this._maxVerticalScrollPosition)
				{
					positionY -= (positionY - this._maxVerticalScrollPosition) / 2;
				}
				this.verticalScrollPosition = positionY;
			}
			
			if(oldVerticalScrollPosition != this._verticalScrollPosition ||
				oldHorizontalScrollPosition != this._horizontalScrollPosition)
			{
				this.dispatchEvent(new Event(Event.SCROLL));
			}
		}
		
		private function autoScroll():void
		{
			if(this._verticalScrollPolicy != ScrollPolicy.OFF)
			{
				var differenceY:Number = (this._verticalScrollPosition - this._targetVerticalScrollPosition) * this._scrollFriction;
				this.verticalScrollPosition -= differenceY;
			}
			
			if(this._horizontalScrollPolicy != ScrollPolicy.OFF)
			{
				var differenceX:Number = (this._horizontalScrollPosition - this._targetHorizontalScrollPosition) * this._scrollFriction;
				this.horizontalScrollPosition -= differenceX;
			}
			
			if(Math.abs(this._verticalScrollPosition - this._targetVerticalScrollPosition) < 1 &&
				Math.abs(this._horizontalScrollPosition - this._targetHorizontalScrollPosition) < 1)
			{
				this.horizontalScrollPosition = this._targetHorizontalScrollPosition;
				this.verticalScrollPosition = this._targetVerticalScrollPosition;
				this._autoScrolling = false;
				FrameTicker.removeExitFrameCallback(onTick);
			}
			this.dispatchEvent(new Event(Event.SCROLL));
		}
		
		private function calculateTargetScrollPosition(scrollPosition:Number, maxScrollPosition:Number, startMouse:Number, currentMouse:Number):Number
		{
			var distance:Number = currentMouse - startMouse;
			var pixelsPerMS:Number = distance / (getTimer() - this._startTime); 
			var pixelsPerFrame:Number = 1.5 * (pixelsPerMS * 1000) / this.loaderInfo.frameRate;
			var targetScrollPosition:Number = this._verticalScrollPosition;
			while(Math.abs(pixelsPerFrame) >= 1) //there's probably an equation for this...
			{
				targetScrollPosition -= pixelsPerFrame;
				if(targetScrollPosition < 0 || targetScrollPosition > maxScrollPosition)
				{
					pixelsPerFrame /= 2;
					targetScrollPosition += pixelsPerFrame;
				}
				pixelsPerFrame *= (1 - this._scrollFriction);
			}
			
			return targetScrollPosition;
		}
		
		private function onTick():void
		{
			if(!this._autoScrolling)
			{
				this.updateScrollFromMousePosition();
			}
			else
			{
				this.autoScroll();
			}
		}

		private function mouseDownHandler(event:MouseEvent):void
		{
			if(!this.enabled)
			{
				return;
			}
			
			this._startTime = getTimer();
			this._startMouseX = this.mouseX;
			this._startMouseY = this.mouseY;
			this._startHorizontalScrollPosition = this._horizontalScrollPosition;
			this._startVerticalScrollPosition = this._verticalScrollPosition;
			this._targetHorizontalScrollPosition = this._horizontalScrollPosition;
			this._targetVerticalScrollPosition = this._verticalScrollPosition;
			
			if(this._autoScrolling)
			{
				this._autoScrolling = false;
			}
			else
			{
				FrameTicker.addExitFrameCallback(onTick);
			}
			
			this.stage.addEventListener(MouseEvent.MOUSE_UP, stage_mouseUpHandler, false, 0, true);
		}
		
		private function stage_mouseUpHandler(event:MouseEvent):void
		{
			this.stage.removeEventListener(MouseEvent.MOUSE_UP, stage_mouseUpHandler);
			
			this._autoScrolling = true;
			if(this._verticalScrollPolicy != ScrollPolicy.OFF)
			{
				if(this._verticalScrollPosition <= 0)
				{
					this._targetVerticalScrollPosition = 0;
				}
				else if(this._verticalScrollPosition >= this._maxVerticalScrollPosition)
				{
					this._targetVerticalScrollPosition = this._maxVerticalScrollPosition;
				}
				else
				{
					this._targetVerticalScrollPosition = this.calculateTargetScrollPosition(this._verticalScrollPosition, this._maxVerticalScrollPosition, this._startMouseY, this.mouseY);
				}
			}
			
			if(this._horizontalScrollPolicy != ScrollPolicy.OFF)
			{
				if(this._horizontalScrollPosition <= 0)
				{
					this._targetHorizontalScrollPosition = 0;
				}
				else if(this._horizontalScrollPosition >= this._maxHorizontalScrollPosition)
				{
					this._targetHorizontalScrollPosition = this._maxHorizontalScrollPosition;
				}
				else
				{
					this._targetHorizontalScrollPosition = this.calculateTargetScrollPosition(this._horizontalScrollPosition, this._maxHorizontalScrollPosition, this._startMouseX, this.mouseX);
				}
			}
			
		}
	}
}