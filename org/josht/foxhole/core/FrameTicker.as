package org.josht.foxhole.core
{
	import flash.display.Shape;
	import flash.events.Event;
	import flash.utils.getTimer;

	public class FrameTicker
	{
		private static const source:Shape = new Shape();
		
		private static const typeToVector:Object = {};
		
		public static function addEnterFrameCallback(callback:Function):void
		{
			addCallback(Event.ENTER_FRAME, callback);
		}
		
		public static function removeEnterFrameCallback(callback:Function):void
		{
			removeCallback(Event.ENTER_FRAME, callback);
		}
		
		public static function addExitFrameCallback(callback:Function):void
		{
			addCallback(Event.EXIT_FRAME, callback);
		}
		
		public static function removeExitFrameCallback(callback:Function):void
		{
			removeCallback(Event.EXIT_FRAME, callback);
		}
		
		public static function addFrameConstructedCallback(callback:Function):void
		{
			addCallback(Event.FRAME_CONSTRUCTED, callback);
		}
		
		public static function removeFrameConstructedCallback(callback:Function):void
		{
			removeCallback(Event.FRAME_CONSTRUCTED, callback);
		}
		
		private static function addCallback(type:String, callback:Function):void
		{
			var callbacks:Vector.<Function> = getCallbacks(type);
			if(callbacks.indexOf(callback) >= 0)
			{
				//ignore a callback that has already been added
				return;
			}
			
			callbacks.push(callback);
			
			if(callbacks.length == 1)
			{
				source.addEventListener(type, callbackHandler);
			}
		}
		
		private static function removeCallback(type:String, callback:Function):void
		{
			var callbacks:Vector.<Function> = getCallbacks(type);
			var index:int = callbacks.indexOf(callback);
			if(index < 0)
			{
				//if not found, do nothing. same as removeEventListener().
				return;
			}
			
			callbacks.splice(index, 1);
			if(callbacks.length == 0)
			{
				source.removeEventListener(type, callbackHandler);
			}
		}
		
		private static function getCallbacks(type:String):Vector.<Function>
		{
			var callbacks:Vector.<Function> = typeToVector[type] as Vector.<Function>;
			if(!callbacks)
			{
				callbacks = new Vector.<Function>;
				typeToVector[type] = callbacks
			}
			return callbacks;
		}
		
		private static function callbackHandler(event:Event):void
		{
			var callbacks:Vector.<Function> = getCallbacks(event.type);
			var callbackCount:int = callbacks.length;
			for(var i:int = 0; i < callbackCount; i++)
			{
				var callback:Function = callbacks[i];
				callback();
			}
		}
	}
}