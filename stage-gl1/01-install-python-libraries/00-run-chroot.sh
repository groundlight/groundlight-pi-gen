#!/bin/bash -e

# set up a groundlight virtual environment for python
echo ABOUT TO SET UP VENV
python3 -m venv /opt/groundlight/gl-py
source /opt/groundlight/gl-py/bin/activate

echo RUNNING MATURIN PREP STEPS
pip install --upgrade pip setuptools
sudo apt-get update
sudo apt-get install build-essential
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env


echo INSTALLING MATURIN FIRST
pip install maturin

# Now install the groundlight python libraries
echo ABOUT TO INSTALL GROUNDLIGHT
pip install groundlight
# framegrab will install opencv-python, numpy, and pillow
echo ABOUT TO INSTALL FRAMEGRAB
pip install framegrab

# add a .bashrc entry to activate the groundlight virtual environment
echo ABOUT TO ADD VENV TO BASHRC
echo "source /opt/groundlight/gl-py/bin/activate" >> /home/${FIRST_USER_NAME}/.bashrc

# Make the .env dir globally writable AFTER everything's installed
echo MAKING ENV WRITEABLE AFTER INSTALLS
chmod a+rw -R /opt/groundlight/gl-py
