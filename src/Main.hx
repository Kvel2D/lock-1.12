import haxegon.*;
import openfl.net.SharedObject;

using haxegon.MathExtensions;
using Lambda;

typedef RaidStats = {
    bolts: Int,
    corrs: Int,
    corr_casts: Int,
    burns: Int
}

typedef Stats = {
    int: Int,
    sp: Int,
    crit: Int,
    hit: Int,
    lock_count: Int,
    world_buffs_crit: Int,
    bolt_dmg: Float,
    corr_dmg: Float,
    burn_dmg: Float
}

@:publicFields
class Main {

    static inline var GCD = 1.5;
    static inline var INT_TO_CRIT = 60.6;
    static inline var BASE_CRIT = 6.7;
    static inline var BOLT_COEFF = 0.8571;
    static inline var BOLT_CAST_TIME = 2.5;
    static inline var CORR_COEFF = 1.0;
    static inline var CORR_CAST_TIME = GCD;
    static inline var CORR_TICKS = 6;
    static inline var CORR_TICK_PERIOD = 3.0;
    static inline var BURN_COEFF = 0.4285;
    static inline var BURN_CAST_TIME = GCD;
    static inline var BOSS_HIT = 83;
    static inline var TRASH_HIT = 94;
    static inline var TALENT_BONUS = 1.15;
    static inline var HIT_CHANCE_MAX = 0.99;
    static inline var CRIT_CHANCE_MAX = 1.0;

    var stats = {
        int: 0,
        sp: 0,
        crit: 0,
        hit: 0,
        lock_count: 0,
        world_buffs_crit: 0,
        bolt_dmg: 481.5,
        corr_dmg: 666,
        burn_dmg: 488
    }

    var raid_boss = {
        bolts: 0,
        corrs: 0,
        corr_casts: 0,
        burns: 0,
        curses: 0,
    };
    var raid_trash = {
        bolts: 0,
        corrs: 0,
        corr_casts: 0,
        burns: 0,
        curses: 0,
    };

    var int_mod = 0.0;
    var crit_mod = 0.0;
    var sp_mod = 0.0;
    var hit_mod = 0.0;
    
    var obj: SharedObject;
    var show_notes = false;

    function new() {
        Gfx.resizescreen(1200, 960);
        GUI.set_pallete(Col.GRAY, Col.NIGHTBLUE, Col.WHITE, Col.WHITE);

        // Load saved stats
        obj = SharedObject.getLocal("stats");
        if (obj.data.stats == null) {
            obj.data.stats = stats;
            obj.flush();
        } else {
            stats = obj.data;
        }
        if (obj.data.raid_boss == null) {
            obj.data.raid_boss = raid_boss;
            obj.flush();
        } else {
            raid_boss = obj.data.raid_boss;
        }
        if (obj.data.raid_trash == null) {
            obj.data.raid_trash = raid_trash;
            obj.flush();
        } else {
            raid_trash = obj.data.raid_trash;
        }
    }

    function update() {
        Gfx.clearscreen(Col.rgb(30, 30, 30));

        // Notes
        GUI.text_button(0, 0, 'Toggle notes', function () { show_notes = !show_notes; });
        if (show_notes) {
            Text.wordwrap = 700;
            Text.display(50, 50, 'Click on numbers to edit.\nRight click on slider to reset it.\nIntellect is total amount, the number that is shown in your character stats.\nCrit is from gear only, not including the base crit or the crit obtained from int or the crit from talents.\nSpell damage values are the ones in the spell tooltip(or average if 2 values).\nLock count includes you.\nStats for other locks are assumed to be equal to yours(without slider mods).\nTake counts/hits/casts from your typical raid on warcraftlogs');
            return;
        }

        //
        // Mod sliders
        //
        GUI.x = 400;
        GUI.y = 50;
        var SLIDER_WIDTH = 700;
        GUI.auto_slider("int", function(x: Float) { int_mod = Math.round(x); }, Math.round(int_mod), -50, 50, 10, SLIDER_WIDTH, 1);
        GUI.auto_slider("sp", function(x: Float) { sp_mod = Math.round(x); }, Math.round(sp_mod), -50, 50, 10, SLIDER_WIDTH, 1);
        GUI.auto_slider("crit", function(x: Float) { crit_mod = Math.round(x); }, Math.round(crit_mod), -5, 5, 10, SLIDER_WIDTH, 1);
        GUI.auto_slider("hit", function(x: Float) { hit_mod = Math.round(x); }, Math.round(hit_mod), -5, 5, 10, SLIDER_WIDTH, 1);

        //
        // Editables
        //
        var auto_editable_x = 10;
        var auto_editable_y = 120;
        var AUTO_EDITABLE_SPACING = 30;
        function auto_editable(text: String, set_function: Dynamic->Void, current: Dynamic) {
            GUI.editable_number(auto_editable_x, auto_editable_y, text, set_function, current);
            auto_editable_y += AUTO_EDITABLE_SPACING;
        }
        function auto_heading(text: String) {
            auto_editable_y += AUTO_EDITABLE_SPACING;
            Text.display(auto_editable_x, auto_editable_y, text);
            auto_editable_y += AUTO_EDITABLE_SPACING;
        }

        auto_heading("Character stats:");
        auto_editable('int = ', function set(x) { stats.int = x; obj.data.stats.int = x; obj.flush();}, stats.int);
        auto_editable('sp = ', function set(x) { stats.sp = x; obj.data.stats.sp = x; obj.flush();}, stats.sp);
        auto_editable('crit = ', function set(x) { stats.crit = x; obj.data.stats.crit = x; obj.flush();}, stats.crit);
        auto_editable('hit = ', function set(x) { stats.hit = x; obj.data.stats.hit = x; obj.flush();}, stats.hit);

        auto_heading("Stats:");
        auto_editable('Bolt dmg = ', function set(x) { stats.bolt_dmg = x; obj.data.stats.bolt_dmg = x; obj.flush();}, stats.bolt_dmg);
        auto_editable('Corruption dmg = ', function set(x) { stats.corr_dmg = x; obj.data.stats.corr_dmg = x; obj.flush();}, stats.corr_dmg);
        auto_editable('Shadowburn dmg = ', function set(x) { stats.burn_dmg = x; obj.data.stats.burn_dmg = x; obj.flush();}, stats.burn_dmg);
        auto_editable('Lock count = ', function set(x) { stats.lock_count = x; obj.data.stats.lock_count = x; obj.flush();}, stats.lock_count);
        auto_editable('World buffs crit = ', function set(x) { stats.world_buffs_crit = x; obj.data.stats.world_buffs_crit = x; obj.flush();}, stats.world_buffs_crit);

        auto_heading("Encounters:");
        auto_editable('Bolt casts = ', function set(x) { raid_boss.bolts = x; obj.data.raid_boss.bolts = x; obj.flush();}, raid_boss.bolts);
        auto_editable('Corruption casts = ', function set(x) { raid_boss.corr_casts = x; obj.data.raid_boss.corr_casts = x; obj.flush();}, raid_boss.corr_casts);
        auto_editable('Corruption hits = ', function set(x) { raid_boss.corrs = x; obj.data.raid_boss.corrs = x; obj.flush();}, raid_boss.corrs);
        auto_editable('Burn casts = ', function set(x) { raid_boss.burns = x; obj.data.raid_boss.burns = x; obj.flush();}, raid_boss.burns);
        auto_editable('Curse casts = ', function set(x) { raid_boss.curses = x; obj.data.raid_boss.curses = x; obj.flush();}, raid_boss.curses);

        auto_heading("Trash:");
        auto_editable('Bolt casts = ', function set(x) { raid_trash.bolts = x; obj.data.raid_trash.bolts = x; obj.flush();}, raid_trash.bolts);
        auto_editable('Corruption casts = ', function set(x) { raid_trash.corr_casts = x; obj.data.raid_trash.corr_casts = x; obj.flush();}, raid_trash.corr_casts);
        auto_editable('Corruption hits = ', function set(x) { raid_trash.corrs = x; obj.data.raid_trash.corrs = x; obj.flush();}, raid_trash.corrs);
        auto_editable('Burn casts = ', function set(x) { raid_trash.burns = x; obj.data.raid_trash.burns = x; obj.flush();}, raid_trash.burns);
        auto_editable('Curse casts = ', function set(x) { raid_trash.curses = x; obj.data.raid_trash.curses = x; obj.flush();}, raid_trash.curses);

        function calc_dps(int: Float, sp: Float, crit: Float, hit: Float, is_boss: Bool) {
            var base_hit = if (is_boss) {
                BOSS_HIT;
            } else {
                TRASH_HIT;
            }
            var raid_stats = if (is_boss) {
                raid_boss;
            } else {
                raid_trash;
            }
            var level_resistance = if (is_boss) {
                24;
            } else {
                16;
            }

            var hit_chance = (base_hit + hit) / 100;
            hit_chance = Math.min(HIT_CHANCE_MAX, hit_chance);

            var crit_chance = (BASE_CRIT + crit + (stats.int / INT_TO_CRIT) + stats.world_buffs_crit) / 100;
            crit_chance = Math.min(CRIT_CHANCE_MAX, crit_chance); 

            //
            // Imp bolt bonus
            //

            // Calculate avg lock's crit chance
            var other_crit_chance = (BASE_CRIT + stats.crit + (stats.int / INT_TO_CRIT) + stats.world_buffs_crit) / 100;
            other_crit_chance = Math.min(CRIT_CHANCE_MAX, other_crit_chance);
            var other_hit_chance = (base_hit + stats.hit) / 100;
            other_hit_chance = Math.min(HIT_CHANCE_MAX, other_hit_chance);
            var other_crit_with_hit = other_crit_chance * other_hit_chance;
            other_crit_with_hit = Math.min(CRIT_CHANCE_MAX, other_crit_with_hit); 
            var crit_with_hit = crit_chance * hit_chance;
            crit_with_hit = Math.min(CRIT_CHANCE_MAX, crit_with_hit);
            var avg_crit_chance = (crit_with_hit + other_crit_chance * (stats.lock_count - 1)) / stats.lock_count;

            // Calculate imp bolt bonus
            // FORMULA EXPLANATION: get bonus if stacks > 0
            // stacks > 0 unless 4 bolts before this one failed to crit(doesn't matter whose bolts)
            // Therefore if bolts always crit, chance to miss is 0 and full 20% always applied => bonus is 1.2
            // If bolts crit 25% of the time, then chance of 4 misses is 0.75^4=0.316
            // 0.2 * (1 - 0.316) + 1 = 1.1368
            var four_miss_chance = Math.pow((1.0 - avg_crit_chance), 4);
            var imp_bolt_bonus = (1.0 - four_miss_chance) * 0.2 + 1.0;
            imp_bolt_bonus = Math.max(1.0, imp_bolt_bonus);

            // Bolt dmg
            var bolt = (stats.bolt_dmg + sp * BOLT_COEFF) * TALENT_BONUS * imp_bolt_bonus;
            // Apply crit
            bolt = bolt * (1.0 - crit_chance) + bolt * 2 * crit_chance;

            // Corruption dmg (per tick)
            var corr = (stats.corr_dmg + sp * CORR_COEFF) * TALENT_BONUS / CORR_TICKS;

            var burn = (stats.burn_dmg + sp * BURN_COEFF) * TALENT_BONUS * imp_bolt_bonus;
            // Apply crit
            burn = burn * (1.0 - crit_chance) + burn * 2 * crit_chance;

            var unmodded_hit_chance = (base_hit + stats.hit) / 100;
            unmodded_hit_chance = Math.min(HIT_CHANCE_MAX, unmodded_hit_chance);

            // Tricky hit calculations

            // Corruption/hit interaction
            // Avoided corruption misses count as additional ticks and bolt damage
            var corr_casts_without_misses = raid_stats.corr_casts / (2.0 - unmodded_hit_chance);
            var corr_casts_corrected = corr_casts_without_misses * (2.0 - hit_chance);
            var corrs_NOT_missed = raid_stats.corr_casts - corr_casts_corrected;
            var extra_corrs = corrs_NOT_missed * CORR_CAST_TIME / CORR_TICK_PERIOD;
            var extra_bolts = GCD * corrs_NOT_missed / BOLT_CAST_TIME;

            // Curse/hit interactions
            // Avoided curse misses count as additional damage from bolts
            // NOTE: technically avoided curse misses can also add corruption ticks but the bonus is small and is inconsistent for trash with few corruptions
            var curses_without_misses = raid_stats.curses / (2.0 - unmodded_hit_chance);
            var curses_corrected = curses_without_misses * (2.0 - hit_chance);
            var curses_NOT_missed = raid_stats.curses - curses_corrected;
            extra_bolts += GCD * curses_NOT_missed / BOLT_CAST_TIME;

            var total_dmg = bolt * (raid_stats.bolts + extra_bolts) * hit_chance + corr * (raid_stats.corrs + extra_corrs) + burn * raid_stats.burns * hit_chance;
            var total_time = BOLT_CAST_TIME * raid_stats.bolts + CORR_CAST_TIME * raid_stats.corrs + BURN_CAST_TIME * raid_stats.burns + raid_stats.curses * GCD;

            var dps = total_dmg / total_time;

            // Apply resistance
            // NOTE: only apply level-based resistance which is static for all mobs of that level
            // Additional resistance is too varied and in almost all cases is comletely removed with curse
            dps = dps * (1 - 0.75 * level_resistance / 300);

            return dps;
        }

        var dps_boss = calc_dps(stats.int, stats.sp, stats.crit, stats.hit, true);
        var dps_trash = calc_dps(stats.int, stats.sp, stats.crit, stats.hit, false);
        var dps = (dps_boss + dps_trash) / 2;
        var dps_modded_boss = calc_dps(stats.int + int_mod, stats.sp + sp_mod, stats.crit + crit_mod, stats.hit + hit_mod, true);
        var dps_modded_trash = calc_dps(stats.int + int_mod, stats.sp + sp_mod, stats.crit + crit_mod, stats.hit + hit_mod, false);
        var dps_modded = (dps_modded_boss + dps_modded_trash) / 2;

        //
        // Results
        //
        var results_string = '';
        results_string += '\nDefault dps: \t${Math.fixed_float(dps, 2)}';
        results_string += '\nModified dps: \t${Math.fixed_float(dps_modded, 2)}';
        Text.display(10, 30, results_string);
    }
}
