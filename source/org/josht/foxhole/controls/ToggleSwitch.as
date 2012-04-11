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
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TouchEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.ui.Mouse;
	import flash.ui.Multitouch;
	import flash.ui.MultitouchInputMode;
	
	import org.josht.foxhole.core.FoxholeControl;
	import org.josht.foxhole.core.IToggle;
	import org.josht.foxhole.text.BitmapFontTextFormat;
	import org.josht.text.BitmapFont;
	import org.josht.utils.display.annihilateMouse;
	import org.osflash.signals.ISignal;
	import org.osflash.signals.Signal;
	
	/**
	 * Similar to a light switch. May be selected or not, like a check box.
	 */
	public class ToggleSwitch extends FoxholeControl implements IToggle
	{
		/**
		 * @private
		 * The minimum physical distance (in inches) that a touch must move
		 * before the scroller starts scrolling.
		 */
		private static const MINIMUM_DRAG_DISTANCE:Number = 0.04;
		
		/**
		 * The ON and OFF labels will be aligned to the middle vertically,
		 * based on the full character height of the font.
		 */
		public static const LABEL_ALIGN_MIDDLE:String = "middle";
		
		/**
		 * The ON and OFF labels will be aligned to the middle vertically,
		 * based on only the baseline vlaue of the font. 
		 */
		public static const LABEL_ALIGN_BASELINE:String = "baseline";
		
		/**
		 * Constructor.
		 */
		public function ToggleSwitch()
		{
			super();
		}
		
		/**
		 * @private
		 */
		protected var thumb:Button;
		
		/**
		 * @private
		 */
		protected var onLabelField:Label;
		
		/**
		 * @private
		 */
		protected var offLabelField:Label;
		
		/**
		 * @private
		 */
		protected var _onSkin:DisplayObject;
		
		/**
		 * The background skin for the left side of the toggle switch, where the
		 * ON label is displayed.
		 */
		public function get onSkin():DisplayObject
		{
			return this._onSkin;
		}
		
		/**
		 * @private
		 */
		public function set onSkin(value:DisplayObject):void
		{
			if(this._onSkin == value)
			{
				return;
			}
			
			if(this._onSkin)
			{
				this.removeChild(this._onSkin);
			}
			this._onSkin = value;
			if(this._onSkin)
			{
				this._onSkin.scrollRect = null;
				this.onSkinOriginalWidth = this._onSkin.width;
				this.onSkinOriginalHeight = this._onSkin.height;
				this.onSkinOriginalScaleX = this._onSkin.scaleX;
				this.onSkinOriginalScaleY = this._onSkin.scaleY;
				this._onSkin.scrollRect = new Rectangle();
				annihilateMouse(this._onSkin, false);
				this.addChildAt(this._onSkin, 0);
			}
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}
		
		/**
		 * @private
		 */
		protected var _offSkin:DisplayObject;
		
		/**
		 * The background skin for the right side of the toggle switch, where
		 * the OFF label is displayed.
		 */
		public function get offSkin():DisplayObject
		{
			return this._offSkin;
		}
		
		/**
		 * @private
		 */
		public function set offSkin(value:DisplayObject):void
		{
			if(this._offSkin == value)
			{
				return;
			}
			
			if(this._offSkin)
			{
				this.removeChild(this._offSkin);
			}
			this._offSkin = value;
			if(this._offSkin)
			{
				this._offSkin.scrollRect = null;
				this.offSkinOriginalWidth = this._offSkin.width
				this.offSkinOriginalHeight = this._offSkin.height;
				this.offSkinOriginalScaleX = this._offSkin.scaleX;
				this.offSkinOriginalScaleY = this._offSkin.scaleY;
				this._offSkin.scrollRect = new Rectangle();
				annihilateMouse(this._offSkin, false);
				this.addChildAt(this._offSkin, 0);
			}
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}
		
		/**
		 * @private
		 */
		protected var _contentPadding:Number = 0;
		
		/**
		 * Space, in pixels, around the edges of the labels. The labels are
		 * scrolled during animations, and they will be cut off this many pixels
		 * from the edge of the toggle switch.
		 */
		public function get contentPadding():Number
		{
			return _contentPadding;
		}
		
		/**
		 * @private
		 */
		public function set contentPadding(value:Number):void
		{
			if(this._contentPadding == value)
			{
				return;
			}
			this._contentPadding = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}
		
		/**
		 * @private
		 */
		protected var _showLabels:Boolean = true;
		
		/**
		 * Determines if the labels should be drawn. The onSkin and offSkin
		 * backgrounds may include the text instead.
		 */
		public function get showLabels():Boolean
		{
			return _showLabels;
		}
		
		/**
		 * @private
		 */
		public function set showLabels(value:Boolean):void
		{
			if(this._showLabels == value)
			{
				return;
			}
			this._showLabels = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}
		
		/**
		 * @private
		 */
		private var _showThumb:Boolean = true;
		
		/**
		 * Determines if the thumb should be displayed. This stops interaction
		 * while still displaying the background.
		 */
		public function get showThumb():Boolean
		{
			return this._showThumb;
		}
		
		/**
		 * @private
		 */
		public function set showThumb(value:Boolean):void
		{
			if(this._showThumb == value)
			{
				return;
			}
			this._showThumb = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}
		
		/**
		 * @private
		 */
		protected var _defaultTextFormat:BitmapFontTextFormat;
		
		/**
		 * The text format used to display the labels, if no higher priority
		 * format is available. For the ON label, <code>onTextFormat</code>
		 * takes priority. For the OFF label, <code>offTextFormat</code> takes
		 * priority.
		 * 
		 * @see onTextFormat
		 * @see offTextFormat
		 */
		public function get defaultTextFormat():BitmapFontTextFormat
		{
			return this._defaultTextFormat;
		}
		
		/**
		 * @private
		 */
		public function set defaultTextFormat(value:BitmapFontTextFormat):void
		{
			this._defaultTextFormat = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}
		
		/**
		 * @private
		 */
		protected var _disabledTextFormat:BitmapFontTextFormat;
		
		/**
		 * The text format used to display the labels if the toggle switch is
		 * disabled. If <code>null</code>, then <code>defaultTextFormat</code>
		 * will be used instead.
		 */
		public function get disabledTextFormat():BitmapFontTextFormat
		{
			return this._disabledTextFormat;
		}
		
		/**
		 * @private
		 */
		public function set disabledTextFormat(value:BitmapFontTextFormat):void
		{
			this._disabledTextFormat = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}
		
		/**
		 * @private
		 */
		protected var _onTextFormat:BitmapFontTextFormat;
		
		/**
		 * The text format used to display the ON label. If <code>null</code>,
		 * then <code>defaultTextFormat</code> will be used instead.
		 */
		public function get onTextFormat():BitmapFontTextFormat
		{
			return this._onTextFormat;
		}
		
		/**
		 * @private
		 */
		public function set onTextFormat(value:BitmapFontTextFormat):void
		{
			this._onTextFormat = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}
		
		/**
		 * @private
		 */
		protected var _offTextFormat:BitmapFontTextFormat;
		
		/**
		 * The text format used to display the OFF label. If <code>null</code>,
		 * then <code>defaultTextFormat</code> will be used instead.
		 */
		public function get offTextFormat():BitmapFontTextFormat
		{
			return this._offTextFormat;
		}
		
		/**
		 * @private
		 */
		public function set offTextFormat(value:BitmapFontTextFormat):void
		{
			this._offTextFormat = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}
		
		/**
		 * @private
		 */
		private var _labelAlign:String = LABEL_ALIGN_BASELINE;
		
		/**
		 * The vertical alignment of the label.
		 */
		public function get labelAlign():String
		{
			return this._labelAlign;
		}
		
		/**
		 * @private
		 */
		public function set labelAlign(value:String):void
		{
			if(this._labelAlign == value)
			{
				return;
			}
			this._labelAlign = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}
		
		/**
		 * @private
		 */
		protected var onSkinOriginalWidth:Number = NaN;
		
		/**
		 * @private
		 */
		protected var onSkinOriginalHeight:Number = NaN;
		
		/**
		 * @private
		 */
		protected var onSkinOriginalScaleX:Number = NaN;
		
		/**
		 * @private
		 */
		protected var onSkinOriginalScaleY:Number = NaN;
		
		/**
		 * @private
		 */
		protected var offSkinOriginalWidth:Number = NaN;
		
		/**
		 * @private
		 */
		protected var offSkinOriginalHeight:Number = NaN;
		
		/**
		 * @private
		 */
		protected var offSkinOriginalScaleX:Number = NaN;
		/**
		 * @private
		 */
		protected var offSkinOriginalScaleY:Number = NaN;
		
		private var _backgroundBounds:Point;
		
		/**
		 * @private
		 */
		private var _isSelected:Boolean = false;
		
		/**
		 * Indicates if the toggle switch is selected (ON) or not (OFF).
		 */
		public function get isSelected():Boolean
		{
			return this._isSelected;
		}
		
		/**
		 * @private
		 */
		public function set isSelected(value:Boolean):void
		{
			//normally, we'd check to see if selected actually changed or not
			//but the animation is triggered by the draw cycle, so we always
			//need to invalidate. notice that the signal isn't dispatched
			//unless the value changes.
			const oldSelected:Boolean = this._isSelected;
			this._isSelected = value;
			this._isSelectionChangedByUser = false;
			this.invalidate(INVALIDATION_FLAG_DATA, INVALIDATION_FLAG_SELECTED);
			if(this._isSelected != oldSelected)
			{
				this._onChange.dispatch(this);
			}
		}
		
		/**
		 * @private
		 */
		private var _onText:String = "ON";
		
		/**
		 * The text to display in the ON label.
		 */
		public function get onText():String
		{
			return this._onText;
		}
		
		/**
		 * @private
		 */
		public function set onText(value:String):void
		{
			if(!value)
			{
				//don't allow null or undefined
				value = "";
			}
			if(this._onText == value)
			{
				return;
			}
			this._onText = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}
		
		/**
		 * @private
		 */
		private var _offText:String = "OFF";
		
		/**
		 * The text to display in the OFF label.
		 */
		public function get offText():String
		{
			return this._offText;
		}
		
		/**
		 * @private
		 */
		public function set offText(value:String):void
		{
			if(!value)
			{
				//don't allow null or undefined
				value = "";
			}
			if(this._offText == value)
			{
				return;
			}
			this._offText = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}
		
		private var _selectionChangeTween:GTween;
		
		private var _ignoreTapHandler:Boolean = false;
		private var _touchPointID:int = -1;
		private var _thumbStartX:Number;
		private var _touchStartX:Number;
		private var _isSelectionChangedByUser:Boolean = false;
		
		/**
		 * @private
		 */
		protected var _onChange:Signal = new Signal(ToggleSwitch);
		
		/**
		 * Dispatched when the selection changes.
		 */
		public function get onChange():ISignal
		{
			return this._onChange;
		}
		
		/**
		 * @private
		 */
		private var _thumbProperties:Object = {};
		
		/**
		 * A set of key/value pairs to be passed down to the toggle switch's
		 * thumb instance. The thumb is a Foxhole Button control.
		 */
		public function get thumbProperties():Object
		{
			return this._thumbProperties;
		}
		
		/**
		 * @private
		 */
		public function set thumbProperties(value:Object):void
		{
			if(this._thumbProperties == value)
			{
				return;
			}
			if(!value)
			{
				value = {};
			}
			this._thumbProperties = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}
		
		/**
		 * Sets a single property on the toggle switch's thumb instance. The
		 * thumb is a Foxhole Button control.
		 */
		public function setThumbProperty(propertyName:String, propertyValue:Object):void
		{
			this._thumbProperties[propertyName] = propertyValue;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function dispose():void
		{
			this._onChange.removeAll();
			super.dispose();
		}
		
		/**
		 * @private
		 */
		override protected function initialize():void
		{
			if(!this.offLabelField)
			{
				this.offLabelField = new Label();
				this.offLabelField.name = "foxhole-toggle-switch-off-label";
				this.offLabelField.scrollRect = new Rectangle();
				this.offLabelField.mouseEnabled = this.offLabelField.mouseChildren = false;
				this.addChild(this.offLabelField);
			}
			
			if(!this.onLabelField)
			{
				this.onLabelField = new Label();
				this.onLabelField.name = "foxhole-toggle-switch-on-label";
				this.onLabelField.scrollRect = new Rectangle();
				this.onLabelField.mouseEnabled = this.onLabelField.mouseChildren = false;
				this.addChild(this.onLabelField);
			}
			
			if(!this.thumb)
			{
				this.thumb = new Button();
				this.thumb.name = "foxhole-toggle-switch-thumb";
				this.thumb.label = "";
				this.thumb.keepDownStateOnRollOut = true;
				//if(!Multitouch.supportsTouchEvents || Multitouch.inputMode != MultitouchInputMode.TOUCH_POINT)
				{
					this.thumb.addEventListener(MouseEvent.MOUSE_DOWN, thumb_touchBeginHandler);
				}
				/*else
				{
					this.thumb.addEventListener(TouchEvent.TOUCH_BEGIN, thumb_touchBeginHandler);
				}*/
				this.addChild(this.thumb);
			}
			//if(!Multitouch.supportsTouchEvents || Multitouch.inputMode != MultitouchInputMode.TOUCH_POINT)
			{
				this.addEventListener(MouseEvent.CLICK, touchTapHandler);
			}
			/*else
			{
				this.addEventListener(TouchEvent.TOUCH_TAP, touchTapHandler);
			}*/
			this.addEventListener(Event.REMOVED_FROM_STAGE, removedFromStageHandler);
		}
		
		/**
		 * @private
		 */
		override protected function draw():void
		{
			const dataInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_DATA);
			const stylesInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STYLES);
			var sizeInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_SIZE);
			const stateInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STATE);
			
			if(stylesInvalid || stateInvalid)
			{
				this.refreshOnLabelStyles();
				this.refreshOffLabelStyles();
				this.refreshThumbProperties();
			}
			
			this.thumb.validate();
			
			var newWidth:Number = this._width;
			var newHeight:Number = this._height;
			if(isNaN(newWidth) || isNaN(newHeight))
			{
				if(isNaN(newWidth))
				{
					newWidth = this.onSkinOriginalWidth + this.offSkinOriginalWidth - this.thumb.width;
					sizeInvalid = true;
				}
				
				if(isNaN(newHeight))
				{
					newHeight = Math.max(this.onSkinOriginalHeight, this.offSkinOriginalHeight);
					sizeInvalid = true;
				}
				
				this.setSizeInternal(newWidth, newHeight, false);
			}
			
			if(stylesInvalid || sizeInvalid || stateInvalid)
			{
				this.scaleSkins();
				this.thumb.y = (this._height - this.thumb.height) / 2;
				this.drawLabels();
			}
			
			if(sizeInvalid || stylesInvalid || dataInvalid)
			{
				this.updateSelection();
			}
		}
		
		/**
		 * @private
		 */
		protected function updateSelection():void
		{
			var xPosition:Number = this._contentPadding;
			if(this._isSelected)
			{
				xPosition = this._width - this.thumb.width - this._contentPadding;
			}
			
			//stop the tween, no matter what
			if(this._selectionChangeTween)
			{
				this._selectionChangeTween.paused = true;
				this._selectionChangeTween = null;
			}
			
			if(this._isSelectionChangedByUser)
			{
				this._selectionChangeTween = new GTween(this.thumb, 0.15,
				{
					x: xPosition
				},
				{
					onChange: selectionTween_onChange,
					onComplete: selectionTween_onComplete
				});
			}
			else
			{
				this.thumb.x = xPosition;
			}
			this._isSelectionChangedByUser = false;
			
			//we want to be sure that the onLabel isn't visible behind the thumb
			//on init so that if we fade out the toggle switch alpha, on won't
			//suddenly appear due to the way that flash changes alpha values
			//of containers.
			this.updateScrollRects();
		}
		
		/**
		 * @private
		 */
		protected function refreshOnLabelStyles():void
		{	
			//no need to style the label field if there's no text to display
			if(!this._showLabels || !this._showThumb)
			{
				this.onLabelField.visible = false;
				return;
			}
			
			var format:BitmapFontTextFormat;
			if(!this._isEnabled)
			{
				format = this._disabledTextFormat;
			}
			if(!format && this._onTextFormat)
			{
				format = this._onTextFormat;
			}
			if(!format)
			{
				format = this._defaultTextFormat;
			}
			
			this.onLabelField.text = this._onText;
			if(format)
			{
				this.onLabelField.textFormat = format;
			}
			this.onLabelField.validate();
			this.onLabelField.visible = true;
		}
		
		/**
		 * @private
		 */
		protected function refreshOffLabelStyles():void
		{	
			//no need to style the label field if there's no text to display
			if(!this._showLabels || !this._showThumb)
			{
				this.offLabelField.visible = false;
				return;
			}
			
			var format:BitmapFontTextFormat;
			if(!this._isEnabled)
			{
				format = this._disabledTextFormat;
			}
			if(!format && this._offTextFormat)
			{
				format = this._offTextFormat;
			}
			if(!format)
			{
				format = this._defaultTextFormat;
			}
			
			this.offLabelField.text = this._offText;
			if(format)
			{
				this.offLabelField.textFormat = format;
			}
			this.offLabelField.validate();
			this.offLabelField.visible = true;
		}
		
		/**
		 * @private
		 */
		protected function refreshThumbProperties():void
		{
			for(var propertyName:String in this._thumbProperties)
			{
				if(this.thumb.hasOwnProperty(propertyName))
				{
					var propertyValue:Object = this._thumbProperties[propertyName];
					this.thumb[propertyName] = propertyValue;
				}
			}
			this.thumb.isEnabled = this._isEnabled;
			this.thumb.visible = this._showThumb;
		}
		
		/**
		 * @private
		 */
		private function scaleSkins():void
		{
			const skinScale:Number = this._height / Math.max(this.onSkinOriginalHeight, this.offSkinOriginalHeight);
			this.onSkin.scaleX = this.onSkinOriginalScaleX * skinScale;
			this.onSkin.scaleY = this.onSkinOriginalScaleY * skinScale;
			this.offSkin.scaleX = this.offSkinOriginalScaleX * skinScale;
			this.offSkin.scaleY = this.offSkinOriginalScaleY * skinScale;
			this.offSkin.y = this.onSkin.y = 0;
		}
		
		/**
		 * @private
		 */
		private function drawLabels():void
		{
			const maxLabelWidth:Number = Math.max(0, this._width - this.thumb.width - 2 * this._contentPadding);
			var totalLabelHeight:Number = Math.max(this.onLabelField.height, this.offLabelField.height);
			var labelHeight:Number;
			if(this._labelAlign == LABEL_ALIGN_MIDDLE || !this._defaultTextFormat || !(this._defaultTextFormat.font is BitmapFont))
			{
				labelHeight = totalLabelHeight;
			}
			else //baseline
			{
				const fontScale:Number = isNaN(this._defaultTextFormat.size) ? 1 : (this._defaultTextFormat.size / this._defaultTextFormat.font.size);
				labelHeight = fontScale * BitmapFont(this._defaultTextFormat.font).base;
			}
			
			var onScrollRect:Rectangle = this.onLabelField.scrollRect;
			onScrollRect.width = maxLabelWidth;
			onScrollRect.height = totalLabelHeight;
			this.onLabelField.scrollRect = onScrollRect;
			
			this.onLabelField.x = this._contentPadding;
			this.onLabelField.y = (this._height - labelHeight) / 2;
			
			var offScrollRect:Rectangle = this.offLabelField.scrollRect;
			offScrollRect.width = maxLabelWidth;
			offScrollRect.height = totalLabelHeight;
			this.offLabelField.scrollRect = offScrollRect;
			
			this.offLabelField.x = this._width - this._contentPadding - maxLabelWidth;
			this.offLabelField.y = (this._height - labelHeight) / 2;
		}
		
		/**
		 * @private
		 */
		private function updateScrollRects():void
		{
			const maxLabelWidth:Number = Math.max(0, this._width - this.thumb.width - 2 * this._contentPadding);
			const thumbOffset:Number = this.thumb.x - this._contentPadding;
			const halfWidth:Number = (this._width - 2 * this._contentPadding) / 2;
			const middleOfThumb:Number = this.thumb.x + this.thumb.width / 2;
			
			var currentScrollRect:Rectangle = this.onLabelField.scrollRect;
			currentScrollRect.x = this._width - this.thumb.width - thumbOffset - (maxLabelWidth - this.onLabelField.width) / 2;
			this.onLabelField.scrollRect = currentScrollRect;
			
			currentScrollRect = this.offLabelField.scrollRect;
			currentScrollRect.x = -thumbOffset - (maxLabelWidth - this.offLabelField.width) / 2;
			this.offLabelField.scrollRect = currentScrollRect;
			
			const onSkinScaledWidth:Number = this.onSkinOriginalWidth * this._onSkin.scaleX;
			currentScrollRect = this._onSkin.scrollRect;
			currentScrollRect.width = Math.min(onSkinScaledWidth, middleOfThumb) / this._onSkin.scaleX;
			currentScrollRect.height = this._height / this._onSkin.scaleX;
			this._onSkin.scrollRect = currentScrollRect;
			
			const offSkinScaledWidth:Number = this.offSkinOriginalWidth * this._offSkin.scaleX;
			this._offSkin.x = Math.max(this._width - offSkinScaledWidth, middleOfThumb);
			currentScrollRect = this._offSkin.scrollRect;
			currentScrollRect.width = Math.min(offSkinScaledWidth, this._width - middleOfThumb) / this._offSkin.scaleX;
			currentScrollRect.height = this._height / this._offSkin.scaleX;
			currentScrollRect.x = Math.max(0, this.offSkinOriginalWidth - currentScrollRect.width);
			this._offSkin.scrollRect = currentScrollRect;
		}
		
		/**
		 * @private
		 */
		private function removedFromStageHandler(event:Event):void
		{
			this._touchPointID = -1;
			this.stage.removeEventListener(MouseEvent.MOUSE_MOVE, stage_touchMoveHandler);
			this.stage.removeEventListener(MouseEvent.MOUSE_UP, stage_touchEndHandler);
			this.stage.removeEventListener(TouchEvent.TOUCH_MOVE, stage_touchMoveHandler);
			this.stage.removeEventListener(TouchEvent.TOUCH_END, stage_touchEndHandler);
		}
		
		/**
		 * @private
		 */
		private function touchTapHandler(event:Event):void
		{
			if(this._ignoreTapHandler)
			{
				this._ignoreTapHandler = false;
				return;
			}
			if(!this._isEnabled)
			{
				return;
			}
			if(this._touchPointID >= 0)
			{
				return;
			}
			this.isSelected = !this._isSelected;
			this._isSelectionChangedByUser = true;
		}
		
		/**
		 * @private
		 */
		private function thumb_touchBeginHandler(event:Event):void
		{
			if(!this._isEnabled)
			{
				return;
			}
			if(this._touchPointID >= 0)
			{
				return;
			}
			
			this._thumbStartX = this.thumb.x;
			this._touchStartX = (event is TouchEvent) ? TouchEvent(event).stageX : MouseEvent(event).stageX;
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
			if(event is TouchEvent && this._touchPointID != TouchEvent(event).touchPointID)
			{
				return;
			}
			
			const stageX:Number = (event is TouchEvent) ? TouchEvent(event).stageX : MouseEvent(event).stageX;
			const trackScrollableWidth:Number = this._width - 2 * this._contentPadding - this.thumb.width;
			const xOffset:Number = stageX - this._touchStartX;
			const xPosition:Number = Math.min(Math.max(this._contentPadding, this._thumbStartX + xOffset), trackScrollableWidth);
			this.thumb.x = xPosition;
			this.updateScrollRects();
		}
			
		private function stage_touchEndHandler(event:Event):void
		{
			if(event is TouchEvent && this._touchPointID != TouchEvent(event).touchPointID)
			{
				return;
			}
			const stageX:Number = (event is TouchEvent) ? TouchEvent(event).stageX : MouseEvent(event).stageX;
			const trackScrollableWidth:Number = this._width - 2 * this._contentPadding - this.thumb.width;
			const inchesMoved:Number = Math.abs(stageX - this._touchStartX) / Capabilities.screenDPI;
			if(inchesMoved > MINIMUM_DRAG_DISTANCE)
			{
				this.isSelected = this.thumb.x > (trackScrollableWidth / 2);
				this._isSelectionChangedByUser = true;
				this._ignoreTapHandler = true;
			}
			this._touchPointID = -1;
			this.stage.removeEventListener(MouseEvent.MOUSE_MOVE, stage_touchMoveHandler);
			this.stage.removeEventListener(MouseEvent.MOUSE_UP, stage_touchEndHandler);
			this.stage.removeEventListener(TouchEvent.TOUCH_MOVE, stage_touchMoveHandler);
			this.stage.removeEventListener(TouchEvent.TOUCH_END, stage_touchEndHandler);
		}
		
		/**
		 * @private
		 */
		private function selectionTween_onChange(tween:GTween):void
		{
			this.updateScrollRects();
		}
		
		/**
		 * @private
		 */
		private function selectionTween_onComplete(tween:GTween):void
		{
			this._selectionChangeTween = null;
		}
	}
}