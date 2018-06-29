import haxegon.*;
import openfl.net.SharedObject;

using haxegon.MathExtensions;
using Lambda;

@:publicFields
class Main {

    static inline var BOLT_DMG = 481.5;
    static inline var DEFAULT_PEN = 0.0;
    static inline var DEFAULT_CRIT = 5.0;
    static inline var DEFAULT_HIT = 7.0;
    static inline var DEFAULT_SP = 400.0;
    static inline var DEFAULT_RESISTANCE = 24.0;
    
    var crit_modifier: Float = 0;
    var sp_modifier: Float = 0;
    var hit_modifier: Float = 0;
    var pen_modifier: Float = 0;

    var number_of_locks = 3;
    var avg_lock_crit = DEFAULT_CRIT;
    var avg_lock_sp = DEFAULT_SP;
    var avg_lock_hit = DEFAULT_HIT;
    var avg_lock_pen = DEFAULT_PEN;

    var own_crit = DEFAULT_CRIT;
    var own_sp = DEFAULT_SP;
    var own_hit = DEFAULT_HIT;
    var own_pen = DEFAULT_PEN;

    var world_buffs = 0; // adds 18 crit if turned on(include head/dm and not flower, because it's up for less than an hour)
    var boss_resistance = DEFAULT_RESISTANCE; // after curse with level-based resistance included

    var obj: SharedObject;

    function new() {
        Gfx.resize_screen(1200, 750);
        GUI.set_pallete(Col.GRAY, Col.NIGHTBLUE, Col.WHITE, Col.WHITE);

        // couldn't figure out how to make a map in sharedobject
        obj = SharedObject.getLocal("stats");
        if (obj.data.number_of_locks != null) {
            number_of_locks = obj.data.number_of_locks;
        }

        if (obj.data.avg_lock_crit != null) {
            avg_lock_crit = obj.data.avg_lock_crit;
        }
        if (obj.data.avg_lock_sp != null) {
            avg_lock_sp = obj.data.avg_lock_sp;
        }
        if (obj.data.avg_lock_hit != null) {
            avg_lock_hit = obj.data.avg_lock_hit;
        }
        if (obj.data.avg_lock_pen != null) {
            avg_lock_pen = obj.data.avg_lock_pen;
        }

        if (obj.data.own_crit != null) {
            own_crit = obj.data.own_crit;
        }
        if (obj.data.own_sp != null) {
            own_sp = obj.data.own_sp;
        }
        if (obj.data.own_hit != null) {
            own_hit = obj.data.own_hit;
        }
        if (obj.data.own_pen != null) {
            own_pen = obj.data.own_pen;
        }
        if (obj.data.world_buffs != null) {
            world_buffs = obj.data.world_buffs;
        }
        if (obj.data.boss_resistance != null) {
            boss_resistance = obj.data.boss_resistance;
        }
    }

    function update() {
        Text.display(500, 20, 'Right click on slider to reset');
        GUI.x = 480;
        GUI.y = 50;
        GUI.auto_slider("crit", function(x: Float) { crit_modifier = Math.round(x); }, 
            Math.round(crit_modifier), -5, 5, 10, 500, 1);
        GUI.auto_slider("sp", function(x: Float) { sp_modifier = Math.round(x); }, 
            Math.round(sp_modifier), -50, 50, 10, 500, 1);
        GUI.auto_slider("hit", function(x: Float) { hit_modifier = Math.round(x); }, 
            Math.round(hit_modifier), -5, 5, 10, 500, 1);
        GUI.auto_slider("pen", function(x: Float) { pen_modifier = Math.round(x); }, 
            Math.round(pen_modifier), -20, 20, 10, 500, 1);

        function calc_dmg(sp: Float, crit: Float, hit: Float, pen: Float, raid_crit: Float) {
            // 83% default hit
            var hit_chance = Math.min(0.99, (83.0 + hit) / 100);
            // Head + DMT, no songflower
            if (world_buffs != 0) {
                crit += 18;
            }
            // 5% crit from Devastation
            var crit_chance = Math.min(1.0, (crit + 5) / 100); 
            var raid_crit_chance = Math.min(1.0, crit_chance * hit_chance + raid_crit / 100);

            // assume that procs dont get overwritten and each lock gets to use the proc on one shadow bolt
            var imp_bolt_bonus = Math.max(1.0, raid_crit_chance * 1.2 + (1 - raid_crit_chance));

            trace(imp_bolt_bonus);
            // 15% from talents
            // shadow bolt coefficient is 85.71%
            var dmg = (BOLT_DMG + sp * 0.8571) * 1.15 * imp_bolt_bonus * hit_chance;
            
            // Apply crit
            dmg = dmg * (1.0 - crit_chance) + dmg * 2 * crit_chance;

            // Apply resistance
            dmg = dmg * (1 - 0.75 * (Math.max(24, (boss_resistance - pen)) / (5 * 60)));

            return dmg;
        }

        // 5% from Devastation
        // modifier applied case by case
        var avg_lock_hit_chance = Math.min(0.99, (83.0 + avg_lock_hit) / 100);
        var raid_lock_crit = (avg_lock_crit + 5) * avg_lock_hit_chance * number_of_locks;
        
        var own_dmg = calc_dmg(own_sp, own_crit, own_hit, own_pen, raid_lock_crit);
        var own_dmg_with_modifiers = calc_dmg(own_sp + sp_modifier, own_crit + crit_modifier, 
            own_hit + hit_modifier, own_pen + pen_modifier,
            raid_lock_crit + crit_modifier);
        var all_locks_dmg = own_dmg + number_of_locks * calc_dmg(avg_lock_sp, avg_lock_crit, avg_lock_hit, 
            avg_lock_pen, raid_lock_crit);
        var all_locks_dmg_with_modifiers = own_dmg_with_modifiers + number_of_locks * calc_dmg(avg_lock_sp, avg_lock_crit, 
            avg_lock_hit, avg_lock_pen, raid_lock_crit + crit_modifier);

        var values_x = Text.width('All lock\'s modified dmg per bolt:') + 5;

        Text.display(0, 0, 'Your default dmg per bolt:');
        Text.display(values_x, 0, '${Math.fixed_float(own_dmg, 2)}');
        Text.display(0, 30, 'Your modified dmg per bolt:');
        Text.display(values_x, 30, '${Math.fixed_float(own_dmg_with_modifiers, 2)}');
        Text.display(0, 70, 'All lock\'s default dmg per bolt:');
        Text.display(values_x, 70, '${Math.fixed_float(all_locks_dmg, 2)}');
        Text.display(0, 110, 'All lock\'s modified dmg per bolt:');
        Text.display(values_x, 110, '${Math.fixed_float(all_locks_dmg_with_modifiers, 2)}');
        Text.display(0, 190, 'Your default dps:');
        Text.display(values_x, 190, '${Math.fixed_float(own_dmg / 2.5, 2)}');
        Text.display(0, 230, 'Your modified dps:');
        Text.display(values_x, 230, '${Math.fixed_float(own_dmg_with_modifiers / 2.5, 2)}');


        Text.display(100, 460, 'Click on numbers to edit');

        GUI.editable_number(100, 500, 'Number of locks(not including you) = ', function set(x) { number_of_locks = x; obj.data.number_of_locks = x; obj.flush();}, number_of_locks);
        GUI.editable_number(100, 530, 'Avg lock sp = ', function set(x) { avg_lock_sp = x; obj.data.avg_lock_sp = x; obj.flush();}, avg_lock_sp);
        GUI.editable_number(100, 560, 'Avg lock crit = ', function set(x) { avg_lock_crit = x; obj.data.avg_lock_crit = x; obj.flush();}, avg_lock_crit);
        GUI.editable_number(100, 590, 'Avg lock hit = ', function set(x) { avg_lock_hit = x; obj.data.avg_lock_hit = x; obj.flush();}, avg_lock_hit);
        GUI.editable_number(100, 620, 'Avg lock pen = ', function set(x) { avg_lock_pen = x; obj.data.avg_lock_pen = x; obj.flush();}, avg_lock_pen);
        
        GUI.editable_number(100, 680, 'World buffs(+13crit) set to 1 for true = ', 
            function set(x) { world_buffs = Math.sign(x); obj.data.world_buffs = Math.sign(x); obj.flush();}, world_buffs);
        GUI.editable_number(100, 710, 'Boss resistance after curse, include 24 innate = ', 
            function set(x) { boss_resistance = x; obj.data.boss_resistance = x; obj.flush();}, boss_resistance);

        GUI.editable_number(600, 530, 'Your sp = ', function set(x) { own_sp = x; obj.data.own_sp = x; obj.flush();}, own_sp);
        GUI.editable_number(600, 560, 'Your crit = ', function set(x) { own_crit = x; obj.data.own_crit = x; obj.flush();}, own_crit);
        GUI.editable_number(600, 590, 'Your hit = ', function set(x) { own_hit = x; obj.data.own_hit = x; obj.flush();}, own_hit);
        GUI.editable_number(600, 620, 'Your pen = ', function set(x) { own_pen = x; obj.data.own_pen = x; obj.flush();}, own_pen);


    }
}
