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
package org.josht.foxhole.controls
{
	import com.gskinner.motion.GTween;
	import com.gskinner.motion.easing.Exponential;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TouchEvent;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.ui.Mouse;
	import flash.ui.Multitouch;
	import flash.ui.MultitouchInputMode;
	import flash.utils.getTimer;
	
	import org.josht.foxhole.core.FoxholeControl;
	import org.josht.utils.math.clamp;
	import org.osflash.signals.ISignal;
	import org.osflash.signals.Signal;
	
	/**
	 * Allows horizontal and vertical scrolling of a viewport (which may be any
	 * Starling display object). Will react to the <code>onResize</code> signal
	 * dispatched by Foxhole controls.
	 */
	public class Scroller extends FoxholeControl
	{
		/**
		 * The scroller may scroll.
		 */
		public static const SCROLL_POLICY_AUTO:String = "auto";
		
		/**
		 * The scroll does not scroll at all.
		 */
		public static const SCROLL_POLICY_OFF:String = "off";
		
		/**
		 * Aligns the viewport to the left, if the viewport's width is smaller
		 * than the scroller's width.
		 */
		public static const HORIZONTAL_ALIGN_LEFT:String = "left";
		
		/**
		 * Aligns the viewport to the center, if the viewport's width is smaller
		 * than the scroller's width.
		 */
		public static const HORIZONTAL_ALIGN_CENTER:String = "center";
		
		/**
		 * Aligns the viewport to the right, if the viewport's width is smaller
		 * than the scroller's width.
		 */
		public static const HORIZONTAL_ALIGN_RIGHT:String = "right";
		
		/**
		 * Aligns the viewport to the top, if the viewport's height is smaller
		 * than the scroller's height.
		 */
		public static const VERTICAL_ALIGN_TOP:String = "top";
		
		/**
		 * Aligns the viewport to the middle, if the viewport's height is smaller
		 * than the scroller's height.
		 */
		public static const VERTICAL_ALIGN_MIDDLE:String = "middle";
		
		/**
		 * Aligns the viewport to the bottom, if the viewport's height is smaller
		 * than the scroller's height.
		 */
		public static const VERTICAL_ALIGN_BOTTOM:String = "bottom";
		
		/**
		 * Flag to indicate that the clipping has changed.
		 */
		public static const INVALIDATION_FLAG_CLIPPING:String = "clipping";
		
		/**
		 * @private
		 * The minimum physical distance (in inches) that a touch must move
		 * before the scroller starts scrolling.
		 */
		private static const MINIMUM_DRAG_DISTANCE:Number = 0.04;
		
		/**
		 * @private
		 * The friction applied every frame when the scroller is "thrown".
		 */
		private static const FRICTION:Number = 0.9925;
		
		/**
		 * Constructor.
		 */
		public function Scroller()
		{
			super();
			
			this._viewPortWrapper = new Sprite();
			this.addChild(this._viewPortWrapper);
		}
		
		private var _touchPointID:int = -1;
		private var _startTouchX:Number;
		private var _startTouchY:Number;
		private var _startHorizontalScrollPosition:Number;
		private var _startVerticalScrollPosition:Number;
		private var _previousTouchTime:int;
		private var _previousTouchX:Number;
		private var _previousTouchY:Number;
		private var _velocityX:Number;
		private var _velocityY:Number;
		private var _previousVelocityX:Number;
		private var _previousVelocityY:Number;
		
		private var _horizontalAutoScrollTween:GTween;
		private var _verticalAutoScrollTween:GTween;
		private var _isDraggingHorizontally:Boolean = false;
		private var _isDraggingVertically:Boolean = false;
		
		private var _viewPortWrapper:Sprite;
		
		/**
		 * @private
		 */
		private var _viewPort:DisplayObject;
		
		/**
		 * The display object displayed and scrolled within the Scroller.
		 */
		public function get viewPort():DisplayObject
		{
			return this._viewPort;
		}
		
		/**
		 * @private
		 */
		public function set viewPort(value:DisplayObject):void
		{
			if(this._viewPort == value)
			{
				return;
			}
			this.invalidate(INVALIDATION_FLAG_DATA);
			if(this._viewPort)
			{
				if(this._viewPort is FoxholeControl)
				{
					FoxholeControl(this._viewPort).onResize.remove(viewPort_onResize);
				}
				this._viewPortWrapper.removeChild(this._viewPort);
			}
			this._viewPort = value;
			if(this._viewPort)
			{
				if(this._viewPort is FoxholeControl)
				{
					FoxholeControl(this._viewPort).onResize.add(viewPort_onResize);
				}
				this._viewPortWrapper.addChild(this._viewPort);
			}
			this.invalidate(INVALIDATION_FLAG_DATA);
		}
		
		/**
		 * @private
		 */
		private var _horizontalScrollPosition:Number = 0;
		
		/**
		 * The number of pixels the scroller has been scrolled horizontally (on
		 * the x-axis).
		 */
		public function get horizontalScrollPosition():Number
		{
			return this._horizontalScrollPosition;
		}
		
		/**
		 * @private
		 */
		public function set horizontalScrollPosition(value:Number):void
		{
			if(this._horizontalScrollPosition == value)
			{
				return;
			}
			this._horizontalScrollPosition = value;
			this.invalidate(INVALIDATION_FLAG_SCROLL);
			this._onScroll.dispatch(this);
		}
		
		/**
		 * @private
		 */
		private var _maxHorizontalScrollPosition:Number = 0;
		
		/**
		 * The maximum number of pixels the scroller may be scrolled
		 * horizontally (on the x-axis). This value is automatically calculated
		 * based on the width of the viewport. The <code>horizontalScrollPosition</code>
		 * property may have a higher value than the maximum due to elastic
		 * edges. However, once the user stops interacting with the scroller,
		 * it will automatically animate back to the maximum (or minimum, if
		 * below 0).
		 */
		public function get maxHorizontalScrollPosition():Number
		{
			return this._maxHorizontalScrollPosition;
		}
		
		/**
		 * @private
		 */
		private var _horizontalScrollPolicy:String = SCROLL_POLICY_AUTO;
		
		/**
		 * Determines whether the scroller may scroll horizontally (on the
		 * x-axis) or not.
		 */
		public function get horizontalScrollPolicy():String
		{
			return this._horizontalScrollPolicy;
		}
		
		/**
		 * @private
		 */
		public function set horizontalScrollPolicy(value:String):void
		{
			if(this._horizontalScrollPolicy == value)
			{
				return;
			}
			this._horizontalScrollPolicy = value;
			this.invalidate(INVALIDATION_FLAG_SCROLL);
		}
		
		/**
		 * @private
		 */
		protected var _horizontalAlign:String = HORIZONTAL_ALIGN_LEFT;
		
		/**
		 * If the viewport's width is less than the scroller's width, it will
		 * be aligned to the left, center, or right of the scroller.
		 * 
		 * @see HORIZONTAL_ALIGN_LEFT
		 * @see HORIZONTAL_ALIGN_CENTER
		 * @see HORIZONTAL_ALIGN_RIGHT
		 */
		public function get horizontalAlign():String
		{
			return _horizontalAlign;
		}
		
		/**
		 * @private
		 */
		public function set horizontalAlign(value:String):void
		{
			if(this._horizontalAlign == value)
			{
				return;
			}
			this._horizontalAlign = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}
		
		/**
		 * @private
		 */
		private var _verticalScrollPosition:Number = 0;
		
		/**
		 * The number of pixels the scroller has been scrolled vertically (on
		 * the y-axis).
		 */
		public function get verticalScrollPosition():Number
		{
			return this._verticalScrollPosition;
		}
		
		/**
		 * @private
		 */
		public function set verticalScrollPosition(value:Number):void
		{
			if(this._verticalScrollPosition == value)
			{
				return;
			}
			this._verticalScrollPosition = value;
			this.invalidate(INVALIDATION_FLAG_SCROLL);
			this._onScroll.dispatch(this);
		}
		
		/**
		 * @private
		 */
		private var _maxVerticalScrollPosition:Number = 0;
		
		/**
		 * The maximum number of pixels the scroller may be scrolled vertically
		 * (on the y-axis). This value is automatically calculated based on the 
		 * height of the viewport. The <code>verticalScrollPosition</code>
		 * property may have a higher value than the maximum due to elastic
		 * edges. However, once the user stops interacting with the scroller,
		 * it will automatically animate back to the maximum (or minimum, if
		 * below 0).
		 */
		public function get maxVerticalScrollPosition():Number
		{
			return this._maxVerticalScrollPosition;
		}
		
		/**
		 * @private
		 */
		private var _verticalScrollPolicy:String = SCROLL_POLICY_AUTO;
		
		/**
		 * Determines whether the scroller may scroll vertically (on the
		 * y-axis) or not.
		 */
		public function get verticalScrollPolicy():String
		{
			return this._verticalScrollPolicy;
		}
		
		/**
		 * @private
		 */
		public function set verticalScrollPolicy(value:String):void
		{
			if(this._verticalScrollPolicy == value)
			{
				return;
			}
			this._verticalScrollPolicy = value;
			this.invalidate(INVALIDATION_FLAG_SCROLL);
		}
		
		/**
		 * @private
		 */
		protected var _verticalAlign:String = VERTICAL_ALIGN_TOP;
		
		/**
		 * If the viewport's height is less than the scroller's height, it will
		 * be aligned to the top, middle, or bottom of the scroller.
		 * 
		 * @see VERTICAL_ALIGN_TOP
		 * @see VERTICAL_ALIGN_MIDDLE
		 * @see VERTICAL_ALIGN_BOTTOM
		 */
		public function get verticalAlign():String
		{
			return _verticalAlign;
		}
		
		/**
		 * @private
		 */
		public function set verticalAlign(value:String):void
		{
			if(this._verticalAlign == value)
			{
				return;
			}
			this._verticalAlign = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}
		
		/**
		 * @private
		 */
		private var _clipContent:Boolean = false;
		
		/**
		 * If true, the viewport will be clipped to the scroller's bounds. In
		 * other words, anything appearing outside the scroller's bounds will
		 * not be visible.
		 * 
		 * <p>To improve performance, turn off clipping and place other display
		 * objects over the edges of the scroller to hide the content that
		 * bleeds outside of the scroller's bounds.</p>
		 */
		public function get clipContent():Boolean
		{
			return this._clipContent;
		}
		
		/**
		 * @private
		 */
		public function set clipContent(value:Boolean):void
		{
			if(this._clipContent == value)
			{
				return;
			}
			this._clipContent = value;
			this.invalidate(INVALIDATION_FLAG_CLIPPING);
		}
		
		/**
		 * @private
		 */
		protected var _onScroll:Signal = new Signal(Scroller);
		
		/**
		 * Dispatched when the scroller scrolls in either direction.
		 */
		public function get onScroll():ISignal
		{
			return this._onScroll;
		}
		
		/**
		 * @private
		 */
		override protected function initialize():void
		{
			this.addEventListener(Event.REMOVED_FROM_STAGE, removedFromStageHandler);
			//if(!Multitouch.supportsTouchEvents || Multitouch.inputMode != MultitouchInputMode.TOUCH_POINT)
			{
				this.addEventListener(MouseEvent.MOUSE_DOWN, touchBeginHandler);
			}
			/*else
			{
				this.addEventListener(TouchEvent.TOUCH_BEGIN, touchBeginHandler);
			}*/
		}
		
		/**
		 * @private
		 */
		override protected function draw():void
		{
			const sizeInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_SIZE);
			const dataInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_DATA);
			const scrollInvalid:Boolean = dataInvalid || this.isInvalid(INVALIDATION_FLAG_SCROLL);
			const clippingInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_CLIPPING);
			
			if(sizeInvalid)
			{
				this.graphics.clear();
				this.graphics.beginFill(0xff00ff, 0);
				this.graphics.drawRect(0, 0, this._width, this._height);
				this.graphics.endFill();
			}
			
			if(sizeInvalid || dataInvalid)
			{
				//stop animating. this is a serious change.
				if(this._horizontalAutoScrollTween)
				{
					this._horizontalAutoScrollTween.paused = true;
					this._horizontalAutoScrollTween = null;
				}
				if(this._verticalAutoScrollTween)
				{
					this._verticalAutoScrollTween.paused = true;
					this._verticalAutoScrollTween = null;
				}
				this._touchPointID = -1;
				this._velocityX = this._previousVelocityX = 0;
				this._velocityY = this._previousVelocityY = 0;
				if(this._viewPort)
				{
					this._maxHorizontalScrollPosition = Math.max(0, this._viewPort.width - this._width);
					this._maxVerticalScrollPosition = Math.max(0, this._viewPort.height - this._height);
				}
				else
				{
					this._maxHorizontalScrollPosition = 0;
					this._maxVerticalScrollPosition = 0;
				}
				this._horizontalScrollPosition = clamp(this._horizontalScrollPosition, 0, this._maxHorizontalScrollPosition);
				this._verticalScrollPosition = clamp(this._verticalScrollPosition, 0, this._maxVerticalScrollPosition);
			}
			
			if(sizeInvalid || dataInvalid || scrollInvalid || clippingInvalid)
			{
				this.scrollContent();
			}
		}
		
		/**
		 * @private
		 */
		protected function scrollContent():void
		{	
			var offsetX:Number = 0;
			var offsetY:Number = 0;
			if(this._maxHorizontalScrollPosition == 0)
			{
				if(this._horizontalAlign == HORIZONTAL_ALIGN_CENTER)
				{
					offsetX = (this._width - this._viewPort.width) / 2;
				}
				else if(this._horizontalAlign == HORIZONTAL_ALIGN_RIGHT)
				{
					offsetX = this._width - this._viewPort.width;	
				}
			}
			if(this._maxVerticalScrollPosition == 0)
			{
				if(this._verticalAlign == VERTICAL_ALIGN_MIDDLE)
				{
					offsetY = (this._height - this._viewPort.height) / 2;
				}
				else if(this._verticalAlign == VERTICAL_ALIGN_BOTTOM)
				{
					offsetY = this._height - this._viewPort.height;	
				}
			}
			if(this._clipContent)
			{
				this._viewPortWrapper.x = 0;
				this._viewPortWrapper.y = 0;
				if(!this._viewPortWrapper.scrollRect)
				{
					this._viewPortWrapper.scrollRect = new Rectangle();
				}
				
				const scrollRect:Rectangle = this._viewPortWrapper.scrollRect;
				scrollRect.width = this._width;
				scrollRect.height = this._height;
				scrollRect.x = this._horizontalScrollPosition - offsetX;
				scrollRect.y = this._verticalScrollPosition - offsetY;
				this._viewPortWrapper.scrollRect = scrollRect;
			}
			else
			{
				if(this._viewPortWrapper.scrollRect)
				{
					this._viewPortWrapper.scrollRect = null;
				}
				this._viewPortWrapper.x = -this._horizontalScrollPosition + offsetX;
				this._viewPortWrapper.y = -this._verticalScrollPosition + offsetY;
			}
		}
		
		/**
		 * @private
		 */
		protected function updateHorizontalScrollFromTouchPosition(touchX:Number):void
		{
			const offset:Number = this._startTouchX - touchX;
			var position:Number = this._startHorizontalScrollPosition + offset;
			if(this._horizontalScrollPosition < 0)
			{
				position /= 2;
			}
			else if(position > this._maxHorizontalScrollPosition)
			{
				position -= (position - this._maxHorizontalScrollPosition) / 2;
			}
			
			this.horizontalScrollPosition = position;
		}
		
		/**
		 * @private
		 */
		protected function updateVerticalScrollFromTouchPosition(touchY:Number):void
		{
			const offset:Number = this._startTouchY - touchY;
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
		
		/**
		 * @private
		 */
		private function finishScrollingHorizontally():void
		{
			var targetHorizontalScrollPosition:Number = NaN;
			if(this._horizontalScrollPosition < 0)
			{
				targetHorizontalScrollPosition = 0;
			}
			else if(this._horizontalScrollPosition > this._maxHorizontalScrollPosition)
			{
				targetHorizontalScrollPosition = this._maxHorizontalScrollPosition;
			}
			
			this._isDraggingHorizontally = false;
			if(this._horizontalAutoScrollTween)
			{
				this._horizontalAutoScrollTween.paused = false;
				this._horizontalAutoScrollTween = null;
			}
			if(!isNaN(targetHorizontalScrollPosition))
			{
				this._horizontalAutoScrollTween = new GTween(this, 0.24,
				{
					horizontalScrollPosition: targetHorizontalScrollPosition
				},
				{
					ease: Exponential.easeOut,
					onComplete: horizontalAutoScrollTween_onComplete
				});
			}
		}
		
		/**
		 * @private
		 */
		private function finishScrollingVertically():void
		{
			var targetVerticalScrollPosition:Number = NaN;
			if(this._verticalScrollPosition < 0)
			{
				targetVerticalScrollPosition = 0;
			}
			else if(this._verticalScrollPosition > this._maxVerticalScrollPosition)
			{
				targetVerticalScrollPosition = this._maxVerticalScrollPosition;
			}
			
			this._isDraggingVertically = false;
			if(this._verticalAutoScrollTween)
			{
				this._verticalAutoScrollTween.paused = false;
				this._verticalAutoScrollTween = null;
			}
			if(!isNaN(targetVerticalScrollPosition))
			{
				this._verticalAutoScrollTween = new GTween(this, 0.24,
				{
					verticalScrollPosition: targetVerticalScrollPosition
				},
				{
					ease: Exponential.easeOut,
					onComplete: verticalAutoScrollTween_onComplete
				});
			}
		}
		
		/**
		 * @private
		 */
		protected function throwHorizontally(pixelsPerMS:Number):void
		{
			const frameRate:int = this.stage.frameRate;
			var pixelsPerFrame:Number = (1000 * pixelsPerMS) / frameRate;
			var targetHorizontalScrollPosition:Number = this._horizontalScrollPosition;
			var frameCount:int = 0;
			while(Math.floor(Math.abs(pixelsPerFrame)) > 0)
			{
				targetHorizontalScrollPosition -= pixelsPerFrame;
				if(targetHorizontalScrollPosition < 0 || targetHorizontalScrollPosition > this._maxHorizontalScrollPosition)
				{
					pixelsPerFrame *= 0.5;
					targetHorizontalScrollPosition += pixelsPerFrame;
				}
				pixelsPerFrame *= FRICTION;
				frameCount++;
			}
			
			if(this._horizontalAutoScrollTween)
			{
				this._horizontalAutoScrollTween.paused = false;
				this._horizontalAutoScrollTween = null;
			}
			this._horizontalAutoScrollTween = new GTween(this, frameCount / frameRate,
			{
				horizontalScrollPosition: targetHorizontalScrollPosition
			},
			{
				ease: Exponential.easeOut,
				onComplete: horizontalAutoScrollTween_onComplete
			});
		}
		
		/**
		 * @private
		 */
		protected function throwVertically(pixelsPerMS:Number):void
		{
			const frameRate:int = this.stage.frameRate;
			var pixelsPerFrame:Number = (1000 * pixelsPerMS) / frameRate;
			var targetVerticalScrollPosition:Number = this._verticalScrollPosition;
			var frameCount:int = 0;
			while(Math.floor(Math.abs(pixelsPerFrame)) > 0)
			{
				targetVerticalScrollPosition -= pixelsPerFrame;
				if(targetVerticalScrollPosition < 0 || targetVerticalScrollPosition > this._maxVerticalScrollPosition)
				{
					pixelsPerFrame *= 0.5;
					targetVerticalScrollPosition += pixelsPerFrame;
				}
				pixelsPerFrame *= FRICTION;
				frameCount++;
			}
			
			if(this._verticalAutoScrollTween)
			{
				this._verticalAutoScrollTween.paused = false;
				this._verticalAutoScrollTween = null;
			}
			this._verticalAutoScrollTween = new GTween(this, frameCount / frameRate,
			{
				verticalScrollPosition: targetVerticalScrollPosition
			},
			{
				ease: Exponential.easeOut,
				onComplete: verticalAutoScrollTween_onComplete
			});
		}
		
		/**
		 * @private
		 */
		protected function viewPort_onResize(viewPort:FoxholeControl):void
		{
			this.invalidate(INVALIDATION_FLAG_DATA);
		}
		
		/**
		 * @private
		 */
		protected function horizontalAutoScrollTween_onComplete(tween:GTween):void
		{
			if(this._horizontalAutoScrollTween == tween)
			{
				this._horizontalAutoScrollTween = null;
				this.finishScrollingHorizontally();
			}
		}
		
		/**
		 * @private
		 */
		protected function verticalAutoScrollTween_onComplete(tween:GTween):void
		{
			if(this._verticalAutoScrollTween == tween)
			{
				this._verticalAutoScrollTween = null;
				this.finishScrollingVertically();
			}
		}
		
		/**
		 * @private
		 */
		protected function touchBeginHandler(event:Event):void
		{
			if(!this._isEnabled)
			{
				return;
			}
			if(this._touchPointID >= 0)
			{
				return;
			}
			
			if(this._horizontalAutoScrollTween)
			{
				this._horizontalAutoScrollTween.paused = true;
				this._horizontalAutoScrollTween = null
			}
			if(this._verticalAutoScrollTween)
			{
				this._verticalAutoScrollTween.paused = true;
				this._verticalAutoScrollTween = null
			}
			
			const stageX:Number = (event is TouchEvent) ? TouchEvent(event).stageX : MouseEvent(event).stageX;
			const stageY:Number = (event is TouchEvent) ? TouchEvent(event).stageY : MouseEvent(event).stageY;
			this._velocityX = this._previousVelocityX = 0;
			this._velocityY = this._previousVelocityY = 0;
			this._previousTouchTime = getTimer();
			this._previousTouchX = this._startTouchX = stageX;
			this._previousTouchY = this._startTouchY = stageY;
			this._startHorizontalScrollPosition = this._horizontalScrollPosition;
			this._startVerticalScrollPosition = this._verticalScrollPosition;
			this._isDraggingHorizontally = false;
			this._isDraggingVertically = false;
			
			if(event is TouchEvent)
			{
				this._touchPointID = TouchEvent(event).touchPointID;
				this.stage.addEventListener(TouchEvent.TOUCH_MOVE, stage_touchMoveHandler);
				this.stage.addEventListener(TouchEvent.TOUCH_END, stage_touchEndHandler);
			}
			else
			{
				this.stage.addEventListener(MouseEvent.MOUSE_MOVE, stage_touchMoveHandler);
				this.stage.addEventListener(MouseEvent.MOUSE_UP, stage_touchEndHandler);
			}
		}
		
		private function stage_touchMoveHandler(event:Event):void
		{
			if(event is TouchEvent && TouchEvent(event).touchPointID != this._touchPointID)
			{
				return;
			}
			const stageX:Number = (event is TouchEvent) ? TouchEvent(event).stageX : MouseEvent(event).stageX;
			const stageY:Number = (event is TouchEvent) ? TouchEvent(event).stageY : MouseEvent(event).stageY;
			
			const now:int = getTimer();
			const timeOffset:int = now - this._previousTouchTime;
			if(timeOffset > 0)
			{
				//we're keeping two velocity updates to improve accuracy
				this._previousVelocityX = this._velocityX;
				this._previousVelocityY = this._velocityY;
				this._velocityX = (stageX - this._previousTouchX) / timeOffset;
				this._velocityY = (stageY - this._previousTouchY) / timeOffset;
				this._previousTouchTime = now
				this._previousTouchX = stageX;
				this._previousTouchY = stageY;
			}
			const horizontalInchesMoved:Number = Math.abs(stageX - this._startTouchX) / Capabilities.screenDPI;
			const verticalInchesMoved:Number = Math.abs(stageY - this._startTouchY) / Capabilities.screenDPI;
			if(this._horizontalScrollPolicy != SCROLL_POLICY_OFF && !this._isDraggingHorizontally && horizontalInchesMoved >= MINIMUM_DRAG_DISTANCE)
			{
				this._isDraggingHorizontally = true;
			}
			if(this._verticalScrollPolicy != SCROLL_POLICY_OFF && !this._isDraggingVertically && verticalInchesMoved >= MINIMUM_DRAG_DISTANCE)
			{
				this._isDraggingVertically = true;
			}
			if(this._isDraggingHorizontally && !this._horizontalAutoScrollTween)
			{
				this.updateHorizontalScrollFromTouchPosition(stageX);
			}
			if(this._isDraggingVertically && !this._verticalAutoScrollTween)
			{
				this.updateVerticalScrollFromTouchPosition(stageY);
			}
		}
		
		private function stage_touchEndHandler(event:Event):void
		{
			if(event is TouchEvent && TouchEvent(event).touchPointID != this._touchPointID)
			{
				return;
			}
			
			this._touchPointID = -1;
			this.stage.removeEventListener(MouseEvent.MOUSE_MOVE, stage_touchMoveHandler);
			this.stage.removeEventListener(MouseEvent.MOUSE_UP, stage_touchEndHandler);
			this.stage.removeEventListener(TouchEvent.TOUCH_MOVE, stage_touchMoveHandler);
			this.stage.removeEventListener(TouchEvent.TOUCH_END, stage_touchEndHandler);
			
			var isFinishingHorizontally:Boolean = false;
			var isFinishingVertically:Boolean = false;
			if(this._horizontalScrollPosition < 0 || this._horizontalScrollPosition > this._maxHorizontalScrollPosition)
			{
				isFinishingHorizontally = true;
				this.finishScrollingHorizontally();
			}
			if(this._verticalScrollPosition < 0 || this._verticalScrollPosition > this._maxVerticalScrollPosition)
			{
				isFinishingVertically = true;
				this.finishScrollingVertically();
			}
			if(isFinishingHorizontally && isFinishingVertically)
			{
				return;
			}
			
			if(!isFinishingHorizontally && this._horizontalScrollPolicy != SCROLL_POLICY_OFF)
			{
				//take the average for more accuracy
				this.throwHorizontally((this._velocityX + this._previousVelocityX) / 2);
			}
			
			if(!isFinishingVertically && this._verticalScrollPolicy != SCROLL_POLICY_OFF)
			{
				this.throwVertically((this._velocityY + this._previousVelocityY) / 2);
			}
			
		}
		
		/**
		 * @private
		 */
		private function removedFromStageHandler(event:Event):void
		{
			this._touchPointID = -1;
			this._velocityX = this._previousVelocityX = 0;
			this._velocityY = this._previousVelocityY = 0;
			if(this._verticalAutoScrollTween)
			{
				this._verticalAutoScrollTween.paused = true;
				this._verticalAutoScrollTween = null;
			}
			if(this._horizontalAutoScrollTween)
			{
				this._horizontalAutoScrollTween.paused = true;
				this._horizontalAutoScrollTween = null;
			}
			
			//if we stopped the animation while the list was outside the scroll
			//bounds, then let's account for that
			this._horizontalScrollPosition = clamp(this._horizontalScrollPosition, 0, this._maxHorizontalScrollPosition);
			this._verticalScrollPosition = clamp(this._verticalScrollPosition, 0, this._maxVerticalScrollPosition);
		}
	}
}