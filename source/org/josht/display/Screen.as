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
package org.josht.display
{
	import flash.display.DisplayObjectContainer;
	import flash.display.LoaderInfo;
	import flash.events.KeyboardEvent;
	import flash.system.Capabilities;
	import flash.ui.Keyboard;
	
	import org.josht.utils.display.calculateScaleRatioToFit;
	
	import flash.display.Sprite;
	import flash.events.Event;
	
	/**
	 * Provides useful capabilities for a menu screen displayed by
	 * <code>ScreenNavigator</code>.
	 * 
	 * @see ScreenNavigator
	 */
	public class Screen extends Sprite
	{
		/**
		 * Constructor.
		 */
		public function Screen()
		{
			super();
			this.addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
		}
		
		/**
		 * @private
		 */
		private var _originalWidth:Number = NaN;
		
		/**
		 * The original intended width of the application. If not set manually,
		 * <code>loaderInfo.width</code> is automatically detected (to get
		 * width value from <code>[SWF]</code> metadata.
		 */
		public function get originalWidth():Number
		{
			return this._originalWidth;
		}
		
		/**
		 * @private
		 */
		public function set originalWidth(value:Number):void
		{
			this._originalWidth = value;
		}
		
		/**
		 * @private
		 */
		private var _originalHeight:Number = NaN;
		
		/**
		 * The original intended height of the application. If not set manually,
		 * <code>loaderInfo.height</code> is automatically detected (to get
		 * height value from <code>[SWF]</code> metadata.
		 */
		public function get originalHeight():Number
		{
			return this._originalHeight;
		}
		
		/**
		 * @private
		 */
		public function set originalHeight(value:Number):void
		{
			this._originalHeight = value;
		}
		
		/**
		 * @private
		 */
		private var _originalDPI:int = 168;
		
		/**
		 * The original intended DPI of the application. This value cannot be
		 * automatically detected and it must be set manually.
		 */
		public function get originalDPI():int
		{
			return this._originalDPI;
		}
		
		/**
		 * @private
		 */
		public function set originalDPI(value:int):void
		{
			this._originalDPI = value;
		}
		
		private var _initialized:Boolean = false;
		
		/**
		 * @private
		 */
		private var _pixelScale:Number = 1;
		
		/**
		 * Uses <code>originalWidth</code>, <code>originalHeight</code>,
		 * <code>stage.stageWidth</code>, and <code>stage.stageHeight</code>,
		 * to calculate a scale value that will allow all content will fit
		 * within the current stage bounds using the same relative layout. This
		 * scale value does not account for differences between the original DPI
		 * and the current device's DPI.
		 */
		protected function get pixelScale():Number
		{
			return this._pixelScale;
		}
		
		/**
		 * @private
		 */
		private var _dpiScale:Number = 1;
		
		/**
		 * Uses <code>originalDPI</code> and <code>Capabilities.screenDPI</code>
		 * to calculate a scale value to allow all content to be the same
		 * physical size (in inches). Using this value will have a much larger
		 * effect on the layout of the content, but it can ensure that
		 * interactive items won't be scaled too small to affect the accuracy
		 * of touches. Likewise, it won't scale items to become ridiculously
		 * physically large. Most useful when targeting many different platforms
		 * with the same code.
		 */
		protected function get dpiScale():Number
		{
			return this._dpiScale;
		}
		
		/**
		 * Callback for the back hardware key. Automatically handles keyboard
		 * events to cancel to default behavior.
		 */
		protected var backButtonHandler:Function;
		
		/**
		 * Callback for the menu hardware key. Automatically handles keyboard
		 * events to cancel to default behavior.
		 */
		protected var menuButtonHandler:Function;
		
		/**
		 * Callback for the search hardware key. Automatically handles keyboard
		 * events to cancel to default behavior.
		 */
		protected var searchButtonHandler:Function;
		
		/**
		 * Override this function to create and initialize the children to be
		 * displayed in this screen.
		 */
		protected function initialize():void
		{
			
		}
		
		/**
		 * Override this function to size and position this screen's content.
		 * This function will be called again every time that the stage changes
		 * size. On Android and other platforms, this can happen many times on
		 * startup. On desktop platforms with resizable windows, this may be
		 * useful for setting up fluid layouts.
		 */
		protected function layout():void
		{
			
		}
		
		/**
		 * Override this function to clean up anything when this screen is
		 * removed from the display list.
		 */
		protected function destroy():void
		{
			
		}
		
		/**
		 * @private
		 */
		private function refreshScaleRatio():void
		{
			if(isNaN(this._originalWidth))
			{
				try
				{
					this._originalWidth = this.loaderInfo.width
				} 
				catch(error:Error) 
				{
					this._originalWidth = this.stage.stageWidth;
				}
			}
			if(isNaN(this._originalHeight))
			{
				try
				{
					this._originalHeight = this.loaderInfo.height;
				} 
				catch(error:Error) 
				{
					this._originalHeight = this.stage.stageHeight;
				}
			}
			this._pixelScale = calculateScaleRatioToFit(originalWidth, originalHeight, this.stage.stageWidth, this.stage.stageHeight);
			this._dpiScale = Capabilities.screenDPI / this._originalDPI;
		}
		
		/**
		 * @private
		 */
		private function addedToStageHandler(event:Event):void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
			this.addEventListener(Event.REMOVED_FROM_STAGE, removedFromStageHandler);
			this.stage.addEventListener(Event.RESIZE, stage_resizeHandler, false, 0, true);
			this.stage.addEventListener(KeyboardEvent.KEY_DOWN, stage_keyDownHandler, false, 0, true);
			if(!this._initialized)
			{
				this.refreshScaleRatio();
				this.initialize();
				this.layout();
				this._initialized = true;
			}
		}
		
		/**
		 * @private
		 */
		private function stage_resizeHandler(event:Event):void
		{
			this.refreshScaleRatio();
			this.layout();
		}
		
		/**
		 * @private
		 */
		private function stage_keyDownHandler(event:KeyboardEvent):void
		{
			//we're accessing Keyboard.BACK (and others) using a string because
			//this code may be compiled for both Flash Player and AIR.
			if(this.backButtonHandler != null &&
				Object(Keyboard).hasOwnProperty("BACK") &&
				event.keyCode == Keyboard["BACK"])
			{
				event.stopImmediatePropagation();
				event.preventDefault();
				this.backButtonHandler();
			}
			
			if(this.menuButtonHandler != null &&
				Object(Keyboard).hasOwnProperty("MENU") &&
				event.keyCode == Keyboard["MENU"])
			{
				event.preventDefault();
				this.menuButtonHandler();
			}
			
			if(this.searchButtonHandler != null &&
				Object(Keyboard).hasOwnProperty("SEARCH") &&
				event.keyCode == Keyboard["SEARCH"])
			{
				event.preventDefault();
				this.searchButtonHandler();
			}
		}
		
		/**
		 * @private
		 */
		private function removedFromStageHandler(event:Event):void
		{
			this.removeEventListener(Event.REMOVED_FROM_STAGE, removedFromStageHandler);
			this.stage.removeEventListener(Event.RESIZE, stage_resizeHandler);
			this.stage.removeEventListener(KeyboardEvent.KEY_DOWN, stage_keyDownHandler);
			this.destroy();
			this.addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
		}
	}
}