package haxegon;

import haxe.ds.Vector;
import openfl.Assets;

class Data {
    public static var width: Int = 0;
    public static var height: Int = 0;
    private static var tempstring: String;

    @:generic
    public static function print_array_of_vectors<T>(array: Array<Vector<T>>) {
        trace('[');
        for (i in 0...array.length) {
            print_vector(array[i]);
        }
        trace(']');
    }

    @:generic
    public static function print_2dvector<T>(vector: Vector<Vector<T>>) {
        trace('[');
        for (i in 0...vector.length) {
            print_vector(vector[i]);
        }
        trace(']');
    }

    @:generic
    public static function print_vector<T>(vector: Vector<T>) {
        var line = '[';
        for (i in 0...vector.length) {
            line += ' ${vector[i]}';
        }
        line += ']';
        trace(line);
    }

    public static function create2darray<T>(width:Int, height:Int, value:T):Array<Array<T>> {
        return [for (x in 0 ... width) [for (y in 0 ... height) value]];
    }

    public static function bool_2d_vector(width: Int, height: Int, default_value: Bool = false): Vector<Vector<Bool>> {
        var vector: Vector<Vector<Bool>> = new Vector(width);
        for (i in 0...width) {
            vector[i] = new Vector(height);
            for (j in 0...height) {
                vector[i][j] = default_value;
            }
        }
        return vector;
    }

    public static function int_2d_vector(width: Int, height: Int, default_value: Int = 0): Vector<Vector<Int>> {
        var vector: Vector<Vector<Int>> = new Vector(width);
        for (i in 0...width) {
            vector[i] = new Vector(height);
            for (j in 0...height) {
                vector[i][j] = default_value;
            }
        }
        return vector;
    }

    public static function int_3d_vector(width: Int, height: Int, depth: Int): Vector<Vector<Vector<Int>>> {
        var vector: Vector<Vector<Vector<Int>>> = new Vector(width);
        for (i in 0...width) {
            vector[i] = new Vector(height);
            for (j in 0...height) {
                vector[i][j] = new Vector(depth);
            }
        }
        return vector;
    }

    public static function float_2d_vector(width: Int, height: Int): Vector<Vector<Float>> {
        var vector: Vector<Vector<Float>> = new Vector(width);
        for (i in 0...width) {
            vector[i] = new Vector(height);
        }
        return vector;
    }

    public static function float_3d_vector(width: Int, height: Int, depth: Int): Vector<Vector<Vector<Float>>> {
        var vector: Vector<Vector<Vector<Float>>> = new Vector(width);
        for (i in 0...width) {
            vector[i] = new Vector(height);
            for (j in 0...height) {
                vector[i][j] = new Vector(depth);
            }
        }
        return vector;
    }

    public static function loadtext(textfile: String): Array<String> {
        tempstring = Assets.getText("data/text/" + textfile);
        if (tempstring == null) {
            trace('loadtext() couldn\'t find a file named ${textfile}');
            return null;
        }
        tempstring = replacechar(tempstring, "\r", "");
        return tempstring.split("\n");
    }

    @:generic
    public static function load_csv<T>(csvfile: String, delimiter: String = ","): Array<T> {
        tempstring = Assets.getText("data/text/" + csvfile + ".csv");

        //figure out width
        width = 1;
        var i: Int = 0;
        while (i < tempstring.length) {
            if (mid(tempstring, i) == delimiter) width++;
            if (mid(tempstring, i) == "\n") {
                break;
            }
            i++;
        }

        tempstring = replacechar(tempstring, "\r", "");
        tempstring = replacechar(tempstring, "\n", delimiter);

        var returnedarray: Array<T> = new Array<T>();
        var stringarray: Array<String> = tempstring.split(delimiter);

        for (i in 0 ... stringarray.length) {
            returnedarray.push(cast stringarray[i]);
        }

        height = Std.int(returnedarray.length / width);
        return returnedarray;
    }

    @:generic
    public static function blank2dArray<T>(width: Int, height: Int): Array<Array<T>> {
        var returnedarray2d: Array<Array<T>> = [for (x in 0 ... width) [for (y in 0 ... height) cast ""]];
        return returnedarray2d;
    }

    @:generic
    public static function load_csv_2d<T>(csvfile: String, delimiter: String = ","): Array<Array<T>> {
        tempstring = Assets.getText("data/text/" + csvfile + ".csv");

        //figure out width
        width = 1;
        var i: Int = 0;
        while (i < tempstring.length) {
            if (mid(tempstring, i) == delimiter) width++;
            if (mid(tempstring, i) == "\n") {
                break;
            }
            i++;
        }

        tempstring = replacechar(tempstring, "\r", "");
        tempstring = replacechar(tempstring, "\n", delimiter);

        var returnedarray: Array<T> = new Array<T>();
        var stringarray: Array<String> = tempstring.split(delimiter);

        for (i in 0 ... stringarray.length) {
            returnedarray.push(cast stringarray[i]);
        }

        height = Std.int(returnedarray.length / width);

        var returnedarray2d: Array<Array<T>> = [for (x in 0 ... width) [for (y in 0 ... height) returnedarray[x + (y * width)]]];
        return returnedarray2d;
    }

    /** Return characters from the middle of a string. */

    private static function mid(currentstring: String, start: Int = 0, length: Int = 1): String {
        return currentstring.substr(start, length);
    }

    private static function replacechar(currentstring: String, ch: String = "|", ch2: String = ""): String {
        var fixedstring: String = "";
        for (i in 0 ... currentstring.length) {
            if (mid(currentstring, i) == ch) {
                fixedstring += ch2;
            } else {
                fixedstring += mid(currentstring, i);
            }
        }
        return fixedstring;
    }
}
