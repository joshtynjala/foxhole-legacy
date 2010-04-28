/*
Copyright (c) 2010 Josh Tynjala

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