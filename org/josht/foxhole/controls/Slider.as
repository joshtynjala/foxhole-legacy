package org.josht.foxhole.controls
{
	import fl.controls.SliderDirection;
	import fl.core.InvalidationType;
	import fl.core.UIComponent;
	import fl.events.SliderEvent;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.utils.getDefinitionByName;
	
	import org.josht.foxhole.controls.Button;
	import org.josht.utils.math.clamp;
	import org.josht.utils.math.roundToNearest;
	
	[Event(name="change", type="flash.events.Event")]
	
	public class Slider extends UIComponent
	{
		private static var defaultStyles:Object =
		{
			trackSkin: "Button_upSkin",
			trackDisabledSkin: "Button_upSkin",
			thumbStyles:
			{
				upSkin: "Button_upSkin",
				overSkin: "Button_overSkin",
				downSkin: "Button_downSkin"
			}
		};
		
		public static function getStyleDefinition():Object
		{ 
			return mergeStyles(defaultStyles, UIComponent.getStyleDefinition());
		}
		
		public function Slider()
		{
			super();
		}
		
		protected var track:DisplayObject;
		protected var thumb:Button;
		
		private var _direction:String = SliderDirection.HORIZONTAL;
		
		public function get direction():String
		{
			return this._direction;
		}
		
		public function set direction(value:String):void
		{
			if(this._direction == value)
			{
				return;
			}
			this._direction = value;
			this.invalidate(InvalidationType.DATA);
		}
		
		private var _value:Number = 0;
		
		public function get value():Number
		{
			return this._value;
		}
		
		public function set value(newValue:Number):void
		{
			newValue = clamp(newValue, this._minimum, this._maximum);
			if(this._step != 0)
			{
				newValue = roundToNearest(newValue, this._step);
			}
			if(this._value == newValue)
			{
				return;
			}
			this._value = newValue;
			this.invalidate(InvalidationType.DATA);
			this.dispatchEvent(new Event(Event.CHANGE));
		}
		
		private var _minimum:Number = 0;
		
		public function get minimum():Number
		{
			return this._minimum;
		}
		
		public function set minimum(value:Number):void
		{
			if(this._minimum == value)
			{
				return;
			}
			this._minimum = value;
			this.invalidate(InvalidationType.DATA);
		}
		
		private var _maximum:Number = 0;
		
		public function get maximum():Number
		{
			return this._maximum;
		}
		
		public function set maximum(value:Number):void
		{
			if(this._maximum == value)
			{
				return;
			}
			this._maximum = value;
			this.invalidate(InvalidationType.DATA);
		}
		
		private var _step:Number = 0;
		
		public function get step():Number
		{
			return this._step;
		}
		
		public function set step(value:Number):void
		{
			if(this._step == value)
			{
				return;
			}
			this._step = value;
		}
		
		override protected function configUI():void
		{
			super.configUI();
			
			this._width = 160;
			this._height = 22;
			
			if(!this.thumb)
			{
				this.thumb = new Button();
				this.thumb.label = "";
				this.thumb.addEventListener(MouseEvent.MOUSE_DOWN, thumb_mouseDownHandler);
				this.addChild(this.thumb);
			}
		}
		
		override protected function draw():void
		{
			const dataInvalid:Boolean = this.isInvalid(InvalidationType.DATA);
			const stylesInvalid:Boolean = this.isInvalid(InvalidationType.STYLES);
			const sizeInvalid:Boolean = this.isInvalid(InvalidationType.SIZE);
			const stateInvalid:Boolean = this.isInvalid(InvalidationType.STATE);
			
			if(stylesInvalid)
			{
				this.refreshThumbStyles();
			}
			
			if(stylesInvalid || stateInvalid)
			{
				this.refreshTrackSkin();
			}
			
			if(stateInvalid)
			{
				this.thumb.enabled = this._enabled;
			}
			
			if(stylesInvalid || sizeInvalid)
			{
				this.track.width = this._width;
				this.track.height = this._height;
			}
			
			if(dataInvalid || stylesInvalid || sizeInvalid)
			{
				var thumbSize:Number = this.getStyleValue("thumbSize") as Number;
				this.thumb.setSize(thumbSize, thumbSize);
				if(this._direction == SliderDirection.HORIZONTAL)
				{
					var trackScrollableWidth:Number = this._width - thumbSize;
					this.thumb.x = (trackScrollableWidth * (this._value - this._minimum) / (this._maximum - this._minimum));
					this.thumb.y = (this._height - this.thumb.height) / 2;
				}
				else
				{
					var trackScrollableHeight:Number = this._height - thumbSize;
					this.thumb.x = (this._width - this.thumb.width) / 2;
					this.thumb.y = (trackScrollableHeight * (this._value - this._minimum) / (this._maximum - this._minimum));
				}
			}
			
			this.thumb.drawNow();
			super.draw();
		}
		
		protected function refreshThumbStyles():void
		{
			var thumbStyles:Object = this.getStyleValue("thumbStyles");
			for(var styleName:String in thumbStyles)
			{
				this.thumb.setStyle(styleName, thumbStyles[styleName]);
			}
		}
		
		protected function refreshTrackSkin():void
		{
			if(this.enabled)
			{
				var trackSkin:* = this.getStyleValue("trackSkin");
				if(trackSkin is String)
				{
					trackSkin = getDefinitionByName(trackSkin);
				}
				if(trackSkin is Class)
				{
					if(this.track is trackSkin)
					{
						return;
					}
					trackSkin = new trackSkin();
				}
				if(trackSkin is DisplayObject)
				{
					if(this.track == trackSkin)
					{
						return;
					}
					if(this.track)
					{
						this.track.removeEventListener(MouseEvent.CLICK, track_clickHandler);
						this.removeChild(this.track);
						this.track = null;
					}
					this.track = trackSkin;
					if(!(this.track is Bitmap))
					{
						this.track.cacheAsBitmap = true;
					}
					this.addChildAt(this.track, 0);
				}
				else
				{
					throw new Error("Skin type not recognized.");
				}
			}
			else
			{
				var disabledTrackSkin:* = this.getStyleValue("disabledTrackSkin");
				if(disabledTrackSkin is String)
				{
					disabledTrackSkin = getDefinitionByName(disabledTrackSkin);
				}
				if(disabledTrackSkin is Class)
				{
					if(this.track is disabledTrackSkin)
					{
						return;
					}
					disabledTrackSkin = new trackSkin();
				}
				if(disabledTrackSkin is DisplayObject)
				{
					if(this.track == disabledTrackSkin)
					{
						return;
					}
					if(this.track)
					{
						this.track.removeEventListener(MouseEvent.CLICK, track_clickHandler);
						this.removeChild(this.track);
						this.track = null;
					}
					this.track = disabledTrackSkin;
					this.addChildAt(this.track, 0);
				}
				else
				{
					throw new Error("Skin type not recognized.");
				}
			}
			this.track.addEventListener(MouseEvent.CLICK, track_clickHandler);
		}
		
		private function thumb_mouseDownHandler(event:MouseEvent):void
		{
			this.stage.addEventListener(MouseEvent.MOUSE_MOVE, stage_mouseMoveHandler, false, 0, true);
			this.stage.addEventListener(MouseEvent.MOUSE_UP, stage_mouseUpHandler, false, 0, true);
		}
		
		private function stage_mouseMoveHandler(event:MouseEvent):void
		{
			var percentage:Number;
			var thumbSize:Number = this.getStyleValue("thumbSize") as Number;
			if(this._direction == SliderDirection.HORIZONTAL)
			{
				var trackScrollableWidth:Number = this._width - thumbSize;
				var thumbWidthOffset:Number = (this._width - trackScrollableWidth) / 2;
				percentage =  (this.mouseX - thumbWidthOffset) / trackScrollableWidth; 
			}
			else
			{
				var trackScrollableHeight:Number = this._height - thumbSize;
				var thumbHeightOffset:Number = (this._height - trackScrollableHeight) / 2;
				percentage = (this.mouseY - thumbHeightOffset) / trackScrollableHeight;
			}
			
			this.value = this._minimum + percentage * (this._maximum - this._minimum);
		}
		
		private function stage_mouseUpHandler(event:MouseEvent):void
		{
			this.stage.removeEventListener(MouseEvent.MOUSE_MOVE, stage_mouseMoveHandler);
			this.stage.removeEventListener(MouseEvent.MOUSE_UP, stage_mouseUpHandler);
		}
		
		private function track_clickHandler(event:MouseEvent):void
		{
			var percentage:Number;
			if(this._direction == SliderDirection.HORIZONTAL)
			{
				percentage = this.mouseX / this._width; 
			}
			else
			{
				percentage = this.mouseY / this._height;
			}
			
			this.value = this._minimum + percentage * (this._maximum - this._minimum);
		}
	}
}