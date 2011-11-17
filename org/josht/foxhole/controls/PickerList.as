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
	import fl.controls.listClasses.CellRenderer;
	import fl.core.InvalidationType;
	import fl.core.UIComponent;
	import fl.data.DataProvider;
	
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;
	
	import org.josht.foxhole.core.PopUpManager;
	
	
	//--------------------------------------
	//  Styles
	//--------------------------------------
	
	/**
	 * The styles to pass to the button skin part.
	 *
	 * @default null
	 */
	[Style(name="buttonStyles", type="Object")]
	
	/**
	 * The styles to pass to the list skin part.
	 *
	 * @default null
	 */
	[Style(name="listStyles", type="Object")]
	
	/**
	 * The the padding around the list on the pop up manager.
	 *
	 * @default 20
	 */
	[Style(name="listPadding", type="Number", format="Length")]
	
	public class PickerList extends UIComponent
	{
		private static const INVALIDATION_TYPE_STAGE_SIZE:String = "stageSize";
		
		private static var defaultStyles:Object =
		{
			buttonStyles: null,
			listStyles:
			{
				skin: null,
				verticalAlign: "middle"
			},
			listPadding: 20
		};
		
		public static function getStyleDefinition():Object
		{ 
			return mergeStyles(defaultStyles, UIComponent.getStyleDefinition());
		}
		public function PickerList()
		{
			super();
		}
		
		private var _button:Button;
		private var _list:TouchList;
		
		private var _dataProvider:DataProvider;

		public function get dataProvider():DataProvider
		{
			return this._dataProvider;
		}

		public function set dataProvider(value:DataProvider):void
		{
			if(this._dataProvider == value)
			{
				return;
			}
			this._dataProvider = value;
			this.invalidate(InvalidationType.DATA);
		}
		
		private var _selectedIndex:int = 0;

		public function get selectedIndex():int
		{
			return this._selectedIndex;
		}

		public function set selectedIndex(value:int):void
		{
			if(this._selectedIndex == value)
			{
				return;
			}
			this._selectedIndex = value;
			this.invalidate(InvalidationType.DATA);
		}
		
		public function get selectedItem():Object
		{
			if(!this._dataProvider)
			{
				return null;
			}
			return this._dataProvider.getItemAt(this._selectedIndex);
		}

		public function set selectedItem(value:Object):void
		{
			if(!this._dataProvider)
			{
				this.selectedIndex = -1;
				return;
			}
			
			this.selectedIndex = this._dataProvider.getItemIndex(value);
		}
		
		private var _labelField:String = "label";

		public function get labelField():String
		{
			return this._labelField;
		}

		public function set labelField(value:String):void
		{
			if(this._labelField == value)
			{
				return;
			}
			this._labelField = value;
			this.invalidate(InvalidationType.DATA);
		}

		private var _labelFunction:Function;

		public function get labelFunction():Function
		{
			return this._labelFunction;
		}

		public function set labelFunction(value:Function):void
		{
			this._labelFunction = value;
			this.invalidate(InvalidationType.DATA);
		}

		override protected function configUI():void
		{
			super.configUI();
			
			this._width = 160;
			this._height = 22;
			
			if(!this._button)
			{
				this._button = new Button();
				this._button.addEventListener(MouseEvent.CLICK, button_clickHandler);
				this.addChild(this._button);
			}
			
			if(!this._list)
			{
				this._list = new TouchList();
				this._list.addEventListener(Event.CHANGE, list_changeHandler);
			}
		}
		
		override protected function draw():void
		{
			const dataInvalid:Boolean = this.isInvalid(InvalidationType.DATA);
			const stylesInvalid:Boolean = this.isInvalid(InvalidationType.STYLES);
			const stateInvalid:Boolean = this.isInvalid(InvalidationType.STATE);
			const sizeChanged:Boolean = this.isInvalid(InvalidationType.SIZE);
			const stageSizeChanged:Boolean = this.isInvalid(INVALIDATION_TYPE_STAGE_SIZE);
			if(stylesInvalid)
			{
				const buttonStyles:Object = this.getStyleValue("buttonStyles");
				const listStyles:Object = this.getStyleValue("listStyles");
				for(var styleName:String in buttonStyles)
				{
					this._button.setStyle(styleName, buttonStyles[styleName]);
				}
				for(styleName in listStyles)
				{
					this._list.setStyle(styleName, listStyles[styleName]);
				}
			}
			
			if(dataInvalid)
			{
				this._list.dataProvider = this._dataProvider;
				this._list.selectedIndex = this.selectedIndex;
				this._list.labelField = this._labelField;
				this._list.labelFunction = this._labelFunction;
				
				if(this._selectedIndex >= 0)
				{
					this._button.label = this.getItemLabel(this.selectedItem);
				}
				else
				{
					this._button.label = "";
				}
			}
			
			if(stateInvalid)
			{
				this._button.enabled = this.enabled;
			}
			
			if(sizeChanged)
			{
				this._button.width = this._width;
				this._button.height = this._height;
			}
			
			this._button.validateNow();
			
			if(stageSizeChanged)
			{
				const listPadding:Number = this.getStyleValue("listPadding") as Number;
				this._list.width = this.stage.stageWidth - 2 * listPadding;
				this._list.height = this.stage.stageHeight - 2 * listPadding;
				this._list.x = listPadding;
				this._list.y = listPadding;
			}
			this._list.validateNow();
			this._selectedIndex = this._list.selectedIndex;
			
			super.draw();
		}
		
		protected function getItemLabel(item:Object):String
		{
			if(this._labelFunction != null)
			{
				return this._labelFunction(item) as String;
			}
			else if(this._labelField != null)
			{
				return item[this._labelField] as String;
			}
			else if(item)
			{
				return item.toString();
			}
			return "";
		}
		
		private function closePopUpList():void
		{
			this.stage.removeEventListener(KeyboardEvent.KEY_DOWN, stage_keyDownHandler);
			this.stage.removeEventListener(Event.RESIZE, stage_resizeHandler);
			PopUpManager.removePopUp(this._list);
		}
		
		private function button_clickHandler(event:MouseEvent):void
		{
			PopUpManager.addPopUp(this._list, this.stage, false);
			this.stage.addEventListener(Event.RESIZE, stage_resizeHandler, false, 0, true);
			this.stage.addEventListener(KeyboardEvent.KEY_DOWN, stage_keyDownHandler, false, int.MAX_VALUE, true);
		}
		
		private function list_changeHandler(event:Event):void
		{
			this.closePopUpList();
			this.selectedIndex = this._list.selectedIndex;
			this.dispatchEvent(new Event(Event.CHANGE));
		}
		
		private function stage_keyDownHandler(event:KeyboardEvent):void
		{
			if(event.keyCode != Keyboard.BACK)
			{
				return;
			}
			//don't let the OS handle the event
			event.preventDefault();
			//don't let other event handlers handle the event
			event.stopImmediatePropagation();
			this.closePopUpList();
		}
		
		private function stage_resizeHandler(event:Event):void
		{
			this.invalidate(INVALIDATION_TYPE_STAGE_SIZE);
		}
	}
}