package org.josht.foxhole.controls
{
	import fl.core.InvalidationType;
	import fl.core.UIComponent;
	import fl.video.ReconnectClient;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	
	public class TouchScroller extends UIComponent
	{
		private static const FRICTION:Number = 0.5;
		
		public function TouchScroller()
		{
			super();
			this.mouseChildren = false;
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
		private var _startMouseY:Number;
		private var _startVerticalScrollPosition:Number;
		private var _targetVerticalScrollPosition:Number;
		private var _maxVerticalScrollPosition:Number = 0;
		private var _autoScrolling:Boolean = false;
		private var _isScrolling:Boolean = false;
		
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
				var maxHorizontalScrollPosition:Number = Math.max(0, this._content.width - this._width);
				this._maxVerticalScrollPosition = Math.max(0, this._content.height - this._height);
				if(this.clipContent)
				{
					scrollRect = this._contentContainer.scrollRect;
					if(!scrollRect)
					{
						scrollRect = new Rectangle();
					}
					scrollRect.y = this._verticalScrollPosition;
					this._contentContainer.scrollRect = scrollRect;
				}
				else
				{
					this._content.y = -this._verticalScrollPosition;
				}
			}
			
			super.draw();
		}
		
		private function finishScrolling():void
		{
			if(Math.abs(this._verticalScrollPosition - this._targetVerticalScrollPosition) < 1)
			{
				this.verticalScrollPosition = this._targetVerticalScrollPosition;
				if(this._isScrolling)
				{
					this.mouseChildren = true;
				}
				this._isScrolling = false;
				this._autoScrolling = false;
				this.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			}
		}

		private function mouseDownHandler(event:MouseEvent):void
		{
			if(!this.enabled)
			{
				return;
			}
			
			this._startTime = getTimer();
			this._startMouseY = this.mouseY;
			this._startVerticalScrollPosition = this._verticalScrollPosition;
			this._targetVerticalScrollPosition = this._verticalScrollPosition;
			
			if(this._autoScrolling)
			{
				this._autoScrolling = false;
			}
			else
			{
				this.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
			}
			
			this.stage.addEventListener(MouseEvent.MOUSE_UP, stage_mouseUpHandler, false, 0, true);
		}
		
		private function enterFrameHandler(event:Event):void
		{
			var offset:Number = 0;
			if(!this._autoScrolling)
			{
				offset = this._startMouseY - this.mouseY;
				var position:Number = this._startVerticalScrollPosition + offset;
				if(this._verticalScrollPosition < 0)
				{
					position /= 2;
				}
				else if(position > this._maxVerticalScrollPosition)
				{
					position -= (position - this._maxVerticalScrollPosition) / 2;
				}
				
				this.verticalScrollPosition = position;
			}
			else
			{
				var difference:Number = this._verticalScrollPosition - this._targetVerticalScrollPosition;
				if(difference > 0)
				{
					offset = Math.ceil(difference * FRICTION);
				}
				else
				{
					offset = Math.floor(difference * FRICTION);
				}
				this.verticalScrollPosition -= offset;
				this.finishScrolling();
			}
			
			if(offset != 0)
			{
				this._isScrolling = true;
				this.mouseChildren = false;
				//this.dispatchEvent(new ScrollEvent(ScrollBarDirection.VERTICAL, offset, this._verticalScrollPosition));
			}
		}
		
		private function stage_mouseUpHandler(event:MouseEvent):void
		{
			this.stage.removeEventListener(MouseEvent.MOUSE_UP, stage_mouseUpHandler);
			
			this._autoScrolling = true;
			if(this._verticalScrollPosition <= 0)
			{
				this._targetVerticalScrollPosition = 0;
				return;
			}
			else if(this._verticalScrollPosition >= this._maxVerticalScrollPosition)
			{
				this._targetVerticalScrollPosition = this._maxVerticalScrollPosition;
				return;
			}
			
			var distance:Number = this.mouseY - this._startMouseY;
			//this._targetVerticalScrollPosition = this._verticalScrollPosition - (distance * 0.5);
			var pixelsPerMS:Number = distance / (getTimer() - this._startTime); 
			var pixelsPerFrame:Number = 1.5 * (pixelsPerMS * 1000) / this.loaderInfo.frameRate;
			this._targetVerticalScrollPosition = this._verticalScrollPosition;
			while(Math.abs(pixelsPerFrame) >= 1) //there's probably an equation for this...
			{
				this._targetVerticalScrollPosition -= pixelsPerFrame;
				if(this._targetVerticalScrollPosition < 0 || this._targetVerticalScrollPosition > this._maxVerticalScrollPosition)
				{
					pixelsPerFrame /= 2;
					this._targetVerticalScrollPosition += pixelsPerFrame;
				}
				pixelsPerFrame *= (1 - FRICTION);
			}
		}
	}
}