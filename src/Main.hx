import haxegon.*;
import GUI;
import openfl.net.SharedObject;

using MathExtensions;

typedef RaidStats = {
    bolts: Int,
    corr_casts: Int,
    corrs: Int,
    burns: Int,
    curses: Int,
}

typedef Stats = {
    int: Int,
    sp: Int,
    crit: Int,
    hit: Int,
}

typedef Vars = {
    lock_count: Int,
    world_buffs_crit: Int,
    bolt_dmg: Float,
    corr_dmg: Float,
    burn_dmg: Float
}

@:publicFields
class Main {
// force unindent

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

var trash_stats: Stats = {
    int: 300,
    sp: 790,
    crit: 1,
    hit: 0,
}

var boss_stats: Stats = {
    int: 300,
    sp: 790,
    crit: 1,
    hit: 0,
}

var vars: Vars = {
    lock_count: 5,
    world_buffs_crit: 18,
    bolt_dmg: 481.5,
    corr_dmg: 666.0,
    burn_dmg: 488.0
}

var raid_boss: RaidStats = {
    bolts: 99,
    corr_casts: 19,
    corrs: 90,
    burns: 10,
    curses: 11,
};
var raid_trash: RaidStats = {
    bolts: 121,
    corr_casts: 34,
    corrs: 163,
    burns: 42,
    curses: 74,
};

var boss_mods: Stats = {
    int: 0,
    sp: 0,
    crit: 0,
    hit: 0,
};

var trash_mods: Stats = {
    int: 0,
    sp: 0,
    crit: 0,
    hit: 0,
};

var obj: SharedObject;
var show_notes = false;
var split_mods = true;

function new() {
    Text.size = 3;
    GUI.set_pallete(Col.GRAY, Col.NIGHTBLUE, Col.WHITE, Col.WHITE);

    // Load saved things
    obj = SharedObject.getLocal("lock-sim-data");
    if (obj.data.vars == null) {
        obj.data.vars = vars;
        obj.flush();
    } else {
        vars = obj.data.vars;
    }
    if (obj.data.boss_stats == null) {
        obj.data.boss_stats = boss_stats;
        obj.flush();
    } else {
        boss_stats = obj.data.boss_stats;
    }
    if (obj.data.trash_stats == null) {
        obj.data.trash_stats = trash_stats;
        obj.flush();
    } else {
        trash_stats = obj.data.trash_stats;
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
    GUI.text_button(0, Text.height() + 20, 'Split mods: ${if (split_mods) 'ON' else 'OFF'}', function () { split_mods = !split_mods; });
    if (show_notes) {
        Text.wordwrap = 700;
        Text.display(50, 50, 'Click on numbers to edit.\nRight click on slider to reset it.\nIntellect is total amount, the number that is shown in your character stats.\nCrit is from gear only, not including the base crit or the crit obtained from int or the crit from talents.\nSpell damage values are the ones in the spell tooltip(or average if 2 values).\nLock count includes you.\nStats for other locks are assumed to be equal to yours(without slider mods).\nTake counts/hits/casts from your typical raid on warcraftlogs.');
        return;
    }

    //
    // Mod sliders
    //
    GUI.x = 370;
    GUI.y = 10;
    var SLIDER_WIDTH = 500;
    var HANDLE_WIDTH = 15;
    var trash_slider_x = GUI.x;
    if (split_mods) {
        Text.display(GUI.x, GUI.y, 'TRASH');
    }
    GUI.auto_slider("int", function(x: Float) { trash_mods.int = Math.round(x); }, Math.round(trash_mods.int), -50, 50, HANDLE_WIDTH, SLIDER_WIDTH, 1);
    GUI.auto_slider("sp", function(x: Float) { trash_mods.sp = Math.round(x); }, Math.round(trash_mods.sp), -50, 50, HANDLE_WIDTH, SLIDER_WIDTH, 1);
    GUI.auto_slider("crit", function(x: Float) { trash_mods.crit = Math.round(x); }, Math.round(trash_mods.crit), -5, 5, HANDLE_WIDTH, SLIDER_WIDTH, 1);
    GUI.auto_slider("hit", function(x: Float) { trash_mods.hit = Math.round(x); }, Math.round(trash_mods.hit), -5, 5, HANDLE_WIDTH, SLIDER_WIDTH, 1);

    GUI.x = 370 + SLIDER_WIDTH + 80;
    GUI.y = 10;
    var boss_slider_x = GUI.x;
    if (split_mods) {
        Text.display(GUI.x, GUI.y, 'BOSS');
        GUI.auto_slider("int", function(x: Float) { boss_mods.int = Math.round(x); }, Math.round(boss_mods.int), -50, 50, HANDLE_WIDTH, SLIDER_WIDTH, 1);
        GUI.auto_slider("sp", function(x: Float) { boss_mods.sp = Math.round(x); }, Math.round(boss_mods.sp), -50, 50, HANDLE_WIDTH, SLIDER_WIDTH, 1);
        GUI.auto_slider("crit", function(x: Float) { boss_mods.crit = Math.round(x); }, Math.round(boss_mods.crit), -5, 5, HANDLE_WIDTH, SLIDER_WIDTH, 1);
        GUI.auto_slider("hit", function(x: Float) { boss_mods.hit = Math.round(x); }, Math.round(boss_mods.hit), -5, 5, HANDLE_WIDTH, SLIDER_WIDTH, 1);
    }

    if (!split_mods) {
        boss_mods.int = trash_mods.int;
        boss_mods.sp = trash_mods.sp;
        boss_mods.crit = trash_mods.crit;
        boss_mods.hit = trash_mods.hit;
    }

    //
    // Editables
    //
    var auto_editable_x = 10.0;
    var auto_editable_y = 120.0;
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

    auto_editable_y += 350;
    auto_editable('bolt dmg = ', function set(x) { vars.bolt_dmg = x; obj.data.vars.bolt_dmg = x; obj.flush();}, vars.bolt_dmg);
    auto_editable('corr dmg = ', function set(x) { vars.corr_dmg = x; obj.data.vars.corr_dmg = x; obj.flush();}, vars.corr_dmg);
    auto_editable('burn dmg = ', function set(x) { vars.burn_dmg = x; obj.data.vars.burn_dmg = x; obj.flush();}, vars.burn_dmg);
    auto_editable('lock count = ', function set(x) { vars.lock_count = x; obj.data.vars.lock_count = x; obj.flush();}, vars.lock_count);
    auto_editable('wbuffs crit = ', function set(x) { vars.world_buffs_crit = x; obj.data.vars.world_buffs_crit = x; obj.flush();}, vars.world_buffs_crit);

    auto_editable_x = boss_slider_x;
    auto_editable_y = 400;
    auto_heading("Encounter stats:");
    auto_editable('int = ', function set(x) { boss_stats.int = x; obj.data.boss_stats.int = x; obj.flush();}, boss_stats.int);
    auto_editable('sp = ', function set(x) { boss_stats.sp = x; obj.data.boss_stats.sp = x; obj.flush();}, boss_stats.sp);
    auto_editable('crit = ', function set(x) { boss_stats.crit = x; obj.data.boss_stats.crit = x; obj.flush();}, boss_stats.crit);
    auto_editable('hit = ', function set(x) { boss_stats.hit = x; obj.data.boss_stats.hit = x; obj.flush(); }, boss_stats.hit);

    auto_heading("Encounters:");
    auto_editable('bolt casts = ', function set(x) { raid_boss.bolts = x; obj.data.raid_boss.bolts = x; obj.flush();}, raid_boss.bolts);
    auto_editable('corr casts = ', function set(x) { raid_boss.corr_casts = x; obj.data.raid_boss.corr_casts = x; obj.flush();}, raid_boss.corr_casts);
    auto_editable('corr hits = ', function set(x) { raid_boss.corrs = x; obj.data.raid_boss.corrs = x; obj.flush();}, raid_boss.corrs);
    auto_editable('burn casts = ', function set(x) { raid_boss.burns = x; obj.data.raid_boss.burns = x; obj.flush();}, raid_boss.burns);
    auto_editable('curse casts = ', function set(x) { raid_boss.curses = x; obj.data.raid_boss.curses = x; obj.flush();}, raid_boss.curses);

    auto_editable_x = trash_slider_x;
    auto_editable_y = 400;
    auto_heading("Trash stats:");
    auto_editable('int = ', function set(x) { trash_stats.int = x; obj.data.trash_stats.int = x; obj.flush();}, trash_stats.int);
    auto_editable('sp = ', function set(x) { trash_stats.sp = x; obj.data.trash_stats.sp = x; obj.flush();}, trash_stats.sp);
    auto_editable('crit = ', function set(x) { trash_stats.crit = x; obj.data.trash_stats.crit = x; obj.flush();}, trash_stats.crit);
    auto_editable('hit = ', function set(x) { trash_stats.hit = x; obj.data.trash_stats.hit = x; obj.flush();}, trash_stats.hit);

    auto_heading("Trash:");
    auto_editable('bolt casts = ', function set(x) { raid_trash.bolts = x; obj.data.raid_trash.bolts = x; obj.flush();}, raid_trash.bolts);
    auto_editable('corr casts = ', function set(x) { raid_trash.corr_casts = x; obj.data.raid_trash.corr_casts = x; obj.flush();}, raid_trash.corr_casts);
    auto_editable('corr hits = ', function set(x) { raid_trash.corrs = x; obj.data.raid_trash.corrs = x; obj.flush();}, raid_trash.corrs);
    auto_editable('burn casts = ', function set(x) { raid_trash.burns = x; obj.data.raid_trash.burns = x; obj.flush();}, raid_trash.burns);
    auto_editable('curse casts = ', function set(x) { raid_trash.curses = x; obj.data.raid_trash.curses = x; obj.flush();}, raid_trash.curses);

    function calc_dps(modded: Bool, is_boss: Bool) {
        var stats = if (is_boss) {
            boss_stats;
        } else {
            trash_stats;
        }
        var mods = if (is_boss) {
            boss_mods;
        } else {
            trash_mods;
        }

        var int = stats.int;
        var sp = stats.sp;
        var crit = stats.crit;
        var hit = stats.hit;
        if (modded) {
            int += mods.int;
            sp += mods.sp;
            crit += mods.crit;
            hit += mods.hit;
        }

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

        var crit_chance = (BASE_CRIT + crit + (int / INT_TO_CRIT) + vars.world_buffs_crit) / 100;
        crit_chance = Math.min(CRIT_CHANCE_MAX, crit_chance); 

        var crit_with_hit = crit_chance * hit_chance;
        crit_with_hit = Math.min(CRIT_CHANCE_MAX, crit_with_hit);

        //
        // Imp bolt bonus
        //

        // Calculate avg lock's crit(with hit applied)
        // NOTE: use unmodded hit/crit values here
        var other_crit_chance = (BASE_CRIT + stats.crit + (int / INT_TO_CRIT) + vars.world_buffs_crit) / 100;
        other_crit_chance = Math.min(CRIT_CHANCE_MAX, other_crit_chance);

        var other_hit_chance = (base_hit + stats.hit) / 100;
        other_hit_chance = Math.min(HIT_CHANCE_MAX, other_hit_chance);
        
        var other_crit_with_hit = other_crit_chance * other_hit_chance;
        other_crit_with_hit = Math.min(CRIT_CHANCE_MAX, other_crit_with_hit); 
        
        var avg_crit_with_hit = (crit_with_hit + other_crit_with_hit * (vars.lock_count - 1)) / vars.lock_count;

        // Calculate imp bolt bonus
        // FORMULA EXPLANATION: get bonus if stacks > 0
        // stacks > 0 unless 4 bolts before this one failed to crit(doesn't matter whose bolts)
        // Therefore if bolts always crit, chance to miss is 0 and full 20% always applied => bonus is 1.2
        // If bolts crit 25% of the time, then chance of 4 misses is 0.75^4=0.316
        // 0.2 * (1 - 0.316) + 1 = 1.1368
        var four_miss_chance = Math.pow((1.0 - avg_crit_with_hit), 4);
        var imp_bolt_bonus = (1.0 - four_miss_chance) * 0.2 + 1.0;
        imp_bolt_bonus = Math.max(1.0, imp_bolt_bonus);

        // Bolt dmg
        var bolt = (vars.bolt_dmg + sp * BOLT_COEFF) * TALENT_BONUS * imp_bolt_bonus;
        // Apply crit
        bolt = bolt * (1.0 - crit_chance) + bolt * 2 * crit_chance;

        // Corruption dmg (per tick)
        var corr = (vars.corr_dmg + sp * CORR_COEFF) * TALENT_BONUS / CORR_TICKS;

        var burn = (vars.burn_dmg + sp * BURN_COEFF) * TALENT_BONUS * imp_bolt_bonus;
        // Apply crit
        burn = burn * (1.0 - crit_chance) + burn * 2 * crit_chance;

        var unmodded_hit_chance = (base_hit + stats.hit) / 100;
        unmodded_hit_chance = Math.min(HIT_CHANCE_MAX, unmodded_hit_chance);

        // Tricky hit calculations ahead

        // Corruption/hit interaction
        // Avoided corruption misses count as additional ticks and bolt damage
        var corr_casts_without_misses = raid_stats.corr_casts / (2.0 - unmodded_hit_chance);
        var corr_casts_corrected = corr_casts_without_misses * (2.0 - hit_chance);
        var corrs_NOT_missed = raid_stats.corr_casts - corr_casts_corrected;
        var extra_corrs = corrs_NOT_missed * CORR_CAST_TIME / CORR_TICK_PERIOD;
        var extra_bolts = GCD * corrs_NOT_missed / BOLT_CAST_TIME;

        // Curse/hit interactions
        // Avoided curse misses count as additional damage from bolts
        // NOTE: technically avoided curse misses can also add corruption ticks but the effect is minor because the majority of curses are cast on trash where few corruptions are used
        var curses_without_misses = raid_stats.curses / (2.0 - unmodded_hit_chance);
        var curses_corrected = curses_without_misses * (2.0 - hit_chance);
        var curses_NOT_missed = raid_stats.curses - curses_corrected;
        extra_bolts += GCD * curses_NOT_missed / BOLT_CAST_TIME;

        var total_dmg = bolt * (raid_stats.bolts + extra_bolts) * hit_chance + corr * (raid_stats.corrs + extra_corrs) + burn * raid_stats.burns * hit_chance;
        var total_time = BOLT_CAST_TIME * raid_stats.bolts + CORR_CAST_TIME * raid_stats.corrs + BURN_CAST_TIME * raid_stats.burns + raid_stats.curses * GCD;

        var dps = total_dmg / total_time;

        // Apply resistance
        // NOTE: only apply level-based resistance which is static for all mobs of that level
        // Additional resistance is too varied and is almost always completely negated by
        dps = dps * (1 - 0.75 * level_resistance / 300);

        return dps;
    }

    var dps_boss = calc_dps(false, true);
    var dps_trash = calc_dps(false, false);
    var dps = (dps_boss + dps_trash) / 2;

    var dps_modded_boss = calc_dps(true, true);
    var dps_modded_trash = calc_dps(true, false);
    var dps_modded = (dps_modded_boss + dps_modded_trash) / 2;

    //
    // Results
    //
    var results_string = 'DPS:';
    results_string += '\ndefault: ${Math.fixed_float(dps, 2)}';
    results_string += '\nmodded: ${Math.fixed_float(dps_modded, 2)}';
    Text.display(10, 100, results_string);
}
}
