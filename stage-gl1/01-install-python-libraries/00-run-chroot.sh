#!/bin/bash -e

# set up a groundlight virtual environment for python
python3 -m venv /opt/groundlight/gl-py
chmod a+rw -R /opt/groundlight/gl-py
source /opt/groundlight/gl-py/bin/activate

# Now install the groundlight python libraries
pip install groundlight
# framegrab will install opencv-python, numpy, and pillow
pip install framegrab

# add a .bashrc entry to activate the groundlight virtual environment
echo "source /opt/groundlight/gl-py/bin/activate" >> /home/${FIRST_USER_NAME}/.bashrc
