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
package feathers.display
{
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import starling.core.RenderSupport;
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.textures.Texture;
	import starling.utils.MatrixUtil;

	/**
	 * Adds capabilities to Starling's <code>Image</code> class, including
	 * <code>scrollRect</code> and pixel snapping.
	 */
	public class Image extends starling.display.Image implements IDisplayObjectWithScrollRect
	{
		private static var helperPoint:Point = new Point();
		private static var helperMatrix:Matrix = new Matrix();
		private static var helperRectangle:Rectangle = new Rectangle();
		
		/**
		 * Constructor.
		 * 
		 * jx: 加上 textureScale 支援
		 */
		public function Image(texture:Texture, _textureScale:Number = 1)
		{
			super(texture);
			
			//jxadded
			this._textureScale = _textureScale;
			readjustSize()
		}
		
		//---------------------------------------------------------------
		//
		// 測: 加上支援 textureScale 功能，像 Scale3Image, Scale9Image 一樣
		// 可做一張 320 大圖，自動縮小為 240, 160
		
		/**
		 * jxadded
		 * @private
		 */
		private var _textureScale:Number = 1;
		
		/**
		 * jxadded
		 * The amount to scale the texture. Useful for DPI changes.
		 */
		public function get textureScale():Number
		{
			return this._textureScale;
		}
		
		//jxadded
		private var _layoutChanged:Boolean;
		
		/**
		 * jxadded
		 * @private
		 */
		public function set textureScale(value:Number):void
		{
			if(this._textureScale == value)
			{
				return;
			}
			this._textureScale = value;
			this._layoutChanged = true;
			
			//只要 scale 改變，就立即套用新的縮放值
			readjustSize();
		}
		
		/**
		 * jxadded: 故意不 call super, 因為 logic 不同
		 */
		override public function readjustSize():void
		{
//			return;			
			//trace("\n\nsuper 原本做的事 = ", _textureScale);
			
			//starling.Image.readjustSize() 原本做的事
//			var frame:Rectangle = texture.frame;
//			var width:Number  = frame ? frame.width  : texture.width;
//			var height:Number = frame ? frame.height : texture.height;
			
//			var frame:Rectangle = this.texture.frame;
//			this.width = frame.width;
//			this.height = frame.height;
			
			var frame:Rectangle = this.texture.frame;
			this.width = frame ?  frame.width * this._textureScale : texture.width;
			this.height = frame ? frame.height * this._textureScale : texture.height;
			
			/*
			mVertexData.setPosition(0, 0.0, 0.0);
			mVertexData.setPosition(1, width, 0.0);
			mVertexData.setPosition(2, 0.0, height);
			mVertexData.setPosition(3, width, height); 
			
			onVertexDataChanged();
			*/
		}

		// ↑ Sep 22, 2012
		//---------------------------------------------------------------
		
		
		//jxadded
		private var _width:Number;
		
		//jxadded
		override public function get width():Number
		{
			return getBounds(this.parent, helperRectangle).width;
		}
		
		/**
		 * @private
		 */
		override public function set width(value:Number):void
		{
			var actualWidth:Number = super.getBounds(this, helperRectangle).width;
			
			//jx: 這個也是我拿掉的，因為跑 super() 就會啟動 DisplayObject的 scaleX 計算，然後就破壞了我的比例
			//super.width = value;
			_width = value;
			
			//we need to override the default scaleX modification here because
			//the "actual" width is modified by the scroll rect.
			if(actualWidth != 0.0)
			{
				this.scaleX = value / actualWidth;	
				//trace("改過的 scaleX = ", this.scaleX, value );
			}
			else
			{
				this.scaleX = 1.0;
			}
		}
		
		//jxadded
		private var _height:Number;
		
		//jxadded
		override public function get height():Number
		{
			return getBounds(this.parent, helperRectangle).height;
		}

		/**
		 * @private
		 */
		override public function set height(value:Number):void
		{
			var actualHeight:Number = super.getBounds(this, helperRectangle).height;
			
			//jx: 不可跑 super, 會破壞 scaleY
			//super.height = value;
			if(actualHeight != 0.0)
			{
				//jx
				this.scaleY = value / actualHeight;
			}
			else
			{
				this.scaleY = 1.0;
			}
		}
		
		/**
		 * @private
		 */
		private var _scrollRect:Rectangle;
		
		/**
		 * @inheritDoc
		 */
		public function get scrollRect():Rectangle
		{
			return this._scrollRect;
		}
		
		/**
		 * @private
		 */
		public function set scrollRect(value:Rectangle):void
		{
			this._scrollRect = value;
			if(this._scrollRect)
			{
				if(!this._scaledScrollRectXY)
				{
					this._scaledScrollRectXY = new Point();
				}
				if(!this._scissorRect)
				{
					this._scissorRect = new Rectangle();
				}
			}
			else
			{
				this._scaledScrollRectXY = null;
				this._scissorRect = null;
			}
		}
		
		private var _scaledScrollRectXY:Point = new Point();
		private var _scissorRect:Rectangle = new Rectangle();

		/**
		 * @private
		 */
		private var _snapToPixels:Boolean = false;

		/**
		 * Determines if the image should be snapped to the nearest global whole
		 * pixel when rendered.
		 */
		public function get snapToPixels():Boolean
		{
			return _snapToPixels;
		}

		/**
		 * @private
		 */
		public function set snapToPixels(value:Boolean):void
		{
			if(this._snapToPixels == value)
			{
				return;
			}
			this._snapToPixels = value;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
		{
			if(this._scrollRect)
			{
				if(!resultRect)
				{
					resultRect = new Rectangle();
				}
				if(targetSpace == this)
				{
					resultRect.x = 0;
					resultRect.y = 0;
					resultRect.width = this._scrollRect.width;
					resultRect.height = this._scrollRect.height;
				}
				else
				{
					this.getTransformationMatrix(targetSpace, helperMatrix);
					MatrixUtil.transformCoords(helperMatrix, 0, 0, helperPoint);
					resultRect.x = helperPoint.x;
					resultRect.y = helperPoint.y;
					resultRect.width = helperMatrix.a * this._scrollRect.width + helperMatrix.c * this._scrollRect.height;
					resultRect.height = helperMatrix.d * this._scrollRect.height + helperMatrix.b * this._scrollRect.width;
				}
				return resultRect;
			}
			return super.getBounds(targetSpace, resultRect);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function render(support:RenderSupport, alpha:Number):void
		{
			if(this._scrollRect)
			{
				const scale:Number = Starling.contentScaleFactor;
				this.getBounds(this.stage, this._scissorRect);
				this._scissorRect.x *= scale;
				this._scissorRect.y *= scale;
				this._scissorRect.width *= scale;
				this._scissorRect.height *= scale;
				
				this.getTransformationMatrix(this.stage, helperMatrix);
				this._scaledScrollRectXY.x = this._scrollRect.x * helperMatrix.a;
				this._scaledScrollRectXY.y = this._scrollRect.y * helperMatrix.d;
				
				const oldRect:Rectangle = ScrollRectManager.currentScissorRect;
				if(oldRect)
				{
					this._scissorRect.x += ScrollRectManager.scrollRectOffsetX * scale;
					this._scissorRect.y += ScrollRectManager.scrollRectOffsetY * scale;
					this._scissorRect = this._scissorRect.intersection(oldRect);
				}
				if(this._scissorRect.width < 1 || this._scissorRect.height < 1 ||
					this._scissorRect.x >= Starling.current.nativeStage.stageWidth ||
					this._scissorRect.y >= Starling.current.nativeStage.stageHeight ||
					(this._scissorRect.x + this._scissorRect.width) <= 0 ||
					(this._scissorRect.y + this._scissorRect.height) <= 0)
				{
					return;
				}
				support.finishQuadBatch();
				Starling.context.setScissorRectangle(this._scissorRect);
				ScrollRectManager.currentScissorRect = this._scissorRect;
				ScrollRectManager.scrollRectOffsetX -= this._scaledScrollRectXY.x;
				ScrollRectManager.scrollRectOffsetY -= this._scaledScrollRectXY.y;
				support.translateMatrix(-this._scrollRect.x, -this._scrollRect.y);
			}
			if(this._snapToPixels)
			{
				this.getTransformationMatrix(this.stage, helperMatrix);
				support.translateMatrix(Math.round(helperMatrix.tx) - helperMatrix.tx, Math.round(helperMatrix.ty) - helperMatrix.ty);
			}
			super.render(support, alpha);
			if(this._scrollRect)
			{
				support.finishQuadBatch();
			}
			if(this._snapToPixels)
			{
				support.translateMatrix(-(Math.round(helperMatrix.tx) - helperMatrix.tx), -(Math.round(helperMatrix.ty) - helperMatrix.ty));
			}
			if(this._scrollRect)
			{
				support.translateMatrix(this._scrollRect.x, this._scrollRect.y);
				ScrollRectManager.scrollRectOffsetX += this._scaledScrollRectXY.x;
				ScrollRectManager.scrollRectOffsetY += this._scaledScrollRectXY.y;
				ScrollRectManager.currentScissorRect = oldRect;
				Starling.context.setScissorRectangle(oldRect);
			}
		}
	}
}