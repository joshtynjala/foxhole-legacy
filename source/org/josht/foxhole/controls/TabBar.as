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
	import org.josht.foxhole.core.FoxholeControl;
	import org.josht.foxhole.core.ToggleGroup;
	import org.josht.foxhole.data.ListCollection;
	import org.osflash.signals.ISignal;
	import org.osflash.signals.Signal;
	
	/**
	 * A line of tabs, where one may be selected at a time.
	 */
	public class TabBar extends FoxholeControl
	{
		/**
		 * The tabs are displayed in order from left to right.
		 */
		public static const DIRECTION_HORIZONTAL:String = "horizontal";
		
		/**
		 * The tabs are displayed in order from top to bottom.
		 */
		public static const DIRECTION_VERTICAL:String = "vertical";
		
		/**
		 * @private
		 */
		private static const DEFAULT_TAB_FIELDS:Vector.<String> = new <String>
			[
				"defaultIcon",
				"defaultSelectedIcon",
				"upIcon",
				"downIcon",
				"selectedUpIcon",
				"selectedDownIcon",
				"selectedDisabledIcon"
			];
		
		/**
		 * Constructor.
		 */
		public function TabBar()
		{
		}
		
		/**
		 * @private
		 */
		protected var toggleGroup:ToggleGroup;
		
		/**
		 * @private
		 */
		protected var activeTabs:Vector.<Button> = new <Button>[];
		
		/**
		 * @private
		 */
		protected var inactiveTabs:Vector.<Button> = new <Button>[];
		
		/**
		 * @private
		 */
		private var _dataProvider:ListCollection;
		
		/**
		 * The collection of data to be displayed with tabs.
		 *
		 * @see tabInitializer
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
			if(this._dataProvider)
			{
				this._dataProvider.onChange.remove(dataProvider_onChange);
			}
			this._dataProvider = value;
			if(this._dataProvider)
			{
				this._dataProvider.onChange.add(dataProvider_onChange);
			}
			this.invalidate(INVALIDATION_FLAG_DATA);
		}
		
		/**
		 * @private
		 */
		protected var _direction:String = DIRECTION_HORIZONTAL;
		
		/**
		 * The tab bar layout is either vertical or horizontal.
		 */
		public function get direction():String
		{
			return _direction;
		}
		
		/**
		 * @private
		 */
		public function set direction(value:String):void
		{
			if(this._direction == value)
			{
				return;
			}
			this._direction = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}
		
		/**
		 * @private
		 */
		protected var _gap:Number = 0;
		
		/**
		 * Space, in pixels, between tabs.
		 */
		public function get gap():Number
		{
			return _gap;
		}
		
		/**
		 * @private
		 */
		public function set gap(value:Number):void
		{
			if(this._gap == value)
			{
				return;
			}
			this._gap = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}
		
		/**
		 * @private
		 */
		private var _tabInitializer:Function = defaultTabInitializer;
		
		/**
		 * Modifies a tab, perhaps by changing its label and icons, based on the
		 * item from the data provider that the tab is meant to represent. The
		 * default tabInitializer function can set the tab's label and icons if
		 * <code>label</code> and/or any of the <code>Button</code> icon fields
		 * (<code>defaultIcon</code>, <code>upIcon</code>, etc.) are present in
		 * the item.
		 */
		public function get tabInitializer():Function
		{
			return this._tabInitializer;
		}
		
		/**
		 * @private
		 */
		public function set tabInitializer(value:Function):void
		{
			if(this._tabInitializer == value)
			{
				return;
			}
			this._tabInitializer = value;
			this.invalidate(INVALIDATION_FLAG_DATA);
		}
		
		/**
		 * @private
		 */
		private var _selectedIndex:int = -1;
		
		/**
		 * The index of the currently selected tab. Returns -1 if no tab is
		 * selected.
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
			this.setSelectedIndexInternal(value, true);
		}
		
		/**
		 * The currently selected item from the data provider. Returns
		 * <code>null</code> if no item is selected.
		 */
		public function get selectedItem():Object
		{
			if(!this._dataProvider || this._selectedIndex < 0 || this._selectedIndex >= this._dataProvider.length)
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
			this.selectedIndex = this._dataProvider.getItemIndex(value);
		}
		
		/**
		 * @private
		 */
		protected var _onChange:Signal = new Signal(TabBar);
		
		/**
		 * Dispatched when the selected tab changes.
		 */
		public function get onChange():ISignal
		{
			return this._onChange;
		}
		
		/**
		 * @private
		 */
		private var _tabProperties:Object = {};
		
		/**
		 * A set of key/value pairs to be passed down to all of the tab bar's
		 * tabs. These values are shared by each tabs, so values that cannot be
		 * shared (such as display objects that need to be added to the display
		 * list) should be passed to tabs in another way (such as with an
		 * <code>AddedWatcher</code>).
		 *
		 * @see AddedWatcher
		 */
		public function get tabProperties():Object
		{
			return this._tabProperties;
		}
		
		/**
		 * @private
		 */
		public function set tabProperties(value:Object):void
		{
			if(this._tabProperties == value)
			{
				return;
			}
			if(!value)
			{
				value = {};
			}
			this._tabProperties = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}
		
		/**
		 * Sets a property value for all of the tab bars's tabs. This property
		 * will be shared by all tabs, so skins and similar objects that can
		 * only be used in one place should be initialized in a different way.
		 */
		public function setTabProperty(propertyName:String, propertyValue:Object):void
		{
			this._tabProperties[propertyName] = propertyValue;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}
		
		/**
		 * @private
		 */
		override protected function initialize():void
		{
			this.toggleGroup = new ToggleGroup();
			this.toggleGroup.isSelectionRequired = true;
			this.toggleGroup.onChange.add(toggleGroup_onChange);
		}
		
		/**
		 * @private
		 */
		override protected function draw():void
		{
			const dataInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_DATA);
			const stylesInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STYLES);
			const stateInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STATE);
			const selectionInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_SELECTED);
			var sizeInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_SIZE);
			
			if(dataInvalid)
			{
				this.refreshTabs();
			}
			
			if(dataInvalid || stylesInvalid)
			{
				this.refreshTabStyles();
			}
			
			if(selectionInvalid)
			{
				this.toggleGroup.selectedIndex = this.selectedIndex;
			}
			
			if(dataInvalid || stateInvalid)
			{
				for each(var tab:Button in this.activeTabs)
				{
					tab.isEnabled = this._isEnabled;
				}
			}
			
			sizeInvalid = this.autoSizeIfNeeded() || sizeInvalid;
			
			if(sizeInvalid || dataInvalid || stylesInvalid)
			{
				this.layoutTabs();
			}
		}
		
		/**
		 * @private
		 */
		protected function refreshTabStyles():void
		{
			for(var propertyName:String in this._tabProperties)
			{
				var propertyValue:Object = this._tabProperties[propertyName];
				for each(var tab:Button in this.activeTabs)
				{
					if(tab.hasOwnProperty(propertyName))
					{
						tab[propertyName] = propertyValue;
					}
				}
			}
		}
		
		/**
		 * @private
		 */
		protected function defaultTabInitializer(tab:Button, item:Object):void
		{
			if(item)
			{
				if(item.hasOwnProperty("label"))
				{
					tab.label = item.label;
				}
				else
				{
					tab.label = item.toString();
				}
				for each(var field:String in DEFAULT_TAB_FIELDS)
				{
					if(item.hasOwnProperty(field))
					{
						tab[field] = item[field];
					}
				}
			}
			else
			{
				tab.label = "";
			}
			
		}
		
		/**
		 * @private
		 */
		protected function refreshTabs():void
		{
			var temp:Vector.<Button> = this.inactiveTabs;
			this.inactiveTabs = this.activeTabs;
			this.activeTabs = temp;
			this.activeTabs.length = 0;
			temp = null;
			
			var itemCount:int = this._dataProvider ? this._dataProvider.length : 0;
			for(var i:int = 0; i < itemCount; i++)
			{
				var item:Object = this._dataProvider.getItemAt(i);
				var tab:Button = this.createTab(item);
				this.activeTabs.push(tab);
			}
			itemCount = this.inactiveTabs.length;
			for(i = 0; i < itemCount; i++)
			{
				tab = this.inactiveTabs.shift();
				this.destroyTab(tab);
			}
		}
		
		/**
		 * @private
		 */
		protected function createTab(item:Object):Button
		{
			if(this.inactiveTabs.length == 0)
			{
				var tab:Button = new Button();
				tab.name = "foxhole-tabbar-tab";
				tab.isToggle = true;
				this.toggleGroup.addItem(tab);
				this.addChild(tab);
			}
			else
			{
				tab = this.inactiveTabs.shift();
			}
			this._tabInitializer(tab, item);
			return tab;
		}
		
		/**
		 * @private
		 */
		protected function destroyTab(tab:Button):void
		{
			this.toggleGroup.removeItem(tab);
			this.removeChild(tab);
		}
		
		/**
		 * @private
		 */
		protected function autoSizeIfNeeded():Boolean
		{
			var needsWidth:Boolean = isNaN(this._width);
			var needsHeight:Boolean = isNaN(this._height);
			if(!needsWidth && !needsHeight)
			{
				return false;
			}
			
			var newWidth:Number = this._width;
			var newHeight:Number = this._height;
			
			if(isNaN(newWidth))
			{
				newWidth = 0;
				for each(var tab:Button in this.activeTabs)
				{
					tab.validate();
					newWidth = Math.max(tab.width, newWidth);
				}
				newWidth = this.activeTabs.length * (newWidth + this._gap) - this._gap;
			}
			
			if(isNaN(newHeight))
			{
				newHeight = 0;
				for each(tab in this.activeTabs)
				{
					tab.validate();
					newHeight = Math.max(tab.height, newHeight);
				}
			}
			this.setSizeInternal(newWidth, newHeight, false);
			return true;
		}
		
		/**
		 * @private
		 */
		protected function layoutTabs():void
		{
			const tabCount:int = this.activeTabs.length;
			const tabSize:Number = (this._direction == DIRECTION_VERTICAL ? this._height : this._width) / tabCount
			var position:Number = 0;
			for(var i:int = 0; i < tabCount; i++)
			{
				var tab:Button = this.activeTabs[i];
				if(this._direction == DIRECTION_VERTICAL)
				{
					tab.width = this._width;
					tab.height = tabSize;
					tab.y = position;
					position += tab.height + this._gap;
				}
				else //horizontal
				{
					tab.width = tabSize;
					tab.height = this._height;
					tab.x = position;
					position += tab.width + this._gap;
				}
			}
		}
		
		/**
		 * @private
		 */
		protected function setSelectedIndexInternal(index:int, canInvalidate:Boolean):void
		{
			if(this._selectedIndex == index)
			{
				return;
			}
			this._selectedIndex = index;
			if(canInvalidate)
			{
				this.invalidate(INVALIDATION_FLAG_SELECTED);
			}
			this._onChange.dispatch(this);
		}
		
		/**
		 * @private
		 */
		protected function toggleGroup_onChange(toggleGroup:ToggleGroup):void
		{
			this.setSelectedIndexInternal(this.toggleGroup.selectedIndex, false);
		}
		
		/**
		 * @private
		 */
		protected function dataProvider_onChange(data:ListCollection):void
		{
			this.invalidate(INVALIDATION_FLAG_DATA);
		}
	}
}
