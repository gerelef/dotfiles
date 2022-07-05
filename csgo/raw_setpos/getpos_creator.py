import tkinter as tk

def callback(event):

    # select text
    event.widget.select_range(0, 'end')
    # move cursor to the end
    event.widget.icursor('end')
    #stop propagation
    return 'break'

def show_entry_fields():
    x = y = 0 
    y = p = 1
    z = r = 2
    
    global OUTPUT 
    
    args = e1.get().strip().split(';')
    pos_flag = False
    angle_flag = False
    echo_str = e2.get().strip()
    util = ""
    for arg in args:
        pos_flag =  "setpos" in arg
        angle_flag = "setang" in arg 
        try:
            if pos_flag:
                truple = arg.split()
                xyz = (truple[1], truple[2], float(truple[3])-64)

            if angle_flag:
                truple = arg.split()
                ypr = (truple[1], truple[2], truple[3])
        except Exception as e:
            print("Exception caught: ", e)
            OUTPUT.set("")
            return

    if "smoke" in echo_str.lower():
        util = "use weapon_smokegrenade"
    
    if "molly" in echo_str.lower():
        util = "use weapon_incgrenade; use weapon_molotov"
    
    if "flash" in echo_str.lower():
        util = "use weapon_flashbang"
    
    if "grenade" in echo_str.lower() or "nade" in echo_str.lower():
        util = "use weapon_hegrenade"
    
    if util == "":
        OUTPUT.set("")
        return

    OUTPUT.set(f"say \"{echo_str}. {e3.get()}\"; setpos_exact {xyz[x]} {xyz[y]} {xyz[z]}; setang {ypr[0]} {ypr[p]} {ypr[r]}; {util}")

master = tk.Tk()
tk.Label(master, text="Position").grid(row=0, column=0)
tk.Label(master, text="Description").grid(row=1, column=0)
tk.Label(master, text="Type:").grid(row=2, column=0)

e1 = tk.Entry(master)
e1.bind('<Control-a>', callback)
e2 = tk.Entry(master)
e2.bind('<Control-a>', callback)
e3 = tk.Entry(master)
e3.bind('<Control-a>', callback)

OUTPUT = tk.StringVar()
OUTPUT.set("")

lbl = tk.Entry(master, textvariable=OUTPUT, fg="black", bg="white", bd=0, state="readonly").grid(row=3, column=1)
#lbl.bind('<Control-a>', callback)

e1.grid(row=0, column=1)
e2.grid(row=1, column=1)
e3.grid(row=2, column=1)

tk.Button(master, 
          text='Output', command=show_entry_fields).grid(row=4, 
                                                       column=1, 
                                                       sticky=tk.W, 
                                                       pady=4)

tk.mainloop()
