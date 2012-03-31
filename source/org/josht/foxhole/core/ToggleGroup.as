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
package org.josht.foxhole.core
{
	import flash.errors.IllegalOperationError;
	
	import org.osflash.signals.ISignal;
	import org.osflash.signals.Signal;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	/**
	 * Controls the selection of two or more IToggle instances where only one
	 * may be selected at a time.
	 * 
	 * @see IToggle
	 */
	public class ToggleGroup extends EventDispatcher
	{
		/**
		 * Constructor.
		 */
		public function ToggleGroup()
		{
		}
		
		private var _ignoreChanges:Boolean = false;
		
		private var _items:Vector.<IToggle> = new Vector.<IToggle>;
		
		/**
		 * @private
		 */
		private var _selectedItem:IToggle;
		
		/**
		 * The currently selected toggle.
		 */
		public function get selectedItem():IToggle
		{
			return this._selectedItem;
		}
		
		/**
		 * @private
		 */
		public function set selectedItem(value:IToggle):void
		{
			this._selectedIndex = this._items.indexOf(value);
			if(this._selectedIndex >= 0)
			{
				this._selectedItem = value;
			}
			else if(!value)
			{
				this._selectedItem = null;
			}
			else
			{
				throw new IllegalOperationError("Cannot select an item that isn't registered with this ToggleGroup.");
			}
			this._ignoreChanges = true;
			for each(var item:IToggle in this._items)
			{
				if(item == value)
				{
					item.isSelected = true;
				}
				else
				{
					item.isSelected = false;
				}
			}
			this._ignoreChanges = false;
			this._onChange.dispatch(this);
		}
		
		/**
		 * @private
		 */
		private var _selectedIndex:int = -1;
		
		/**
		 * The index of the currently selected toggle.
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
			if(value < 0 || value >= this._items.length)
			{
				throw new RangeError("Index " + value + " is out of range " + this._items.length + " for ToggleGroup.");
			}
			this.selectedItem = this._items[value];
		}
		
		/**
		 * @private
		 */
		protected var _onChange:Signal = new Signal(ToggleGroup);
		
		/**
		 * Dispatched when the selection changes.
		 */
		public function get onChange():ISignal
		{
			return this._onChange;
		}
		
		/**
		 * Adds a toggle to the group. If it is the first one, it is
		 * automatically selected.
		 */
		public function addItem(item:IToggle):void
		{
			if(!item)
			{
				throw new ArgumentError("IToggle passed to ToggleGroup addItem() must not be null.");
			}
			
			const index:int = this._items.indexOf(item);
			if(index >= 0)
			{
				throw new IllegalOperationError("Cannot add an item to a ToggleGroup more than once.");
			}
			this._items.push(item);
			if(!this._selectedItem)
			{
				this.selectedItem = item;
			}
			else
			{
				item.isSelected = false;
			}
			item.onChange.add(item_onChange);
		}
		
		/**
		 * Removes a toggle from the group.
		 */
		public function removeItem(item:IToggle):void
		{
			const index:int = this._items.indexOf(item);
			if(index < 0)
			{
				return;
			}
			item.onChange.remove(item_onChange);
			this._items.splice(index, 1);
			if(this._selectedItem == item)
			{
				this.selectedIndex = -1;
			}
		}
		
		/**
		 * @private
		 */
		private function item_onChange(item:IToggle):void
		{
			if(this._ignoreChanges)
			{
				return;
			}
			
			if(item.isSelected || this._selectedItem == item)
			{
				this.selectedItem = item;
			}
		}

	}
}