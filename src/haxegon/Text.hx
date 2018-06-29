package haxegon;

import haxegon.util.*;
import openfl.Assets;
import openfl.display.*;
import openfl.geom.*;
import openfl.events.*;
import openfl.net.*;
import openfl.text.*;

@:access(haxegon.Input)
@:access(haxegon.Gfx)
class Text {
	private static var fontfile:Array<Fontfile> = new Array<Fontfile>();
	private static var fontfileindex:Map<String,Int> = new Map<String,Int>();
	
	private static var typeface:Array<Fontclass> = new Array<Fontclass>();
	private static var typefaceindex:Map<String,Int> = new Map<String,Int>();
	
	private static var fontmatrix:Matrix = new Matrix();
	private static var currentindex:Int = -1;
	public static var currentfont:String = "null";
	public static var currentsize:Float = -1;
	private static var gfxstage:Stage;
	
	public static var drawto:BitmapData;
	
	public static var LEFT:Int = -10000;
	public static var RIGHT:Int = -20000;
	public static var TOP:Int = -10000;
	public static var BOTTOM:Int = -20000;
	public static var CENTER:Int = -15000;
	
	private static var textalign:Int = LEFT;
	private static var textrotate:Float = 0;
	private static var textrotatexpivot:Float = 0;
	private static var textrotateypivot:Float = 0;
	private static var textalphamult:Float = 1.0;
	private static var temprotate:Float = 0;
	private static var tempxscale:Float = 1;
	private static var tempyscale:Float = 1;
	private static var tempxpivot:Float = 0;
	private static var tempypivot:Float = 0;
	private static var tempalpha:Float = 1;
	private static var tempred:Float = 1;
	private static var tempgreen:Float = 1;
	private static var tempblue:Float = 1;
	private static var changecolours:Bool = false;
	private static var alphact:ColorTransform;
	
	//Text input variables
	public static var inputmaxlength:Int;
	public static var inputtext:String;
	private static var lastentry:String;
	
	private static var input_textxp:Float;
	private static var input_textyp:Float;
	private static var input_responsexp:Float;
	private static var input_responseyp:Float;
	private static var input_textcol:Int;
	private static var input_responsecol:Int;
	private static var input_text:String;
	private static var input_response:String;
	private static var input_cursorglow:Int;
	private static var input_font:String;
	private static var input_textsize:Float;
	// Non zero when an input string is being checked. So that I can use 
	// the M and F keys without muting or changing to fullscreen.
	public static var input_show = 0;
	

	public static function init(stage:Stage) {
		drawto = Gfx.backbuffer;
		gfxstage = stage;
		alphact = new ColorTransform();
		input_cursorglow = 0;
		inputmaxlength = 40;
	}
	
	public static function align(a:Int) {
		textalign = a;	
	}
	
	public static function rotation(a:Float, xpivot:Int = -15000, ypivot:Int = -15000) {
		textrotate = a;
		textrotatexpivot = xpivot;
		textrotateypivot = ypivot;
	}
	
	private static function input_checkfortext() {
		inputtext = Input.keybuffer;
	}
	
	public static function input(x:Float, y:Float, text:String, col:Int = 0xFFFFFF, responsecol:Int = 0xCCCCCC):Bool {
		input_show = 2;
		
		input_font = currentfont;
		input_textsize = currentsize;
		if (typeface[currentindex].type == "bitmap") {
			typeface[currentindex].tf_bitmap.text = text + inputtext;
		}else if (typeface[currentindex].type == "ttf") {
			typeface[currentindex].tf_ttf.text = text + inputtext;
		}
		x = alignx(x); y = aligny(y);
		input_textxp = x;
		input_textyp = y;
		
		if (typeface[currentindex].type == "bitmap") {			
			typeface[currentindex].tf_bitmap.text = text;
			input_responsexp = input_textxp + Math.floor(typeface[currentindex].tf_bitmap.textWidth);
		}else if (typeface[currentindex].type == "ttf") {			
			typeface[currentindex].tf_ttf.text = text;
			input_responsexp = input_textxp + Math.floor(typeface[currentindex].tf_ttf.textWidth);
		}
		input_responseyp = y;
		
		input_text = text;
		input_response = inputtext;
		input_textcol = col;
		input_responsecol = responsecol;
		input_checkfortext();
		
		if (Input.just_pressed(Key.ENTER) && inputtext != "") {
			return true;
		}
		return false;
	}
	
	// Returns the entered string, and resets the input for next time.
	public static function get_input():String {
		var response:String = inputtext;
		lastentry = inputtext;
		inputtext = "";
		reset_text_input();
		input_show = 0;
		
		return response;
	}
	
	public static function drawstringinput() {
		if (input_show > 0) {
			Text.setfont(input_font, input_textsize);
			input_cursorglow++;
			if (input_cursorglow >= 96) input_cursorglow = 0;
			
			display(input_textxp, input_textyp, input_text, input_textcol);
			if (input_text.length < inputmaxlength) {
				if (input_cursorglow % 48 < 24) {
					display(input_responsexp, input_responseyp, input_response, input_responsecol);
				}else {
					display(input_responsexp, input_responseyp, input_response + "_", input_responsecol);
				}
			}else{
				display(input_responsexp, input_responseyp, input_response, input_responsecol);
			}
		}
		
		input_show--;
		if (input_show < 0) input_show = 0;
	}
	
	public static function width(t:String):Float {
		if (typeface[currentindex].type == "ttf") {
			typeface[currentindex].tf_ttf.text = t;
			return typeface[currentindex].tf_ttf.textWidth;
		}else if (typeface[currentindex].type == "bitmap") {
			var text:String = t;
			var numlines:Int = 1;
			var currentline:String = "";
			var longestline:Int = -1;
			var thislength:Int;
			var i:Int = 0;
			if(S.isinstring(text,"\n")){
				while (i < text.length) {
					if (text.substr(i, 1) == "\n") {
						numlines++;
						thislength = Math.round(typeface[currentindex].tf_bitmap.getStringWidth(currentline, false));
						if (thislength > longestline) longestline = thislength;
						currentline = "";
					}else	currentline += text.substr(i, 1);
					i++;
				}
				thislength = Math.round(typeface[currentindex].tf_bitmap.getStringWidth(currentline, false));
				if (thislength > longestline) longestline = thislength;
			}else {
				longestline = Math.round(typeface[currentindex].tf_bitmap.getStringWidth(text, false));
			}
			return longestline;
		}
		return 0;
	}
	
	public static function height():Float {
		if (typeface[currentindex].type == "ttf") {
			var oldtext:String = typeface[currentindex].tf_ttf.text;
			typeface[currentindex].tf_ttf.text = "???";
			var h:Float = typeface[currentindex].tf_ttf.textHeight;
			typeface[currentindex].tf_ttf.text = oldtext;
			return h;
		}else if (typeface[currentindex].type == "bitmap") {
			typeface[currentindex].tf_bitmap.text = "???";
			return typeface[currentindex].height * currentsize;
		}
		return 0;
	}
	
	private static var t1:Float;
	private static var t2:Float;
	private static var t3:Float;
	
	private static function cachealignx(x:Float, c:Int):Float {
		if (x <= -5000) {
			t1 = x - CENTER;
			t2 = x - LEFT;
			t3 = x - RIGHT;
			if (t1 == 0 || (Math.abs(t1) < Math.abs(t2) && Math.abs(t1) < Math.abs(t3))) {
				return t1 + Math.floor(Gfx.screen_widthMid - (cachedtext[c].width * currentsize / 2));
			}else if (t2 == 0 || ((Math.abs(t2) < Math.abs(t1) && Math.abs(t2) < Math.abs(t3)))) {
				return t2;
			}else {
				return t3 + Math.floor(Gfx.screen_width - (cachedtext[c].width * currentsize));
			}
		}
		
		return Math.floor(x);
	}
	
	private static function cachealigny(y:Float, c:Int):Float {
		if (y <= -5000) {
			t1 = y - CENTER;
			t2 = y - TOP;
			t3 = y - BOTTOM;
			if (t1 == 0 || (Math.abs(t1) < Math.abs(t2) && Math.abs(t1) < Math.abs(t3))) {
				return t1 + Math.floor(Gfx.screen_heightMid - cachedtext[c].height * currentsize / 2);
			}else if (t2 == 0 || ((Math.abs(t2) < Math.abs(t1) && Math.abs(t2) < Math.abs(t3)))) {
				return t2;
			}else {
				return t3 + Math.floor(Gfx.screen_height - (cachedtext[c].height * currentsize));
			}
		}
		
		return Math.floor(y);
	}

	private static function currentwidth():Float {
		if (typeface[currentindex].type == "ttf") {
			return typeface[currentindex].tf_ttf.textWidth;
		}else if (typeface[currentindex].type == "bitmap") {
			var text:String = typeface[currentindex].tf_bitmap.text;
			var numlines:Int = 1;
			var currentline:String = "";
			var longestline:Int = -1;
			var thislength:Int;
			var i:Int = 0;
			if(S.isinstring(text,"\n")){
				while (i < text.length) {
					if (text.substr(i, 1) == "\n") {
						numlines++;
						thislength = Math.round(typeface[currentindex].tf_bitmap.getStringWidth(currentline, false));
						if (thislength > longestline) longestline = thislength;
						currentline = "";
					}else	currentline += text.substr(i, 1);
					i++;
				}
				thislength = Math.round(typeface[currentindex].tf_bitmap.getStringWidth(currentline, false));
				if (thislength > longestline) longestline = thislength;
			}else {
				longestline = Math.round(typeface[currentindex].tf_bitmap.getStringWidth(text, false));
			}
			return longestline;
		}
		return 0;
	}
	
	private static function alignx(x:Float):Float {
		if (x <= -5000) {
			t1 = x - CENTER;
			t2 = x - LEFT;
			t3 = x - RIGHT;
			if (t1 == 0 || (Math.abs(t1) < Math.abs(t2) && Math.abs(t1) < Math.abs(t3))) {
				return t1 + Math.floor(Gfx.screen_widthMid - (currentwidth() / 2));
			}else if (t2 == 0 || ((Math.abs(t2) < Math.abs(t1) && Math.abs(t2) < Math.abs(t3)))) {
				return t2;
			}else {
				return t3 + Math.floor(Gfx.screen_width - currentwidth());
			}
		}
		
		return Math.floor(x);
	}

	private static function currentheight():Float {
		if (typeface[currentindex].type == "ttf") {
			return typeface[currentindex].tf_ttf.textHeight;
		}else if (typeface[currentindex].type == "bitmap") {
			return typeface[currentindex].tf_bitmap.textHeight * currentsize;
		}
		return 0;
	}
	
	private static function aligny(y:Float):Float {
		if (y <= -5000) {
			t1 = y - CENTER;
			t2 = y - TOP;
			t3 = y - BOTTOM;
			if (t1 == 0 || (Math.abs(t1) < Math.abs(t2) && Math.abs(t1) < Math.abs(t3))) {
				return t1 + Math.floor(Gfx.screen_heightMid - currentheight() / 2);
			}else if (t2 == 0 || ((Math.abs(t2) < Math.abs(t1) && Math.abs(t2) < Math.abs(t3)))) {
				return t2;
			}else {
				return t3 + Math.floor(Gfx.screen_height - currentheight());
			}
		}
		
		return Math.floor(y);
	}
	
	private static function cachealigntextx(c:Int, x:Float):Float {
		if (x <= -5000) {
			t1 = x - CENTER;
			t2 = x - LEFT;
			t3 = x - RIGHT;
			if (t1 == 0 || (Math.abs(t1) < Math.abs(t2) && Math.abs(t1) < Math.abs(t3))) {
				return t1 + Math.floor(cachedtext[c].width * currentsize / 2);
			}else if (t2 == 0 || ((Math.abs(t2) < Math.abs(t1) && Math.abs(t2) < Math.abs(t3)))) {
				return t2;
			}else {
				return t3 + cachedtext[c].width * currentsize;
			}
		}
		
		return x;
	}
	
	private static function cachealigntexty(c:Int, y:Float):Float {
		if (y <= -5000) {
			t1 = y - CENTER;
			t2 = y - TOP;
			t3 = y - BOTTOM;
			if (t1 == 0 || (Math.abs(t1) < Math.abs(t2) && Math.abs(t1) < Math.abs(t3))) {
				return t1 + Math.floor(cachedtext[c].height * currentsize / 2);
			}else if (t2 == 0 || ((Math.abs(t2) < Math.abs(t1) && Math.abs(t2) < Math.abs(t3)))) {
				return t2;
			}else {
				return t3 + cachedtext[c].height * currentsize;
			}
		}
		return y;
	}
	
	private static function aligntextx(t:String, x:Float):Float {
		if (x <= -5000) {
			t1 = x - CENTER;
			t2 = x - LEFT;
			t3 = x - RIGHT;
			if (t1 == 0 || (Math.abs(t1) < Math.abs(t2) && Math.abs(t1) < Math.abs(t3))) {
				return t1 + Math.floor(width(t) / 2);
			}else if (t2 == 0 || ((Math.abs(t2) < Math.abs(t1) && Math.abs(t2) < Math.abs(t3)))) {
				return t2;
			}else {
				return t3 + width(t);
			}
		}
		
		return x;
	}
	
	private static function aligntexty(y:Float):Float {
		if (y <= -5000) {
			t1 = y - CENTER;
			t2 = y - TOP;
			t3 = y - BOTTOM;
			if (t1 == 0 || (Math.abs(t1) < Math.abs(t2) && Math.abs(t1) < Math.abs(t3))) {
				return t1 + Math.floor(height() / 2);
			}else if (t2 == 0 || ((Math.abs(t2) < Math.abs(t1) && Math.abs(t2) < Math.abs(t3)))) {
				return t2;
			}else {
				return t3 + height();
			}
		}
		return y;
	}

	public static function reset_text_input() {
		Input.keybuffer = "";
	}
	
	private static var cachedtextindex:Map<String, Int> = new Map<String, Int>();
	private static var cachedtext:Array<BitmapData> = [];
	private static var cacheindex:Int;
	private static var cachelabel:String;
	
	public static function cleartextcache() {
		cachedtextindex = new Map<String, Int>();
		for (i in 0 ... cachedtext.length) {
			cachedtext[i].dispose();	
		}
		cachedtext = [];
		
		align(LEFT);
		rotation(0);
	}
	
	public static function display(x:Float, y:Float, text:String, col:Int = 0xFFFFFF) {
		if (!Gfx.clearscreeneachframe) if (Gfx.skiprender && Gfx.drawingtoscreen) return;
		if (text == "") return;
		if (typeface[currentindex].type == "bitmap") {
			cachelabel = text + "_" + currentfont + Std.string(col);
			if (!cachedtextindex.exists(cachelabel)) {
				//Cache the text
				var numlines:Int = 1;
				var currentline:String = "";
				var longestline:Int = -1;
				var thislength:Int;
				var i:Int = 0;
				if(S.isinstring(text,"\n")){
					while (i < text.length) {
						if (text.substr(i, 1) == "\n") {
							numlines++;
							thislength = Math.round(typeface[currentindex].tf_bitmap.getStringWidth(currentline, false));
							if (thislength > longestline) longestline = thislength;
							currentline = "";
						}else	currentline += text.substr(i, 1);
						i++;
					}
					thislength = Math.round(typeface[currentindex].tf_bitmap.getStringWidth(currentline, false));
					if (thislength > longestline) longestline = thislength;
				}else {
					longestline = Math.round(typeface[currentindex].tf_bitmap.getStringWidth(text, false));
				}
				
				cacheindex = cachedtext.length;
				cachedtextindex.set(cachelabel, cacheindex);
				cachedtext.push(new BitmapData(longestline, Math.round(typeface[currentindex].height) * numlines, true, 0));

				drawto = cachedtext[cacheindex];
				//cachedtext[cacheindex].fillRect(cachedtext[cacheindex].rect, (0xFF << 24) + Col.RED);
				cache_bitmap_text(text, col);
				drawto = Gfx.drawto;
			}
			
			cacheindex = cachedtextindex.get(cachelabel);
			display_bitmap(x, y, cacheindex, currentsize);
		}else if (typeface[currentindex].type == "ttf") {
			display_ttf(x, y, text, col);
		}
	}
	
	private static function cache_bitmap_text(text:String, col:Int) {
		typeface[currentindex].tf_bitmap.useTextColor = true;
		typeface[currentindex].tf_bitmap.textColor = (0xFF << 24) + col;
		typeface[currentindex].tf_bitmap.text = text;
		drawto.draw(typeface[currentindex].tf_bitmap);
	}
	
	private static function display_bitmap(x:Float, y:Float, text:Int, size:Float) {
		x = cachealignx(x, text); y = cachealigny(y, text);
		x -= cachealigntextx(text, textalign);
		
		fontmatrix.identity();
		if(size != 1){
			fontmatrix.scale(size, size);
		}
		if (textrotate != 0) {
			if (textrotatexpivot != 0.0) tempxpivot = cachealigntextx(text, textrotatexpivot);
			if (textrotateypivot != 0.0) tempypivot = cachealigntexty(text, textrotatexpivot);
			fontmatrix.translate( -tempxpivot, -tempypivot);
			fontmatrix.rotate((textrotate * 3.1415) / 180);
			fontmatrix.translate( tempxpivot, tempypivot);
		}
		
		fontmatrix.translate(Math.floor(x), Math.floor(y));
		drawto.draw(cachedtext[text], fontmatrix);
	}
	
	private static function display_ttf(x:Float, y:Float, text:String, col:Int = 0xFFFFFF) {
		if (!Gfx.clearscreeneachframe) if (Gfx.skiprender && Gfx.drawingtoscreen) return;
		if (text == null) {
			text = "";
		}

		typeface[currentindex].tf_ttf.textColor = col;
		typeface[currentindex].tf_ttf.text = text;
		
		x = alignx(x); y = aligny(y);
		x -= aligntextx(text, textalign);
		
		fontmatrix.identity();
		
		if (textrotate != 0) {
			if (textrotatexpivot != 0.0) tempxpivot = aligntextx(text, textrotatexpivot);
			if (textrotateypivot != 0.0) tempypivot = aligntexty(textrotatexpivot);
			fontmatrix.translate( -tempxpivot, -tempypivot);
			fontmatrix.rotate((textrotate * 3.1415) / 180);
			fontmatrix.translate( tempxpivot, tempypivot);
		}
		
		fontmatrix.translate(x, y);
		drawto.draw(typeface[currentindex].tf_ttf, fontmatrix);
		fontmatrix.identity();
	}
	
	private static function createtypeface(t:String) {
		//Create a typeface for a bitmap font without changing to it. Used for Zeedonk's
		//precaching trickery.
		if (fontfile[fontfileindex.get(t)].type == "bitmap") {
			if (!typefaceindex.exists(t + "_1")) {
				addtypeface(t, 1);
			}
		}
	}
	
	public static function setfont(t:String, s:Float = 1) {
		if (!fontfileindex.exists(t)) {
			addfont(t, s);
		}
		
		if (t != currentfont) {
			currentfont = t;
			if (s != -1) {
				if (fontfile[fontfileindex.get(t)].type == "bitmap") {
					if (typefaceindex.exists(currentfont + "_1")) {
						currentindex = typefaceindex.get(currentfont + "_1");
					}else {
						addtypeface(currentfont, 1);
						currentindex = typefaceindex.get(currentfont + "_1");
					}
				}else if (fontfile[fontfileindex.get(t)].type == "ttf") {
					if (typefaceindex.exists(currentfont + "_" + Std.string(currentsize))) {
						currentindex = typefaceindex.get(currentfont + "_" + Std.string(currentsize));
					}else {
						addtypeface(currentfont, currentsize);
						currentindex = typefaceindex.get(currentfont + "_" + Std.string(currentsize));
					}
				}
			}
		}
		
		change_size(s);
	}
	
	public static function change_size(t:Float) {
		if (t != currentsize){
			currentsize = t;
			if (currentfont != "null") {
				if (fontfile[fontfileindex.get(currentfont)].type == "bitmap") {
					if (typefaceindex.exists(currentfont + "_1")) {
						currentindex = typefaceindex.get(currentfont + "_1");
					}else {
						addtypeface(currentfont, 1);
						currentindex = typefaceindex.get(currentfont + "_1");
					}
				}else if (fontfile[fontfileindex.get(currentfont)].type == "ttf") {
					if (typefaceindex.exists(currentfont + "_" + Std.string(currentsize))) {
						currentindex = typefaceindex.get(currentfont + "_" + Std.string(currentsize));
					}else {
						addtypeface(currentfont, currentsize);
						currentindex = typefaceindex.get(currentfont + "_" + Std.string(currentsize));
					}
				}
			}
		}
	}
	
	private static function addfont(t:String, defaultsize:Float = 1) {
		fontfile.push(new Fontfile(t));
		fontfileindex.set(t, fontfile.length - 1);
		currentfont = t;
		
		change_size(defaultsize);
	}
	
	private static function addtypeface(_name:String, _size:Float) {
		typeface.push(new Fontclass(_name, _size));
		typefaceindex.set(_name+"_" + Std.string(_size), typeface.length - 1);
	}
	
	/** Return a font's internal TTF name. Used for loading in fonts during setup. */
	public static function getfonttypename(fontname:String):String {
		return fontfile[Text.fontfileindex.get(fontname)].typename;
	}
}