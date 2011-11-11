package org.josht.foxhole.core
{
	import fl.managers.StyleManager;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Shape;
	import flash.display.Stage;
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;

	public class PopUpManager
	{
		private static const POPUP_TO_OVERLAY:Dictionary = new Dictionary(true);
		
		public static function addPopUp(popUp:DisplayObject, stage:Stage, isCentered:Boolean = true):void
		{
			var backgroundSkin:Object = StyleManager.getComponentStyle("PopUpManager", "backgroundSkin");
			if(backgroundSkin is String)
			{
				backgroundSkin = getDefinitionByName(backgroundSkin as String);
			}
			if(backgroundSkin is Class)
			{
				backgroundSkin = new backgroundSkin();
			}
			
			var bitmapData:BitmapData;
			if(backgroundSkin is BitmapData)
			{
				bitmapData = BitmapData(backgroundSkin);
			}
			else if(backgroundSkin is DisplayObject)
			{
				const displaySkin:DisplayObject = DisplayObject(backgroundSkin);
				if(displaySkin is Bitmap)
				{
					bitmapData = Bitmap(displaySkin).bitmapData;
				}
				else
				{
					bitmapData = new BitmapData(displaySkin.width, displaySkin.height, true, 0x00000000);
					bitmapData.draw(displaySkin);
				}
			}
			
			const overlay:Shape = new Shape();
			if(bitmapData)
			{
				overlay.graphics.beginBitmapFill(bitmapData);
			}
			else
			{
				overlay.graphics.beginFill(0xff00ff, 0);
			}
			overlay.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			stage.addChild(overlay);
			POPUP_TO_OVERLAY[popUp] = overlay;
			stage.addChild(popUp);
			
			if(isCentered)
			{
				centerPopUp(popUp, stage);
			}
		}
		
		public static function removePopUp(popUp:DisplayObject):void
		{
			const overlay:Shape = Shape(POPUP_TO_OVERLAY[popUp]);
			if(!overlay)
			{
				throw IllegalOperationError("Cannot remove display object as pop up because it is not a pop up.");
			}
			delete POPUP_TO_OVERLAY[popUp];
			
			overlay.parent.removeChild(overlay);
			popUp.parent.removeChild(popUp);
		}
		
		private static function centerPopUp(popUp:DisplayObject, stage:Stage):void
		{
			popUp.x = (stage.stageWidth - popUp.width) / 2;
			popUp.y = (stage.stageHeight - popUp.height) / 2;
		}
	}
}