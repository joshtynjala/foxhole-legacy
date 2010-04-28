package org.josht.foxhole.controls
{
	import fl.core.InvalidationType;
	
	import flash.display.DisplayObject;
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import org.josht.foxhole.controls.Button;
	import org.josht.foxhole.core.IToggle;
	
	//--------------------------------------
	//  Styles
	//--------------------------------------
	
	/**
	 * The class that provides the skin for the up state of the component when
	 * the component is selected.
	 *
	 * @default Button_selectedUpSkin
	 */
	[Style(name="selectedUpSkin", type="Class")]
	
	/**
	 * The class that provides the skin for the down state of the component when
	 * the component is selected.
	 *
	 * @default Button_selectedDownSkin
	 */
	[Style(name="selectedDownSkin", type="Class")]
	
	public class ToggleButton extends Button implements IToggle
	{
		private static const STATE_SELECTED_UP:String = "selectedUp";
		private static const STATE_SELECTED_DOWN:String = "selectedDown";
		
	//--------------------------------------
	//  Static Properties
	//--------------------------------------
		
		private static var defaultStyles:Object =
		{
			selectedUpSkin: "Button_selectedUpSkin",
			selectedDownSkin: "Button_selectedDownSkin"
		};
		
	//--------------------------------------
	//  Static Methods
	//--------------------------------------
		
		public static function getStyleDefinition():Object
		{ 
			return mergeStyles(defaultStyles, Button.getStyleDefinition());
		}
		
	//--------------------------------------
	//  Constructor
	//--------------------------------------
		
		public function ToggleButton()
		{
			super();
			this.addEventListener(MouseEvent.CLICK, clickHandler);
		}
		
	//--------------------------------------
	//  Properties
	//--------------------------------------
		
		private var _toggle:Boolean = true;

		public function get toggle():Boolean
		{
			return this._toggle;
		}

		public function set toggle(value:Boolean):void
		{
			this._toggle = value;
		}

		private var _selected:Boolean = false;

		public function get selected():Boolean
		{
			return this._selected;
		}

		public function set selected(value:Boolean):void
		{
			this._selected = value;
			this.currentState = this.currentState;
			this.invalidate(InvalidationType.SELECTED);
			this.invalidate(InvalidationType.STATE);
			this.dispatchEvent(new Event(Event.CHANGE));
		}
		
		override protected function set currentState(value:String):void
		{
			if(this._selected && value.indexOf("selected") < 0)
			{
				value = "selected" + String.fromCharCode(value.substr(0, 1).charCodeAt(0) - 32) + value.substr(1);
			}
			else if(!this._selected && value.indexOf("selected") == 0)
			{
				value = String.fromCharCode(value.substr(8, 1).charCodeAt(0) + 32) + value.substr(9);
			}
			super.currentState = value;
		}
		
		override protected function get stateNames():Vector.<String>
		{
			return super.stateNames.concat(Vector.<String>([STATE_SELECTED_UP, STATE_SELECTED_DOWN]));
		}
		
	//--------------------------------------
	//  Private Event Handlers
	//--------------------------------------
		
		private function clickHandler(event:MouseEvent):void
		{
			if(this.toggle)
			{
				this.selected = !this.selected;
			}
		}
		
	}
}