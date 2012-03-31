package org.josht.utils.display
{
	/**
	 * Calculates a scale value to maintain aspect ratio and fill the required
	 * bounds (with the possibility of cutting of the edges a bit).
	 */
	public function calculateScaleRatioToFill(originalWidth:Number, originalHeight:Number, targetWidth:Number, targetHeight:Number):Number
	{
		var widthRatio:Number = targetWidth / originalWidth;
		var heightRatio:Number = targetHeight / originalHeight;
		return Math.max(widthRatio, heightRatio);
	}
}