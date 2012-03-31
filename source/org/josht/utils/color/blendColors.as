////////////////////////////////////////////////////////////////////////////////
//
//  Copyright (c) 2010 Josh Tynjala
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to 
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//
////////////////////////////////////////////////////////////////////////////////

package org.josht.utils.color
{
	/**
	 * Blends two color values.
	 * 
	 * @param color1		The first color to blend.
	 * @param color2		The second color to blend.
	 * @param percent		The amount of the furst color to use, in the range 0.0 - 1.0
	 * 						where the amount of the second color to use is <code>1 - percent</code>.
	 */
	public function blendColors(color1:uint, color2:uint, percent:Number = 0.5):uint
	{
		var remaining:Number = 1 - percent;
		
		var red:uint = uintToRed(color1);
		var green:uint = uintToGreen(color1);
		var blue:uint = uintToBlue(color1);
		color1 = uintFromRGB(red * percent, green * percent, blue * percent);
		
		red = uintToRed(color2);
		green = uintToGreen(color2);
		blue = uintToBlue(color2);
		color2 = uintFromRGB(red * remaining, green * remaining, blue * remaining);
		
		return color1 + color2;
	}
}