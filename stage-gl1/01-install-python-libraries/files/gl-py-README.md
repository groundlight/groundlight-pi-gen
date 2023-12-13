# Groundlight Python Libraries
We have set up a python virtual environment (`venv`) for you to use.  To activate it, run:

```
source /opt/groundlight/gl-py/bin/activate
```

(This line is already in your .bashrc file, so you probably don't need to run it yourself.)

Some might think this is unnecessarily complicated, or not how they'd like to manage their
python systems.  We understand.  We have chosen this approach because it is the most
natural for many users, especially those who "just want to use pip thank you very much."
This attitude is extremely understandable, however modern python (3.11) and debian/ubuntu
systems have made this difficult with the "externally-managed-environment" feature
which basically prevents you from using pip without a virtual environment.

If you like `conda`, `mamba`, `poetry`, `pyenv`, or some other python environment manager, 
so do we!  Please go ahead and use them.  Hopefully this default has not gotten in your way.
If it is, please [get in touch](https://github.com/groundlight/groundlight-pi-gen/issues).

Happy visual understanding!
