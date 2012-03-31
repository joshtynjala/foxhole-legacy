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
	import flash.errors.IllegalOperationError;
	
	import org.osflash.signals.ISignal;
	import org.osflash.signals.Signal;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	
	/**
	 * A "view stack"-like container that supports navigation between screens
	 * (any display object) through events.
	 * 
	 * @see ScreenNavigatorItem
	 * @see Screen
	 */
	public class ScreenNavigator extends Sprite
	{
		/**
		 * Constructor.
		 */
		public function ScreenNavigator()
		{
			super();
		}
		
		/**
		 * @private
		 */
		private var _activeScreenID:String;
		
		/**
		 * The string identifier for the currently active screen.
		 */
		public function get activeScreenID():String
		{
			return this._activeScreenID;
		}
		
		/**
		 * @private
		 */
		private var _activeScreen:DisplayObject;
		
		/**
		 * A reference to the currently active screen.
		 */
		public function get activeScreen():DisplayObject
		{
			return this._activeScreen;
		}
		
		/**
		 * A function that is called when the <code>ScreenNavigator</code> is
		 * changing screens.
		 */
		public var transition:Function = defaultTransition;
		
		private var _screens:Object = {};
		private var _screenEvents:Object = {};
		
		/**
		 * The identifier of the "default" screen.
		 * 
		 * @see showDefaultScreen
		 */
		public var defaultScreenID:String;
		
		private var _transitionIsActive:Boolean = false;
		private var _previousScreenInTransition:DisplayObject;
		private var _nextScreenID:String = null;
		private var _clearAfterTransition:Boolean = false;
		
		/**
		 * @private
		 */
		private var _onChange:Signal = new Signal(ScreenNavigator, DisplayObject);
		
		/**
		 * Dispatched when the active screen changes.
		 */
		public function get onChange():ISignal
		{
			return this._onChange;
		}
		
		/**
		 * @private
		 */
		private var _onClear:Signal = new Signal(ScreenNavigator);
		
		/**
		 * Dispatched when the current screen is removed and there is no active
		 * screen. 
		 */
		public function get onClear():ISignal
		{
			return this._onClear;
		}
		
		/**
		 * Displays a screen and returns a reference to it. If a previous
		 * transition is running, the new screen will be queued, and no
		 * reference will be returned.
		 */
		public function showScreen(id:String):DisplayObject
		{
			if(!this._screens.hasOwnProperty(id))
			{
				throw new IllegalOperationError("Screen with id '" + id + "' cannot be shown because it has not been defined.");
			}
			
			if(this._activeScreenID == id)
			{
				return this._activeScreen;
			}
			
			if(this._transitionIsActive)
			{
				this._nextScreenID = id;
				this._clearAfterTransition = false;
				return null;
			}
			
			this._previousScreenInTransition = this._activeScreen;
			if(this._activeScreen)
			{
				this.clearScreenInternal(false);
			}
			
			const item:ScreenNavigatorItem = ScreenNavigatorItem(this._screens[id]);
			this._activeScreen = item.getScreen();
			this._activeScreenID = id;
			
			const events:Object = item.events;
			const savedScreenEvents:Object = {};
			for(var eventName:String in events)
			{
				var signal:ISignal = this._activeScreen.hasOwnProperty(eventName) ? (this._activeScreen[eventName] as ISignal) : null;
				var eventAction:Object = events[eventName];
				if(eventAction is Function)
				{
					if(signal)
					{
						signal.add(eventAction as Function);
					}
					else
					{
						this._activeScreen.addEventListener(eventName, eventAction as Function);
					}
				}
				else if(eventAction is String)
				{
					var eventListener:Function = this.createScreenListener(eventAction as String);
					if(signal)
					{
						signal.add(eventListener);
					}
					else
					{
						this._activeScreen.addEventListener(eventName, eventListener);
					}
					savedScreenEvents[eventName] = eventListener;
				}
				else
				{
					throw new TypeError("Unknown event action defined for screen:", eventAction.toString());
				}
			}
			
			this._screenEvents[id] = savedScreenEvents;
			
			this.addChild(this._activeScreen);
			
			this._transitionIsActive = true;
			this.transition(this._previousScreenInTransition, this._activeScreen, transitionComplete);
			
			this._onChange.dispatch(this, this._activeScreen);
			return this._activeScreen;
		}
		
		/**
		 * Shows the "default" screen.
		 * 
		 * @see defaultScreenID
		 */
		public function showDefaultScreen():DisplayObject
		{
			if(!this.defaultScreenID)
			{
				throw new IllegalOperationError("Cannot show default screen because the default screen ID has not been defined.");
			}
			return this.showScreen(this.defaultScreenID);
		}
		
		/**
		 * Removes the current screen, leaving the <code>ScreenNavigator</code>
		 * empty.
		 */
		public function clearScreen():void
		{
			if(this._transitionIsActive)
			{
				this._nextScreenID = null;
				this._clearAfterTransition = true;
				return;
			}
			
			this.clearScreenInternal(true);
			this._onClear.dispatch(this);
		}
		
		/**
		 * @private
		 */
		private function clearScreenInternal(displayTransition:Boolean):void
		{
			if(!this._activeScreen)
			{
				//no screen visible.
				return;
			}
			
			const item:ScreenNavigatorItem = ScreenNavigatorItem(this._screens[this._activeScreenID]);
			const events:Object = item.events;
			const savedScreenEvents:Object = this._screenEvents[this._activeScreenID];
			for(var eventName:String in events)
			{
				var signal:ISignal = this._activeScreen.hasOwnProperty(eventName) ? (this._activeScreen[eventName] as ISignal) : null;
				var eventAction:Object = events[eventName];
				if(eventAction is Function)
				{
					if(signal)
					{
						signal.remove(eventAction as Function);
					}
					else
					{
						this._activeScreen.removeEventListener(eventName, eventAction as Function);
					}
				}
				else if(eventAction is String)
				{
					var eventListener:Function = savedScreenEvents[eventName] as Function;
					if(signal)
					{
						signal.remove(eventListener);
					}
					else
					{
						this._activeScreen.removeEventListener(eventName, eventListener);
					}
				}
			}
			
			if(displayTransition)
			{
				this._transitionIsActive = true;
				this._previousScreenInTransition = this._activeScreen;
				this.transition(this._previousScreenInTransition, null, transitionComplete);
			}
			this._screenEvents[this._activeScreenID] = null;
			this._activeScreen = null;
			this._activeScreenID = null;
		}
		
		/**
		 * Registers a new screen by its identifier.
		 */
		public function addScreen(id:String, item:ScreenNavigatorItem):void
		{
			if(this._screens.hasOwnProperty(id))
			{
				throw new IllegalOperationError("Screen with id '" + id + "' already defined. Cannot add two screens with the same id.");
			}
			
			if(!this.defaultScreenID)
			{
				//the first screen will set the default ID if it is not set already
				this.defaultScreenID = id;
			}
			
			this._screens[id] = item;
		}
		
		/**
		 * Removes an existing screen using its identifier.
		 */
		public function removeScreen(id:String):void
		{
			if(!this._screens.hasOwnProperty(id))
			{
				throw new IllegalOperationError("Screen '" + id + "' cannot be removed because it has not been added.");
			}
			delete this._screens[id];
		}
		
		/**
		 * @private
		 */
		private function defaultTransition(oldScreen:DisplayObject, newScreen:DisplayObject, completeHandler:Function):void
		{
			//in short, do nothing
			completeHandler();
		}
		
		/**
		 * @private
		 */
		private function transitionComplete():void
		{
			if(this._previousScreenInTransition)
			{
				this.removeChild(this._previousScreenInTransition);
				this._previousScreenInTransition = null;
			}
			this._transitionIsActive = false;
			
			if(this._clearAfterTransition)
			{
				this.clearScreen();
			}
			else if(this._nextScreenID)
			{
				this.showScreen(this._nextScreenID);
			}
			
			this._nextScreenID = null;
			this._clearAfterTransition = false;
		}
		
		/**
		 * @private
		 */
		private function createScreenListener(screenID:String):Function
		{
			const self:ScreenNavigator = this;
			const eventListener:Function = function(...rest:Array):void
			{
				self.showScreen(screenID);
			}
			
			return eventListener;
		}
	}
	
}