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
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TouchEvent;
	import flash.system.Capabilities;
	import flash.ui.Keyboard;
	import flash.ui.Mouse;
	import flash.ui.Multitouch;
	import flash.ui.MultitouchInputMode;
	
	import org.josht.foxhole.core.FoxholeControl;
	import org.josht.foxhole.core.PopUpManager;
	import org.josht.foxhole.data.ListCollection;
	import org.osflash.signals.ISignal;
	import org.osflash.signals.Signal;
	
	/**
	 * A combo-box like list control. Displayed as a button. The list appears
	 * on tap as a full-screen overlay.
	 */
	public class PickerList extends FoxholeControl
	{
		/**
		 * @private
		 */
		private static const INVALIDATION_FLAG_STAGE_SIZE:String = "stageSize";
		
		/**
		 * Constructor.
		 */
		public function PickerList()
		{
			super();
		}
		
		private var _button:Button;
		private var _list:List;
		
		private var _touchPointID:int = -1;
		private var _hasBeenScrolled:Boolean = false;
		
		/**
		 * @private
		 */
		private var _dataProvider:ListCollection;
		
		/**
		 * @copy List#dataProvider
		 */
		public function get dataProvider():ListCollection
		{
			return this._dataProvider;
		}
		
		/**
		 * @private
		 */
		public function set dataProvider(value:ListCollection):void
		{
			if(this._dataProvider == value)
			{
				return;
			}
			this._dataProvider = value;
			if(!this._dataProvider || this._dataProvider.length == 0)
			{
				this.selectedIndex = -1;
			}
			else if(this._selectedIndex < 0)
			{
				this.selectedIndex = 0
			}
			this.invalidate(INVALIDATION_FLAG_DATA);
		}
		
		/**
		 * @private
		 */
		private var _selectedIndex:int = -1;
		
		/**
		 * @copy List#selectedIndex
		 */
		public function get selectedIndex():int
		{
			return this._selectedIndex;
		}
		
		/**
		 * @private
		 */
		public function set selectedIndex(value:int):void
		{
			if(this._selectedIndex == value)
			{
				return;
			}
			this._selectedIndex = value;
			this.invalidate(INVALIDATION_FLAG_DATA);
			this._onChange.dispatch(this);
		}
		
		/**
		 * @copy List#selectedItem
		 */
		public function get selectedItem():Object
		{
			if(!this._dataProvider)
			{
				return null;
			}
			return this._dataProvider.getItemAt(this._selectedIndex);
		}
		
		/**
		 * @private
		 */
		public function set selectedItem(value:Object):void
		{
			if(!this._dataProvider)
			{
				this.selectedIndex = -1;
				return;
			}
			
			this.selectedIndex = this._dataProvider.getItemIndex(value);
		}
		
		/**
		 * @private
		 */
		private var _labelField:String = "label";
		
		/**
		 * @copy List#labelField
		 */
		public function get labelField():String
		{
			return this._labelField;
		}
		
		/**
		 * @private
		 */
		public function set labelField(value:String):void
		{
			if(this._labelField == value)
			{
				return;
			}
			this._labelField = value;
			this.invalidate(INVALIDATION_FLAG_DATA);
		}
		
		/**
		 * @private
		 */
		private var _labelFunction:Function;
		
		/**
		 * @copy List#labelFunction
		 */
		public function get labelFunction():Function
		{
			return this._labelFunction;
		}
		
		/**
		 * @private
		 */
		public function set labelFunction(value:Function):void
		{
			this._labelFunction = value;
			this.invalidate(INVALIDATION_FLAG_DATA);
		}
		
		/**
		 * @private
		 */
		private var _popUpPadding:Number = 20;
		
		/**
		 * The space, in pixels, around the edges of the pop-up list as it fills
		 * the stage.
		 */
		public function get popUpPadding():Number
		{
			return this._popUpPadding;
		}
		
		/**
		 * @private
		 */
		public function set popUpPadding(value:Number):void
		{
			if(this._popUpPadding == value)
			{
				return;
			}
			this._popUpPadding = value;
			this.invalidate(INVALIDATION_FLAG_STAGE_SIZE);
		}
		
		/**
		 * @private
		 */
		protected var _onChange:Signal = new Signal(PickerList);
		
		/**
		 * @copy List#onChange
		 */
		public function get onChange():ISignal
		{
			return this._onChange;
		}
		
		/**
		 * @private
		 */
		private var _buttonProperties:Object = {};
		
		/**
		 * A set of key/value pairs to be passed down to the picker's button
		 * instance. It is a Foxhole Button control.
		 */
		public function get buttonProperties():Object
		{
			return this._buttonProperties;
		}
		
		/**
		 * @private
		 */
		public function set buttonProperties(value:Object):void
		{
			if(this._buttonProperties == value)
			{
				return;
			}
			this._buttonProperties = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}
		
		/**
		 * @private
		 */
		private var _listProperties:Object = {};
		
		/**
		 * A set of key/value pairs to be passed down to the picker's internal
		 * List instance. The track is a Foxhole Button control.
		 */
		public function get listProperties():Object
		{
			return this._listProperties;
		}
		
		/**
		 * @private
		 */
		public function set listProperties(value:Object):void
		{
			if(this._listProperties == value)
			{
				return;
			}
			this._listProperties = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}
		
		/**
		 * @private
		 */
		private var _itemRendererProperties:Object = {};
		
		/**
		 * @copy List#itemRendererProperties
		 */
		public function get itemRendererProperties():Object
		{
			return this._itemRendererProperties;
		}
		
		/**
		 * @private
		 */
		public function set itemRendererProperties(value:Object):void
		{
			if(this._itemRendererProperties == value)
			{
				return;
			}
			this._itemRendererProperties = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}
		
		/**
		 * Sets a single property on the pickers's button instance.
		 */
		public function setButtonProperty(propertyName:String, propertyValue:Object):void
		{
			this._buttonProperties[propertyName] = propertyValue;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}
		
		/**
		 * Sets a single property on the pickers's internal list instance.
		 */
		public function setListProperty(propertyName:String, propertyValue:Object):void
		{
			this._listProperties[propertyName] = propertyValue;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}
		
		/**
		 * @copy List#setItemRendererProperty
		 */
		public function setItemRendererProperty(propertyName:String, propertyValue:Object):void
		{
			//pssst... pass it on
			this._list.setItemRendererProperty(propertyName, propertyValue);
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}
		
		/**
		 * @copy List#itemToLabel
		 */
		public function itemToLabel(item:Object):String
		{
			return this._list.itemToLabel(item);
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
			if(!this._button)
			{
				this._button = new Button();
				this._button.onRelease.add(button_onRelease);
				this.addChild(this._button);
			}
			
			if(!this._list)
			{
				this._list = new List();
				this._list.onScroll.add(list_onScroll);
				this._list.onChange.add(list_onChange);
				this._list.onItemTouch.add(list_onItemTouch);
				
				//if(!Multitouch.supportsTouchEvents || Multitouch.inputMode != MultitouchInputMode.TOUCH_POINT)
				{
					this._list.addEventListener(MouseEvent.MOUSE_DOWN, list_touchBeginHandler);
				}
				/*else
				{
					this._list.addEventListener(TouchEvent.TOUCH_BEGIN, list_touchBeginHandler);
				}*/
			}
			this.addEventListener(Event.REMOVED_FROM_STAGE, removedFromStageHandler);
		}
		
		/**
		 * @private
		 */
		override protected function draw():void
		{
			const dataInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_DATA);
			const stylesInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STYLES);
			const stateInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STATE);
			var sizeInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_SIZE);
			const stageSizeInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STAGE_SIZE);
			
			if(stylesInvalid)
			{
				this.refreshButtonProperties();
				this.refreshListProperties();
			}
			
			if(dataInvalid)
			{
				this._list.dataProvider = this._dataProvider;
				this._list.selectedIndex = this.selectedIndex;
				this._list.labelField = this._labelField;
				this._list.labelFunction = this._labelFunction;
				this._hasBeenScrolled = false;
				
				if(this._selectedIndex >= 0)
				{
					this._button.label = this.itemToLabel(this.selectedItem);
				}
				else
				{
					this._button.label = "";
				}
			}
			
			if(stateInvalid)
			{
				this._button.isEnabled = this.isEnabled;
			}
			
			this._button.validate();
			
			if(isNaN(this._width))
			{
				this._width = this._button.width;
				sizeInvalid = true;
			}
			if(isNaN(this._height))
			{
				this._height = this._button.height;
				sizeInvalid = true;
			}
			
			if(sizeInvalid)
			{
				this._button.width = this._width;
				this._button.height = this._height;
			}
			this._button.validate();
			
			if(stageSizeInvalid)
			{
				this.resizeAndPositionList();
			}
			this._list.validate();
			this._selectedIndex = this._list.selectedIndex;
		}
		
		/**
		 * @private
		 */
		protected function resizeAndPositionList():void
		{
			this._list.width = this.stage.stageWidth - 2 * this._popUpPadding;
			this._list.height = this.stage.stageHeight - 2 * this._popUpPadding;
			this._list.x = this._popUpPadding;
			this._list.y = this._popUpPadding;
		}
		
		/**
		 * @private
		 */
		protected function refreshButtonProperties():void
		{
			for(var propertyName:String in this._buttonProperties)
			{
				if(this._button.hasOwnProperty(propertyName))
				{
					var propertyValue:Object = this._buttonProperties[propertyName];
					this._button[propertyName] = propertyValue;
				}
			}
		}
		
		/**
		 * @private
		 */
		protected function refreshListProperties():void
		{
			for(var propertyName:String in this._listProperties)
			{
				if(this._list.hasOwnProperty(propertyName))
				{
					var propertyValue:Object = this._listProperties[propertyName];
					this._list[propertyName] = propertyValue;
				}
			}
			this._list.itemRendererProperties = this._itemRendererProperties;
		}
		
		/**
		 * @private
		 */
		protected function closePopUpList():void
		{
			this._list.validate();
			this.stage.removeEventListener(KeyboardEvent.KEY_DOWN, stage_keyDownHandler);
			this.stage.removeEventListener(Event.RESIZE, stage_resizeHandler);
			if(this._list.parent)
			{
				PopUpManager.removePopUp(this._list);
			}
		}
		
		/**
		 * @private
		 */
		protected function button_onRelease(button:Button):void
		{
			PopUpManager.addPopUp(this._list, this.stage, false);
			this.resizeAndPositionList();
			this._list.scrollToDisplayIndex(this._selectedIndex);
			this._list.validate();
			
			this.stage.addEventListener(Event.RESIZE, stage_resizeHandler);
			this.stage.addEventListener(KeyboardEvent.KEY_DOWN, stage_keyDownHandler, false, int.MAX_VALUE, true);
			this._hasBeenScrolled = false;
		}
		
		/**
		 * @private
		 */
		protected function list_onChange(list:List):void
		{
			this.selectedIndex = this._list.selectedIndex;
		}
		
		/**
		 * @private
		 */
		protected function list_onScroll(list:List):void
		{
			if(this._touchPointID < 0)
			{
				return;
			}
			this._hasBeenScrolled = true;
		}
		
		/**
		 * @private
		 */
		protected function list_onItemTouch(list:List, item:Object, index:int, event:Event):void
		{
			const displayRenderer:DisplayObject = DisplayObject(event.currentTarget);
			if(this._hasBeenScrolled || (event is TouchEvent && this._touchPointID != TouchEvent(event).touchPointID) ||
				(event.type != TouchEvent.TOUCH_TAP && event.type != MouseEvent.CLICK))
			{
				return;
			}
			
			this.closePopUpList();
		}
		
		/**
		 * @private
		 */
		private function removedFromStageHandler(event:Event):void
		{
			this._touchPointID = -1;
			this.stage.removeEventListener(MouseEvent.MOUSE_UP, stage_touchTapHandler);
			this.stage.removeEventListener(TouchEvent.TOUCH_END, stage_touchTapHandler);
		}
		
		/**
		 * @private
		 */
		protected function list_touchBeginHandler(event:Event):void
		{
			if(this._touchPointID >= 0)
			{
				return;
			}
			this._hasBeenScrolled = false;
			
			if(event is TouchEvent)
			{
				this._touchPointID = TouchEvent(event).touchPointID;
				this.stage.addEventListener(TouchEvent.TOUCH_TAP, stage_touchTapHandler);
			}
			else
			{
				this._touchPointID = 0;
				this.stage.addEventListener(MouseEvent.CLICK, stage_touchTapHandler);
			}
		}
		
		protected function stage_touchTapHandler(event:Event):void
		{
			if(event is TouchEvent && TouchEvent(event).touchPointID != this._touchPointID)
			{
				return;
			}
			
			this._touchPointID = -1;
			this.stage.removeEventListener(MouseEvent.MOUSE_UP, stage_touchTapHandler);
			this.stage.removeEventListener(TouchEvent.TOUCH_END, stage_touchTapHandler);
		}
		
		/**
		 * @private
		 */
		private function stage_keyDownHandler(event:KeyboardEvent):void
		{
			if(event.keyCode != Keyboard.BACK && event.keyCode != Keyboard.ESCAPE)
			{
				return;
			}
			//don't let the OS handle the event
			event.preventDefault();
			//don't let other event handlers handle the event
			event.stopImmediatePropagation();
			this.closePopUpList();
		}
		
		/**
		 * @private
		 */
		private function stage_resizeHandler(event:Event):void
		{
			this.invalidate(INVALIDATION_FLAG_STAGE_SIZE);
		}
	}
}