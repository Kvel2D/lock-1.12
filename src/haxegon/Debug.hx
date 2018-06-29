package haxegon;
	
import haxegon.util.*;
import openfl.display.*;
import openfl.geom.*;
import openfl.events.*;
import openfl.net.*;
import openfl.text.*;
import openfl.Assets;
import openfl.Lib;
import openfl.system.Capabilities;

class Debug {
	public static var showTest:Bool;


	public static var debuglog:Array<String> = new Array<String>();

	/** Clear the debug buffer */
	public static function clearLog() {
		debuglog = new Array<String>();
	}
	
	/** Outputs a string to the screen for testing. */
	public static function log(t:Dynamic) {
		debuglog.push(Std.string(t));
		showTest = true;
		if (debuglog.length > 20) {
			debuglog.reverse();
			debuglog.pop();
			debuglog.reverse();
		}
	}
	
	/** Shows a single test string. */
	public static function test(t:Dynamic) {
		debuglog[0] = Std.string(t);
		showTest = true;
	}
	
	public static function showLog() {
		if (showTest) {
			for (k in 0 ... debuglog.length) {
				for (j in -1 ... 2) {
					for (i in -1 ... 2) {
						Text.display(2 + i, j + Std.int(2 + ((debuglog.length - 1 - k) * (Text.height() + 2))), debuglog[k], Col.rgb(0, 0, 0));
					}
				}
				Text.display(2, Std.int(2 + ((debuglog.length-1-k) * (Text.height() + 2))), debuglog[k], Col.rgb(255, 255, 255));
			}
		}
	}
}