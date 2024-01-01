## utils
Utility scripts, meant to make life easier. In detail, by descending order of complexity:
- `update_utils.py`
    - utility python library for update scripts; various functions, primary one being the `Manager` class, 
    which implements basic common functions all of my update scripts need. 
    Everything else is *not* meant to be used by implementees, however they may do so, accepting that it needs caution.
    Particularly proud of this, and it's implementees!
- `update-compat-layers.py`
    - utility script meant to install all compatibility layers; plans to reach feature parity with `protonup-qt`, but not necessarily;
    see `update-compat-layers.py --help` for more. Appropriate compgen function should be in `.bashrc`, and if it isn't, it's being worked on.
    Based on `update_utils.py`.
- `update-ff-theme.py`
    - utility script meant to install a few popular, actively maintained firefox themes; 
    see `update-ff-theme.py --help` for more. Appropriate compgen function should be in `.bashrc`, and if it isn't, it's being worked on.
    Based on `update_utils.py`.
- `lss.py`
    - `ls` adjacent-"replacement" of choice; it's not really an `ls` replacement, it's just a greedy `ls -la` display essentially, 
    meant to maximize available terminal lines/cols usage when possible, instead of forcing you to scroll, or wrapping text around. 
- `*.sh` files
    - dependencies for `../.bashrc`, various functions; see src of each one to understand; names should be self explanatory
