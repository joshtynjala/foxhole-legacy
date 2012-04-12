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
	import flash.display.Stage;
	import flash.events.Event;
	import flash.utils.getTimer;
	
	/**
	 * Displays the frames per second.
	 */
	public class FPSDisplay extends Label
	{
		/**
		 * Constructor.
		 */
		public function FPSDisplay()
		{
			super();
			this.text = "0";
			this.mouseEnabled = this.mouseChildren = false;
			this.addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
		}
		
		private var _frameCount:int = 0;
		private var _elapsedTime:Number = 0;
		private var _lastUpdate:int;
		private var _nativeStage:Stage;
		
		/**
		 * If true, will display both the actual frame rate, and the target
		 * frame rate of the stage.
		 */
		public var showTargetFPS:Boolean = false
		
		/**
		 * @private
		 */
		private function enterFrameHandler(event:Event):void
		{
			this._frameCount++;
			const now:int = getTimer();
			this._elapsedTime += (now - this._lastUpdate);
			this._lastUpdate = now;
			
			if(this._elapsedTime >= 1000)
			{
				this.text = int(this._frameCount / (this._elapsedTime / 1000)) + (this.showTargetFPS ? " / " + this._nativeStage.frameRate : "");
				this._elapsedTime = this._frameCount = 0;
			}
		}
		
		/**
		 * @private
		 */
		private function addedToStageHandler(event:Event):void
		{
			this._lastUpdate = getTimer();
			this.removeEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
			this.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
			this.addEventListener(Event.REMOVED_FROM_STAGE, removedFromStageHandler);
		}
		
		/**
		 * @private
		 */
		private function removedFromStageHandler(event:Event):void
		{
			this.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			this.removeEventListener(Event.REMOVED_FROM_STAGE, removedFromStageHandler);
			this.addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
		}
	}
}