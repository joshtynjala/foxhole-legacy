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
package org.josht.utils.display
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.InteractiveObject;

	/**
	 * Traverses the display list starting at a target root node and sets
	 * mouseEnabled and mouseChildren to false on absolutely everything. For
	 * some reason, this lowers CPU usage better than setting mouseChildren
	 * on the root node alone. The performance improvement is even more apparent
	 * on mobile.
	 */
	public function annihilateMouse(target:DisplayObject, childrenOnly:Boolean = false):void
	{
		//no need to go on if the target isn't interactive. the typing of target
		//as DisplayObject is for convenience.
		if(!(target is InteractiveObject))
		{
			return;
		}
		const interactiveTarget:InteractiveObject = InteractiveObject(target);
		if(!childrenOnly)
		{
			interactiveTarget.mouseEnabled = false;
		}
		if(interactiveTarget is DisplayObjectContainer)
		{
			const doc:DisplayObjectContainer = DisplayObjectContainer(interactiveTarget);
			doc.mouseChildren = false;
			const childCount:int = doc.numChildren;
			for(var i:int = 0; i < childCount; i++)
			{
				var child:DisplayObject = doc.getChildAt(i);
				annihilateMouse(child);
			}
		}
	}
}