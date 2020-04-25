import haxegon.*;
import GUI;
import openfl.net.SharedObject;

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
    kings: Int,
    heart: Int,
}

@:publicFields
class Main {
// force unindent

static inline var INT_TO_CRIT = 60.6;
static inline var BASE_CRIT = 6.7;
static inline var BOLT_COEFF = 0.8571;
static inline var BOSS_HIT = 83;
static inline var TRASH_HIT = 94;
static inline var TALENT_BONUS = 1.15;
static inline var HIT_CHANCE_MAX = 0.99;
static inline var CRIT_CHANCE_MAX = 1.0;
static inline var KINGS_INT_BONUS = 1.15;
static inline var HEART_INT_BONUS = 1.1;

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

var trash_mods: Stats = {
    int: 0,
    sp: 0,
    crit: 0,
    hit: 0,
};

var boss_mods: Stats = {
    int: 0,
    sp: 0,
    crit: 0,
    hit: 0,
};

var vars: Vars = {
    lock_count: 5,
    world_buffs_crit: 18,
    bolt_dmg: 481.5,
    kings: 0,
    heart: 0,
}

var obj: SharedObject;
var show_notes = false;
var split_mods = true;

function new() {
    Text.size = 3;
    GUI.set_pallete(Col.GRAY, Col.NIGHTBLUE, Col.WHITE, Col.WHITE);

    // Load saved things
    obj = SharedObject.getLocal("lock-data");
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
}

function update() {
    Gfx.clearscreen(Col.rgb(30, 30, 30));

    // Notes
    GUI.text_button(0, 0, 'Toggle notes', function () { show_notes = !show_notes; });
    GUI.text_button(0, Text.height() + 20, 'Split mods: ${if (split_mods) 'ON' else 'OFF'}', function () { split_mods = !split_mods; });
    if (show_notes) {
        Text.wordwrap = 700;
        Text.display(50, 50, 'Click on numbers to edit.\nRight click on slider to reset it.\nIntellect is total amount, the number that is shown in your character stats.\nCrit is from gear only, not including the base crit or the crit obtained from int or the crit from talents.\nShadow bolt damage is base, the one in the tooltip.\nLock count includes you.\nStats for other locks are assumed to be equal to yours(without slider mods).');
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
    auto_editable('bolt dmg: ', function set(x) { vars.bolt_dmg = x; obj.data.vars.bolt_dmg = x; obj.flush();}, vars.bolt_dmg);
    auto_editable('lock count: ', function set(x) { vars.lock_count = x; obj.data.vars.lock_count = x; obj.flush();}, vars.lock_count);
    auto_editable('wbuffs crit: ', function set(x) { vars.world_buffs_crit = x; obj.data.vars.world_buffs_crit = x; obj.flush();}, vars.world_buffs_crit);
    auto_editable('kings on: ', function set(x) { vars.kings = x; obj.data.vars.kings = x; obj.flush();}, vars.kings);
    auto_editable('heart on: ', function set(x) { vars.heart = x; obj.data.vars.heart = x; obj.flush();}, vars.heart);

    auto_editable_x = boss_slider_x;
    auto_editable_y = 400;
    auto_heading("Encounter stats:");
    auto_editable('int: ', function set(x) { boss_stats.int = x; obj.data.boss_stats.int = x; obj.flush();}, boss_stats.int);
    auto_editable('sp: ', function set(x) { boss_stats.sp = x; obj.data.boss_stats.sp = x; obj.flush();}, boss_stats.sp);
    auto_editable('crit: ', function set(x) { boss_stats.crit = x; obj.data.boss_stats.crit = x; obj.flush();}, boss_stats.crit);
    auto_editable('hit: ', function set(x) { boss_stats.hit = x; obj.data.boss_stats.hit = x; obj.flush(); }, boss_stats.hit);

    auto_editable_x = trash_slider_x;
    auto_editable_y = 400;
    auto_heading("Trash stats:");
    auto_editable('int: ', function set(x) { trash_stats.int = x; obj.data.trash_stats.int = x; obj.flush();}, trash_stats.int);
    auto_editable('sp: ', function set(x) { trash_stats.sp = x; obj.data.trash_stats.sp = x; obj.flush();}, trash_stats.sp);
    auto_editable('crit: ', function set(x) { trash_stats.crit = x; obj.data.trash_stats.crit = x; obj.flush();}, trash_stats.crit);
    auto_editable('hit: ', function set(x) { trash_stats.hit = x; obj.data.trash_stats.hit = x; obj.flush();}, trash_stats.hit);

    function calc_dmg(modded: Bool, is_boss: Bool): Int {
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

        var int_bonus_from_buffs = 1.0;
        if (vars.kings == 1) {
            int_bonus_from_buffs *= KINGS_INT_BONUS;
        }
        if (vars.heart == 1) {
            int_bonus_from_buffs *= HEART_INT_BONUS;
        }
        int = Math.round(int * int_bonus_from_buffs);

        var base_hit = if (is_boss) {
            BOSS_HIT;
        } else {
            TRASH_HIT;
        }
        var level_resistance = if (is_boss) {
            24;
        } else {
            16;
        }

        var hit_chance = (base_hit + hit) / 100;
        // NOTE: hit chance is capped at 99%
        if (hit_chance > 0.99) {
            hit_chance = 0.99;
        }

        var crit_chance = (BASE_CRIT + crit + (int / INT_TO_CRIT) + vars.world_buffs_crit) / 100;
        if (crit_chance > 1.0) {
            crit_chance = 1.0;
        }

        //
        // Imp bolt bonus
        //

        // For imp bolt bonus calculation need chance of crits HITTING, not just crits at all
        var crit_with_hit = crit_chance * hit_chance;

        // Calculate avg lock's crit(with hit applied)
        // NOTE: use unmodded hit/crit values here for other lcoks
        var other_crit_chance = (BASE_CRIT + stats.crit + (int / INT_TO_CRIT) + vars.world_buffs_crit) / 100;
        if (other_crit_chance > 1.0) {
            other_crit_chance = 1.0;
        }

        var other_hit_chance = (base_hit + stats.hit) / 100;
        other_hit_chance = Math.min(HIT_CHANCE_MAX, other_hit_chance);
        if (other_hit_chance > 1.0) {
            other_hit_chance = 1.0;
        }
        
        var other_crit_with_hit = other_crit_chance * other_hit_chance;
        
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
        // Apply hit
        bolt = bolt * hit_chance;

        return Math.round(bolt);
    }

    var dmg_base_boss = calc_dmg(false, true);
    var dmg_base_trash = calc_dmg(false, false);
    var dmg_base = Math.round((dmg_base_boss + dmg_base_trash) / 2);

    var dmg_modded_boss = calc_dmg(true, true);
    var dmg_modded_trash = calc_dmg(true, false);
    var dmg_modded = Math.round((dmg_modded_boss + dmg_modded_trash) / 2);

    Text.display(10, 100, 'Bolt damage:\nbase: $dmg_base\nmodded: $dmg_modded');
}
}
