package haxegon;

import openfl.display.DisplayObject;
import openfl.events.MouseEvent;
import openfl.ui.Mouse;
import openfl.events.Event;
import openfl.net.*;
import openfl.Lib;

class Mouse {
	// right click menu toggle for flash
	private static var flash_menu_on = false;

	public static var x:Int;
	public static var y:Int;
	
	public static var mousewheel:Int = 0;
	
	public static var mouseoffstage:Bool;
	public static var isdragging:Bool;

	private static var _current:Int;
	private static var _last:Int;
	
	private static var _middlecurrent:Int;
	private static var _middlelast:Int;
	private static var _rightcurrent:Int;
	private static var _rightlast:Int;
	
	public static function leftheld():Bool { return _current > 0; }
	public static function leftclick():Bool { return _current == 2; }
	public static function leftreleased():Bool { return _current == -1; }
	
	public static function rightheld():Bool { return _rightcurrent > 0; }
	public static function rightclick():Bool { return _rightcurrent == 2; }	
	public static function rightreleased():Bool { return _rightcurrent == -1; }
	
	public static function middleheld():Bool { return _middlecurrent > 0; }
	public static function middleclick():Bool { return _middlecurrent == 2; }	
	public static function middlereleased():Bool { return _middlecurrent == -1; }
	
	private static function init(stage:DisplayObject) {
		// disable html5's context menu
		#if html5
        untyped {
            document.oncontextmenu = document.body.oncontextmenu = function() {return false;}
        }
        #end
		if (!flash_menu_on) {
			stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, right_down);
			stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, right_up);
		}
		stage.addEventListener(MouseEvent.MOUSE_DOWN, mouse_down);
		stage.addEventListener(MouseEvent.MOUSE_UP, mouse_up);
		stage.addEventListener(MouseEvent.MIDDLE_MOUSE_DOWN, middle_down);
		stage.addEventListener(MouseEvent.MIDDLE_MOUSE_UP, middle_up);
		stage.addEventListener(MouseEvent.MOUSE_WHEEL, mousewheel_handler);
		stage.addEventListener(MouseEvent.MOUSE_MOVE, mouse_over);
		stage.addEventListener(Event.MOUSE_LEAVE, mouse_leave);
		x = 0;
		y = 0;
		_rightcurrent = 0;
		_rightlast = 0;
		_middlecurrent = 0;
		_middlelast = 0;
		_current = 0;
		_last = 0;
	}
	
	private static function unload(stage:DisplayObject) {
		if (!flash_menu_on) {
			stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, right_down);
			stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, right_up);
		}
		stage.removeEventListener(MouseEvent.MOUSE_DOWN, mouse_down);
		stage.removeEventListener(MouseEvent.MOUSE_UP, mouse_up);
		stage.removeEventListener(MouseEvent.MIDDLE_MOUSE_DOWN, middle_down);
		stage.removeEventListener(MouseEvent.MIDDLE_MOUSE_UP, middle_up);
		stage.removeEventListener(MouseEvent.MOUSE_WHEEL, mousewheel_handler);
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouse_over);
		stage.removeEventListener(Event.MOUSE_LEAVE, mouse_leave);
	}	

	private static function mouse_leave(e:Event) {
		mouseoffstage = true;
		_current = 0;
		_last = 0;
		isdragging = false;
		_rightcurrent = 0;
		_rightlast = 0;
		_middlecurrent = 0;
		_middlelast = 0;
	}
	
	private static function mouse_over(e:MouseEvent) {
		mouseoffstage = false;
	}
	
	private static function mousewheel_handler( e:MouseEvent ) {
		mousewheel = e.delta;
	}
	
	public static function show() {
		openfl.ui.Mouse.show();	
	}
	
	public static function hide() {
		openfl.ui.Mouse.hide();	
	}
	
	public static function update(X:Int,Y:Int){
		x = X;
		y = Y;
		
		if ((_last == -1) && (_current == -1))
			_current = 0;
		else if ((_last == 2) && (_current == 2))
			_current = 1;
		_last = _current;
		
		if ((_rightlast == -1) && (_rightcurrent == -1))
			_rightcurrent = 0;
		else if ((_rightlast == 2) && (_rightcurrent == 2))
			_rightcurrent = 1;
		_rightlast = _rightcurrent;
		
		if ((_middlelast == -1) && (_middlecurrent == -1))
			_middlecurrent = 0;
		else if ((_middlelast == 2) && (_middlecurrent == 2))
			_middlecurrent = 1;
		_middlelast = _middlecurrent;
	}
	
	private static function reset(){
		_current = 0;
		_last = 0;
		_rightcurrent = 0;
		_rightlast = 0;
		_middlecurrent = 0;
		_middlelast = 0;
	}
	

	private static function right_down(event:MouseEvent) {
		if (_rightcurrent > 0) { 
			_rightcurrent = 1; 
		} else { 
			_rightcurrent = 2; 
		} 
	}
	private static function right_up(event:MouseEvent) {
		if (_rightcurrent > 0) 
		{ 
			_rightcurrent = -1; 
		} else { 
			_rightcurrent = 0; 
		}	
	}
	
	private static function middle_down(event:MouseEvent) {	
		if (_middlecurrent > 0) { 
			_middlecurrent = 1; 
		} else { 
			_middlecurrent = 2; 
		} 
	}
	private static function middle_up(event:MouseEvent) {
		if (_middlecurrent > 0) {
			_middlecurrent = -1; 
		} else { 
			_middlecurrent = 0; 
		}	
	}
	
	private static function mouse_down(event:MouseEvent) {
		if (Input.pressed(Key.CONTROL)) {
			if (_rightcurrent > 0) _rightcurrent = 1;
			else _rightcurrent = 2;
		} else {
			if (_current > 0) _current = 1;
			else _current = 2;
		}
	}
	
	private static function mouse_up(event:MouseEvent) {		
		if (_rightcurrent > 0) _rightcurrent = -1;
		else _rightcurrent = 0;
		
		if (_current > 0) _current = -1;
		else _current = 0;
	}
}