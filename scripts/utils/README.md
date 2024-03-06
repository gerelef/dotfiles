## utils
Utility scripts, meant to make life easier. In detail, by descending order of complexity:
- `sela`
    - utility python library for update scripts; various functions, primary one being the `Manager` class, 
    which implements basic common functions all of my update scripts need.
    Particularly proud of this, and it's implementees!
- `update-compat-layers.py`
    - utility script meant to install all compatibility layers; plans to reach feature parity with `protonup-qt`, but not necessarily;
    see `update-compat-layers.py --help` for more. Appropriate compgen function should be in `.bashrc`, and if it isn't, it's being worked on.
    Based on `sela`.
- `update-ff-theme.py`
    - utility script meant to install a few popular, actively maintained firefox themes; 
    see `update-ff-theme.py --help` for more. Appropriate compgen function should be in `.bashrc`, and if it isn't, it's being worked on.
    Based on `sela`.

## Historical note
A massive trim was done on 28/2/2024. 
You may find functions/utilities that were removed, here: `fbc1fa8`.