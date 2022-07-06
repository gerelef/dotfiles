from sys import argv

if len(argv) < 2:
    print("python3 converter.py 'filename'")

if __name__ == "__main__":

    for arg in argv[1:len(argv)]:
        alias_name = arg
        alias_counter = 0
        final_alias = ""
        with open(arg, "r") as f:
            for line in f:
                if "say" in line.lower():
                    if alias_counter > 0:
                        final_alias += f"; bind f10 {alias_name}{alias_counter-1}; alias {alias_name} {alias_name}{alias_counter};"
                    print(final_alias)
                    final_alias = f"alias \"{alias_name}{alias_counter}\" \"{line[:-1]}"
                    alias_counter += 1 
                    last_say = line
            print(f"alias \"{alias_name}{alias_counter-1}\" \"{last_say[0:-1]}\"; bind f10 {alias_name}{alias_counter-1}; alias {alias_name} {alias_name}0")
            print(f"alias \"{alias_name}\" \"{alias_name}0\"")
            print()
            print()
        
    print("alias \"pov\" \"map de_overpass; bind f9 REPLACE_WITH_ALIAS\"")
    print("alias \"pnu\" \"map de_nuke; bind f9 REPLACE_WITH_ALIAS\"")
    print("alias \"pmi\" \"map de_mirage; bind f9 REPLACE_WITH_ALIAS\"")
    print("alias \"pan\" \"map de_ancient; bind f9 REPLACE_WITH_ALIAS\"")
    print("alias \"pve\" \"map de_vertigo; bind f9 REPLACE_WITH_ALIAS\"")
    print("alias \"pdu\" \"map de_dust2; bind f9 REPLACE_WITH_ALIAS\"")
    print("alias \"pex\" \"exec training\"")
