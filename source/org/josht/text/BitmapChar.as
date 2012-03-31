// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package org.josht.text
{
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.utils.Dictionary;

    /** A BitmapChar contains the information about one char of a bitmap font.  
     *  <em>You don't have to use this class directly in most cases. 
     *  The TextField class contains methods that handle bitmap fonts for you.</em>    
     */ 
    public class BitmapChar
    {
        private var mTexture:BitmapData;
        private var mCharID:int;
        private var mXOffset:Number;
        private var mYOffset:Number;
        private var mXAdvance:Number;
        private var mKernings:Dictionary;
        
        /** Creates a char with a texture and its properties. */
        public function BitmapChar(id:int, texture:BitmapData, 
                                   xOffset:Number, yOffset:Number, xAdvance:Number)
        {
            mCharID = id;
            mTexture = texture;
            mXOffset = xOffset;
            mYOffset = yOffset;
            mXAdvance = xAdvance;
            mKernings = null;
        }
        
        /** Adds kerning information relative to a specific other character ID. */
        public function addKerning(charID:int, amount:Number):void
        {
            if (mKernings == null)
                mKernings = new Dictionary();
            
            mKernings[charID] = amount;
        }
        
        /** Retrieve kerning information relative to the given character ID. */
        public function getKerning(charID:int):Number
        {
            if (mKernings == null || mKernings[charID] == undefined) return 0.0;
            else return mKernings[charID];
        }
        
        /** Creates an image of the char. */
        public function createImage(bitmap:Bitmap = null):Bitmap
        {
			if(bitmap)
			{
				bitmap.bitmapData = mTexture;
				return bitmap;
			}
            return new Bitmap(mTexture);
        }
        
        /** The unicode ID of the char. */
        public function get charID():int { return mCharID; }
        
        /** The number of pixels to move the char in x direction on character arrangement. */
        public function get xOffset():Number { return mXOffset; }
        
        /** The number of pixels to move the char in y direction on character arrangement. */
        public function get yOffset():Number { return mYOffset; }
        
        /** The number of pixels the cursor has to be moved to the right for the next char. */
        public function get xAdvance():Number { return mXAdvance; }
        
        /** The texture of the character. */
        public function get texture():BitmapData { return mTexture; }
    }
}