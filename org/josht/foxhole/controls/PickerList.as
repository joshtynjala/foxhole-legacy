package org.josht.foxhole.controls
{
	import fl.controls.listClasses.CellRenderer;
	import fl.core.InvalidationType;
	import fl.core.UIComponent;
	import fl.data.DataProvider;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	
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
				skin: null
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
				this.copyStylesToChild(this._button, this.getStyleValue("buttonStyles"));
				this.copyStylesToChild(this._list, this.getStyleValue("listStyles"));
			}
			
			if(dataInvalid)
			{
				this._list.dataProvider = this._dataProvider;
				this._list.selectedIndex = this.selectedIndex;
				this._list.labelField = this._labelField;
				this._list.labelFunction = this._labelFunction;
				
				this._button.label = this.getItemLabel(this.selectedItem);
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
		
		private function button_clickHandler(event:MouseEvent):void
		{
			PopUpManager.addPopUp(this._list, this.stage, false);
			this.stage.addEventListener(Event.RESIZE, stage_resizeHandler, false, 0, true);
		}
		
		private function list_changeHandler(event:Event):void
		{
			this.stage.removeEventListener(Event.RESIZE, stage_resizeHandler);
			PopUpManager.removePopUp(this._list);
			this.selectedIndex = this._list.selectedIndex;
			this.dispatchEvent(new Event(Event.CHANGE));
		}
		
		private function stage_resizeHandler(event:Event):void
		{
			this.invalidate(INVALIDATION_TYPE_STAGE_SIZE);
		}
	}
}