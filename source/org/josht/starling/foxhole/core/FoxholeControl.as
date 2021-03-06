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
package org.josht.starling.foxhole.core
{
	import com.pubulous.utils.GlobalUtil;
	
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.setTimeout;
	
	import org.josht.starling.display.Sprite;
	import org.josht.starling.foxhole.controls.text.BitmapFontTextRenderer;
	import org.osflash.signals.ISignal;
	import org.osflash.signals.Signal;
	
	import starling.display.DisplayObject;
	import starling.events.Event;
	import starling.utils.MatrixUtil;
	
	/**
	 * Base class for all Foxhole UI controls. Implements invalidation and sets
	 * up some basic template functions like <code>initialize()</code> and
	 * <code>draw()</code>.
	 */
	public class FoxholeControl extends Sprite
	{
		/**
		 * jxadded
		 * 這參數太常用到，直接放到 root element 比較好
		 */
		public const dpiScale:Number = GlobalUtil.dpiScale();
		
		/**
		 * jxadded
		 * 功能與 flex 一樣，每個元件要有獨一無二的名稱
		 */
		private static var cnt:int = 1;
		public var id:String = "foxhole_" + cnt++ /*+ "_" + getTimer()*/;
		
		/**
		 * jxadded: 當一個元件已跑過 initialize() 時，代表畫面上所有 sub-components 都已建立，就廣播事件
		 */
		public var onInitializedSignal:Signal = new Signal( FoxholeControl );
		
		//---------------------------------------------------------------
		//
		// 測: jx - percent width/height
		
		/**
		 *  @private
		 *  Storage for the percentWidth property.
		 */
		private var _percentWidth:Number;
		
		/**
		 *  Specifies the width of a component as a percentage
		 *  of its parent's size. Allowed values are 0-100. The default value is NaN.
		 *  Setting the <code>width</code> or <code>explicitWidth</code> properties
		 *  resets this property to NaN.
		 *
		 *  <p>This property returns a numeric value only if the property was
		 *  previously set; it does not reflect the exact size of the component
		 *  in percent.</p>
		 *
		 *  <p>This property is always set to NaN for the UITextField control.</p>
		 * 
		 *  <p>When used with Spark layouts, this property is used to calculate the
		 *  width of the component's bounds after scaling and rotation. For example 
		 *  if the component is rotated at 90 degrees, then specifying 
		 *  <code>percentWidth</code> will affect the component's height.</p>
		 *  
		 */
		public function get percentWidth():Number
		{
			return _percentWidth;
		}

		/**
		 *  @private
		 */
		public function set percentWidth(value:Number):void
		{
			if (_percentWidth == value)
				return;
			
			if (!isNaN(value))
				explicitWidth = NaN;
			
			_percentWidth = value;
			
			//invalidateParentSizeAndDisplayList();
		}
		
		//----------------------------------
		//  percentHeight
		//----------------------------------
		
		/**
		 *  @private
		 *  Storage for the percentHeight property.
		 */
		private var _percentHeight:Number;
		
		/**
		 *  Specifies the height of a component as a percentage
		 *  of its parent's size. Allowed values are 0-100. The default value is NaN.
		 *  Setting the <code>height</code> or <code>explicitHeight</code> properties
		 *  resets this property to NaN.
		 *
		 *  <p>This property returns a numeric value only if the property was
		 *  previously set; it does not reflect the exact size of the component
		 *  in percent.</p>
		 *
		 *  <p>This property is always set to NaN for the UITextField control.</p>
		 *  
		 *  <p>When used with Spark layouts, this property is used to calculate the
		 *  height of the component's bounds after scaling and rotation. For example 
		 *  if the component is rotated at 90 degrees, then specifying 
		 *  <code>percentHeight</code> will affect the component's width.</p>
		 *  
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function get percentHeight():Number
		{
			return _percentHeight;
		}
		
		/**
		 *  @private
		 */
		public function set percentHeight(value:Number):void
		{
			if (_percentHeight == value)
				return;
			
			if (!isNaN(value))
				explicitHeight = NaN;
			
			_percentHeight = value;
			
			//invalidateParentSizeAndDisplayList();
		}
		
		// ↑ Sep 6, 2012
		//---------------------------------------------------------------
		
		
		/**
		 * @private
		 */
		private static const helperMatrix:Matrix = new Matrix();

		/**
		 * @private
		 */
		private static const helperPoint:Point = new Point();

		/**
		 * @private
		 */
		protected static var validationQueue:ValidationQueue;

		/**
		 * Flag to indicate that everything is invalid and should be redrawn.
		 */
		public static const INVALIDATION_FLAG_ALL:String = "all";

		/**
		 * Invalidation flag to indicate that the state has changed. Used by
		 * <code>isEnabled</code>, but may be used for other control states too.
		 *
		 * @see #isEnabled
		 */
		public static const INVALIDATION_FLAG_STATE:String = "state";

		/**
		 * Invalidation flag to indicate that the dimensions of the UI control
		 * have changed.
		 */
		public static const INVALIDATION_FLAG_SIZE:String = "size";

		/**
		 * Invalidation flag to indicate that the styles or visual appearance of
		 * the UI control has changed.
		 */
		public static const INVALIDATION_FLAG_STYLES:String = "styles";

		/**
		 * Invalidation flag to indicate that the primary data displayed by the
		 * UI control has changed.
		 */
		public static const INVALIDATION_FLAG_DATA:String = "data";

		/**
		 * Invalidation flag to indicate that the scroll position of the UI
		 * control has changed.
		 */
		public static const INVALIDATION_FLAG_SCROLL:String = "scroll";

		/**
		 * Invalidation flag to indicate that the selection of the UI control
		 * has changed.
		 */
		public static const INVALIDATION_FLAG_SELECTED:String = "selected";

		/**
		 * @private
		 */
		protected static const INVALIDATION_FLAG_TEXT_RENDERER:String = "textRenderer";

		/**
		 * @private
		 */
		public static var defaultTextRendererFactory:Function = function():ITextRenderer
		{
			return new BitmapFontTextRenderer();
		}

		/**
		 * Constructor.
		 */
		public function FoxholeControl()
		{
			super();
			this.addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
		}

		/**
		 * @private
		 */
		protected var _nameList:TokenList = new TokenList();

		/**
		 * Contains a list of all "names" assigned to this control. Names are
		 * like classes in CSS selectors. They are a non-unique identifier that
		 * can differentiate multiple styles of the same type of UI control. A
		 * single control may have many names, and many controls can share a
		 * single name. Names may be added, removed, or toggled on the <code>nameList</code>.
		 *
		 * @see #name
		 */
		public function get nameList():TokenList
		{
			return this._nameList;
		}

		/**
		 * The concatenated <code>nameList</code>, with each name separated by
		 * spaces. Names are like classes in CSS selectors. They are a
		 * non-unique identifier that can differentiate multiple styles of the
		 * same type of UI control. A single control may have many names, and
		 * many controls can share a single name.
		 *
		 * @see #nameList
		 */
		override public function get name():String
		{
			return this._nameList.value;
		}

		/**
		 * @private
		 */
		override public function set name(value:String):void
		{
			this._nameList.value = value;
		}

		/**
		 * @private
		 */
		private var _isQuickHitAreaEnabled:Boolean = false;

		/**
		 * Similar to mouseChildren on the classic display list. If true,
		 * children cannot dispatch touch events, but hit tests will be much
		 * faster.
		 */
		public function get isQuickHitAreaEnabled():Boolean
		{
			return this._isQuickHitAreaEnabled;
		}

		/**
		 * @private
		 */
		public function set isQuickHitAreaEnabled(value:Boolean):void
		{
			this._isQuickHitAreaEnabled = value;
		}

		/**
		 * @private
		 */
		protected var _hitArea:Rectangle = new Rectangle();

		/**
		 * @private
		 * Flag indicating if the <code>initialize()</code> function has been called yet.
		 */
		private var _isInitialized:Boolean = false;

		/**
		 * @private
		 * A flag that indicates that everything is invalid. If true, no other
		 * flags will need to be tracked.
		 * 
		 * jx: 一個元件生命週期啟始時，這個值應該都設為 true，代表所有東西都要新建立
		 */
		private var _isAllInvalid:Boolean = false;

		/**
		 * @private
		 */
		private var _invalidationFlags:Object = {};

		/**
		 * @private
		 */
		private var _delayedInvalidationFlags:Object = {};

		/**
		 * @private
		 */
		protected var _isEnabled:Boolean = true;

		/**
		 * Indicates whether the control is interactive or not.
		 */
		public function get isEnabled():Boolean
		{
			return _isEnabled;
		}

		/**
		 * @private
		 */
		public function set isEnabled(value:Boolean):void
		{
			if(this._isEnabled == value)
			{
				return;
			}
			this._isEnabled = value;
			this.invalidate(INVALIDATION_FLAG_STATE);
		}

		/**
		 * The width value explicitly set by calling the width setter or
		 * setSize().
		 */
		protected var explicitWidth:Number = NaN;

		/**
		 * The final width value that should be used for layout. If the width
		 * has been explicitly set, then that value is used. If not, the actual
		 * width will be calculated automatically. Each component has different
		 * automatic sizing behavior, but it's usually based on the component's
		 * skin or content, including text or subcomponents.
		 */
		protected var actualWidth:Number = 0;

		/**
		 * The width of the component, in pixels. This could be a value that was
		 * set explicitly, or the component will automatically resize if no
		 * explicit width value is provided. Each component has a different
		 * automatic sizing behavior, but it's usually based on the component's
		 * skin or content, including text or subcomponents.
		 */
		override public function get width():Number
		{
			return this.actualWidth;
		}

		/**
		 * @private
		 */
		override public function set width(value:Number):void
		{
			if(this.explicitWidth == value || (isNaN(value) && isNaN(this.explicitWidth)))
			{
				return;
			}
			this.explicitWidth = value;
			this.setSizeInternal(value, this.actualHeight, true);
		}

		/**
		 * The height value explicitly set by calling the height setter or
		 * setSize().
		 */
		protected var explicitHeight:Number = NaN;

		/**
		 * The final height value that should be used for layout. If the height
		 * has been explicitly set, then that value is used. If not, the actual
		 * height will be calculated automatically. Each component has different
		 * automatic sizing behavior, but it's usually based on the component's
		 * skin or content, including text or subcomponents.
		 */
		protected var actualHeight:Number = 0;

		/**
		 * The height of the component, in pixels. This could be a value that
		 * was set explicitly, or the component will automatically resize if no
		 * explicit height value is provided. Each component has a different
		 * automatic sizing behavior, but it's usually based on the component's
		 * skin or content, including text or subcomponents.
		 */
		override public function get height():Number
		{
			return this.actualHeight;
		}

		/**
		 * @private
		 */
		override public function set height(value:Number):void
		{
			if(this.explicitHeight == value || (isNaN(value) && isNaN(this.explicitHeight)))
			{
				return;
			}
			this.explicitHeight = value;
			this.setSizeInternal(this.actualWidth, value, true);
		}

		/**
		 * @private
		 */
		private var _minTouchWidth:Number = 0;

		/**
		 * If using <code>isQuickHitAreaEnabled</code>, and the hit area's
		 * width is smaller than this value, it will be expanded.
		 */
		public function get minTouchWidth():Number
		{
			return this._minTouchWidth;
		}

		/**
		 * @private
		 */
		public function set minTouchWidth(value:Number):void
		{
			if(this._minTouchWidth == value)
			{
				return;
			}
			this._minTouchWidth = value;
			this.invalidate(INVALIDATION_FLAG_SIZE);
		}

		/**
		 * @private
		 */
		private var _minTouchHeight:Number = 0;

		/**
		 * If using <code>isQuickHitAreaEnabled</code>, and the hit area's
		 * height is smaller than this value, it will be expanded.
		 */
		public function get minTouchHeight():Number
		{
			return this._minTouchHeight;
		}

		/**
		 * @private
		 */
		public function set minTouchHeight(value:Number):void
		{
			if(this._minTouchHeight == value)
			{
				return;
			}
			this._minTouchHeight = value;
			this.invalidate(INVALIDATION_FLAG_SIZE);
		}

		/**
		 * @private
		 */
		protected var _minWidth:Number = 0;

		/**
		 * The minimum recommended width to be used for self-measurement and,
		 * optionally, by any code that is resizing this component. This value
		 * is not strictly enforced in all cases. An explicit width value that
		 * is smaller than <code>minWidth</code> may be set and will not be
		 * affected by the minimum.
		 */
		public function get minWidth():Number
		{
			return this._minWidth;
		}

		/**
		 * @private
		 */
		public function set minWidth(value:Number):void
		{
			if(this._minWidth == value)
			{
				return;
			}
			if(isNaN(value))
			{
				throw new ArgumentError("minWidth cannot be NaN");
			}
			this._minWidth = value;
			this.invalidate(INVALIDATION_FLAG_SIZE);
		}

		/**
		 * @private
		 */
		protected var _minHeight:Number = 0;

		/**
		 * The minimum recommended height to be used for self-measurement and,
		 * optionally, by any code that is resizing this component. This value
		 * is not strictly enforced in all cases. An explicit height value that
		 * is smaller than <code>minHeight</code> may be set and will not be
		 * affected by the minimum.
		 */
		public function get minHeight():Number
		{
			return this._minHeight;
		}

		/**
		 * @private
		 */
		public function set minHeight(value:Number):void
		{
			if(this._minHeight == value)
			{
				return;
			}
			if(isNaN(value))
			{
				throw new ArgumentError("minHeight cannot be NaN");
			}
			this._minHeight = value;
			this.invalidate(INVALIDATION_FLAG_SIZE);
		}

		/**
		 * @private
		 */
		protected var _maxWidth:Number = Number.POSITIVE_INFINITY;

		/**
		 * The maximum recommended width to be used for self-measurement and,
		 * optionally, by any code that is resizing this component. This value
		 * is not strictly enforced in all cases. An explicit width value that
		 * is larger than <code>maxWidth</code> may be set and will not be
		 * affected by the maximum.
		 */
		public function get maxWidth():Number
		{
			return this._maxWidth;
		}

		/**
		 * @private
		 */
		public function set maxWidth(value:Number):void
		{
			if(this._maxWidth == value)
			{
				return;
			}
			if(isNaN(value))
			{
				throw new ArgumentError("maxWidth cannot be NaN");
			}
			this._maxWidth = value;
			this.invalidate(INVALIDATION_FLAG_SIZE);
		}

		/**
		 * @private
		 */
		protected var _maxHeight:Number = Number.POSITIVE_INFINITY;

		/**
		 * The maximum recommended height to be used for self-measurement and,
		 * optionally, by any code that is resizing this component. This value
		 * is not strictly enforced in all cases. An explicit height value that
		 * is larger than <code>maxHeight</code> may be set and will not be
		 * affected by the maximum.
		 */
		public function get maxHeight():Number
		{
			return this._maxHeight;
		}

		/**
		 * @private
		 */
		public function set maxHeight(value:Number):void
		{
			if(this._maxHeight == value)
			{
				return;
			}
			if(isNaN(value))
			{
				throw new ArgumentError("maxHeight cannot be NaN");
			}
			this._maxHeight = value;
			this.invalidate(INVALIDATION_FLAG_SIZE);
		}

		/**
		 * @private
		 */
		protected var _onResize:Signal = new Signal(FoxholeControl);

		/**
		 * Dispatched when the width or height of the control changes.
		 */
		public function get onResize():ISignal
		{
			return this._onResize;
		}

		/**
		 * @private
		 * Flag to indicate that the control is currently validating.
		 */
		private var _isValidating:Boolean = false;

		/**
		 * @private
		 */
		private var _invalidateCount:int = 0;

		/**
		 * @private
		 */
		public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
		{
			if(this.scrollRect)
			{
				return super.getBounds(targetSpace, resultRect);
			}

			if(!resultRect)
			{
				resultRect = new Rectangle();
			}

			var minX:Number = Number.MAX_VALUE, maxX:Number = -Number.MAX_VALUE;
			var minY:Number = Number.MAX_VALUE, maxY:Number = -Number.MAX_VALUE;

			if (targetSpace == this) // optimization
			{
				minX = 0;
				minY = 0;
				maxX = this.actualWidth;
				maxY = this.actualHeight;
			}
			else
			{
				this.getTransformationMatrix(targetSpace, helperMatrix);
				
				MatrixUtil.transformCoords(helperMatrix, 0, 0, helperPoint);
				minX = minX < helperPoint.x ? minX : helperPoint.x;
				maxX = maxX > helperPoint.x ? maxX : helperPoint.x;
				minY = minY < helperPoint.y ? minY : helperPoint.y;
				maxY = maxY > helperPoint.y ? maxY : helperPoint.y;

				MatrixUtil.transformCoords(helperMatrix, 0, this.actualHeight, helperPoint);
				minX = minX < helperPoint.x ? minX : helperPoint.x;
				maxX = maxX > helperPoint.x ? maxX : helperPoint.x;
				minY = minY < helperPoint.y ? minY : helperPoint.y;
				maxY = maxY > helperPoint.y ? maxY : helperPoint.y;

				MatrixUtil.transformCoords(helperMatrix, this.actualWidth, 0, helperPoint);
				minX = minX < helperPoint.x ? minX : helperPoint.x;
				maxX = maxX > helperPoint.x ? maxX : helperPoint.x;
				minY = minY < helperPoint.y ? minY : helperPoint.y;
				maxY = maxY > helperPoint.y ? maxY : helperPoint.y;

				MatrixUtil.transformCoords(helperMatrix, this.actualWidth, this.actualHeight, helperPoint);
				minX = minX < helperPoint.x ? minX : helperPoint.x;
				maxX = maxX > helperPoint.x ? maxX : helperPoint.x;
				minY = minY < helperPoint.y ? minY : helperPoint.y;
				maxY = maxY > helperPoint.y ? maxY : helperPoint.y;
			}

			resultRect.x = minX;
			resultRect.y = minY;
			resultRect.width  = maxX - minX;
			resultRect.height = maxY - minY;

			return resultRect;
		}

		/**
		 * @private
		 */
		override public function hitTest(localPoint:Point, forTouch:Boolean=false):DisplayObject
		{
			if(this._isQuickHitAreaEnabled)
			{
				if(forTouch && (!this.visible || !this.touchable))
				{
					return null;
				}
				return this._hitArea.containsPoint(localPoint) ? this : null;
			}
			return super.hitTest(localPoint, forTouch);
		}

		/**
		 * When called, the UI control will redraw within one frame.
		 * Invalidation limits processing so that multiple property changes only
		 * trigger a single redraw.
		 *
		 * <p>If the UI control isn't on the display list, it will never redraw.
		 * The control will automatically invalidate once it has been added.</p>
		 */
		public function invalidate(...rest:Array):void
		{
			if(!this.stage)
			{
				//we'll invalidate everything once we're added to the stage, so
				//there's no point in micro-managing it before that.
				return;
			}
			const isAlreadyInvalid:Boolean = this.isInvalid();
			var isAlreadyDelayedInvalid:Boolean = false;
			if(this._isValidating)
			{
				for(var flag:String in this._delayedInvalidationFlags)
				{
					isAlreadyDelayedInvalid = true;
					break;
				}
			}
			for each(flag in rest)
			{
				if(this._isValidating)
				{
					this._delayedInvalidationFlags[flag] = true;
				}
				else
				{
					if(flag == INVALIDATION_FLAG_ALL)
					{
						continue;
					}
					this._invalidationFlags[flag] = true;
				}
			}
			if(rest.length == 0 || rest.indexOf(INVALIDATION_FLAG_ALL) >= 0)
			{
				if(this._isValidating)
				{
					this._delayedInvalidationFlags[INVALIDATION_FLAG_ALL] = true;
				}
				else
				{
					this._isAllInvalid = true;
				}
			}
			if(!validationQueue)
			{
				//since ValidationQueue references FoxholeControl, we can't
				//instantiate it as a static variable. we do it here instead.
				validationQueue = new ValidationQueue();
			}
			if(this._isValidating)
			{
				if(isAlreadyDelayedInvalid)
				{
					return;
				}
				this._invalidateCount++;
				validationQueue.addControl(this, this._invalidateCount >= 10);
				return;
			}
			if(isAlreadyInvalid)
			{
				return;
			}
			this._invalidateCount = 0;
			
			//jx: 這個 queue 很重要，它會確保每個 foxhole 元件身上的 validate() method 被執行，而不用人工觸發
			//每次當一個元件身上任何參數改變，並且設定 invalidation flag 後 - 也就是執行 invaliate( flag ) 
			//該元件就會被加入這個 queue 裏，等下一輪 jugglor.advanceTime() 時，就會依序從 queue 裏取出 item 執行它身上的 validate()
			//然後 validate() → draw() 就啟動了新一輪的畫面更新
			validationQueue.addControl(this, false);
		}
		
		
		/**
		 * jxadded 
		 */
		public var onCreationComplete:Signal = new Signal(FoxholeControl);
		
		/**
		 * jxadded
		 */
		public var creationCompleted:Boolean = false;
		
		/**
		 * Immediately validates the control, which triggers a redraw, if one
		 * is pending.
		 */
		public function validate():void
		{
			if(!this.stage || !this.isInvalid())
			{
				return;
			}
			this._isValidating = true;
			this.draw(); //← 這支最重要，真正繪出畫面
			for(var flag:String in this._invalidationFlags)
			{
				delete this._invalidationFlags[flag];
			}
			this._isAllInvalid = false;
			for(flag in this._delayedInvalidationFlags)
			{
				if(flag == INVALIDATION_FLAG_ALL)
				{
					this._isAllInvalid = true;
				}
				else
				{
					this._invalidationFlags[flag] = true;
				}
				delete this._delayedInvalidationFlags[flag];
			}
			this._isValidating = false;
			
			//jx - 元件 addedToStage 後第一輪生命週期跑完了，可視為此元件已 creation complete
			if( creationCompleted == false )
			{
				creationCompleted = true;
				onCreationComplete.dispatch( this );
			}
		}

		/**
		 * Indicates whether the control is invalid or not. You may optionally
		 * pass in a specific flag to check if that particular flag is set. If
		 * the "all" flag is set, the result will always be true.
		 */
		public function isInvalid(flag:String = null):Boolean
		{
			if(this._isAllInvalid)
			{
				return true;
			}
			if(!flag) //return true if any flag is set
			{
				for(var flag:String in this._invalidationFlags)
				{
					return true;
				}
				return false;
			}
			return this._invalidationFlags[flag];
		}

		/**
		 * Sets both the width and the height of the control.
		 */
		public function setSize(width:Number, height:Number):void
		{
			this.explicitWidth = width;
			this.explicitHeight = height;
			this.setSizeInternal(width, height, true);
		}

		/**
		 * @private
		 */
		override public function dispose():void
		{
			this._onResize.removeAll();
			super.dispose();
		}

		/**
		 * Sets the width and height of the control, with the option of
		 * invalidating or not. Intended to be used for automatic resizing.
		 * 
		 * jx: 某些 foxhole 元件(例如 TextfieldTextRenderer) 會自動判斷本身 w, h
		 * 它內部量完後得到數據，就會操作這支來真正設定元件的 w, h，之後下列參數就會有值
		 * width, height
		 * explicitWidth, explicitHeight
		 * actualWidth, actualHeight
		 */
		protected function setSizeInternal(width:Number, height:Number, canInvalidate:Boolean):Boolean
		{
			var resized:Boolean = false;
			if(!isNaN(this.explicitWidth))
			{
				width = this.explicitWidth;
			}
			else
			{
				width = Math.min(this._maxWidth, Math.max(this._minWidth, width));
			}
			if(!isNaN(this.explicitHeight))
			{
				height = this.explicitHeight;
			}
			else
			{
				height = Math.min(this._maxHeight, Math.max(this._minHeight, height));
			}
			if(this.actualWidth != width)
			{
				this.actualWidth = width;
				this._hitArea.width = Math.max(width, this._minTouchWidth);
				this._hitArea.x = (this.actualWidth - this._hitArea.width) / 2;
				if(this._hitArea.x != this._hitArea.x)
				{
					this._hitArea.x = 0;
				}
				resized = true;
			}
			if(this.actualHeight != height)
			{
				this.actualHeight = height;
				this._hitArea.height = Math.max(height, this._minTouchHeight);
				this._hitArea.y = (this.actualHeight - this._hitArea.height) / 2;
				if(this._hitArea.y != this._hitArea.y)
				{
					this._hitArea.y = 0;
				}
				resized = true;
			}
			if(resized)
			{
				if(canInvalidate)
				{
					this.invalidate(INVALIDATION_FLAG_SIZE);
				}
				this._onResize.dispatch(this);
			}
			return resized;
		}

		/**
		 * Override to initialize the UI control. Should be used to create
		 * children and set up event listeners.
		 * 
		 * jx: 等於 createChildren()
		 */
		protected function initialize():void
		{

		}

		/**
		 * Override to customize layout and to adjust properties of children.
		 * 
		 * jx: draw() 就等於 updateDisplayList()，一樣是依照 flag 條件來判斷是否真的要更新頁面
		 */
		protected function draw():void
		{

		}

		/**
		 * @private
		 * Initialize the control, if it hasn't been initialized yet. Then,
		 * invalidate.
		 * 
		 * jx: 原理是 - 當一個元件 constructor 執行完後，就開始聽 addedToStage 事件，這就是元件生命週期的啟始點
		 * 因此通常第一件事就是 reset 所有變數，讓它下一輪 draw() 時會全部建立新的
		 */
		private function addedToStageHandler(event:Event):void
		{
			//重要：因為此元件的小孩也會發生 addedToStage 事件，並可能往上 bubble，因此要先檢查 target 是否為自已？
			//不然就會多次觸發(例如有100個 child components，就會觸發100次...)
			if(event.target != this)
			{
				return;
			}
			
			//觸發 initialize()，這等於 flex 的 createChildren()，是建立小孩的時候
			if(!this._isInitialized)
			{
				this.initialize();
				this._isInitialized = true;
				
				//jxadded
				onInitializedSignal.dispatch( this );
			}
			
			//jxadded - 重要，foxhole 元件每次被加到畫面上時，就 *必然* 會重跑一次 invalidate 與其後的 draw() 等流程
			//為了維持在生命週期第一次的 draw() 之後廣播 creationComplete 事件，因此每次都要 reset 這個值為 false
			creationCompleted = false;
			
			//clear any flags that may have been set while we didn't have a
			//stage (or when we had a stage previously).
			for(var key:String in this._invalidationFlags)
			{
				delete this._invalidationFlags[key];
			}
			for(key in this._delayedInvalidationFlags)
			{
				delete this._delayedInvalidationFlags[key];
			}
			
			//人工觸發一次 invalidate()，會設定一個 all dirty flag，代表所有 flag 都髒掉了，
			//這樣下一輪 draw() 時就會重建與重設所有參數與子元件
			//注意：draw() 就等於 updateDisplayList()，一樣是依照 flag 條件來判斷是否真的要更新頁面
			this._isAllInvalid = false;
			this.invalidate(); //invalidate everything
		}
	}
}