import os
import sys
from sys import argv
from typing import List, Tuple
import os.path as osp

if len(argv) < 2:
    print("python3 converter.py 'filename.lineup'")

TOGGLE_KEY = "f8"
REPEAT_KEY = "f7"
NEXT_KEY = "f6"
PREV_KEY = "f5"

ALIAS_POSTFIX = "_util"
REVERSE_POSTFIX = "_rev"

identifier_limiter = r"// ------------------------ AUTO-GENERATED LIMITER ------------------------ //"
training_extra = fr"""alias "showspawns" "map_showspawnpoints 15"
alias "+toggleables" "showspawns; toggle mp_radar_showall;toggle cl_showpos;toggle sv_autobunnyhopping;toggle sv_showimpacts;toggle cl_grenadepreview; toggle mp_drop_knife_enable; toggle sv_regeneration_force_on"
alias "-toggleables ""
alias "+fastforward" "host_timescale 15"
alias "-fastforward" "host_timescale 1"

bind "," "sv_rethrow_last_grenade"
bind "." "bot_place"
bind "/" "toggle bot_crouch"
bind "l" "radio"
bind ";" "radio1"
bind "'" "+fastforward"
bind "mouse3" "toggle bot_mimic; cast_ray"
bind "{TOGGLE_KEY}" "say_team SHOWING SPAWNS & TOGGLING: mp_radar_showall cl_showpos sv_autobunnyhopping sv_showimpacts cl_grenadepreview mp_drop_knife_enable;+toggleables"


//training cfg
say "COMMANDS: Check commands in console, toggle helper settings with '{TOGGLE_KEY}'"
bot_kick;
sv_cheats 1; 

cl_grenadepreview 0;
sv_showimpacts 0; 
sv_autobunnyhopping 0;
cl_showpos 0;
mp_radar_showall 0;
sv_regeneration_force_on 0;

mp_ignore_round_win_conditions 1;
mp_drop_knife_enable 0; // for switching knives
weapon_accuracy_nospread "0"; //stops running acc too.. fml
mp_items_prohibited 0;
mp_anyone_can_pickup_c4 1;

bot_stop 1;
bot_add_ct;
bot_add_t;
bot_loadout ak47 m4a1 deagle;
bot_allow_grenades 0;
bot_allow_machine_guns 0;
bot_allow_pistols 0;
bot_allow_rifles 1;
bot_allow_shotguns 0;
bot_allow_snipers 0;
bot_allow_sub_machine_guns 0;
bot_ignore_players 1;
bot_zombie 1;
bot_mimic_yaw_offset 360;

mp_warmuptime 99999999; 
mp_c4timer 3600
mp_roundtime 60
mp_roundtime_defuse 60; 
mp_hostages_rescuetime 600;
mp_freezetime 0;
mp_warmup_start; 

mp_autokick 0;
mp_limitteams 0; 
mp_autoteambalance 0;
mp_respawn_on_death_ct 1;
mp_respawn_on_death_t 1;
mp_respawnwavetime_t 0;
mp_respawnwavetime_ct 0;

mp_weapons_allow_typecount 500;
ammo_grenade_limit_total 100; 
ammo_grenade_limit_flashbang 1;

sv_grenade_trajectory 1; 
sv_showimpacts_time 5;
sv_infinite_ammo 2; 

mp_buy_anywhere 1;
mp_buytime 999999; 
mp_maxmoney 50000; 
mp_startmoney 50000; 
mp_warmup_end;
mp_restartgame 1;

buddha; // this will toggle no-death forever, to avoid running god or gods every time"""

controls = r"""
echo +------------+-----------------+
echo | F5         | Previous Lineup |
echo | F6         | Next Lineup     |
echo | F7         | Repeat Lineup   |
echo | F8         | Toggle Helpers  |
echo | L          | Radio  (modded) |
echo | Colon(;)   | Radio1 (modded) |
echo | Apostrophe | Fast Forward    |
echo | Comma (,)  | Rethrow grenade |
echo | Dot   (.)  | Place bot       |
echo | Slash (/)  | Crouch bot      |
echo | Mouse3(m3) | Mimic bot       |
echo +------------+-----------------+
"""


def open_file_and_keep_old(fname, fexisted) -> List[str]:
    lines = []
    if not fexisted:
        return []

    with open(fname, "r+") as f:
        delete = False
        for l in f:
            l = l.rstrip('\r\n').strip()
            if l == identifier_limiter:
                delete = not delete
                continue
            if delete or l == "":
                continue
            lines.append(l)

        if delete:
            print("Catastrophic failure: didn't find second autogenerated limiter. Stopping to prevent data loss!")
            exit(0)

    return lines


# noinspection PyMethodOverriding
class Lineup:
    def __init__(self, data, extra: str = ""):
        self.data = data
        self.extra = extra

    def to_str(self, rname, index, max_c: int, is_last=False, reverse=False, pure=False) -> str:
        this_lineup = f"{rname}{REVERSE_POSTFIX if reverse else str()}{index}"
        if pure:
            return this_lineup
        next_lineup = f"{rname}{REVERSE_POSTFIX if reverse else str()}{index + 1}"

        if is_last and reverse:
            if index == 0:
                next_lineup = f"{rname}{REVERSE_POSTFIX if reverse else str()}{index+1}"
            else:
                next_lineup = f"{rname}{REVERSE_POSTFIX if reverse else str()}0"

        if is_last and not reverse:
            next_lineup = f"{rname}{REVERSE_POSTFIX if reverse else str()}0"

        return f"{self.data}; bind {REPEAT_KEY} {this_lineup}; alias {rname}{REVERSE_POSTFIX if reverse else str()} {next_lineup};{self.extra}"


# noinspection PyMethodOverriding
class RootLineup:
    def __init__(self, rname):
        self.rname = rname

    def to_str(self, reverse=False, pure=False):
        if pure:
            return f"\"{self.rname}{REVERSE_POSTFIX if reverse else str()}{0}\""
        return f"alias \"{self.rname}{REVERSE_POSTFIX if reverse else str()}\" \"{self.rname}{REVERSE_POSTFIX if reverse else str()}{0}\""

    def str_plain(self, reverse):
        return f"{self.rname}{REVERSE_POSTFIX if reverse else str()}"


class Map:
    def __init__(self, mapname: str, lineups: List[Lineup] = None):
        if lineups is None:
            lineups = []
        self.mapname = mapname
        self.rname = mapname + ALIAS_POSTFIX
        self.root = RootLineup(self.rname)
        self.lineups: List[Lineup] = lineups

    def add_lineup(self, *args):
        for arg in args:
            self.lineups.append(arg)

    def output_lineups(self, output, reverse):
        max_c = len(self.lineups) - 1
        if reverse:
            for c, lineup in enumerate(self.lineups):
                is_last = max_c == c
                is_last_rev = c == 0 or is_last
                print(
                    f"alias \"{lineup.to_str(self.rname, abs(c - max_c), max_c, is_last_rev, reverse=True, pure=True)}\" \"{lineup.to_str(self.rname, abs(c - max_c), max_c, is_last_rev, reverse=True)} alias {self.root.str_plain(reverse=False)} {lineup.to_str(self.rname, c, max_c, is_last, reverse=False, pure=True)}",
                    file=output)
            print(self.root.to_str(reverse=True), file=output)
            return

        for c, lineup in enumerate(self.lineups):
            is_last = max_c == c
            print(
                f"alias \"{lineup.to_str(self.rname, c, max_c, is_last, pure=True)}\" \"{lineup.to_str(self.rname, c, max_c, is_last, reverse=False)} alias {self.root.str_plain(reverse=True)} {lineup.to_str(self.rname, abs(c - max_c), max_c, is_last, reverse=True, pure=True)}",
                file=output)
        print(self.root.to_str(), file=output)

    def get_shorthand_prac_bind(self, output):
        if self.lineups:
            print(
                f"alias \"p{self.mapname[3:5]}\" \"game_type 0; game_mode 1; map {self.mapname}; bind {NEXT_KEY} {self.root.str_plain(reverse=False)}; bind {PREV_KEY} {self.root.str_plain(reverse=True)}\"",
                file=output)
            return
        print(
            f"alias \"p{self.mapname[3:5]}\" \"echo \"Found no binds for {self.mapname}! Is everything alright?\"; say_team \"Found no binds for {self.mapname}! Is everything alright?\"",
            file=output)


def sanitize_names(args) -> List:
    mnames = []

    for arg in args:
        mnames.append((arg.split('.')[0]).split(os.path.sep)[-1])

    return mnames


if __name__ == "__main__":
    raw_files = argv[1:]
    map_names = sanitize_names(raw_files)
    map_lineups: List[Map] = []

    for count, fraw_name in enumerate(raw_files):
        map_lineups.append(Map(map_names[count]))

        ac = 0  # alias counter (lineup index)
        with open(fraw_name, "r") as fraw:
            for line in fraw:
                if "say" in line.lower():
                    line = line.rstrip('\r\n').strip()
                    map_lineups[count].add_lineup(Lineup(line))
                    ac += 1

    filename = "training.cfg"
    file_existed = osp.exists(filename)

    old_lines = open_file_and_keep_old(filename, file_existed)

    with open(filename, "w") as cfg:
        cfg.write(identifier_limiter + '\n')
        cfg.write("// DO NOT TOUCH ANYTHING IN BETWEEN THE LIMITERS (LIMITERS INCLUDED)\n")
        cfg.write("// ------------------------------ LINEUPS --------------------------------- //\n")
        for mp in map_lineups:
            mp.output_lineups(cfg, False)
            mp.output_lineups(cfg, True)
        cfg.write("// ------------------------------ LINEUPS  ------------------------------ //\n")
        cfg.write("// ------------------------------ TRAINING ------------------------------ //\n")
        cfg.write(training_extra + '\n')
        cfg.write("clear\n")
        cfg.write("// ------------------------------ TRAINING ------------------------------ //\n")
        cfg.write(controls)
        cfg.write("// ADD YOUR OWN DATA BELOW THE AUTO-GENERATED LIMITER\n")
        cfg.write(identifier_limiter + '\n')
        for extra_line in old_lines:
            cfg.write(extra_line + "\n")
    print("Add this to your autoexec\n")
    for mp in map_lineups:
        mp.get_shorthand_prac_bind(sys.stdout)
    print("alias \"pex\" \"exec training\"", file=sys.stdout)
    print("alias \"pre\" \"mp_restartgame 1\"", file=sys.stdout)
