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
package org.josht.starling.foxhole.layout
{
	import org.osflash.signals.ISignal;
	
	import starling.display.DisplayObject;

	/**
	 * Interface providing layout capabilities for containers.
	 */
	public interface ILayout
	{
		/**
		 * Dispatched when a property of the layout changes, indicating that a
		 * redraw is probably needed.
		 */
		function get onLayoutChange():ISignal;
		
		//jxadded
		function set paddingLeft( value:Number ):void;
		function get paddingLeft():Number;
		function set paddingRight( value:Number ):void;
		function get paddingRight():Number;
		function set paddingTop( value:Number ):void;
		function get paddingTop():Number;
		function set paddingBottom( value:Number ):void;
		function get paddingBottom():Number;
		function set gap( value:Number ):void;
		function get gap():Number;

		/**
		 * Positions (and possibly resizes) the supplied items within the
		 * optional bounds argument. If no bounds are specified, the layout
		 * algorithm will assume that the bounds start a 0,0 and have unbounded
		 * dimensions. Returns the actual bounds of the content, which may
		 * be different than the specified bounds.
		 *
		 * <p>Note: The items are <strong>not</strong> absolutely
		 * restricted to appear only within the bounds. The bounds can affect
		 * positioning, but the algorithm may very well ignore them completely.</p>
		 *
		 */
		function layout(items:Vector.<DisplayObject>, viewPortBounds:ViewPortBounds = null, result:LayoutBoundsResult = null):LayoutBoundsResult;
	}
}
