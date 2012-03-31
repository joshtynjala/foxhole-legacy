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
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.utils.Dictionary;
	
	/**
	 * Adds a display object as a pop-up to the stage.
	 */
	public class PopUpManager
	{
		private static const POPUP_TO_OVERLAY:Dictionary = new Dictionary(true);
		
		/**
		 * A function that returns a display object to use as a modal overlay.
		 */
		public static var overlayFactory:Function = function():DisplayObject
		{
			const overlay:Sprite = new Sprite();
			overlay.graphics.beginFill(0x000000, 0);
			overlay.graphics.drawRect(0, 0, 100, 100);
			overlay.graphics.endFill();
			overlay.alpha = 0;
			return overlay;
		};
		
		/**
		 * Adds a pop-up to the stage.
		 */
		public static function addPopUp(popUp:DisplayObject, stage:Stage, isCentered:Boolean = true):void
		{
			if(overlayFactory != null)
			{
				var overlay:DisplayObject = overlayFactory();
				overlay.width = stage.stageWidth;
				overlay.height = stage.stageHeight;
				stage.addChild(overlay);
				POPUP_TO_OVERLAY[popUp] = overlay;
			}
			
			stage.addChild(popUp);
			
			if(isCentered)
			{
				centerPopUp(popUp, stage);
			}
		}
		
		/**
		 * Removes a pop-up from the stage.
		 */
		public static function removePopUp(popUp:DisplayObject, dispose:Boolean = false):void
		{
			const overlay:DisplayObject = DisplayObject(POPUP_TO_OVERLAY[popUp]);
			if(overlay)
			{
				overlay.parent.removeChild(overlay);
			}
			delete POPUP_TO_OVERLAY[popUp];
			
			popUp.parent.removeChild(popUp);
		}
		
		/**
		 * @private
		 */
		private static function centerPopUp(popUp:DisplayObject, stage:Stage):void
		{
			popUp.x = (stage.stageWidth - popUp.width) / 2;
			popUp.y = (stage.stageHeight - popUp.height) / 2;
		}
	}
}