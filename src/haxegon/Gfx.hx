package haxegon;

#if haxegon3D
import haxegon3D.*;
#end

import haxegon.util.*;
import openfl.display.*;
import openfl.geom.*;
import openfl.events.*;
import openfl.net.*;
import openfl.text.*;
import openfl.Assets;
import openfl.Lib;
import openfl.system.Capabilities;

using haxegon.MathExtensions;

#if haxegon3D
@:access(haxegon3D.Gfx3D)
#end
class Gfx {
	public static var LEFT: Int = -10000;
	public static var RIGHT: Int = -20000;
	public static var TOP: Int = -10000;
	public static var BOTTOM: Int = -20000;
	public static var CENTER: Int = -15000;

	public static var screenwidth: Int;
	public static var screenheight: Int;
	public static var screenwidthMid: Int;
	public static var screenheightMid: Int;
	public static var clearscreeneachframe: Bool;

	public static var screenscale: Int;
	public static var devicexres: Int;
	public static var deviceyres: Int;
	public static var fullscreen: Bool;

	public static var currenttilesetname: String;
	public static var backbuffer: BitmapData;
	public static var drawto: BitmapData;

	/** Create a screen with a given width, height and scale. Also inits Text. */

	public static function resizescreen(width: Float, height: Float, scale: Int = 1) {
		initgfx(Std.int(width), Std.int(height), scale);
		#if (js || html5)
		onresize(null);
		#end
		Text.init(gfxstage);
		showfps = false;
		gfxstage.addChild(screen);

		updategraphicsmode();
	}

	public static var showfps: Bool;
	private static var renderfps: Int;
	private static var renderfps_max: Int = -1;
	private static var updatefps: Int;
	private static var updatefps_max: Int = -1;

	public static function get_renderfps(): Int {
		return renderfps_max;
	}

	public static function get_updatefps(): Int {
		return updatefps_max;
	}

	/** Clear all rotations, scales and image colour changes */

	private static function reset() {
		transform = false;
		imagerotate = 0;
		imagerotatexpivot = 0; imagerotateypivot = 0;
		imagexscale = 1.0; imageyscale = 1.0;
		imagescalexpivot = 0; imagescaleypivot = 0;

		coltransform = false;
		imagealphamult = 1.0;   imageredmult = 1.0; imagegreenmult = 1.0;   imagebluemult = 1.0;
		imageredadd = 0.0; imagegreenadd = 0.0; imageblueadd = 0.0;
	}

	/** Called when a transform takes place to check if any transforms are active */

	private static function reset_ifclear() {
		if (imagerotate == 0) {
			if (imagexscale == 1.0) {
				if (imageyscale == 1.0) {
					transform = false;
				}
			}
		}

		if (imagealphamult == 1.0) {
			if (imageredmult == 1.0 && imagegreenmult == 1.0 && imagebluemult == 1.0 && imageredadd == 0.0 && imagegreenadd == 0.0 && imageblueadd == 0.0) {
				coltransform = false; 
			}
		}
	}

	/** Rotates image drawing functions. */

	public static function rotation(angle: Float, xpivot: Float = -15000, ypivot: Float = -15000) {
		imagerotate = angle;
		imagerotatexpivot = xpivot;
		imagerotateypivot = ypivot;
		transform = true;
		reset_ifclear();
	}

	public static function scale(xscale: Float, yscale: Float = -1, xpivot: Float = 0, ypivot: Float = 0) {
		if (yscale == -1) {
			yscale = xscale;
		}

		imagexscale = xscale;
		imageyscale = yscale;
		imagescalexpivot = xpivot;
		imagescaleypivot = ypivot;

		transform = true;
		reset_ifclear();
	}

	/** Set an alpha multipler for image drawing functions. */

	public static function imagealpha(a: Float) {
		imagealphamult = a;
		coltransform = true;
		reset_ifclear();
	}

	/** Set a colour multipler for image drawing functions. */

	public static function imagecolor(c: Int = 0xFFFFFF, add:Int = 0x000000) {
		#if flash
		if (getred(c) > 0) {
			imageredmult = getred(c) / 254.94;
			imageredadd = getred(add) + 1;
		} else {
			imageredmult = 0;
			imageredadd = getred(add);
		}
		if (getgreen(c) > 0) {
			imagegreenmult = getgreen(c) / 254.94;
			imagegreenadd = getgreen(add) + 1;
		} else {
			imagegreenmult = 0;
			imagegreenadd = getgreen(add);
		}
		if (getblue(c) > 0) {
			imagebluemult = getblue(c) / 254.94;
			imageblueadd = getblue(add) + 1;
		} else {
			imagebluemult = 0;
			imageblueadd = getblue(add);
		}
		#else
		imageredmult = getred(c) / 255;
		imagegreenmult = getgreen(c) / 255;
		imagebluemult = getblue(c) / 255;
		imageredadd = getred(add);
		imagegreenadd = getgreen(add);
		imageblueadd = getblue(add);
		#end
		coltransform = true;
		reset_ifclear();
	}

	/** Change the tileset that the draw functions use. */

	public static function changetileset(tilesetname: String) {
		if (currenttilesetname != tilesetname) {
			if (tilesetindex.exists(tilesetname)) {
				currenttileset = tilesetindex.get(tilesetname);
				currenttilesetname = tilesetname;
			} else {
				throw("ERROR: Cannot change to tileset \"" + tilesetname + "\", no tileset with that name found.");
			}
		}
	}

	public static function numberoftiles(): Int {
		return tiles[currenttileset].tiles.length;
	}

	/** Makes a tile array from a given image. */

	public static function loadtiles(imagename: String, width: Int, height: Int) {
		buffer = new Bitmap(Assets.getBitmapData("data/graphics/" + imagename + ".png")).bitmapData;
		if (buffer == null) {
			throw("ERROR: In loadtiles, cannot find data/graphics/" + imagename + ".png.");
			return;
		}

		var tiles_rect: Rectangle = new Rectangle(0, 0, width, height);
		tiles.push(new haxegon.util.Tileset(imagename, width, height));
		tilesetindex.set(imagename, tiles.length - 1);
		currenttileset = tiles.length - 1;

		var tilerows: Int;
		var tilecolumns: Int;
		tilecolumns = Std.int((buffer.width - (buffer.width % width)) / width);
		tilerows = Std.int((buffer.height - (buffer.height % height)) / height);

		for (j in 0 ... tilerows) {
			for (i in 0 ... tilecolumns) {
				var t: BitmapData = new BitmapData(width, height, true, 0x000000);
				settrect(i * width, j * height, width, height);
				t.copyPixels(buffer, trect, tl);
				tiles[currenttileset].tiles.push(t);
			}
		}

		changetileset(imagename);
	}

	/** Creates a blank tileset, with the name "imagename", with each tile a given width and height, containing "amount" tiles. */

	public static function createtiles(imagename: String, width: Float, height: Float, amount: Int) {
		tiles.push(new haxegon.util.Tileset(imagename, Std.int(width), Std.int(height)));
		tilesetindex.set(imagename, tiles.length - 1);
		currenttileset = tiles.length - 1;

		for (i in 0 ... amount) {
			var t: BitmapData = new BitmapData(Std.int(width), Std.int(height), true, 0x000000);
			tiles[currenttileset].tiles.push(t);
		}

		changetileset(imagename);
	}

	/** Returns the width of a tile in the current tileset. */

	public static function tilewidth(): Int {
		return tiles[currenttileset].width;
	}

	/** Returns the height of a tile in the current tileset. */

	public static function tileheight(): Int {
		return tiles[currenttileset].height;
	}

	/** Loads an image into the game. */

	public static function loadimage(imagename: String) {
		buffer = new Bitmap(Assets.getBitmapData("data/graphics/" + imagename + ".png")).bitmapData;
		if (buffer == null) {
			throw("ERROR: In loadimage, cannot find data/graphics/" + imagename + ".png.");
			return;
		}

		imageindex.set(imagename, images.length);

		var t: BitmapData = new BitmapData(buffer.width, buffer.height, true, 0x000000);
		settrect(0, 0, buffer.width, buffer.height);
		t.copyPixels(buffer, trect, tl);
		images.push(t);
	}

	/** Creates a blank image, with the name "imagename", with given width and height. */

	public static function createimage(imagename: String, width: Float, height: Float) {
		imageindex.set(imagename, images.length);

		var t: BitmapData = new BitmapData(Math.floor(width), Math.floor(height), true, 0);
		images.push(t);
	}

	/** Resizes an image to a new size and stores it with the same label. */

	public static function resizeimage(imagename: String, scale: Float) {
		var oldindex: Int = imageindex.get(imagename);
		var newbitmap: BitmapData = new BitmapData(Std.int(images[oldindex].width * scale), Std.int(images[oldindex].height * scale), true, 0);
		var pixelalpha: Int;
		var pixel: Int;

		images[oldindex].lock();
		newbitmap.lock();

		for (j in 0 ... images[oldindex].height) {
			for (i in 0 ... images[oldindex].width) {
				pixel = images[oldindex].getPixel(i, j);
				pixelalpha = images[oldindex].getPixel32(i, j) >> 24 & 0xFF;
				settrect(Math.ceil(i * scale), Math.ceil(j * scale), Math.ceil(scale), Math.ceil(scale));
				newbitmap.fillRect(trect, (pixelalpha << 24) + pixel);
			}
		}

		images[oldindex].unlock();
		newbitmap.unlock();

		images[oldindex].dispose();
		images[oldindex] = newbitmap;
	}

	/** Returns the width of the image. */

	public static function imagewidth(imagename: String): Int {
		if (imageindex.exists(imagename)) {
			imagenum = imageindex.get(imagename);
		} else {
			throw("ERROR: In imagewidth, cannot find image \"" + imagename + "\".");
			return 0;
		}

		return images[imagenum].width;
	}

	/** Returns the height of the image. */

	public static function imageheight(imagename: String): Int {
		if (imageindex.exists(imagename)) {
			imagenum = imageindex.get(imagename);
		} else {
			throw("ERROR: In imageheight, cannot find image \"" + imagename + "\".");
			return 0;
		}

		return images[imagenum].height;
	}

	/** Tell draw commands to draw to the actual screen. */

	public static function drawtoscreen() {
		drawingtoscreen = true;
		drawto.unlock();
		drawto = backbuffer;
		drawto.lock();

		Text.drawto = Gfx.drawto;
	}

	/** Tell draw commands to draw to the given image. */

	public static function drawtoimage(imagename: String) {
		drawingtoscreen = false;
		imagenum = imageindex.get(imagename);

		drawto.unlock();
		drawto = images[imagenum];
		drawto.lock();

		Text.drawto = Gfx.drawto;
	}

	/** Tell draw commands to draw to the given tile in the current tileset. */
	public static function drawtotile(tilenumber: Int) {
		drawingtoscreen = false;
		drawto.unlock();
		drawto = tiles[currenttileset].tiles[tilenumber];
		drawto.lock();

		Text.drawto = Gfx.drawto;
	}

	/** Helper functions for image drawing functions. */
	private static var t1: Float;
	private static var t2: Float;
	private static var t3: Float;

	private static function imagealignx(x: Float): Float {
		if (x <= -5000) {
			t1 = x - CENTER;
			t2 = x - LEFT;
			t3 = x - RIGHT;
			if (t1 == 0 || (Math.abs(t1) < Math.abs(t2) && Math.abs(t1) < Math.abs(t3))) {
				return t1 + Gfx.screenwidthMid - Std.int(images[imagenum].width / 2);
			} else if (t2 == 0 || ((Math.abs(t2) < Math.abs(t1) && Math.abs(t2) < Math.abs(t3)))) {
				return t2;
			} else {
				return t3 + images[imagenum].width;
			}
		}

		return x;
	}

	private static function imagealigny(y: Float): Float {
		if (y <= -5000) {
			t1 = y - CENTER;
			t2 = y - TOP;
			t3 = y - BOTTOM;
			if (t1 == 0 || (Math.abs(t1) < Math.abs(t2) && Math.abs(t1) < Math.abs(t3))) {
				return t1 + Gfx.screenheightMid - Std.int(images[imagenum].height / 2);
			} else if (t2 == 0 || ((Math.abs(t2) < Math.abs(t1) && Math.abs(t2) < Math.abs(t3)))) {
				return t2;
			} else {
				return t3 + images[imagenum].height;
			}
		}

		return y;
	}

	private static function imagealignonimagex(x: Float): Float {
		if (x <= -5000) {
			t1 = x - CENTER;
			t2 = x - LEFT;
			t3 = x - RIGHT;
			if (t1 == 0 || (Math.abs(t1) < Math.abs(t2) && Math.abs(t1) < Math.abs(t3))) {
				return t1 + Std.int(images[imagenum].width / 2);
			} else if (t2 == 0 || ((Math.abs(t2) < Math.abs(t1) && Math.abs(t2) < Math.abs(t3)))) {
				return t2;
			} else {
				return t3 + images[imagenum].width;
			}
		}

		return x;
	}

	private static function imagealignonimagey(y: Float): Float {
		if (y <= -5000) {
			t1 = y - CENTER;
			t2 = y - TOP;
			t3 = y - BOTTOM;
			if (t1 == 0 || (Math.abs(t1) < Math.abs(t2) && Math.abs(t1) < Math.abs(t3))) {
				return t1 + Std.int(images[imagenum].height / 2);
			} else if (t2 == 0 || ((Math.abs(t2) < Math.abs(t1) && Math.abs(t2) < Math.abs(t3)))) {
				return t2;
			} else {
				return t3 + images[imagenum].height;
			}
		}

		return y;
	}

	public static function drawimage(x: Float, y: Float, imagename: String) {
		if (!clearscreeneachframe) if (skiprender && drawingtoscreen) return;
		if (!imageindex.exists(imagename)) {
			throw("ERROR: In drawimage, cannot find image \"" + imagename + "\".");
			return;
		}
		imagenum = imageindex.get(imagename);
		x = imagealignx(x); y = imagealigny(y);

		if (!transform && !coltransform) {
			settpoint(Std.int(x), Std.int(y));
			drawto.copyPixels(images[imagenum], images[imagenum].rect, tpoint, null, null, true);
		} else {
			tempxalign = 0; tempyalign = 0;

			shapematrix.identity();

			if (imagexscale != 1.0 || imageyscale != 1.0) {
				if (imagescalexpivot != 0.0) tempxalign = imagealignonimagex(imagescalexpivot);
				if (imagescaleypivot != 0.0) tempyalign = imagealignonimagey(imagescaleypivot);
				shapematrix.translate(-tempxalign, -tempyalign);
				shapematrix.scale(imagexscale, imageyscale);
				shapematrix.translate(tempxalign, tempyalign);
			}

			if (imagerotate != 0) {
				if (imagerotatexpivot != 0.0) tempxalign = imagealignonimagex(imagerotatexpivot);
				if (imagerotateypivot != 0.0) tempyalign = imagealignonimagey(imagerotateypivot);
				shapematrix.translate(-tempxalign, -tempyalign);
				shapematrix.rotate((imagerotate * 3.1415) / 180);
				shapematrix.translate(tempxalign, tempyalign);
			}

			shapematrix.translate(x, y);
			if (coltransform) {
				alphact.alphaMultiplier = imagealphamult;
				alphact.redMultiplier = imageredmult;
				alphact.greenMultiplier = imagegreenmult;
				alphact.blueMultiplier = imagebluemult;
				alphact.redOffset = imageredadd;
				alphact.greenOffset = imagegreenadd;
				alphact.blueOffset = imageblueadd;
				drawto.draw(images[imagenum], shapematrix, alphact);    
			} else {
				drawto.draw(images[imagenum], shapematrix);
			}
			shapematrix.identity();
		}
	}

	public static function grabtilefromscreen(tilenumber: Int, x: Float, y: Float) {
		if (currenttileset == -1) {
			throw("ERROR: In grabtilefromscreen, there is no tileset currently set. Use Gfx.changetileset(\"tileset name\") to set the current tileset.");
			return;
		}

		settrect(x, y, tilewidth(), tileheight());
		tiles[currenttileset].tiles[tilenumber].copyPixels(backbuffer, trect, tl);
	}

	public static function grabtilefromimage(tilenumber: Int, imagename: String, x: Float, y: Float) {
		if (!imageindex.exists(imagename)) {
			throw("ERROR: In grabtilefromimage, \"" + imagename + "\" does not exist.");
			return;
		}

		if (currenttileset == -1) {
			throw("ERROR: In grabtilefromimage, there is no tileset currently set. Use Gfx.changetileset(\"tileset name\") to set the current tileset.");
			return;
		}

		imagenum = imageindex.get(imagename);

		settrect(x, y, tilewidth(), tileheight());
		tiles[currenttileset].tiles[tilenumber].copyPixels(images[imagenum], trect, tl);
	}

	public static function grabimagefromscreen(imagename: String, x: Float, y: Float) {
		if (!imageindex.exists(imagename)) {
			throw("ERROR: In grabimagefromscreen, \"" + imagename + "\" does not exist. You need to create an image label first before using this function.");
			return;
		}
		imagenum = imageindex.get(imagename);

		settrect(x, y, images[imagenum].width, images[imagenum].height);
		images[imagenum].copyPixels(backbuffer, trect, tl);
	}

	public static function grabimagefromimage(imagename: String, imagetocopyfrom: String, x: Float, y: Float, w: Float = 0, h: Float = 0) {
		if (!imageindex.exists(imagename)) {
			throw("ERROR: In grabimagefromimage, \"" + imagename + "\" does not exist. You need to create an image label first before using this function.");
			return;
		}

		imagenum = imageindex.get(imagename);
		if (!imageindex.exists(imagetocopyfrom)) {
			trace("ERROR: No image called \"" + imagetocopyfrom + "\" found.");
		}
		var imagenumfrom: Int = imageindex.get(imagetocopyfrom);

		if (w == 0 && h == 0) {
			settrect(x, y, images[imagenum].width, images[imagenum].height);
		} else {
			settrect(x, y, w, h);
		}
		images[imagenum].copyPixels(images[imagenumfrom], trect, tl);
	}

	public static function copytile(totilenumber: Int, fromtileset: String, fromtilenumber: Int) {
		if (tilesetindex.exists(fromtileset)) {
			if (tiles[currenttileset].width == tiles[tilesetindex.get(fromtileset)].width && tiles[currenttileset].height == tiles[tilesetindex.get(fromtileset)].height) {
				tiles[currenttileset].tiles[totilenumber].copyPixels(tiles[tilesetindex.get(fromtileset)].tiles[fromtilenumber], tiles[tilesetindex.get(fromtileset)].tiles[fromtilenumber].rect, tl);
			} else {
				trace("ERROR: Tilesets " + currenttilesetname + " (" + Std.string(tilewidth()) + "x" + Std.string(tileheight()) + ") and " + fromtileset + " (" + Std.string(tiles[tilesetindex.get(fromtileset)].width) + "x" + Std.string(tiles[tilesetindex.get(fromtileset)].height) + ") are different sizes. Maybe try just drawing to the tile you want instead with Gfx.drawtotile()?");
				return;
			}
		} else {
			trace("ERROR: Tileset " + fromtileset + " hasn't been loaded or created.");
			return;
		}
	}

	public static function drawtile(x: Float, y: Float, t: Int) {
		if (!clearscreeneachframe) if (skiprender && drawingtoscreen) return;
		if (currenttileset == -1) {
			throw("ERROR: No tileset currently set. Use Gfx.changetileset(\"tileset name\") to set the current tileset.");
			return;
		}
		if (t >= numberoftiles()) {
			if (t == numberoftiles()) {
				throw("ERROR: Tried to draw tile number " + Std.string(t) + ", but there are only " + Std.string(numberoftiles()) + " tiles in tileset \"" + tiles[currenttileset].name + "\". (Because this includes tile number 0, " + Std.string(t) + " is not a valid tile.)");
				return;
			} else {
				throw("ERROR: Tried to draw tile number " + Std.string(t) + ", but there are only " + Std.string(numberoftiles()) + " tiles in tileset \"" + tiles[currenttileset].name + "\".");
				return;
			}
		}

		x = tilealignx(x); y = tilealigny(y);

		if (!transform && !coltransform) {
			settpoint(Std.int(x), Std.int(y));
			drawto.copyPixels(tiles[currenttileset].tiles[t], tiles[currenttileset].tiles[t].rect, tpoint, null, null, true);
		}else {     
			tempxalign = 0; tempyalign = 0;

			shapematrix.identity();

			if (imagexscale != 1.0 || imageyscale != 1.0) {
				if (imagescalexpivot != 0.0) tempxalign = tilealignontilex(imagescalexpivot);
				if (imagescaleypivot != 0.0) tempyalign = tilealignontiley(imagescaleypivot);
				shapematrix.translate( -tempxalign, -tempyalign);
				shapematrix.scale(imagexscale, imageyscale);
				shapematrix.translate( tempxalign, tempyalign);
			}

			if (imagerotate != 0) {
				if (imagerotatexpivot != 0.0) tempxalign = tilealignontilex(imagerotatexpivot);
				if (imagerotateypivot != 0.0) tempyalign = tilealignontiley(imagerotateypivot);
				shapematrix.translate( -tempxalign, -tempyalign);
				shapematrix.rotate((imagerotate * 3.1415) / 180);
				shapematrix.translate( tempxalign, tempyalign);
			}

			shapematrix.translate(x, y);
			if (coltransform) {
				alphact.alphaMultiplier = imagealphamult;
				alphact.redMultiplier = imageredmult;
				alphact.greenMultiplier = imagegreenmult;
				alphact.blueMultiplier = imagebluemult;
				alphact.redOffset = imageredadd;
				alphact.greenOffset = imagegreenadd;
				alphact.blueOffset = imageblueadd;
				drawto.draw(tiles[currenttileset].tiles[t], shapematrix, alphact);  
			}else {
				drawto.draw(tiles[currenttileset].tiles[t], shapematrix);
			}
			shapematrix.identity();
		}
	}

	private static function tilealignx(x: Float): Float {
		if (x == CENTER) return Gfx.screenwidthMid - Std.int(tiles[currenttileset].width / 2);
		if (x == LEFT || x == TOP) return 0;
		if (x == RIGHT || x == BOTTOM) return tiles[currenttileset].width;
		return x;
	}

	private static function tilealigny(y: Float): Float {
		if (y == CENTER) return Gfx.screenheightMid - Std.int(tiles[currenttileset].height / 2);
		if (y == LEFT || y == TOP) return 0;
		if (y == RIGHT || y == BOTTOM) return tiles[currenttileset].height;
		return y;
	}

	private static function tilealignontilex(x: Float): Float {
		if (x == CENTER) return Std.int(tiles[currenttileset].width / 2);
		if (x == LEFT || x == TOP) return 0;
		if (x == RIGHT || x == BOTTOM) return tiles[currenttileset].width;
		return x;
	}

	private static function tilealignontiley(y: Float): Float {
		if (y == CENTER) return Std.int(tiles[currenttileset].height / 2);
		if (y == LEFT || y == TOP) return 0;
		if (y == RIGHT || y == BOTTOM) return tiles[currenttileset].height;
		return y;
	}

	public static function draw_line(_x1: Float, _y1: Float, _x2: Float, _y2: Float, col: Int, alpha: Float = 1.0) {
		if (!clearscreeneachframe) if (skiprender && drawingtoscreen) return;
		tempshape.graphics.clear();
		tempshape.graphics.lineStyle(line_thickness, col, alpha);
		tempshape.graphics.moveTo(_x1, _y1);
		tempshape.graphics.lineTo(_x2, _y2);

		shapematrix.identity();
		drawto.draw(tempshape, shapematrix);
	}

	public static function drawHexagon(x: Float, y: Float, radius: Float, angle: Float, col: Int, alpha: Float = 1.0) {
		if (!clearscreeneachframe) if (skiprender && drawingtoscreen) return;
		tempshape.graphics.clear();
		tempshape.graphics.lineStyle(line_thickness, col, alpha);

		temprotate = ((Math.PI * 2) / 6);

		tx = (Math.cos(angle) * radius);
		ty = (Math.sin(angle) * radius);

		tempshape.graphics.moveTo(tx, ty);
		for (i in 0 ... 7) {
			tx = (Math.cos(angle + (temprotate * i)) * radius);
			ty = (Math.sin(angle + (temprotate * i)) * radius);

			tempshape.graphics.lineTo(tx, ty);
		}

		shapematrix.identity();
		shapematrix.translate(x, y);
		drawto.draw(tempshape, shapematrix);
	}

	public static function fillHexagon(x: Float, y: Float, radius: Float, angle: Float, col: Int, alpha: Float = 1.0) {
		if (!clearscreeneachframe) if (skiprender && drawingtoscreen) return;
		tempshape.graphics.clear();
		temprotate = ((Math.PI * 2) / 6);

		tx = (Math.cos(angle) * radius);
		ty = (Math.sin(angle) * radius);

		tempshape.graphics.moveTo(tx, ty);
		tempshape.graphics.beginFill(col, alpha);
		for (i in 0 ... 7) {
			tx = (Math.cos(angle + (temprotate * i)) * radius);
			ty = (Math.sin(angle + (temprotate * i)) * radius);

			tempshape.graphics.lineTo(tx, ty);
		}
		tempshape.graphics.endFill();

		shapematrix.identity();
		shapematrix.translate(x, y);
		drawto.draw(tempshape, shapematrix);
	}

	public static function draw_circle(x: Float, y: Float, radius: Float, col: Int, alpha: Float = 1.0) {
		if (!clearscreeneachframe) if (skiprender && drawingtoscreen) return;
		tempshape.graphics.clear();
		tempshape.graphics.lineStyle(line_thickness, col, alpha);
		tempshape.graphics.drawCircle(0, 0, radius);

		shapematrix.identity();
		shapematrix.translate(x, y);
		drawto.draw(tempshape, shapematrix);
	}

	public static function fill_circle(x: Float, y: Float, radius: Float, col: Int, alpha: Float = 1.0) {
		if (!clearscreeneachframe) if (skiprender && drawingtoscreen) return;
		tempshape.graphics.clear();
		tempshape.graphics.beginFill(col, alpha);
		tempshape.graphics.drawCircle(0, 0, radius);
		tempshape.graphics.endFill();

		shapematrix.identity();
		shapematrix.translate(x, y);
		drawto.draw(tempshape, shapematrix);
	}

	public static function draw_tri(x1: Float, y1: Float, x2: Float, y2: Float, x3: Float, y3: Float, col: Int, alpha: Float = 1.0) {
		if (!clearscreeneachframe) if (skiprender && drawingtoscreen) return;
		tempshape.graphics.clear();
		tempshape.graphics.lineStyle(line_thickness, col, alpha);
		tempshape.graphics.lineTo(0, 0);
		tempshape.graphics.lineTo(x2 - x1, y2 - y1);
		tempshape.graphics.lineTo(x3 - x1, y3 - y1);
		tempshape.graphics.lineTo(0, 0);
		tempshape.graphics.endFill();

		shapematrix.identity();
		shapematrix.translate(x1, y1);
		drawto.draw(tempshape, shapematrix);
	}

	public static function fill_tri_array(tri: Array<Float>, col: Int, alpha: Float = 1.0) {
		if (tri.length != 6) {
			trace("Gfx.fill_tri_array(): tri array size must be 6");
			return;
		}
		if (!clearscreeneachframe) if (skiprender && drawingtoscreen) return;
		tempshape.graphics.clear();
		tempshape.graphics.beginFill(col, alpha);
		tempshape.graphics.lineTo(0, 0);
		tempshape.graphics.lineTo(tri[2] - tri[0], tri[3] - tri[1]);
		tempshape.graphics.lineTo(tri[4] - tri[0], tri[5] - tri[1]);
		tempshape.graphics.lineTo(0, 0);
		tempshape.graphics.endFill();

		shapematrix.identity();
		shapematrix.translate(tri[0], tri[1]);
		drawto.draw(tempshape, shapematrix);
	}

	public static function fill_tri(x1: Float, y1: Float, x2: Float, y2: Float, x3: Float, y3: Float, col: Int, alpha: Float = 1.0) {
		if (!clearscreeneachframe) if (skiprender && drawingtoscreen) return;
		tempshape.graphics.clear();
		tempshape.graphics.beginFill(col, alpha);
		tempshape.graphics.lineTo(0, 0);
		tempshape.graphics.lineTo(x2 - x1, y2 - y1);
		tempshape.graphics.lineTo(x3 - x1, y3 - y1);
		tempshape.graphics.lineTo(0, 0);
		tempshape.graphics.endFill();

		shapematrix.identity();
		shapematrix.translate(x1, y1);
		drawto.draw(tempshape, shapematrix);
	}

	public static function drawbox(x: Float, y: Float, width: Float, height: Float, col: Int, alpha: Float = 1.0) {
		if (!clearscreeneachframe) if (skiprender && drawingtoscreen) return;
		if (width < 0) {
			width = -width;
			x = x - width;
		}
		if (height < 0) {
			height = -height;
			y = y - height;
		}
		if (line_thickness < 2) {
			fillbox(x, y, width, 1, col, alpha);
			fillbox(x, y + height - 1, width - 1, 1, col, alpha);
			fillbox(x, y + 1, 1, height - 1, col, alpha);
			fillbox(x + width - 1, y + 1, 1, height - 1, col, alpha);
		} else {
			tempshape.graphics.clear();
			tempshape.graphics.lineStyle(line_thickness, col, alpha);
			tempshape.graphics.lineTo(width, 0);
			tempshape.graphics.lineTo(width, height);
			tempshape.graphics.lineTo(0, height);
			tempshape.graphics.lineTo(0, 0);

			shapematrix.identity();
			shapematrix.translate(x, y);
			drawto.draw(tempshape, shapematrix);
		}
	}

	public static function fillbox(x: Float, y: Float, width: Float, height: Float, col: Int, alpha: Float = 1.0) {
		if (!clearscreeneachframe) if (skiprender && drawingtoscreen) return;
		tempshape.graphics.clear();
		tempshape.graphics.beginFill(col, alpha);
		tempshape.graphics.lineTo(width, 0);
		tempshape.graphics.lineTo(width, height);
		tempshape.graphics.lineTo(0, height);
		tempshape.graphics.lineTo(0, 0);
		tempshape.graphics.endFill();

		shapematrix.identity();
		shapematrix.translate(x, y);
		drawto.draw(tempshape, shapematrix);
	}

	public static function draw_poly(poly: Array<Float>, col: Int, alpha: Float = 1.0) {
		if (!clearscreeneachframe) if (skiprender && drawingtoscreen) return;
		tempshape.graphics.clear();
		tempshape.graphics.lineStyle(line_thickness, col, alpha);
		tempshape.graphics.lineTo(0, 0);
		for (i in 1...Std.int(poly.length / 2)) {
			tempshape.graphics.lineTo(poly[i * 2] - poly[0], poly[i * 2 + 1] - poly[1]);
		}
		tempshape.graphics.lineTo(0, 0);
		tempshape.graphics.endFill();

		shapematrix.identity();
		shapematrix.translate(poly[0], poly[1]);
		drawto.draw(tempshape, shapematrix);
	}

	public static function fill_poly(poly: Array<Float>, col: Int, alpha: Float = 1.0) {
		if (!clearscreeneachframe) if (skiprender && drawingtoscreen) return;
		tempshape.graphics.clear();
		tempshape.graphics.beginFill(col, alpha);
		tempshape.graphics.lineTo(0, 0);
		for (i in 1...Std.int(poly.length / 2)) {
			tempshape.graphics.lineTo(poly[i * 2] - poly[0], poly[i * 2 + 1] - poly[1]);
		}
		tempshape.graphics.lineTo(0, 0);
		tempshape.graphics.endFill();

		shapematrix.identity();
		shapematrix.translate(poly[0], poly[1]);
		drawto.draw(tempshape, shapematrix);
	}

	private static function isosceles_curve(x1: Float, y1: Float, x2: Float, y2: Float, angle: Float) {
		tempshape.graphics.moveTo(x1, y1);
		var l = Math.dst(x1, y1, x2, y2);
		var h = (l / 2) / Math.cos(angle);
		var h_angle = Math.atan2(y2 - y1, x2 - x1) - angle;
		var dx = h * Math.cos(h_angle);
		var dy = h * Math.sin(h_angle);
		tempshape.graphics.curveTo(x1 + dx, y1 + dy, x2, y2);
	}

	public static function draw_round_tri(x: Float, y: Float, radius: Float, internal_angle: Float, angle: Float, col: Int, alpha: Float = 1.0) {
		if (!clearscreeneachframe) if (skiprender && drawingtoscreen) return;
		tempshape.graphics.clear();
		tempshape.graphics.lineStyle(line_thickness, col, alpha);
		var p1 = {x: 0.0, y: radius};
		Math.rotate_vector(p1, 0, 0, angle);
		var p2 = {x: p1.x, y: p1.y};
		var p3 = {x: p1.x, y: p1.y};
		Math.rotate_vector(p2, 0, 0, 2 * Math.PI / 3);
		Math.rotate_vector(p3, 0, 0, 4 * Math.PI / 3);
		isosceles_curve(p1.x, p1.y, p2.x, p2.y, internal_angle / 2);
		isosceles_curve(p2.x, p2.y, p3.x, p3.y, internal_angle / 2);
		isosceles_curve(p3.x, p3.y, p1.x, p1.y, internal_angle / 2);
		tempshape.graphics.lineTo(0, 0);
		tempshape.graphics.endFill();


		shapematrix.identity();
		shapematrix.translate(x, y);
		drawto.draw(tempshape, shapematrix);
	}

	public static function fill_round_tri(x: Float, y: Float, radius: Float, internal_angle: Float, angle: Float, col: Int, alpha: Float = 1.0) {
		if (!clearscreeneachframe) if (skiprender && drawingtoscreen) return;
		tempshape.graphics.clear();
		tempshape.graphics.beginFill(col, alpha);
		var p1 = {x: radius, y: 0.0};
		Math.rotate_vector(p1, 0, 0, angle);
		var p2 = {x: p1.x, y: p1.y};
		var p3 = {x: p1.x, y: p1.y};
		Math.rotate_vector(p2, 0, 0, 2 * Math.PI / 3);
		Math.rotate_vector(p3, 0, 0, 4 * Math.PI / 3);
		isosceles_curve(p1.x, p1.y, p2.x, p2.y, internal_angle / 2);
		isosceles_curve(p2.x, p2.y, p3.x, p3.y, internal_angle / 2);
		isosceles_curve(p3.x, p3.y, p1.x, p1.y, internal_angle / 2);
		tempshape.graphics.lineTo(p2.x, p2.y);
		tempshape.graphics.endFill();

		shapematrix.identity();
		shapematrix.translate(x, y);
		drawto.draw(tempshape, shapematrix);
	}

	public static function clearscreen(col: Int = 0x000000) {
		if (!clearscreeneachframe) if (skiprender && drawingtoscreen) return;
		drawto.fillRect(drawto.rect, (0x00 << 24) + col);
	}

	public static function clearscreentransparent() {
		if (!clearscreeneachframe) if (skiprender && drawingtoscreen) return;
		drawto.fillRect(drawto.rect, 0);
	}

	public static function test(x, y, color) {
		drawto.setPixel32(x, y, color);
	}

	public static function get_pixel(x: Float, y: Float): Int {
		var pixelalpha: Int = drawto.getPixel32(Std.int(x), Std.int(y)) >> 24 & 0xFF;
		var pixel: Int = drawto.getPixel(Std.int(x), Std.int(y));

		if (pixelalpha == 0) return Col.TRANSPARENT;
		return pixel;
	}

	public static function set_pixel(x: Float, y: Float, col: Int, alpha: Float = 1.0) {
		if (!clearscreeneachframe) if (skiprender && drawingtoscreen) return;
		drawto.setPixel32(Std.int(x), Std.int(y), (Std.int(alpha * 0xFF) << 24) + col);
	}

	public static function getred(c: Int): Int {
		return (( c >> 16 ) & 0xFF);
	}

	public static function getgreen(c: Int): Int {
		return ( (c >> 8) & 0xFF );
	}

	public static function getblue(c: Int): Int {
		return ( c & 0xFF );
	}

	/** Get the Hue value (0-360) of a hex code colour. **/

	public static function gethue(c: Int): Int {
		var r: Float = getred(c) / 255;
		var g: Float = getgreen(c) / 255;
		var b: Float = getblue(c) / 255;
		var max: Float = Math.max(Math.max(r, g), b);
		var min: Float = Math.min(Math.min(r, g), b);

		var h: Float = (max + min) / 2;

		if (max != min) {
			var d: Float = max - min;
			if (max == r) {
				h = (g - b) / d + (g < b ? 6 : 0);
			} else if (max == g) {
				h = (b - r) / d + 2;
			} else if (max == b) {
				h = (r - g) / d + 4;
			}
			h /= 6;
		}

		return Std.int(h * 360);
	}

	/** Get the Saturation value (0.0-1.0) of a hex code colour. **/

	public static function getsaturation(c: Int): Float {
		var r: Float = getred(c) / 255;
		var g: Float = getgreen(c) / 255;
		var b: Float = getblue(c) / 255;
		var max: Float = Math.max(Math.max(r, g), b);
		var min: Float = Math.min(Math.min(r, g), b);

		var s: Float = (max + min) / 2;
		var l: Float = s;

		if (max == min) {
			s = 0;
		} else {
			var d: Float = max - min;
			s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
		}

		return s;
	}

	/** Get the Lightness value (0.0-1.0) of a hex code colour. **/

	public static function getlightness(c: Int): Float {
		var r: Float = getred(c) / 255;
		var g: Float = getgreen(c) / 255;
		var b: Float = getblue(c) / 255;
		var max: Float = Math.max(Math.max(r, g), b);
		var min: Float = Math.min(Math.min(r, g), b);

		return (max + min) / 2;
	}

	public static function setzoom(t: Int) {
		screen.width = screenwidth * t;
		screen.height = screenheight * t;
		screen.x = (screenwidth - (screenwidth * t)) / 2;
		screen.y = (screenheight - (screenheight * t)) / 2;
	}

	private static function updategraphicsmode() {
		if (fullscreen) {
			Lib.current.stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
			gfxstage.scaleMode = StageScaleMode.NO_SCALE;

			var xScaleFresh: Float = cast(devicexres, Float) / cast(screenwidth, Float);
			var yScaleFresh: Float = cast(deviceyres, Float) / cast(screenheight, Float);
			if (xScaleFresh < yScaleFresh) {
				screen.width = screenwidth * xScaleFresh;
				screen.height = screenheight * xScaleFresh;
			} else if (yScaleFresh < xScaleFresh) {
				screen.width = screenwidth * yScaleFresh;
				screen.height = screenheight * yScaleFresh;
			} else {
				screen.width = screenwidth * xScaleFresh;
				screen.height = screenheight * yScaleFresh;
			}
			screen.x = (cast(devicexres, Float) / 2.0) - (screen.width / 2.0);
			screen.y = (cast(deviceyres, Float) / 2.0) - (screen.height / 2.0);
            //Mouse.hide();
        } else {
        	Lib.current.stage.displayState = StageDisplayState.NORMAL;
        	gfxstage.scaleMode = StageScaleMode.SHOW_ALL;
        	screen.width = screenwidth * screenscale;
        	screen.height = screenheight * screenscale;
        	screen.x = 0.0;
        	screen.y = 0.0;
        	#if html5
        	gfxstage.quality = StageQuality.LOW;
        	#else
        	gfxstage.quality = StageQuality.HIGH;
        	#end
        }
    }

    /** Just gives Gfx access to the stage. */

    private static function init(stage: Stage) {
    	if (initrun) {
    		gfxstage = stage;

    		#if (js || html5)
    		onresize(null);
    		stage.addEventListener(Event.RESIZE, onresize);
    		#end
    	}
    	clearscreeneachframe = true;
    	reset();
    	line_thickness = 1;
    	transparentpixel = new BitmapData(1, 1, true, 0);

    	#if haxegon3D
    	Gfx3D.init3d();
    	#end
    }

    #if html5

    private static function onresize(e: Event): Void {
    	var scaleX: Float;
    	var scaleY: Float;

    	scaleX = Math.floor(gfxstage.stageWidth / screenwidth);
    	scaleY = Math.floor(gfxstage.stageHeight / screenheight);

    	var jsscale: Int = Math.round(Math.min(scaleX, scaleY));

    	gfxstage.scaleX = jsscale;
    	gfxstage.scaleY = jsscale;

    	gfxstage.x = (gfxstage.stageWidth - screenwidth * jsscale) / 2;
    	gfxstage.y = (gfxstage.stageHeight - screenheight * jsscale) / 2;
    }
    #end

    /** Called from resizescreen(). Sets up all our graphics buffers. */

    private static function initgfx(width: Int, height: Int, scale: Int) {
        //We initialise a few things
        screenwidth = width; screenheight = height;
        screenwidthMid = Std.int(screenwidth / 2); screenheightMid = Std.int(screenheight / 2);

        devicexres = Std.int(flash.system.Capabilities.screenResolutionX);
        deviceyres = Std.int(flash.system.Capabilities.screenResolutionY);
        screenscale = scale;

        trect = new Rectangle(); tpoint = new Point();
        tbuffer = new BitmapData(1, 1, true);
        ct = new ColorTransform(0, 0, 0, 1, 255, 255, 255, 1); //Set to white
        alphact = new ColorTransform();

        if (backbuffer != null) backbuffer.dispose();
        #if haxegon3D
        backbuffer = new BitmapData(screenwidth, screenheight, true, 0);
        #else
        backbuffer = new BitmapData(screenwidth, screenheight, false, 0x000000);
        #end
        drawto = backbuffer;
        drawingtoscreen = true;

        screen = new Bitmap(backbuffer);
        screen.smoothing = false;
        screen.width = screenwidth * scale;
        screen.height = screenheight * scale;

        fullscreen = false;
        haxegon.Debug.showTest = false;
    }

    /** Sets the values for the temporary rect structure. Probably better than making a new one, idk */

    private static function settrect(x: Float, y: Float, w: Float, h: Float) {
    	trect.x = x;
    	trect.y = y;
    	trect.width = w;
    	trect.height = h;
    }

    /** Sets the values for the temporary point structure. Probably better than making a new one, idk */

    private static function settpoint(x: Float, y: Float) {
    	tpoint.x = x;
    	tpoint.y = y;
    }

    private static var tiles: Array<haxegon.util.Tileset> = new Array<haxegon.util.Tileset>();
    private static var tilesetindex: Map<String, Int> = new Map<String, Int>();
    private static var currenttileset: Int = -1;

    private static var images: Array<BitmapData> = new Array<BitmapData>();
    private static var imagenum: Int;
    private static var ct: ColorTransform;
    private static var alphact: ColorTransform;
    private static var images_rect: Rectangle;
    private static var tl: Point = new Point(0, 0);
    private static var trect: Rectangle;
    private static var tpoint: Point;
    private static var tbuffer: BitmapData;
    public static var imageindex: Map<String, Int> = new Map<String, Int>();

    private static var transform: Bool;
    private static var coltransform: Bool;
    private static var imagerotate: Float;
    private static var imagerotatexpivot: Float;
    private static var imagerotateypivot: Float;
    private static var imagexscale: Float;
    private static var imageyscale: Float;
    private static var imagescalexpivot: Float;
    private static var imagescaleypivot: Float;
    private static var imagealphamult: Float;
    private static var imageredmult: Float;
    private static var imagegreenmult: Float;
    private static var imagebluemult: Float;
    private static var imageredadd:Float;
    private static var imagegreenadd:Float;
    private static var imageblueadd:Float;
    private static var tempframe: Int;
    private static var tempxalign: Float;
    private static var tempyalign: Float;
    private static var temprotate: Float;
    private static var changecolours: Bool;
    private static var oldtileset: String;
    private static var tx: Float;
    private static var ty: Float;
    private static var tx2: Float;
    private static var ty2: Float;
    private static var transparentpixel: BitmapData;

    public static var line_thickness: Float;

    private static var buffer: BitmapData;

    private static var temptile: BitmapData;
    //Actual backgrounds
    public static var screen: Bitmap;
    private static var tempshape: Shape = new Shape();
    public static var shapematrix: Matrix = new Matrix();

    private static var alphamult: Int;
    private static var gfxstage: Stage;

    public static var initrun: Bool;
    public static var skiprender: Bool;
    private static var drawingtoscreen: Bool;
}