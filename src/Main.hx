import haxegon.*;
import openfl.net.SharedObject;

using haxegon.MathExtensions;
using Lambda;

@:publicFields
class Main {

    static inline var INT_TO_CRIT = 60.6;
    // NOTE: including 5% from talents
    static inline var BASE_CRIT = 6.7;
    static inline var BOLT_COEFF = 0.8571;
    static inline var BOLT_CAST_TIME = 2.5;
    static inline var CORR_COEFF = 1.0;
    static inline var CORR_CAST_TIME = 1.5;
    static inline var CORR_DURATION = 18;

    static inline var DEFAULT_INT = 200.0;
    static inline var DEFAULT_SP = 400.0;
    static inline var DEFAULT_CRIT = 5.0;
    static inline var DEFAULT_HIT = 7.0;
    static inline var DEFAULT_PEN = 0.0;
    static inline var DEFAULT_RESISTANCE = 24.0;

    var my_int = DEFAULT_INT;
    var my_sp = DEFAULT_SP;
    var my_crit = DEFAULT_CRIT;
    var my_hit = DEFAULT_HIT;
    var my_pen = DEFAULT_PEN;

    var avg_lock_int = DEFAULT_INT;
    var avg_lock_sp = DEFAULT_SP;
    var avg_lock_crit = DEFAULT_CRIT;
    var avg_lock_hit = DEFAULT_HIT;
    var avg_lock_pen = DEFAULT_PEN;

    var int_mod: Float = 0;
    var crit_mod: Float = 0;
    var sp_mod: Float = 0;
    var hit_mod: Float = 0;
    var pen_mod: Float = 0;

    var bolt_dmg = 481.5;
    var corr_dmg = 666;
    var lock_count = 3;
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
        if (obj.data.corr_dmg != null) {
            corr_dmg = obj.data.corr_dmg;
        }
        if (obj.data.lock_count != null) {
            lock_count = obj.data.lock_count;
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
            Text.display(50, 50, 'Click on numbers to edit.\nRight click on slider to reset it.\nIntellect is total amount, the number that is shown in your character stats.\nCrit is from gear only, not including the base crit or the crit obtained from int or the crit from talents.\nShadow bolt damage is the average damage based on numbers in the spell tooltip.\nLock count includes you.\nBoss resistance is after curse and needs to include level-based resistance, which is 24.\nCorruption dmg is the damage in the tooltip, the damage dealt over full duration.');
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
        var auto_editable_y = 300;
        function auto_editable(text: String, set_function: Dynamic->Void, current: Dynamic) {
            GUI.editable_number(auto_editable_x, auto_editable_y, text, set_function, current);
            auto_editable_y += 30;
        }

        auto_editable('Bolt dmg = ', function set(x) { bolt_dmg = x; obj.data.bolt_dmg = x; obj.flush();}, bolt_dmg);
        auto_editable('Corruption dmg = ', function set(x) { corr_dmg = x; obj.data.corr_dmg = x; obj.flush();}, corr_dmg);
        auto_editable('Lock count = ', function set(x) { lock_count = x; obj.data.lock_count = x; obj.flush();}, lock_count);
        auto_editable('World buffs crit = ', 
            function set(x) { world_buffs_crit = x; obj.data.world_buffs_crit = x; obj.flush();}, world_buffs_crit);
        auto_editable('Boss resistance= ', 
            function set(x) { boss_resistance = x; obj.data.boss_resistance = x; obj.flush();}, boss_resistance);
        auto_editable_y += 20;

        auto_editable('Your int = ', function set(x) { my_int = x; obj.data.my_int = x; obj.flush();}, my_int);
        auto_editable('Your sp = ', function set(x) { my_sp = x; obj.data.my_sp = x; obj.flush();}, my_sp);
        auto_editable('Your crit = ', function set(x) { my_crit = x; obj.data.my_crit = x; obj.flush();}, my_crit);
        auto_editable('Your hit = ', function set(x) { my_hit = x; obj.data.my_hit = x; obj.flush();}, my_hit);
        auto_editable('Your pen = ', function set(x) { my_pen = x; obj.data.my_pen = x; obj.flush();}, my_pen);
        auto_editable_y += 20;

        auto_editable('Avg lock int = ', function set(x) { avg_lock_int = x; obj.data.avg_lock_int = x; obj.flush();}, avg_lock_int);
        auto_editable('Avg lock sp = ', function set(x) { avg_lock_sp = x; obj.data.avg_lock_sp = x; obj.flush();}, avg_lock_sp);
        auto_editable('Avg lock crit = ', function set(x) { avg_lock_crit = x; obj.data.avg_lock_crit = x; obj.flush();}, avg_lock_crit);
        auto_editable('Avg lock hit = ', function set(x) { avg_lock_hit = x; obj.data.avg_lock_hit = x; obj.flush();}, avg_lock_hit);
        auto_editable('Avg lock pen = ', function set(x) { avg_lock_pen = x; obj.data.avg_lock_pen = x; obj.flush();}, avg_lock_pen);

        // Calculate crit chance for other locks
        var avg_lock_crit_total = avg_lock_crit + (avg_lock_int / INT_TO_CRIT) + world_buffs_crit + BASE_CRIT;
        var avg_lock_hit_chance = Math.min(0.99, (83.0 + avg_lock_hit) / 100);
        var avg_lock_crit_chance = Math.min(1.0, avg_lock_crit_total / 100 * avg_lock_hit_chance);

        function calc_dps(int: Float, sp: Float, crit: Float, hit: Float, pen: Float) {
            // 83% default hit
            var hit_chance = Math.min(0.99, (83.0 + hit) / 100);

            // NOTE: can't use crit_chance() here because we need crit without application of hit, hit is applied later to overall dps
            crit += (int / INT_TO_CRIT) + world_buffs_crit + BASE_CRIT;
            var crit_chance = Math.min(1.0, crit / 100); 

            // FORMULA EXPLANATION: get bonus if stacks > 0
            // stacks > 0 unless 4 bolts before this one failed to crit(doesn't matter whose bolts)
            // Therefore if bolts always crit, chance to miss is 0 and full 20% always applied => bonus is 1.2
            // If bolts crit 25% of the time, then chance of 4 misses is 0.75^4=0.316
            // 0.2 * (1 - 0.316) + 1 = 1.1368
            var my_crit_with_hit = crit_chance * hit_chance;
            var avg_crit_chance = (my_crit_with_hit + avg_lock_crit_chance * (lock_count - 1)) / lock_count;
            var four_miss_chance = Math.pow((1.0 - avg_crit_chance), 4);
            var imp_bolt_bonus = (1.0 - four_miss_chance) * 0.2 + 1.0;
            imp_bolt_bonus = Math.max(1.0, imp_bolt_bonus);

            // 
            // BOLT DMG
            //
            // 15% dmg bonus from talents
            var bolt = (bolt_dmg + sp * BOLT_COEFF) * 1.15 * imp_bolt_bonus * hit_chance;
            
            // Apply crit
            bolt = bolt * (1.0 - crit_chance) + bolt * 2 * crit_chance;

            // Corruption dmg
            // 15% dmg bonus from talents
            var corr = (corr_dmg + sp * CORR_COEFF) * 1.15;

            // DPS
            // Calculate dps with 1 cycle of corruption + bolts
            // Add gcd portion based on a potential recast due to a missed corruption
            var bolts_per_corr = Math.floor(CORR_DURATION / BOLT_CAST_TIME);
            var total_dmg = bolts_per_corr * bolt + corr;
            var time = CORR_DURATION + (1 - hit_chance) * CORR_CAST_TIME;

            var dps = total_dmg / time;

            // Apply resistance
            dps = dps * (1 - 0.75 * (Math.max(24, (boss_resistance - pen)) / (5 * 60)));

            return dps;
        }

        var my_dps = calc_dps(my_int, my_sp, my_crit, my_hit, my_pen);
        var my_dps_modded = calc_dps(my_int + int_mod, my_sp + sp_mod, my_crit + crit_mod, my_hit + hit_mod, my_pen + pen_mod);

        var all_locks_dps = my_dps + (lock_count - 1) * calc_dps(avg_lock_int, avg_lock_sp, avg_lock_crit, avg_lock_hit, avg_lock_pen);

        var all_locks_dps_modded = my_dps_modded + (lock_count - 1) * calc_dps(avg_lock_int, avg_lock_sp, avg_lock_crit, avg_lock_hit, avg_lock_pen);
        
        //
        // Results
        //
        var results_string = '';
        results_string += '\nYour default dps: \t\t\t${Math.fixed_float(my_dps, 2)}';
        results_string += '\nYour modified dps: \t\t\t${Math.fixed_float(my_dps_modded, 2)}';
        results_string += '\nAll lock\'s default dps: \t\t\t${Math.fixed_float(all_locks_dps, 2)}';
        results_string += '\nAll lock\'s modified dps: \t\t${Math.fixed_float(all_locks_dps_modded, 2)}';
        Text.display(10, 50, results_string);
    }
}
