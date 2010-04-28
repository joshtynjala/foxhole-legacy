package org.josht.foxhole.controls
{	
	import fl.controls.ScrollBarDirection;
	import fl.controls.listClasses.CellRenderer;
	import fl.controls.listClasses.ICellRenderer;
	import fl.controls.listClasses.ListData;
	import fl.core.InvalidationType;
	import fl.core.UIComponent;
	import fl.data.DataProvider;
	import fl.events.DataChangeEvent;
	import fl.events.ListEvent;
	import fl.events.ScrollEvent;
	import fl.video.ReconnectClient;
	
	import flash.display.DisplayObject;
	import flash.display.InteractiveObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import org.josht.foxhole.core.FrameTicker;
	
	
	//--------------------------------------
	//  Events
	//--------------------------------------
	
	/**
	 * Dispatched when the user rolls the pointer off of an item in the component.
	 *
	 * @eventType fl.events.ListEvent.ITEM_ROLL_OUT
	 *
	 * @see #event:itemRollOver
	 */
	[Event(name="itemRollOut", type="fl.events.ListEvent")]
	
	/**
	 * Dispatched when the user rolls the pointer over an item in the component.
	 *
	 * @eventType fl.events.ListEvent.ITEM_ROLL_OVER
	 *
	 * @see #event:itemRollOut
	 */
	[Event(name="itemRollOver", type="fl.events.ListEvent")]
	
	/**
	 * Dispatched when the user clicks an item in the component. 
	 *
	 * <p>The <code>click</code> event is dispatched before the value
	 * of the component is changed. To identify the row and column that were clicked,
	 * use the properties of the event object; do not use the <code>selectedIndex</code> 
	 * and <code>selectedItem</code> properties.</p>
	 *
	 * @eventType fl.events.ListEvent.ITEM_CLICK
	 */
	[Event(name="itemClick", type="fl.events.ListEvent")]
	
	/**
	 * Dispatched when the user clicks an item in the component twice in
	 * rapid succession. Unlike the <code>click</code> event, the doubleClick event is 
	 * dispatched after the <code>selectedIndex</code> of the component is 
	 * changed.
	 *
	 * @eventType fl.events.ListEvent.ITEM_DOUBLE_CLICK
	 */
	[Event(name="itemDoubleClick", type="fl.events.ListEvent")]
	
	/**
	 * Dispatched when a different item is selected in the list.
	 *
	 * @eventType flash.events.Event.CHANGE
	 */
	[Event(name="change", type="flash.events.Event")]
	
	/**
	 * Dispatched when the user scrolls horizontally or vertically.
	 *
	 * @eventType fl.events.ScrollEvent.SCROLL
	 */
	[Event(name="scroll", type="fl.events.ScrollEvent")]
	
	/**
	 * The padding that separates the border of the list from its contents, in pixels.
	 *
	 * @default null
	 */
	[Style(name="contentPadding", type="Number", format="Length")]
	
	
	//--------------------------------------
	//  Styles
	//--------------------------------------
	
	/**
	 * The class that provides the skin for the background of the component.
	 *
	 * @default List_skin
	 */
	[Style(name="skin", type="Class")]
	
	
	/**
	 * The class that provides the cell renderer for each item in the component.
	 *
	 * @default fl.contols.listClasses.CellRenderer
	 */
	[Style(name="cellRenderer", type="Class")]
	
	public class TouchList extends UIComponent
	{
		
		//--------------------------------------
		//  Static Properties
		//--------------------------------------
		
		private static const MINIMUM_DISTANCE:Number = 20;
		private static const PIXELS_PER_MS:Number = 0.4;
		private static const FRICTION:Number = 0.5;
		
		private static const CLIPPING_INVALID:String = "clippingInvalid";
		
		private static var defaultStyles:Object =
		{
			skin: "List_skin",
			cellRenderer: CellRenderer,
			contentPadding: null,
			scaleSkin: false
		};
		
		public static function getStyleDefinition():Object
		{ 
			return mergeStyles(defaultStyles, UIComponent.getStyleDefinition());
		}
		
		//--------------------------------------
		//  Constructor
		//--------------------------------------
		
		public function TouchList()
		{
			super();
			
			this.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
		}
		
		//--------------------------------------
		//  Properties
		//--------------------------------------
		
		private var _background:DisplayObject;
		//private var _content:Sprite;
		
		private var _verticalScrollPosition:int = 0;
		
		public function get verticalScrollPosition():int
		{
			return this._verticalScrollPosition;
		}
		
		public function set verticalScrollPosition(value:int):void
		{
			if(this._verticalScrollPosition == value)
			{
				return;
			}
			this._verticalScrollPosition = value;
			this.invalidate(InvalidationType.SCROLL);
		}
		
		private var _maxVerticalScrollPosition:int = 0;
		
		public function get maxVerticalScrollPosition():int
		{
			return this._maxVerticalScrollPosition;
		}
		
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
			if(this._dataProvider)
			{
				this._dataProvider.removeEventListener(DataChangeEvent.DATA_CHANGE, dataProvider_dataChangeHandler);
			}
			this._dataProvider = value;
			if(this._dataProvider)
			{
				this._dataProvider.addEventListener(DataChangeEvent.DATA_CHANGE, dataProvider_dataChangeHandler);
			}
			this.invalidate(InvalidationType.DATA);
		}
		
		private var _rowHeight:Number = 30;
		
		public function get rowHeight():Number
		{
			return this._rowHeight;
		}
		
		public function set rowHeight(value:Number):void
		{
			if(this._rowHeight == value)
			{
				return;
			}
			this._rowHeight = value;
			this.invalidate(InvalidationType.SCROLL);
		}
		
		private var _selectable:Boolean = true;
		
		public function get selectable():Boolean
		{
			return this._selectable;
		}
		
		public function set selectable(value:Boolean):void
		{
			if(this._selectable == value)
			{
				return;
			}
			if(!value)
			{
				this.selectedIndex = -1;
			}
			this._selectable = value;
		}
		
		private var _selectedIndex:int = -1;
		
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
			this.invalidate(InvalidationType.SELECTED);
		}
		
		public function get selectedItem():Object
		{
			if(!this._dataProvider || this._selectedIndex < 0 || this._selectedIndex >= this._dataProvider.length)
			{
				return null;
			}
			
			return this._dataProvider.getItemAt(this._selectedIndex);
		}
		
		public function set selectedItem(value:Object):void
		{
			this.selectedIndex = this._dataProvider.getItemIndex(value);
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
			this.invalidate(CLIPPING_INVALID);
		}

		
		private var _startTouchTime:int;
		private var _startTouchY:Number;
		private var _startVerticalScrollPosition:int;
		
		private var _autoScrolling:Boolean = false;
		private var _isScrolling:Boolean = false;
		
		private var _inactiveRenderers:Vector.<ICellRenderer> = new Vector.<ICellRenderer>;
		private var _activeRenderers:Vector.<ICellRenderer> = new Vector.<ICellRenderer>;
		private var _rendererMap:Dictionary = new Dictionary(true);
		
		private var _targetY:int;
		
		//--------------------------------------
		//  Protected Methods
		//--------------------------------------
		
		override protected function configUI():void
		{
			super.configUI();
			
			//holds all the renderers
			//this._content = new Sprite();
			//this.addChild(this._content);
		}
		
		override protected function draw():void
		{
			var sizeInvalid:Boolean = this.isInvalid(InvalidationType.SIZE);
			var dataInvalid:Boolean = this.isInvalid(InvalidationType.DATA);
			var scrollInvalid:Boolean = this.isInvalid(InvalidationType.SCROLL);
			var stylesInvalid:Boolean = this.isInvalid(InvalidationType.STYLES);
			var selectionInvalid:Boolean = this.isInvalid(InvalidationType.SELECTED);
			var cellRendererTypeIsInvalid:Boolean = false;
			var maskInvalid:Boolean = this.isInvalid(CLIPPING_INVALID);
			
			if(stylesInvalid)
			{
				var contentPadding:Number = this.getStyleValue("contentPadding") as Number;
				//if(this._content.x != contentPadding)
				{
					sizeInvalid = true;
					scrollInvalid = true;
				}
				
				this.refreshBackground();
				cellRendererTypeIsInvalid = this.hasCellRendererTypeChanged();
			}
			
			if(sizeInvalid)
			{
				this.handleResize();
			}
			
			/*if(sizeInvalid || maskInvalid)
			{
				this.refreshClippedContent();
			}*/
			
			if(dataInvalid || sizeInvalid || cellRendererTypeIsInvalid)
			{
				this.refreshScrollBounds();
				this.refreshRenderers(cellRendererTypeIsInvalid);
				this.drawRenderers();
			}
			
			if(selectionInvalid)
			{
				this.refreshSelection();
			}
			
			var rendererCount:int = this._activeRenderers.length;
			for(var i:int = 0; i < rendererCount; i++)
			{
				var renderer:ICellRenderer = this._activeRenderers[i];
				if(renderer is UIComponent)
				{
					UIComponent(renderer).drawNow();
				}
			}
			
			if(dataInvalid || scrollInvalid || maskInvalid)
			{
				this.scrollContent();
			}
			
			super.draw();
		}
		
		//--------------------------------------
		//  Private Methods
		//--------------------------------------
		
		private function hasCellRendererTypeChanged():Boolean
		{
			var CellRendererType:Class = this.getStyleValue("cellRenderer") as Class;
			if(this._activeRenderers.length > 0)
			{
				var renderer:ICellRenderer = this._activeRenderers[0];
				return !(renderer is CellRendererType);
			}
			
			//there were no previous renderers, so we can say no.
			return false;
		}
		
		private function refreshScrollBounds():void
		{
			var contentPadding:Number = this.getStyleValue("contentPadding") as Number;
			var availableHeight:Number = this._height - 2 * contentPadding;
			if(this._dataProvider)
			{
				var contentHeight:Number = this._dataProvider.length * this._rowHeight;
				this._maxVerticalScrollPosition = Math.max(0, contentHeight - availableHeight);
			}
			else
			{
				this._maxVerticalScrollPosition = 0;
			}
		}
		
		/*private function refreshClippedContent():void
		{
			var contentPadding:Number = this.getStyleValue("contentPadding") as Number;
			var availableWidth:Number = this._width - 2 * contentPadding;
			var availableHeight:Number = this._height - 2 * contentPadding;
			
			//use a scrollRect on _content
			if(this._clipContent)
			{
				//reuse the existing scrollRect instead of creating a new object
				var scrollRect:Rectangle = this._content.scrollRect;
				if(!scrollRect)
				{
					scrollRect = new Rectangle();
				}
				scrollRect.width = availableWidth;
				scrollRect.height = availableHeight;
				this._content.scrollRect = scrollRect;
			}
			else if(scrollRect)
			{
				this._content.scrollRect = null;
			}
		}*/
		
		private function refreshSelection():void
		{
			var itemCount:int = this._dataProvider ? this._dataProvider.length : 0;
			for(var i:int = 0; i < itemCount; i++)
			{
				var item:Object = this._dataProvider.getItemAt(i);
				var renderer:ICellRenderer = this.itemToCellRenderer(item);
				renderer.selected = this._selectedIndex == i;
			}
		}
		
		private function refreshBackground():void
		{
			var backgroundSkin:Object = this.getStyleValue("skin");
			var replaceBackground:Boolean = !this._background || //background doesn't exist
				(this._background && !backgroundSkin) || //background exists, but the style is now null
				(backgroundSkin is Class && !(this._background is Class(backgroundSkin))) || //backgroun ddoesn't match the style class
				(backgroundSkin is DisplayObject && this._background != backgroundSkin); //background should be a different display object
			
			if(replaceBackground)
			{
				if(this._background)
				{
					this.removeChild(this._background);
					this._background = null;
				}
				
				if(backgroundSkin is Class)
				{
					this._background = new backgroundSkin();
				}
				else if(backgroundSkin is DisplayObject)
				{
					this._background = DisplayObject(backgroundSkin);
				}
				
				if(this._background)
				{
					this._background.cacheAsBitmap = true;
					this.addChildAt(this._background, 0);
				}
			}
		}
		
		private function handleResize():void
		{
			var contentPadding:Number = this.getStyleValue("contentPadding") as Number;
			
			if(this._background)
			{
				var scaleSkin:Boolean = this.getStyleValue("scaleSkin");
				if(scaleSkin)
				{
					this._background.width = this._width;
					this._background.height = this._height;
				}
			}
			
			//this._content.x = contentPadding;
			//this._content.y = contentPadding;
		}
		
		private function scrollContent():void
		{	
			/*var contentPadding:Number = this.getStyleValue("contentPadding") as Number;
			var scrollRect:Rectangle = this._content.scrollRect;
			if(scrollRect)
			{
				scrollRect.y = this._verticalScrollPosition;
				this._content.scrollRect = scrollRect;
				if(this._content.y != contentPadding)
				{
					this._content.y = contentPadding;
				}
			}
			else
			{
				this._content.y = contentPadding - this._verticalScrollPosition;
			}*/
			var contentPadding:Number = this.getStyleValue("contentPadding") as Number;
			var availableHeight:Number = this._height - 2 * contentPadding;
			var positionY:Number = -this._verticalScrollPosition + contentPadding;
			var itemCount:int = this._dataProvider ? this._dataProvider.length : 0;
			var maxNonClippedPositionY:Number = contentPadding + availableHeight - this._rowHeight;
			for(var i:int = 0; i < itemCount; i++)
			{
				var item:Object = this._dataProvider.getItemAt(i);
				var renderer:DisplayObject = DisplayObject(this.itemToCellRenderer(item));
				if(!this._clipContent || (positionY >= 0 && positionY <= maxNonClippedPositionY))
				{
					renderer.x = contentPadding;
					renderer.y = positionY;
					if(renderer.scrollRect)
					{
						renderer.scrollRect = null;
					}
					renderer.visible = true;
				}
				else if(positionY < 0)
				{
					if(positionY <= -this._rowHeight)
					{
						renderer.visible = false;
					}
					else
					{
						renderer.visible = true;
						renderer.x = contentPadding;
						renderer.y = contentPadding;
						renderer.scrollRect = new Rectangle(0, -positionY, renderer.width, this._rowHeight + positionY);
					}
				}
				else
				{
					if(positionY >= contentPadding + availableHeight)
					{
						renderer.visible = false;
						renderer.y = positionY;
					}
					else
					{
						renderer.visible = true;
						renderer.x = contentPadding;
						renderer.y = positionY;
						renderer.scrollRect = new Rectangle(0, 0, renderer.width, availableHeight + contentPadding - positionY);
					}
				}
				positionY += this._rowHeight;
			}
		}
		
		private function drawRenderers():void
		{	
			var contentPadding:Number = this.getStyleValue("contentPadding") as Number;
			var contentWidth:Number = this._width - 2 * contentPadding;
			//var positionY:Number = 0;
			var itemCount:int = this._dataProvider ? this._dataProvider.length : 0;
			for(var i:int = 0; i < itemCount; i++)
			{
				var item:Object = this._dataProvider.getItemAt(i);
				var renderer:ICellRenderer = this.itemToCellRenderer(item);
				//renderer.y = positionY;
				renderer.setSize(contentWidth, this._rowHeight);
				//positionY += this._rowHeight;
			}
		}
		
		private function refreshRenderers(cellRendererTypeIsInvalid:Boolean):void
		{
			if(!cellRendererTypeIsInvalid)
			{
				this._inactiveRenderers = this._activeRenderers;
			}
			this._activeRenderers = new Vector.<ICellRenderer>;
			
			if(this._dataProvider)
			{
				var unrenderedData:Array = this.findUnrenderedData();
				this.recoverInactiveRenderers();
				this.renderUnrenderedData(unrenderedData);
				this.freeInactiveRenderers();
			}
		}
		
		private function itemToCellRenderer(item:Object):ICellRenderer
		{
			return ICellRenderer(this._rendererMap[item]);
		}
		
		private function findUnrenderedData():Array
		{
			var unrenderedData:Array = [];
			var itemCount:int = this._dataProvider ? this._dataProvider.length : 0;
			for(var i:int = 0; i < itemCount; i++)
			{
				var item:Object = this._dataProvider.getItemAt(i);
				var renderer:ICellRenderer = ICellRenderer(this._rendererMap[item]);
				if(renderer)
				{
					this._activeRenderers.push(renderer);
					this._inactiveRenderers.splice(this._inactiveRenderers.indexOf(renderer), 1);
				}
				else
				{
					unrenderedData.push(item);
				}
			}
			return unrenderedData;
		}
		
		private function renderUnrenderedData(unrenderedData:Array):void
		{
			var CellRendererType:Class = this.getStyleValue("cellRenderer") as Class;
			var itemCount:int = unrenderedData.length;
			for(var i:int = 0; i < itemCount; i++)
			{
				var item:Object = unrenderedData[i];
				this.createRenderer(item, CellRendererType);
			}
		}
		
		private function recoverInactiveRenderers():void
		{
			var itemCount:int = this._inactiveRenderers.length;
			for(var i:int = 0; i < itemCount; i++)
			{
				var renderer:ICellRenderer = this._inactiveRenderers[i];
				delete this._rendererMap[renderer.data];
			}
		}
		
		private function freeInactiveRenderers():void
		{
			var itemCount:int = this._inactiveRenderers.length;
			for(var i:int = 0; i < itemCount; i++)
			{
				var renderer:ICellRenderer = this._inactiveRenderers.shift();
				var interactiveRenderer:InteractiveObject = InteractiveObject(renderer);
				interactiveRenderer.removeEventListener(MouseEvent.CLICK, renderer_clickHandler);
				//this._content.removeChild(DisplayObject(renderer));
				this.removeChild(DisplayObject(renderer));
			}
		}
		
		private function createRenderer(item:Object, CellRendererType:Class):void
		{
			if(this._inactiveRenderers.length == 0)
			{
				var renderer:ICellRenderer = new CellRendererType();
				var interactiveRenderer:InteractiveObject = InteractiveObject(renderer);
				interactiveRenderer.addEventListener(MouseEvent.CLICK, renderer_clickHandler);
				//this._content.addChild(DisplayObject(renderer));
				this.addChild(DisplayObject(renderer));
			}
			else
			{
				renderer = this._inactiveRenderers.shift();
			}
			renderer.data = item;
			var listData:ListData = renderer.listData;
			if(!listData)
			{
				var itemIndex:int = this._dataProvider.getItemIndex(item);
				//TODO: get label and icon
				listData = new ListData("", null, this, itemIndex, itemIndex, 0);
			}
			renderer.listData = listData;
			this._rendererMap[item] = renderer;
			this._activeRenderers.push(renderer);
		}
		
		private function finishScrolling():void
		{
			var maxDifference:Number = this._verticalScrollPosition - this._maxVerticalScrollPosition;
			if(maxDifference > 0)
			{
				this._autoScrolling = true;
				this._targetY = this._maxVerticalScrollPosition;
			}
			else if(this._verticalScrollPosition < 0)
			{
				this._autoScrolling = true;
				this._targetY = 0;
			}
			else
			{
				if(this._isScrolling)
				{
					//this._content.mouseChildren = true;
					this.mouseChildren = true;
				}
				this._isScrolling = false;
				this._autoScrolling = false;
				FrameTicker.removeExitFrameCallback(exitFrameHandler);
			}
		}
		
		//--------------------------------------
		//  Private Event Handlers
		//--------------------------------------
		
		private function mouseDownHandler(event:MouseEvent):void
		{
			event.stopImmediatePropagation();
			if(this._autoScrolling)
			{
				this._autoScrolling = false;
			}
			else
			{
				FrameTicker.addExitFrameCallback(exitFrameHandler);
			}
			
			this.stage.addEventListener(MouseEvent.MOUSE_UP, stage_mouseUpHandler, false, 0, true);
			this._startTouchTime = getTimer();
			this._startTouchY = this.mouseY;
			this._startVerticalScrollPosition = this._verticalScrollPosition;
		}
		
		private function exitFrameHandler():void
		{
			var offset:int = 0;
			if(!this._autoScrolling)
			{
				offset = this._startTouchY - this.mouseY;
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
				var difference:Number = this._verticalScrollPosition - this._targetY;
				if(difference > 0)
				{
					offset = Math.ceil(difference * FRICTION);
				}
				else
				{
					offset = Math.floor(difference * FRICTION);
				}
				this.verticalScrollPosition -= offset;
				if(Math.abs(difference) < 1)
				{
					this.finishScrolling();
				}
			}
			if(offset != 0)
			{
				this._isScrolling = true;
				//this._content.mouseChildren = false;
				this.mouseChildren = false;
				this.dispatchEvent(new ScrollEvent(ScrollBarDirection.VERTICAL, offset, this._verticalScrollPosition));
			}
		}
		
		private function stage_mouseUpHandler(event:MouseEvent):void
		{
			this.stage.removeEventListener(MouseEvent.MOUSE_UP, stage_mouseUpHandler);
			
			if(this._verticalScrollPosition <= 0 || this._verticalScrollPosition >= this._maxVerticalScrollPosition)
			{
				this.finishScrolling();
				return;
			}
			
			var distance:Number = this.mouseY - this._startTouchY;
			this._targetY = this._verticalScrollPosition - (distance * 0.5);
			var pixelsPerMS:Number = distance / (getTimer() - this._startTouchTime); 
			var pixelsPerFrame:Number = 1.5 * (pixelsPerMS * 1000) / this.loaderInfo.frameRate;
			this._targetY = this._verticalScrollPosition;
			while(Math.abs(pixelsPerFrame) >= 1) //there's probably an equation for this...
			{
				this._targetY -= pixelsPerFrame;
				if(this._targetY < 0 || this._targetY > this._maxVerticalScrollPosition)
				{
					pixelsPerFrame /= 2;
					this._targetY += pixelsPerFrame;
				}
				pixelsPerFrame *= (1 - FRICTION);
			}
			this._autoScrolling = true;
		}
		
		private function dataProvider_dataChangeHandler(event:DataChangeEvent):void
		{
			this.invalidate(InvalidationType.DATA);
		}
		
		private function renderer_clickHandler(event:Event):void
		{
			var renderer:ICellRenderer = ICellRenderer(event.currentTarget);
			var listData:ListData = renderer.listData;
			this.dispatchEvent(new ListEvent(ListEvent.ITEM_CLICK, false, false,
				listData.column, listData.row, listData.index, renderer.data));
			
			if(this._selectable)
			{
				this.selectedIndex = listData.index;
				this.dispatchEvent(new Event(Event.CHANGE));
			}
		}
	}
}