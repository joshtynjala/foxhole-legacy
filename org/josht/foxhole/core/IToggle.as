package org.josht.foxhole.core
{
	import flash.events.IEventDispatcher;

	[Event(name="change",type="flash.events.Event")]
	
	public interface IToggle extends IEventDispatcher
	{
		function get selected():Boolean;
		function set selected(value:Boolean):void;
	}
}