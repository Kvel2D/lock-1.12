import haxegon.*;
import openfl.net.SharedObject;

using haxegon.MathExtensions;
using Lambda;

@:publicFields
class Main {

    static inline var INT_TO_CRIT = 60.6;
    static inline var BASE_CRIT = 1.7;
    static inline var BOLT_COEFF = 0.8571;

    static inline var DEFAULT_INT = 200.0;
    static inline var DEFAULT_SP = 400.0;
    static inline var DEFAULT_CRIT = 5.0;
    static inline var DEFAULT_TALENT_CRIT = 5.0;
    static inline var DEFAULT_HIT = 7.0;
    static inline var DEFAULT_PEN = 0.0;
    static inline var DEFAULT_RESISTANCE = 24.0;

    var my_int = DEFAULT_INT;
    var my_sp = DEFAULT_SP;
    var my_crit = DEFAULT_CRIT;
    var my_talent_crit = DEFAULT_TALENT_CRIT;
    var my_hit = DEFAULT_HIT;
    var my_pen = DEFAULT_PEN;

    var avg_lock_int = DEFAULT_INT;
    var avg_lock_sp = DEFAULT_SP;
    var avg_lock_crit = DEFAULT_CRIT;
    var avg_lock_talent_crit = DEFAULT_TALENT_CRIT;
    var avg_lock_hit = DEFAULT_HIT;
    var avg_lock_pen = DEFAULT_PEN;

    var int_mod: Float = 0;
    var crit_mod: Float = 0;
    var sp_mod: Float = 0;
    var hit_mod: Float = 0;
    var pen_mod: Float = 0;

    var bolt_dmg = 481.5;
    var number_of_locks = 3;
    var world_buffs_crit = 0;
    var boss_resistance = DEFAULT_RESISTANCE;

    var obj: SharedObject;
    var show_notes = false;

    function new() {
        Gfx.resizescreen(1200, 960);
        GUI.set_pallete(Col.GRAY, Col.NIGHTBLUE, Col.WHITE, Col.WHITE);

        // NOTE: Couldn't figure out how to make a map in sharedobject
        obj = SharedObject.getLocal("stats");

        if (obj.data.my_int != null) {
            my_sp = obj.data.my_sp;
        }
        if (obj.data.my_sp != null) {
            my_sp = obj.data.my_sp;
        }
        if (obj.data.my_crit != null) {
            my_crit = obj.data.my_crit;
        }
        if (obj.data.my_hit != null) {
            my_hit = obj.data.my_hit;
        }
        if (obj.data.my_pen != null) {
            my_pen = obj.data.my_pen;
        }

        if (obj.data.avg_lock_int != null) {
            avg_lock_int = obj.data.avg_lock_int;
        }
        if (obj.data.avg_lock_sp != null) {
            avg_lock_sp = obj.data.avg_lock_sp;
        }
        if (obj.data.avg_lock_crit != null) {
            avg_lock_crit = obj.data.avg_lock_crit;
        }
        if (obj.data.avg_lock_hit != null) {
            avg_lock_hit = obj.data.avg_lock_hit;
        }
        if (obj.data.avg_lock_pen != null) {
            avg_lock_pen = obj.data.avg_lock_pen;
        }

        if (obj.data.bolt_dmg != null) {
            bolt_dmg = obj.data.bolt_dmg;
        }
        if (obj.data.number_of_locks != null) {
            number_of_locks = obj.data.number_of_locks;
        }
        if (obj.data.world_buffs_crit != null) {
            world_buffs_crit = obj.data.world_buffs_crit;
        }
        if (obj.data.boss_resistance != null) {
            boss_resistance = obj.data.boss_resistance;
        }
    }

    function update() {
        GUI.text_button(0, 0, 'Toggle notes', function () { show_notes = !show_notes; });
        
        if (show_notes) {
            Text.wordwrap = 700;
            Text.display(50, 50, 'Click on numbers to edit.\nRight click on slider to reset it.\nIntellect is total amount, the number that is shown in your character stats.\nCrit is from gear only, not including the base crit or the crit obtained from int or the crit from talents.\nShadow bolt damage is the average damage based on numbers in the spell tooltip.\nNumber of locks includes you.\nBoss resistance is after curse and needs to include level-based resistance, which is 24.');
            return;
        }


        //
        // Mod sliders
        //
        GUI.x = 550;
        GUI.y = 50;
        GUI.auto_slider("int", function(x: Float) { int_mod = Math.round(x); }, Math.round(int_mod), -50, 50, 10, 500, 1);
        GUI.auto_slider("sp", function(x: Float) { sp_mod = Math.round(x); }, Math.round(sp_mod), -50, 50, 10, 500, 1);
        GUI.auto_slider("crit", function(x: Float) { crit_mod = Math.round(x); }, Math.round(crit_mod), -5, 5, 10, 500, 1);
        GUI.auto_slider("hit", function(x: Float) { hit_mod = Math.round(x); }, Math.round(hit_mod), -5, 5, 10, 500, 1);
        GUI.auto_slider("pen", function(x: Float) { pen_mod = Math.round(x); }, Math.round(pen_mod), -20, 20, 10, 500, 1);

        //
        // Editables
        //
        var auto_editable_x = 10;
        var auto_editable_y = 400;
        function auto_editable(text: String, set_function: Dynamic->Void, current: Dynamic) {
            GUI.editable_number(auto_editable_x, auto_editable_y, text, set_function, current);
            auto_editable_y += 30;
        }

        auto_editable('Bolt dmg = ', function set(x) { bolt_dmg = x; obj.data.bolt_dmg = x; obj.flush();}, bolt_dmg);
        auto_editable('Number of locks = ', function set(x) { number_of_locks = x; obj.data.number_of_locks = x; obj.flush();}, number_of_locks);
        auto_editable('World buffs crit = ', 
            function set(x) { world_buffs_crit = x; obj.data.world_buffs_crit = x; obj.flush();}, world_buffs_crit);
        auto_editable('Boss resistance= ', 
            function set(x) { boss_resistance = x; obj.data.boss_resistance = x; obj.flush();}, boss_resistance);

        auto_editable('Your int = ', function set(x) { my_int = x; obj.data.my_int = x; obj.flush();}, my_int);
        auto_editable('Your sp = ', function set(x) { my_sp = x; obj.data.my_sp = x; obj.flush();}, my_sp);
        auto_editable('Your crit = ', function set(x) { my_crit = x; obj.data.my_crit = x; obj.flush();}, my_crit);
        auto_editable('Your talent crit = ', function set(x) { my_talent_crit = x; obj.data.my_talent_crit = x; obj.flush();}, my_talent_crit);
        auto_editable('Your hit = ', function set(x) { my_hit = x; obj.data.my_hit = x; obj.flush();}, my_hit);
        auto_editable('Your pen = ', function set(x) { my_pen = x; obj.data.my_pen = x; obj.flush();}, my_pen);

        auto_editable('Avg lock int = ', function set(x) { avg_lock_int = x; obj.data.avg_lock_int = x; obj.flush();}, avg_lock_int);
        auto_editable('Avg lock sp = ', function set(x) { avg_lock_sp = x; obj.data.avg_lock_sp = x; obj.flush();}, avg_lock_sp);
        auto_editable('Avg lock crit = ', function set(x) { avg_lock_crit = x; obj.data.avg_lock_crit = x; obj.flush();}, avg_lock_crit);
        auto_editable('Avg lock talent crit = ', function set(x) { avg_lock_talent_crit = x; obj.data.avg_lock_talent_crit = x; obj.flush();}, avg_lock_talent_crit);
        auto_editable('Avg lock hit = ', function set(x) { avg_lock_hit = x; obj.data.avg_lock_hit = x; obj.flush();}, avg_lock_hit);
        auto_editable('Avg lock pen = ', function set(x) { avg_lock_pen = x; obj.data.avg_lock_pen = x; obj.flush();}, avg_lock_pen);

        function calc_dmg(int: Float, sp: Float, crit: Float, hit: Float, pen: Float, raid_crit_total: Float) {
            // 83% default hit
            var hit_chance = Math.min(0.99, (83.0 + hit) / 100);

            // NOTE: can't use crit_total() here, need crit without application of hit
            crit += (int / INT_TO_CRIT) + world_buffs_crit + BASE_CRIT;
            var crit_chance = Math.min(1.0, crit / 100); 

            // Assume that procs dont get overwritten and each lock gets to use the proc on one shadow bolt
            var raid_crit_chance = Math.min(1.0, raid_crit_total / 100);
            var imp_bolt_bonus = Math.max(1.0, raid_crit_chance * 1.2 + (1 - raid_crit_chance));

            // 15% from talents
            var dmg = (bolt_dmg + sp * BOLT_COEFF) * 1.15 * imp_bolt_bonus * hit_chance;
            
            // Apply crit
            dmg = dmg * (1.0 - crit_chance) + dmg * 2 * crit_chance;

            // Apply resistance
            dmg = dmg * (1 - 0.75 * (Math.max(24, (boss_resistance - pen)) / (5 * 60)));

            return dmg;
        }

        function crit_total(crit: Float, int: Float, hit: Float) {
            crit += (int / INT_TO_CRIT) + world_buffs_crit + BASE_CRIT;

            var hit_chance = Math.min(0.99, (83.0 + hit) / 100);

            return Math.min(1.0, crit / 100 * hit_chance);
        }

        // Calculate raid crit total with and without mods
        var my_crit_total = crit_total(my_crit + my_talent_crit, my_int, my_hit);
        var my_crit_total_modded = crit_total(my_crit + my_talent_crit + crit_mod, my_int + int_mod, my_hit + hit_mod);

        var avg_lock_crit_total = crit_total(avg_lock_crit + avg_lock_talent_crit, avg_lock_int, avg_lock_hit);

        var raid_crit_total = Math.min(1.0, my_crit_total + avg_lock_crit_total * (number_of_locks - 1));   
        var raid_crit_total_modded = Math.min(1.0, my_crit_total_modded + avg_lock_crit_total * (number_of_locks - 1));   

        var my_dmg = calc_dmg(my_int, my_sp, my_crit + my_talent_crit, my_hit, my_pen, raid_crit_total);
        var my_dmg_modded = calc_dmg(my_int + int_mod, my_sp + sp_mod, my_crit + my_talent_crit + crit_mod, my_hit + hit_mod, my_pen + pen_mod, raid_crit_total_modded);

        var all_locks_dmg = my_dmg + (number_of_locks - 1) * calc_dmg(avg_lock_int, avg_lock_sp, avg_lock_crit + avg_lock_talent_crit, avg_lock_hit, avg_lock_pen, raid_crit_total);

        var all_locks_dmg_modded = my_dmg_modded + (number_of_locks - 1) * calc_dmg(avg_lock_int, avg_lock_sp, avg_lock_crit + avg_lock_talent_crit, avg_lock_hit, avg_lock_pen, raid_crit_total_modded);
        
        //
        // Results
        //
        var results_string = '';
        results_string += 'Your default dmg per bolt: \t\t${Math.fixed_float(my_dmg, 2)}';
        results_string += '\nYour modified dmg per bolt: \t\t${Math.fixed_float(my_dmg_modded, 2)}';
        results_string += '\nAll lock\'s default dmg per bolt: \t${Math.fixed_float(all_locks_dmg, 2)}';
        results_string += '\nAll lock\'s modified dmg per bolt: \t${Math.fixed_float(all_locks_dmg_modded, 2)}';
        results_string += '\nYour default dps: \t\t\t${Math.fixed_float(my_dmg / 2.5, 2)}';
        results_string += '\nYour modified dps: \t\t\t${Math.fixed_float(my_dmg_modded / 2.5, 2)}';
        results_string += '\nAll lock\'s default dps: \t\t\t${Math.fixed_float(all_locks_dmg / 2.5, 2)}';
        results_string += '\nAll lock\'s modified dps: \t\t${Math.fixed_float(all_locks_dmg_modded / 2.5, 2)}';
        Text.display(10, 50, results_string);
    }
}
