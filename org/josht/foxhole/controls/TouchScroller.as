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
	import com.gskinner.motion.GTween;
	import com.gskinner.motion.easing.Bounce;
	import com.gskinner.motion.easing.Sine;
	
	import fl.controls.ScrollPolicy;
	import fl.core.InvalidationType;
	import fl.core.UIComponent;
	import fl.video.ReconnectClient;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.system.System;
	import flash.utils.getTimer;
	
	import org.josht.foxhole.core.FrameTicker;
	
	/**
	 * Dispatched when horizontalScrollPosition, verticalScrollPosition,
	 * maxHorizontalScrollPosition, or maxVerticalScrollPosition changes.
	 */
	[Event(name="scroll",type="flash.events.Event")]
	
	/**
	 * A chrome-less container for touch-based scrolling of content. Supports
	 * elastic edges (the user can over-scroll, and the content will
	 * automatically bounce back to the edge) and flick gestures to throw
	 * content.
	 * 
	 * @author Josh Tynjala
	 */
	public class TouchScroller extends UIComponent
	{
		private static const DEFAULT_FRICTION_COEFFICIENT:Number = 0.1;
		
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
			if(this._clipContent == value)
			{
				return;
			}
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
		private var _lastTime:int;
		private var _lastMouseX:Number;
		private var _lastMouseY:Number;
		private var _lastVelocityX:Number;
		private var _lastVelocityY:Number;
		private var _startHorizontalScrollPosition:Number;
		private var _startVerticalScrollPosition:Number;
		
		private var _autoScrolling:Boolean = false;
		
		private var _fling:GTween;
		
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
			this.dispatchEvent(new Event(Event.SCROLL));
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
			this.dispatchEvent(new Event(Event.SCROLL));
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
		
		private var _scrollFrictionCoefficient:Number = DEFAULT_FRICTION_COEFFICIENT;

		public function get scrollFrictionCoefficient():Number
		{
			return this._scrollFrictionCoefficient;
		}

		public function set scrollFrictionCoefficient(value:Number):void
		{
			this._scrollFrictionCoefficient = value;
		}
		
		private var _hasElasticEdges:Boolean = true;

		public function get hasElasticEdges():Boolean
		{
			return this._hasElasticEdges;
		}

		public function set hasElasticEdges(value:Boolean):void
		{
			this._hasElasticEdges = value;
		}

		override protected function configUI():void
		{
			super.configUI();
			
			this._width = 320;
			this._height = 320;
			
			this._contentContainer = new Sprite();
			this.addChild(this._contentContainer);
		}
		
		override protected function draw():void
		{
			var scrollInvalid:Boolean = this.isInvalid(InvalidationType.SCROLL);
			var sizeInvalid:Boolean = this.isInvalid(InvalidationType.SIZE);
			
			if(sizeInvalid)
			{
				this.updateSize();
			}
			
			if(scrollInvalid || sizeInvalid)
			{
				this.updateScrollPosition();
			}
			
			super.draw();
		}
		
		private function updateSize():void
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
				this._contentContainer.x = 0;
				this._contentContainer.y = 0;
			}
			else if(this._contentContainer.scrollRect)
			{
				this._contentContainer.scrollRect = null;
			}
			
			//draw a transparent background so that we can catch the mouse
			this.graphics.clear();
			this.graphics.beginFill(0xff00ff, 0);
			this.graphics.drawRect(0, 0, this._width, this._height);
			this.graphics.endFill();
		}
		
		private function updateScrollPosition():void
		{
			if(!this._content)
			{
				return;
			}
			
			var oldMaxHorizontalScrollPosition:Number = this._maxHorizontalScrollPosition;
			var oldMaxVerticalScrollPosition:Number = this._maxVerticalScrollPosition;
			this._maxHorizontalScrollPosition = Math.max(0, this._content.width - this._width);
			this._maxVerticalScrollPosition = Math.max(0, this._content.height - this._height);
			if(this.clipContent)
			{
				var scrollRect:Rectangle = this._contentContainer.scrollRect;
				scrollRect.x = this._horizontalScrollPosition;
				scrollRect.y = this._verticalScrollPosition;
				this._contentContainer.scrollRect = scrollRect;
			}
			else
			{
				this._contentContainer.x = -this._horizontalScrollPosition;
				this._contentContainer.y = -this._verticalScrollPosition;
			}
			
			if(oldMaxHorizontalScrollPosition != this._maxHorizontalScrollPosition ||
				oldMaxVerticalScrollPosition != this._maxVerticalScrollPosition)
			{
				this.dispatchEvent(new Event(Event.SCROLL));
			}
		}
		
		private function calculateTargetScrollPosition(scrollPosition:Number, maxScrollPosition:Number, velocity:Number):FlingResult
		{
			const deceleration:Number = (velocity < 0 ? -1 : 1) * 386 * Capabilities.screenDPI * this._scrollFrictionCoefficient;
			
			var targetScrollPosition:Number = scrollPosition;
			var duration:Number = 0.25;
			if(scrollPosition < 0)
			{
				targetScrollPosition = 0;
			}
			else if(scrollPosition > maxScrollPosition)
			{
				targetScrollPosition = maxScrollPosition;
			}
			else if(velocity != 0)
			{
				duration = velocity / deceleration;
				var distance:Number = (velocity * duration) - (deceleration * duration * duration) / 2;
				targetScrollPosition = scrollPosition + distance;
				
				if(targetScrollPosition < 0)
				{
					duration *= (1 - (targetScrollPosition / distance));
					targetScrollPosition = 0;
				}
				else if(targetScrollPosition > maxScrollPosition)
				{
					duration *= (1 - (targetScrollPosition - maxScrollPosition) / distance);
					targetScrollPosition = maxScrollPosition;
				}
			}
			
			return new FlingResult(duration, targetScrollPosition);
		}
		
		private function onTick():void
		{
			var now:int = getTimer();
			if(this._horizontalScrollPolicy != ScrollPolicy.OFF)
			{
				var offsetX:Number = this._startMouseX - this.mouseX;
				var positionX:Number = this._startHorizontalScrollPosition + offsetX;
				if(positionX < 0)
				{
					if(this._hasElasticEdges)
					{
						positionX /= 3;
					}
					else
					{
						positionX = 0;
					}
				}
				else if(positionX > this._maxHorizontalScrollPosition)
				{
					if(this._hasElasticEdges)
					{
						positionX -= (positionX - this._maxHorizontalScrollPosition) / 3;
					}
					else
					{
						positionX = this._maxHorizontalScrollPosition;
					}
				}
				this.horizontalScrollPosition = positionX;
				this._lastVelocityX = (this._lastMouseX - this.mouseX) * (1000 / (now - this._lastTime));
				this._lastMouseX = this.mouseX;
			}
			
			if(this._verticalScrollPolicy != ScrollPolicy.OFF)
			{
				var offsetY:Number = this._startMouseY - this.mouseY;
				var positionY:Number = this._startVerticalScrollPosition + offsetY;
				if(positionY < 0)
				{
					if(this._hasElasticEdges)
					{
						positionY /= 3;
					}
					else
					{
						positionY = 0;
					}
				}
				else if(positionY > this._maxVerticalScrollPosition)
				{
					if(this._hasElasticEdges)
					{
						positionY -= (positionY - this._maxVerticalScrollPosition) / 3;
					}
					else
					{
						positionY = this._maxVerticalScrollPosition;
					}
				}
				this.verticalScrollPosition = positionY;
				this._lastVelocityY = (this._lastMouseY - this.mouseY) * (1000 / (now - this._lastTime));
				this._lastMouseY = this.mouseY;
			}
			this._lastTime = now;
		}
		
		private function fling_onComplete(tween:GTween):void
		{
			var targetHorizontalScrollPosition:Number = Math.min(Math.max(0, this._horizontalScrollPosition), this._maxHorizontalScrollPosition);
			var targetVerticalScrollPosition:Number = Math.min(Math.max(0, this._verticalScrollPosition), this._maxVerticalScrollPosition);
			
			if(targetHorizontalScrollPosition != this._horizontalScrollPosition ||
				targetVerticalScrollPosition != this._verticalScrollPosition)
			{
				this._fling = new GTween(this, 0.5,
				{
					horizontalScrollPosition: targetHorizontalScrollPosition,
					verticalScrollPosition: targetVerticalScrollPosition
				},
				{
					ease: Sine.easeOut
				});
			}
		}

		private function mouseDownHandler(event:MouseEvent):void
		{
			if(!this.enabled)
			{
				return;
			}
			
			if(this._fling)
			{
				this._fling.paused = true;
				this._fling = null;
			}
			
			this._startTime = getTimer();
			this._startMouseX = this.mouseX;
			this._startMouseY = this.mouseY;
			this._startHorizontalScrollPosition = this._horizontalScrollPosition;
			this._startVerticalScrollPosition = this._verticalScrollPosition;
			this._lastMouseX = this.mouseX;
			this._lastMouseY = this.mouseY;
			
			FrameTicker.addExitFrameCallback(onTick);
			
			this.stage.addEventListener(MouseEvent.MOUSE_UP, stage_mouseUpHandler, false, 0, true);
		}
		
		private function stage_mouseUpHandler(event:MouseEvent):void
		{
			this.stage.removeEventListener(MouseEvent.MOUSE_UP, stage_mouseUpHandler);
			FrameTicker.removeExitFrameCallback(onTick);
			
			var duration:Number = 0.25;
			var targetVerticalScrollPosition:Number = this._verticalScrollPosition;
			var targetHorizontalScrollPosition:Number = this._horizontalScrollPosition;
			this._autoScrolling = true;
			if(this._verticalScrollPolicy != ScrollPolicy.OFF)
			{
				var result:FlingResult = this.calculateTargetScrollPosition(this._verticalScrollPosition, this._maxVerticalScrollPosition, this._lastVelocityY);
				duration = Math.max(duration, result.duration);
				targetVerticalScrollPosition = result.position;
			}
			
			if(this._horizontalScrollPolicy != ScrollPolicy.OFF)
			{
				result = this.calculateTargetScrollPosition(this._horizontalScrollPosition, this._maxHorizontalScrollPosition, this._lastVelocityX);
				duration = Math.max(duration, result.duration);
				targetHorizontalScrollPosition = result.position;
			}
			
			if(targetVerticalScrollPosition != this._verticalScrollPosition ||
				targetHorizontalScrollPosition != this._horizontalScrollPosition)
			{
				this._fling = new GTween(this, duration,
				{
					horizontalScrollPosition: targetHorizontalScrollPosition,
					verticalScrollPosition: targetVerticalScrollPosition
				},
				{
					ease: Sine.easeOut,
					onComplete: fling_onComplete
				});
			}
			
		}
	}
}

class FlingResult
{
	public function FlingResult(duration:Number = 0, position:Number = 0)
	{
		this.duration = duration;
		this.position = position;
	}
	
	public var duration:Number;
	public var position:Number;
}