from sys import argv


#alias "amg1" "say ඞ; alias amg amg2;"
#alias "amg2" "say amogus; alias amg amg3;"
#alias "amg3" "say амогус; alias amg amg4;"
#alias "amg4" "say amorgos; alias amg amg1;"

#alias "amg" "amg1"

if len(argv) < 2:
    print("python3 converter.py 'filename'")

if __name__ == "__main__":
    alias_name = argv[1]
    alias_counter = 0
    final_alias = ""
    with open(argv[1], "r") as f:
        for line in f:
            if "say" in line:
                if alias_counter > 0:
                    final_alias += f"; bind f10 {alias_name}{alias_counter-1}; alias {alias_name} {alias_name}{alias_counter};"
                print(final_alias)
                final_alias = f"alias \"{alias_name}{alias_counter}\" \"{line[:-1]}"
                alias_counter += 1 
        
    print(f"alias \"{alias_name}{alias_counter-1}\" \"{alias_name}0\"")
    print(f"alias \"{alias_name}\" \"{alias_name}0\"")
