package org.josht.foxhole.controls
{
	import fl.core.InvalidationType;
	import fl.core.UIComponent;
	
	import flash.display.DisplayObject;
	import flash.errors.IllegalOperationError;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.getDefinitionByName;
	
	
	//--------------------------------------
	//  Styles
	//--------------------------------------
	
	/**
	 * The class that provides the skin for the up state of the component.
	 *
	 * @default Button_upSkin
	 */
	[Style(name="upSkin", type="Class")]
	
	/**
	 * The class that provides the skin for the down state of the component.
	 *
	 * @default Button_downSkin
	 */
	[Style(name="downSkin", type="Class")]
	
	/**
	 * The padding that separates the border of the button from its contents, in pixels.
	 *
	 * @default null
	 */
	[Style(name="contentPadding", type="Number", format="Length")]
	
	public class Button extends UIComponent
	{
		private static const STATE_UP:String = "up";
		private static const STATE_DOWN:String = "down";
		
		private static var defaultStyles:Object =
		{
			upSkin: "Button_upSkin",
			downSkin: "Button_downSkin",
			contentPadding: null,
			scaleSkins: true,
			//not used by default, but good to have set as a default for when
			//the developer set scaleSkins to false
			skinAlign: SkinAlign.TOP_LEFT
		};
		
		public static function getStyleDefinition():Object
		{ 
			return mergeStyles(defaultStyles, UIComponent.getStyleDefinition());
		}
		
		public function Button()
		{
			this.mouseChildren = false;
			this.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
		}
		
		private var _stateToDefaultSize:Object = {};
		private var _stateToSkin:Object = {};
		
		private var _currentState:String = STATE_UP;

		protected function get currentState():String
		{
			return _currentState;
		}

		protected function set currentState(value:String):void
		{
			if(this._currentState == value)
			{
				return;
			}
			if(this.stateNames.indexOf(value) < 0)
			{
				throw new ArgumentError("Invalid state: " + value + ".");
			}
			this._currentState = value;
			this.invalidate(InvalidationType.STATE);
		}

		protected var labelField:TextField;
		protected var currentSkin:DisplayObject;
		
		private var _label:String = "";

		public function get label():String
		{
			return this._label;
		}

		public function set label(value:String):void
		{
			if(!value)
			{
				//don't allow null or undefined
				value = "";
			}
			if(this._label == value)
			{
				return;
			}
			this._label = value;
			this.invalidate(InvalidationType.DATA);
		}
		
		protected function get stateNames():Vector.<String>
		{
			return Vector.<String>([STATE_UP, STATE_DOWN]);
		}

		override protected function configUI():void
		{
			super.configUI();
			
			if(!this.labelField)
			{
				this.labelField = new TextField();
				this.labelField.selectable = this.labelField.mouseEnabled = false;
				this.labelField.cacheAsBitmap = true;
				this.addChild(this.labelField);
			}
		}
		
		override protected function draw():void
		{
			var dataInvalid:Boolean = this.isInvalid(InvalidationType.DATA);
			var stylesInvalid:Boolean = this.isInvalid(InvalidationType.STYLES);
			var sizeInvalid:Boolean = this.isInvalid(InvalidationType.SIZE);
			var stateInvalid:Boolean = this.isInvalid(InvalidationType.STATE);
			
			if(dataInvalid)
			{
				this.labelField.text = this._label;
			}
			
			var contentPaddingChanged:Boolean = false;
			if(stylesInvalid)
			{
				this.refreshSkins();
				this.refreshLabelStyles();
				var contentPadding:Number = this.getStyleValue("contentPadding") as Number;
				contentPaddingChanged = this.labelField.x != contentPadding;
			}
			
			if(dataInvalid || sizeInvalid || contentPaddingChanged)
			{
				var contentWidth:Number = Math.max(this._width - contentPadding * 2);
				var contentHeight:Number = Math.max(0, this._height - contentPadding * 2);
				this.labelField.width = contentWidth;
				this.labelField.height = Math.min(contentHeight, this.labelField.textHeight + 4);
				this.labelField.x = contentPadding;
				this.labelField.y = Math.round((this._height - this.labelField.height) / 2);
			}
			
			if(stateInvalid)
			{
				for(var state:String in this._stateToSkin)
				{
					var skin:DisplayObject = DisplayObject(this._stateToSkin[state]);
					if(this._currentState != state)
					{
						skin.visible = false;
					}
					else
					{
						skin.visible = true;
						this.currentSkin = skin;
					}
				}
			}
			
			if(stylesInvalid || stateInvalid || sizeInvalid)
			{
				var scaleSkins:Boolean = this.getStyleValue("scaleSkins") as Boolean;
				if(scaleSkins)
				{
					this.scaleSkin();
				}
				else
				{
					this.alignSkin();
				}
			}
			
			super.draw();
		}
		
		protected function refreshSkins():void
		{
			var states:Vector.<String> = this.stateNames;
			for each(var state:String in states)
			{
				var skin:DisplayObject = this._stateToSkin[state];
				var skinName:String = state + "Skin";
				var skinStyle:Object = this.getStyleValue(skinName);
				if(!skinStyle)
				{
					throw new IllegalOperationError("Skin must be defined for state: " + state);
				}
				if(skinStyle is String)
				{
					skinStyle = getDefinitionByName(skinStyle as String) as Class;
				}
				if(skinStyle is Class)
				{
					var SkinType:Class = Class(skinStyle);
					if(!(skin is SkinType))
					{
						if(skin)
						{
							this.removeChild(skin);
						}
						skin = new SkinType();
						this.addChild(skin);
					}
				}
				else if(skinStyle is DisplayObject)
				{
					if(skin != skinStyle)
					{
						if(skin)
						{
							this.removeChild(skin);
						}
						skin = DisplayObject(skinStyle);
						this.addChild(skin);
					}
				}
				else
				{
					throw new IllegalOperationError("Unknown skin type: " + skinStyle);
				}
				
				if(state == this._currentState)
				{
					this.currentSkin = skin;
				}
				this._stateToSkin[state] = skin;
				var size:Point = this._stateToDefaultSize[state];
				if(!size)
				{
					size = new Point();
				}
				size.x = skin.width;
				size.y = skin.height;
				this._stateToDefaultSize[state] = size;
				skin.cacheAsBitmap = true;
			}
			
			//make sure the label is always on top.
			var topChildIndex:int = this.numChildren - 1;
			if(this.getChildIndex(this.labelField) != topChildIndex)
			{
				this.setChildIndex(this.labelField, topChildIndex);
			}
		}
		
		protected function refreshLabelStyles():void
		{	
			var textFormat:TextFormat = this.getStyleValue("textFormat") as TextFormat;
			this.labelField.setTextFormat(textFormat);
			this.labelField.defaultTextFormat = textFormat;
			this.labelField.embedFonts = this.getStyleValue("embedFonts") as Boolean;
		}
		
		protected function scaleSkin():void
		{
			if(this.currentSkin.width != this._width)
			{
				this.currentSkin.width = this._width;
			}
			if(this.currentSkin.height != this._height)
			{
				this.currentSkin.height = this._height;
			}
			this.currentSkin.x = 0;
			this.currentSkin.y = 0;
		}
		
		protected function alignSkin():void
		{
			var stateBounds:Point = this._stateToDefaultSize[this.currentState];
			if(this.currentSkin.width != stateBounds.x)
			{
				this.currentSkin.width = stateBounds.x;
			}
			if(this.currentSkin.height != stateBounds.y)
			{
				this.currentSkin.height = stateBounds.y;
			}
			var skinAlign:String = this.getStyleValue("skinAlign") as String;
			switch(skinAlign)
			{
				case SkinAlign.TOP_LEFT:
				{
					this.currentSkin.x = 0;
					this.currentSkin.y = 0;
					break;
				}
				case SkinAlign.TOP_CENTER:
				{
					this.currentSkin.x = (this._width - this.currentSkin.width) / 2;
					this.currentSkin.y = 0;
					break;
				}
				case SkinAlign.TOP_RIGHT:
				{
					this.currentSkin.x = this._width - this.currentSkin.width;
					this.currentSkin.y = 0;
					break;
				}
				case SkinAlign.MIDDLE_LEFT:
				{
					this.currentSkin.x = 0;
					this.currentSkin.y = (this._height - this.currentSkin.height) / 2;
					break;
				}
				case SkinAlign.MIDDLE_CENTER:
				{
					this.currentSkin.x = (this._width - this.currentSkin.width) / 2;
					this.currentSkin.y = (this._height - this.currentSkin.height) / 2;
					break;
				}
				case SkinAlign.MIDDLE_RIGHT:
				{
					this.currentSkin.x = this._width - this.currentSkin.width;
					this.currentSkin.y = (this._height - this.currentSkin.height) / 2;
					break;
				}
				case SkinAlign.BOTTOM_LEFT:
				{
					this.currentSkin.x = 0;
					this.currentSkin.y = this._height - this.currentSkin.height;
					break;
				}
				case SkinAlign.BOTTOM_CENTER:
				{
					this.currentSkin.x = (this._width - this.currentSkin.width) / 2;
					this.currentSkin.y = this._height - this.currentSkin.height;
					break;
				}
				case SkinAlign.BOTTOM_RIGHT:
				{
					this.currentSkin.x = this._width - this.currentSkin.width;
					this.currentSkin.y = this._height - this.currentSkin.height;
					break;
				}
				default:
				{
					throw new IllegalOperationError("Unknown skin alignment value: " + skinAlign);
				}
			}
		}
		
		private function mouseDownHandler(event:MouseEvent):void
		{
			this.currentState = STATE_DOWN;
			this.addEventListener(MouseEvent.ROLL_OUT, rollOutHandler);
			this.stage.addEventListener(MouseEvent.MOUSE_UP, stage_mouseUpHandler, false, 0, true);
		}
		
		private function rollOutHandler(event:MouseEvent):void
		{
			this.currentState = STATE_UP;
			this.addEventListener(MouseEvent.ROLL_OVER, rollOverHandler);
		}
		
		private function rollOverHandler(event:MouseEvent):void
		{
			this.removeEventListener(MouseEvent.ROLL_OVER, rollOverHandler);
			this.currentState = STATE_DOWN;
		}
		
		private function stage_mouseUpHandler(event:MouseEvent):void
		{
			this.removeEventListener(MouseEvent.ROLL_OUT, rollOutHandler);
			this.removeEventListener(MouseEvent.ROLL_OVER, rollOverHandler);
			this.stage.removeEventListener(MouseEvent.MOUSE_UP, stage_mouseUpHandler);
			this.currentState = STATE_UP;
		}
	}
}