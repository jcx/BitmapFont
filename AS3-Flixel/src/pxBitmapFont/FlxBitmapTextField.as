package pxBitmapFont
{
	import flash.display.BitmapData;
	import flash.text.TextFormatAlign;
	import org.flixel.FlxSprite;

	/**
	 * Extends <code>FlxSprite</code> to support rendering text.
	 * Can tint, fade, rotate and scale just like a sprite.
	 * Doesn't really animate though, as far as I know.
	 * Also does nice pixel-perfect centering on pixel fonts
	 * as long as they are only one liners.
	 */
	public class FlxBitmapTextField extends FlxSprite
	{
		
		private var _font:PxBitmapFont;
		private var _text:String;
		private var _textColor:int;
		private var _outline:Boolean;
		private var _outlineColor:int;
		private var _shadow:Boolean;
		private var _shadowColor:int;
		private var _background:Boolean;
		private var _backgroundColor:int;
		private var _alignment:int;
		private var _padding:int;
		
		private var _lineSpacing:int;
		private var _letterSpacing:int;
		private var _fontScale:Number;
		private var _autoUpperCase:Boolean;
		private var _wordWrap:Boolean;
		private var _fixedWidth:Boolean;
		
		private var _pendingTextChange:Boolean;
		private var _fieldWidth:int;
		private var _multiLine:Boolean;
		
		private var _preparedTextGlyphs:Array;
		private var _preparedShadowGlyphs:Array;
		private var _preparedOutlineGlyphs:Array;
		
		/**
		 * Constructs a new text field component.
		 * @param pFont	optional parameter for component's font prop
		 */
		public function FlxBitmapTextField(pFont:PxBitmapFont = null) 
		{
			_text = "";
			_textColor = 0x0;
			_outline = false;
			_outlineColor = 0x0;
			_shadow = false;
			_shadowColor = 0x0;
			_background = false;
			_backgroundColor = 0xFFFFFF;
			_alignment = PxTextAlign.LEFT;
			_padding = 0;
			_pendingTextChange = false;
			_fieldWidth = 1;
			_multiLine = false;
			
			_lineSpacing = 0;
			_letterSpacing = 0;
			_fontScale = 1;
			_autoUpperCase = false;
			_fixedWidth = true;
			_wordWrap = true;
			_alpha = 1;
			
			super();
			
			if (pFont == null)
			{
				if (PxBitmapFont.fetch("default") == null)
				{
					PxDefaultFontGenerator.generateAndStoreDefaultFont();
				}
				_font = PxBitmapFont.fetch("default");
			}
			else
			{
				_font = pFont;
			}
			
			updateGlyphs(true, _shadow, _outline);
			
			_pixels = new BitmapData(1, 1, true);
			
			_pendingTextChange = true;
			updateBitmapData();
		}
		
		/**
		 * Clears all resources used.
		 */
		override public function destroy():void 
		{
			_font = null;
			clearPreparedGlyphs(_preparedTextGlyphs);
			clearPreparedGlyphs(_preparedShadowGlyphs);
			clearPreparedGlyphs(_preparedOutlineGlyphs);
			
			super.destroy();
		}
		
		/**
		 * Text to display.
		 */
		public function get text():String
		{
			return _text;
		}
		
		public function set text(pText:String):void 
		{
			var tmp:String = pText;
			tmp = tmp.split("\\n").join("\n");
			if (tmp != _text)
			{
				_text = pText;
				_text = _text.split("\\n").join("\n");
				if (_autoUpperCase)
				{
					_text = _text.toUpperCase();
				}
				_pendingTextChange = true;
				updateBitmapData();
			}
		}
		
		/**
		 * Internal method for updating the view of the text component
		 */
		private function updateBitmapData():void 
		{
			if (!_pendingTextChange) 
			{
				return;
			}
			
			if (_font == null)
			{
				return;
			}
			
			var calcFieldWidth:int = _fieldWidth;
			var rows:Array = [];
			var fontHeight:int = Math.floor(_font.getFontHeight() * _fontScale);
			var alignment:int = _alignment;
			
			// cut text into pices
			var lineComplete:Boolean;
			
			// get words
			var lines:Array = _text.split("\n");
			var i:int = -1;
			var j:int = -1;
			if (!_multiLine)
			{
				lines = [lines[0]];
			}
			
			var wordLength:int;
			var word:String;
			var tempStr:String;
			while (++i < lines.length) 
			{
				if (_fixedWidth)
				{
					lineComplete = false;
					var words:Array = lines[i].split(" ");
					
					if (words.length > 0) 
					{
						var wordPos:int = 0;
						var txt:String = "";
						while (!lineComplete) 
						{
							word = words[wordPos];
							var currentRow:String = txt + word + " ";
							var changed:Boolean = false;
							
							if (_wordWrap)
							{
								if (_font.getTextWidth(currentRow, _letterSpacing, _fontScale) > _fieldWidth) 
								{
									if (txt == "")
									{
										words.splice(0, 1);
									}
									else
									{
										rows.push(txt.substr(0, txt.length - 1));
									}
									
									txt = "";
									if (_multiLine)
									{
										words.splice(0, wordPos);
									}
									else
									{
										words.splice(0, words.length);
									}
									
									wordPos = 0;
									changed = true;
								}
								else
								{
									txt += word + " ";
									wordPos++;
								}
							}
							else
							{
								if (_font.getTextWidth(currentRow, _letterSpacing, _fontScale) > _fieldWidth) 
								{
									j = 0;
									tempStr = "";
									wordLength = word.length;
									while (j < wordLength)
									{
										currentRow = txt + word.charAt(j);
										if (_font.getTextWidth(currentRow, _letterSpacing, _fontScale) > _fieldWidth) 
										{
											rows.push(txt.substr(0, txt.length - 1));
											txt = "";
											word = "";
											wordPos = words.length;
											j = wordLength;
											changed = true;
										}
										else
										{
											txt += word.charAt(j);
										}
										j++;
									}
								}
								else
								{
									txt += word + " ";
									wordPos++;
								}
							}
							
							if (wordPos >= words.length) 
							{
								if (!changed) 
								{
									var subText:String = txt.substr(0, txt.length - 1);
									calcFieldWidth = Math.floor(Math.max(calcFieldWidth, _font.getTextWidth(subText, _letterSpacing, _fontScale)));
									rows.push(subText);
								}
								lineComplete = true;
							}
						}
					}
					else
					{
						rows.push("");
					}
				}
				else
				{
					calcFieldWidth = Math.floor(Math.max(calcFieldWidth, _font.getTextWidth(lines[i], _letterSpacing, _fontScale)));
					rows.push(lines[i]);
				}
			}
			
			var finalWidth:int = calcFieldWidth + _padding * 2 + (_outline ? 2 : 0);
			var finalHeight:int = Math.floor(_padding * 2 + Math.max(1, (rows.length * fontHeight + (_shadow ? 1 : 0)) + (_outline ? 2 : 0))) + ((rows.length >= 1) ? _lineSpacing * (rows.length - 1) : 0);
			
			if (_pixels != null) 
			{
				if (finalWidth != _pixels.width || finalHeight != _pixels.height) 
				{
					_pixels.dispose();
					_pixels = null;
				}
			}
			
			if (_pixels == null) 
			{
				_pixels = new BitmapData(finalWidth, finalHeight, !_background, _backgroundColor);
			} 
			else 
			{
				_pixels.fillRect(_pixels.rect, _backgroundColor);
			}
			_pixels.lock();
			
			// render text
			var row:int = 0;
			
			for each (var t:String in rows) 
			{
				var ox:int = 0; // LEFT
				var oy:int = 0;
				if (alignment == PxTextAlign.CENTER) 
				{
					if (_fixedWidth)
					{
						ox = Math.floor((_fieldWidth - _font.getTextWidth(t, _letterSpacing, _fontScale)) / 2);
					}
					else
					{
						ox = Math.floor((finalWidth - _font.getTextWidth(t, _letterSpacing, _fontScale)) / 2);
					}
				}
				if (alignment == PxTextAlign.RIGHT) 
				{
					if (_fixedWidth)
					{
						ox = _fieldWidth - Math.floor(_font.getTextWidth(t, _letterSpacing, _fontScale));
					}
					else
					{
						ox = finalWidth - Math.floor(_font.getTextWidth(t, _letterSpacing, _fontScale)) - 2 * padding;
					}
				}
				if (_outline) 
				{
					for (var py:int = 0; py <= 2; py++) 
					{
						for (var px:int = 0; px <= 2; px++) 
						{
							_font.render(_pixels, _preparedOutlineGlyphs, t, _outlineColor, px + ox + _padding, py + row * (fontHeight + _lineSpacing) + _padding, _letterSpacing);
						}
					}
					ox += 1;
					oy += 1;
				}
				if (_shadow) 
				{
					_font.render(_pixels, _preparedShadowGlyphs, t, _shadowColor, 1 + ox + _padding, 1 + oy + row * (fontHeight + _lineSpacing) + _padding, _letterSpacing);
				}
				_font.render(_pixels, _preparedTextGlyphs, t, _textColor, ox + _padding, oy + row * (fontHeight + _lineSpacing) + _padding, _letterSpacing);
				row++;
			}
			_pixels.unlock();
			pixels = _pixels;
			
			_pendingTextChange = false;
		}
		
		/**
		 * Specifies whether the text field should have a filled background.
		 */
		public function get background():Boolean
		{
			return _background;
		}
		
		public function set background(value:Boolean):void 
		{
			if (_background != value)
			{
				_background = value;
				_pendingTextChange = true;
				update();
			}
		}
		
		/**
		 * Specifies the color of the text field background.
		 */
		public function get backgroundColor():int
		{
			return _backgroundColor;
		}
		
		public function set backgroundColor(value:int):void
		{
			if (_backgroundColor != value)
			{
				_backgroundColor = value;
				if (_background)
				{
					_pendingTextChange = true;
					update();
				}
			}
		}
		
		/**
		 * Specifies whether the text should have a shadow.
		 */
		public function get shadow():Boolean
		{
			return _shadow;
		}
		
		public function set shadow(value:Boolean):void
		{
			if (_shadow != value)
			{
				_shadow = value;
				_outline = false;
				updateGlyphs(false, _shadow, false);
				_pendingTextChange = true;
				updateBitmapData();
			}
		}
		
		/**
		 * Specifies the color of the text field shadow.
		 */
		public function get shadowColor():int
		{
			return _shadowColor;
		}
		
		public function set shadowColor(value:int):void 
		{
			if (_shadowColor != value)
			{
				_shadowColor = value;
				updateGlyphs(false, _shadow, false);
				_pendingTextChange = true;
				updateBitmapData();
			}
		}
		
		/**
		 * Sets the padding of the text field. This is the distance between the text and the border of the background (if any).
		 */
		public function get padding():int
		{
			return _padding;
		}
		
		public function set padding(value:int):void 
		{
			if (_padding != value)
			{
				_padding = value;
				_pendingTextChange = true;
				updateBitmapData();
			}
		}
		
		/**
		 * Sets the color of the text.
		 */
		public function get textColor():int
		{
			return _textColor;
		}
		
		public function set textColor(value:int):void 
		{
			if (_textColor != value)
			{
				_textColor = value;
				updateGlyphs(true, false, false);
				_pendingTextChange = true;
				updateBitmapData();
			}
		}
		
		/**
		 * Sets the width of the text field. If the text does not fit, it will spread on multiple lines.
		 */
		public function setWidth(pWidth:int):void 
		{
			if (pWidth < 1) 
			{
				pWidth = 1;
			}
			if (pWidth != _fieldWidth)
			{
				_fieldWidth = pWidth;
				_pendingTextChange = true;
				updateBitmapData();
			}
		}
		
		/**
		 * Specifies how the text field should align text.
		 * LEFT, RIGHT, CENTER.
		 */
		public function get alignment():int
		{
			return _alignment;
		}
		
		public function set alignment(pAlignment:int):void 
		{
			if (_alignment != pAlignment)
			{
				_alignment = pAlignment;
				_pendingTextChange = true;
				updateBitmapData();
			}
		}
		
		/**
		 * Specifies whether the text field will break into multiple lines or not on overflow.
		 */
		public function get multiLine():Boolean
		{
			return _multiLine;
		}
		
		public function set multiLine(pMultiLine:Boolean):void 
		{
			if (_multiLine != pMultiLine)
			{
				_multiLine = pMultiLine;
				_pendingTextChange = true;
				updateBitmapData();
			}
		}
		
		/**
		 * Specifies whether the text should have an outline.
		 */
		public function get outline():Boolean
		{
			return _outline;
		}
		
		public function set outline(value:Boolean):void 
		{
			if (_outline != value)
			{
				_outline = value;
				_shadow = false;
				updateGlyphs(false, false, true);
				_pendingTextChange = true;
				updateBitmapData();
			}
		}
		
		/**
		 * Specifies whether color of the text outline.
		 */
		public function get outlineColor():int
		{
			return _outlineColor;
		}
		
		public function set outlineColor(value:int):void 
		{
			if (_outlineColor != value)
			{
				_outlineColor = value;
				updateGlyphs(false, false, _outline);
				_pendingTextChange = true;
				updateBitmapData();
			}
		}
		
		/**
		 * Sets which font to use for rendering.
		 */
		public function get font():PxBitmapFont
		{
			return _font;
		}
		
		public function set font(pFont:PxBitmapFont):void 
		{
			if (_font != pFont)
			{
				_font = pFont;
				updateGlyphs(true, _shadow, _outline);
				_pendingTextChange = true;
				updateBitmapData();
			}
		}
		
		/**
		 * Sets the distance between lines
		 */
		public function get lineSpacing():int
		{
			return _lineSpacing;
		}
		
		public function set lineSpacing(pSpacing:int):void
		{
			if (_lineSpacing != pSpacing)
			{
				_lineSpacing = Math.floor(Math.abs(pSpacing));
				_pendingTextChange = true;
				updateBitmapData();
			}
		}
		
		/**
		 * Sets the "font size" of the text
		 */
		public function get fontScale():Number
		{
			return _fontScale;
		}
		
		public function set fontScale(pScale:Number):void
		{
			var tmp:Number = Math.abs(pScale);
			if (tmp != _fontScale)
			{
				_fontScale = tmp;
				updateGlyphs(true, _shadow, _outline);
				_pendingTextChange = true;
				updateBitmapData();
			}
		}
		
		public function get letterSpacing():int
		{
			return _letterSpacing;
		}
		
		public function set letterSpacing(pSpacing:int):void
		{
			var tmp:int = Math.floor(Math.abs(pSpacing));
			if (tmp != _letterSpacing)
			{
				_letterSpacing = tmp;
				_pendingTextChange = true;
				updateBitmapData();
			}
		}
		
		public function get autoUpperCase():Boolean 
		{
			return _autoUpperCase;
		}
		
		public function set autoUpperCase(value:Boolean):void 
		{
			if (_autoUpperCase != value)
			{
				_autoUpperCase = value;
				if (_autoUpperCase)
				{
					text = _text.toUpperCase();
				}
			}
		}
		
		public function get wordWrap():Boolean 
		{
			return _wordWrap;
		}
		
		public function set wordWrap(value:Boolean):void 
		{
			if (_wordWrap != value)
			{
				_wordWrap = value;
				_pendingTextChange = true;
				updateBitmapData();
			}
		}
		
		public function get fixedWidth():Boolean 
		{
			return _fixedWidth;
		}
		
		public function set fixedWidth(value:Boolean):void 
		{
			if (_fixedWidth != value)
			{
				_fixedWidth = value;
				_pendingTextChange = true;
				updateBitmapData();
			}
		}
		
		private function updateGlyphs(textGlyphs:Boolean = false, shadowGlyphs:Boolean = false, outlineGlyphs:Boolean = false):void
		{
			if (textGlyphs)
			{
				clearPreparedGlyphs(_preparedTextGlyphs);
				_preparedTextGlyphs = _font.getPreparedGlyphs(_fontScale, _textColor);
			}
			
			if (shadowGlyphs)
			{
				clearPreparedGlyphs(_preparedShadowGlyphs);
				_preparedShadowGlyphs = _font.getPreparedGlyphs(_fontScale, _shadowColor);
			}
			
			if (outlineGlyphs)
			{
				clearPreparedGlyphs(_preparedOutlineGlyphs);
				_preparedOutlineGlyphs = _font.getPreparedGlyphs(_fontScale, _outlineColor);
			}
		}
		
		private function clearPreparedGlyphs(pGlyphs:Array):void
		{
			if (pGlyphs != null)
			{
				for each (var bmd:BitmapData in pGlyphs)
				{
					if (bmd != null)
					{
						bmd.dispose();
					}
				}
				pGlyphs = null;
			}
		}
		
	}
}