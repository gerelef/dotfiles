import tkinter as tk
from tkinter import messagebox
import pyperclip as ppc  # requires xclip on linux 

    
def paste_e1():
    global e1, e1_backup, master
    e1_backup = e1.get()
    e1.set("")
    e1.set(master.clipboard_get())

def undo_e1():
    global e1, e1_backup, master
    e1.set("")
    e1.set(e1_backup)

def paste_e2():
    global e2, e2_backup, master
    e2_backup = e2.get()
    e2.set("")
    e2.set(master.clipboard_get())

def undo_e2():
    global e2, e2_backup, master
    e2.set("")
    e2.set(e2_backup)

def paste_e3():
    global e3, e3_backup, master
    e3_backup = e3.get()
    e3.set("")
    e3.set(master.clipboard_get())

def undo_e3():
    global e3, e3_backup, master
    e3.set("")
    e3.set(e3_backup)

def copy_out_str():
    global OUTPUT
    ppc.copy(OUTPUT.get())

def show_entry_fields():
    x = y = 0 
    y = p = 1
    z = r = 2
    
    global OUTPUT 

    err_msg = None
    
    args = e1.get().strip().replace("\n", "").replace("\t", "").split(';')
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
            err_msg = "Couldn't decode getpos/clearpos"
    
    if err_msg:
        messagebox.showerror("Error", err_msg)
        return
            

    if "smoke" in echo_str.lower():
        util = "use weapon_smokegrenade"
    
    if "molly" in echo_str.lower() or "molotof" in echo_str.lower():
        util = "use weapon_incgrenade; use weapon_molotov"
    
    if "flash" in echo_str.lower() or "flashbang" in echo_str.lower():
        util = "use weapon_flashbang"
    
    if "grenade" in echo_str.lower() or "nade" in echo_str.lower():
        util = "use weapon_hegrenade"
    
    if util == "":
        OUTPUT.set("")
        err_msg = "Couldn't find utility to use!"
    
    if err_msg:
        messagebox.showerror("Error", err_msg)
        return

    OUTPUT.set(f"say \"{echo_str}. {e3.get()}\"; setpos_exact {xyz[x]} {xyz[y]} {xyz[z]}; setang {ypr[0]} {ypr[p]} {ypr[r]}; {util}")

master = tk.Tk()
tk.Label(master, text="Position:", font='TkFixedFont').grid(row=0, column=0)
tk.Label(master, text="Description:", font='TkFixedFont').grid(row=1, column=0)
tk.Label(master, text="Type:", font='TkFixedFont').grid(row=2, column=0)
tk.Label(master, text="Output:", font='TkFixedFont').grid(row=3, column=0)

e1 = tk.StringVar()
e1.set("")
e1_backup = str()
e1_lbl = tk.Entry(master, textvariable=e1, font='TkFixedFont', fg="black", bg="white", bd=0, state="readonly").grid(row=0, column=1)
tk.Button(master, text='Paste', font='TkFixedFont', command=paste_e1).grid(row=0, 
                                                       column=2, 
                                                       sticky=tk.W, 
                                                       pady=2)
tk.Button(master, text='Undo', font='TkFixedFont', command=undo_e1).grid(row=0, 
                                                       column=3, 
                                                       sticky=tk.W, 
                                                       pady=2)

e2 = tk.StringVar()
e2.set("")
e2_backup = str()
e2_lbl = tk.Entry(master, textvariable=e2, font='TkFixedFont', fg="black", bg="white", bd=0, state="readonly").grid(row=1, column=1)
tk.Button(master, text='Paste', font='TkFixedFont', command=paste_e2).grid(row=1, 
                                                       column=2, 
                                                       sticky=tk.W, 
                                                       pady=2)
tk.Button(master, text='Undo', font='TkFixedFont', command=undo_e2).grid(row=1, 
                                                       column=3, 
                                                       sticky=tk.W, 
                                                       pady=2)

e3 = tk.StringVar()
e3.set("")
e3_backup = str()
e3_lbl = tk.Entry(master, textvariable=e3, font='TkFixedFont', fg="black", bg="white", bd=0, state="readonly").grid(row=2, column=1)
tk.Button(master, text='Paste', font='TkFixedFont', command=paste_e3).grid(row=2, 
                                                       column=2, 
                                                       sticky=tk.W, 
                                                       pady=2)
tk.Button(master, text='Undo', font='TkFixedFont', command=undo_e3).grid(row=2, 
                                                       column=3, 
                                                       sticky=tk.W, 
                                                       pady=2)


OUTPUT = tk.StringVar()
OUTPUT.set("")

lbl = tk.Entry(master, textvariable=OUTPUT, fg="black", bg="white", bd=0, state="readonly").grid(row=3, column=1)

tk.Button(master, text='Copy', font='TkFixedFont', command=copy_out_str).grid(row=3, 
                                                       column=3, 
                                                       sticky=tk.W, 
                                                       pady=2)
tk.Button(master, text='Make', font='TkFixedFont', command=show_entry_fields).grid(row=3, 
                                                       column=2, 
                                                       sticky=tk.W, 
                                                       pady=2)
master.resizable(False, False)
tk.mainloop()
