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
//
//  Contains third-party source code released under the following license terms:
//
//  Copyright (c) 2008, Yahoo! Inc. All rights reserved.
//  
//  Redistribution and use of this software in source and binary forms, with or
//  without modification, are permitted provided that the following conditions
//  are met:
//  
//    * Redistributions of source code must retain the above copyright notice,
//      this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright
//      notice, this list of conditions and the following disclaimer in the
//      documentation and/or other materials provided with the distribution.
//    * Neither the name of Yahoo! Inc. nor the names of its contributors may be
//      used to endorse or promote products derived from this software without
//      specific prior written permission of Yahoo! Inc.
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//
//  Source: http://developer.yahoo.com/flash/
//
////////////////////////////////////////////////////////////////////////////////

package org.josht.utils.color
{
	/**
	 * Converts hue, saturation, and brightness color components (0 - 1) to a uint
	 * color value.
	 * 
	 * @param hue			The hue component between 0 and 1
	 * @param saturation	The saturation component between 0 and 1
	 * @param brightness	The brightness component between 0 and 1
	 * @return				A combined color value
	 *
	 * @author Yahoo! (modified by Josh Tynjala)
	 */
	public function uintFromHSB(hue:Number, saturation:Number, brightness:Number):uint
	{
		if(saturation == 0)
		{
			//gray
			return uintFromRGB(brightness * 0xff, brightness * 0xff, brightness * 0xff);
		}
		
		var red:Number = 0;
		var green:Number = 0;
		var blue:Number = 0;
		
		var h:Number = hue * 6;
		var i:Number = Math.floor(h);
		var f:Number = h - i;
		var p:Number = brightness * (1 - saturation);
		var q:Number = brightness * (1 - f * saturation);
		//skip r and s because they could cause confusion with red and saturation
		var t:Number = brightness * (1 - (1 - f) * saturation);
		
		switch(i)
		{
			case 0:
			{
				red = brightness;
				green = t;
				blue = p;
				break;
			}
			case 1:
			{
				red = q;
				green = brightness;
				blue = p;
				break;
			}
			case 2:
			{
				red = p;
				green = brightness
				blue = t;
				break;
			}
			case 3:
			{
				red = p
				green = q;
				blue = brightness;
				break;
			}
			case 4:
			{
				red = t;
				green = p;
				blue = brightness;
				break;
			}
			case 5:
			{
				red = brightness;
				green = p;
				blue = q;
				break;
			}
		}
		
		//normalize all to range between 0 - 255
		red = Math.round(red * 0xff);
		green = Math.round(green * 0xff);
		blue = Math.round(blue * 0xff);
		
		return uintFromRGB(red, green, blue);
	}
}