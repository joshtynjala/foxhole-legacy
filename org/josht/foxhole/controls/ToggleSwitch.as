/*
Copyright (c) 2011 Josh Tynjala

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
	
	import fl.core.InvalidationType;
	import fl.core.UIComponent;
	
	import flash.display.DisplayObject;
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.getDefinitionByName;
	
	import org.josht.foxhole.core.FrameTicker;
	import org.josht.foxhole.core.IToggle;
	
	public class ToggleSwitch extends UIComponent implements IToggle
	{
		private static var defaultStyles:Object =
		{
			onSkin: "Button_upSkin",
			offSkin: "Button_upSkin",
			thumbStyles: null,
			contentPadding: null,
			showLabels: true
		};
		
		public static function getStyleDefinition():Object
		{ 
			return mergeStyles(defaultStyles, UIComponent.getStyleDefinition());
		}
		
		public function ToggleSwitch()
		{
			super();
			this.addEventListener(MouseEvent.CLICK, clickHandler);
		}
		
		protected var onSkin:DisplayObject;
		protected var offSkin:DisplayObject;
		protected var sampleThumbSkin:DisplayObject;
		protected var thumb:Button;
		protected var onLabelField:TextField;
		protected var offLabelField:TextField;
		
		protected var onSkinOriginalHeight:Number = NaN;
		protected var offSkinOriginalHeight:Number = NaN;
		protected var sampleThumbSkinOriginalHeight:Number = NaN;
		
		private var _backgroundBounds:Point;
		
		private var _selected:Boolean = false;

		public function get selected():Boolean
		{
			return this._selected;
		}

		public function set selected(value:Boolean):void
		{
			this._selected = value;
			this._userChange = false;
			this.invalidate(InvalidationType.DATA);
		}
		
		private var _selectionChangeTween:GTween;
		
		private var _ignoreClickHandler:Boolean = false;
		private var _thumbStartX:Number;
		private var _mouseStartX:Number;
		private var _userChange:Boolean = false;
		
		override protected function configUI():void
		{
			super.configUI();
			
			if(!this.offLabelField)
			{
				this.offLabelField = new TextField();
				this.offLabelField.selectable = false;
				this.offLabelField.mouseEnabled = false;
				this.offLabelField.text = "OFF";
				this.offLabelField.scrollRect = new Rectangle(0, 0, this.offLabelField.textWidth + 5, this.offLabelField.textHeight + 4);
				this.addChild(this.offLabelField);
			}
			
			if(!this.onLabelField)
			{
				this.onLabelField = new TextField();
				this.onLabelField.selectable = false;
				this.onLabelField.mouseEnabled = false;
				this.onLabelField.text = "ON";
				this.onLabelField.scrollRect = new Rectangle(0, 0, this.onLabelField.textWidth + 5, this.onLabelField.textHeight + 4);
				this.addChild(this.onLabelField);
			}
			
			if(!this.thumb)
			{
				this.thumb = new Button();
				this.thumb.addEventListener(MouseEvent.MOUSE_DOWN, thumb_mouseDownHandler);
				this.addChild(this.thumb);
			}
		}
		
		override protected function draw():void
		{
			const dataInvalid:Boolean = this.isInvalid(InvalidationType.DATA);
			const stylesInvalid:Boolean = this.isInvalid(InvalidationType.STYLES);
			const sizeInvalid:Boolean = this.isInvalid(InvalidationType.SIZE);
			
			var contentPaddingChanged:Boolean = false;
			if(stylesInvalid)
			{
				this.refreshSkins();
				this.refreshLabelStyles();
				this.refreshThumbStyles();
				const contentPadding:Number = this.getStyleValue("contentPadding") as Number;
				contentPaddingChanged = this.onLabelField.x != contentPadding;
			}
			
			if(stylesInvalid || sizeInvalid)
			{
				this.scaleSkins();
			}
			
			if(sizeInvalid || contentPaddingChanged)
			{
				this.drawThumb();
			}
			
			if(sizeInvalid || stylesInvalid)
			{
				this.drawLabels();
			}
			
			this.thumb.validateNow();
			
			if(sizeInvalid || stylesInvalid || dataInvalid)
			{
				this.updateSelection();
			}
			
			super.draw();
		}
		
		protected function updateSelection():void
		{
			const contentPadding:Number = this.getStyleValue("contentPadding") as Number;
			var xPosition:Number = contentPadding;
			if(this._selected)
			{
				xPosition = this._width - this.thumb.width - contentPadding;
			}
			
			//stop the tween, no matter what
			if(this._selectionChangeTween)
			{
				this._selectionChangeTween.paused = true;
				this._selectionChangeTween = null;
			}
			
			if(this._userChange)
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
				this.updateSkinOrderBasedOnThumb();
			}
			this._userChange = false;
		}
		
		protected function refreshLabelStyles():void
		{	
			const showLabels:Boolean = this.getStyleValue("showLabels") as Boolean;
			if(!showLabels)
			{
				this.onLabelField.visible = this.offLabelField.visible = false;
				return;
			}
			const textFormat:TextFormat = this.getStyleValue("textFormat") as TextFormat;
			const embedFonts:Boolean = this.getStyleValue("embedFonts") as Boolean;
			
			this.onLabelField.setTextFormat(textFormat);
			this.onLabelField.defaultTextFormat = textFormat;
			this.onLabelField.embedFonts = embedFonts;
			this.onLabelField.visible = true;
			
			this.offLabelField.setTextFormat(textFormat);
			this.offLabelField.defaultTextFormat = textFormat;
			this.offLabelField.embedFonts = embedFonts;
			this.offLabelField.visible = true;
		}
		
		protected function refreshThumbStyles():void
		{
			const thumbStyles:Object = this.getStyleValue("thumbStyles");
			for(var styleName:String in thumbStyles)
			{
				this.thumb.setStyle(styleName, thumbStyles[styleName]);
			}
		}
		
		protected function refreshSkins():void
		{
			const thumbStyles:Object = this.getStyleValue("thumbStyles");
			this.refreshSkin("sampleThumbSkin", thumbStyles.upSkin);
			this.sampleThumbSkin.visible = false;
			
			this.refreshSkin("onSkin", this.getStyleValue("onSkin"));
			this.refreshSkin("offSkin", this.getStyleValue("offSkin"));
		}
		
		protected function refreshSkin(skinVariableName:String, skinStyle:Object):void
		{
			if(!skinStyle)
			{
				throw new IllegalOperationError("Skin must be defined.");
			}
			if(skinStyle is String)
			{
				skinStyle = getDefinitionByName(skinStyle as String) as Class;
			}
			var oldSkin:DisplayObject = this[skinVariableName];
			if(skinStyle is Class)
			{
				var SkinType:Class = Class(skinStyle);
				if(!(oldSkin is SkinType))
				{
					if(oldSkin)
					{
						this.removeChild(oldSkin);
					}
					var newSkin:DisplayObject = new SkinType();
					this[skinVariableName] = newSkin;
					this.addChildAt(newSkin, 0);
				}
			}
			else if(skinStyle is DisplayObject)
			{
				if(oldSkin != skinStyle)
				{
					if(oldSkin)
					{
						this.removeChild(oldSkin);
					}
					this[skinVariableName] = newSkin = DisplayObject(skinStyle);
					this.addChildAt(newSkin, 0);
				}
			}
			else
			{
				throw new IllegalOperationError("Unknown skin type: " + skinStyle);
			}
			
			if(newSkin)
			{
				this[skinVariableName + "OriginalHeight"] = newSkin.height;
			}
		}
		
		private function scaleSkins():void
		{
			const skinScale:Number = this._height / Math.max(this.onSkinOriginalHeight, this.offSkinOriginalHeight);
			if(this.onSkin.scaleX != skinScale)
			{
				this.onSkin.scaleX = this.onSkin.scaleY = skinScale;
			}
			if(this.offSkin.scaleX != skinScale)
			{
				this.offSkin.scaleX = this.offSkin.scaleY = skinScale;
			}
			
			this.onSkin.x = 0;
			this.offSkin.x = this._width - this.offSkin.width;
			this.offSkin.y = this.onSkin.y = 0;
		}
		
		private function drawThumb():void
		{
			const contentPadding:Number = this.getStyleValue("contentPadding") as Number;
			this.thumb.y = contentPadding;
			
			const thumbHeight:Number = this._height - 2 * contentPadding;
			const thumbScale:Number = thumbHeight / sampleThumbSkinOriginalHeight;
			this.thumb.height = thumbHeight;			
			this.thumb.width = sampleThumbSkin.width * thumbScale;
		}	
		
		private function drawLabels():void
		{
			const contentPadding:Number = this.getStyleValue("contentPadding") as Number;
			const labelWidth:Number = Math.max(0, this._width - this.thumb.width - 4 * contentPadding);
			
			this.onLabelField.width = labelWidth;
			this.onLabelField.height = this.onLabelField.textHeight + 4;
			var onScrollRect:Rectangle = this.onLabelField.scrollRect;
			onScrollRect.width = labelWidth;
			onScrollRect.height = this.onLabelField.textHeight + 4;
			this.onLabelField.scrollRect = onScrollRect;
			
			this.onLabelField.x = contentPadding;
			this.onLabelField.y = (this._height - this.onLabelField.textHeight - 4) / 2;
			
			this.offLabelField.width = labelWidth;
			this.offLabelField.height = this.onLabelField.textHeight + 4;
			var offScrollRect:Rectangle = this.offLabelField.scrollRect;
			offScrollRect.width = labelWidth;
			offScrollRect.height = this.offLabelField.textHeight + 4;
			this.offLabelField.scrollRect = offScrollRect;
			
			this.offLabelField.x = this._width - contentPadding - labelWidth;
			this.offLabelField.y = (this._height - this.offLabelField.textHeight - 4) / 2;
		}
		
		private function updateSkinOrderBasedOnThumb():void
		{
			const contentPadding:Number = this.getStyleValue("contentPadding") as Number;
			const positionRatio:Number = (this.thumb.x - contentPadding) / (this._width - this.thumb.width - 2 * contentPadding);
			const offSkinIndex:int = this.getChildIndex(this.offSkin);
			const onSkinIndex:int = this.getChildIndex(this.onSkin);
			if(positionRatio > 0.5 && offSkinIndex != 0)
			{
				this.setChildIndex(this.offSkin, 0);
			}
			else if(positionRatio <= 0.5 && offSkinIndex != 1)
			{
				this.setChildIndex(this.offSkin, 1);
			}
		}
		
		private function updateLabelScroll():void
		{
			const contentPadding:Number = this.getStyleValue("contentPadding") as Number;
			const thumbOffset:Number = this.thumb.x - contentPadding;
			
			const halfWidth:Number = (this._width - 2 * contentPadding) / 2;
			
			var onLabelRect:Rectangle = this.onLabelField.scrollRect;
			onLabelRect.x = halfWidth - thumbOffset;
			this.onLabelField.scrollRect = onLabelRect;
			
			var offLabelRect:Rectangle = this.offLabelField.scrollRect;
			offLabelRect.x = -thumbOffset;
			this.offLabelField.scrollRect = offLabelRect;
		}
		
		private function clickHandler(event:MouseEvent):void
		{
			if(this._ignoreClickHandler)
			{
				this._ignoreClickHandler = false;
				return;
			}
			this.selected = !this._selected;
			this._userChange = true;
			this.dispatchEvent(new Event(Event.CHANGE));
		}
		
		private function thumb_mouseDownHandler(event:MouseEvent):void
		{
			this._thumbStartX = this.thumb.x;
			this._mouseStartX = this.mouseX;
			FrameTicker.addExitFrameCallback(thumb_exitFrameHandler);
			this.stage.addEventListener(MouseEvent.MOUSE_UP, stage_mouseUpHandler);
		}
		
		private function thumb_exitFrameHandler():void
		{
			const contentPadding:Number = this.getStyleValue("contentPadding") as Number;
			const xOffset:Number = this.mouseX - this._mouseStartX;
			const xPosition:Number = Math.min(Math.max(contentPadding, this._thumbStartX + xOffset),
				this._width - this.thumb.width - 2 * contentPadding);
			this.thumb.x = xPosition;
			this.updateLabelScroll();
			this.updateSkinOrderBasedOnThumb();
		}
		
		private function stage_mouseUpHandler(event:MouseEvent):void
		{
			FrameTicker.removeExitFrameCallback(thumb_exitFrameHandler);
			this.stage.removeEventListener(MouseEvent.MOUSE_UP, stage_mouseUpHandler);
			
			if(this._thumbStartX != this.thumb.x)
			{
				const oldSelected:Boolean = this._selected;
				this.selected = this.thumb.x > (this._width / 4);
				this._userChange = true;
				if(this._selected != oldSelected)
				{
					this.dispatchEvent(new Event(Event.CHANGE));
				}
				
				if(this.mouseX >= 0 && this.mouseX <= this._width && this.mouseY >= 0 && this.mouseY <= this._height)
				{
					this._ignoreClickHandler = true;
				}
			}
		}
		
		private function selectionTween_onChange(tween:GTween):void
		{
			this.updateLabelScroll();
			this.updateSkinOrderBasedOnThumb();
		}
		
		private function selectionTween_onComplete(tween:GTween):void
		{
			this._selectionChangeTween = null;
		}
	}
}