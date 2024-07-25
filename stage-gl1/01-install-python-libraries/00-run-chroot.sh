#!/bin/bash -e

# Set up a groundlight virtual environment for python. --system-site-packages is
# required for picamera2.
python3 -m venv /opt/groundlight/gl-py --system-site-packages
source /opt/groundlight/gl-py/bin/activate

# Now install the groundlight python libraries
pip install groundlight
# framegrab will install opencv-python, numpy, and pillow
pip install framegrab

# Install picamera2, required for use of Raspberry Pi CSI2 cameras. Note that there is
# an option to install through pip, but that is not the reccommended installation
# method. --no-install-recommends prevents installation of GUI dependencies.
sudo apt install -y python3-picamera2 --no-install-recommends

# add a .bashrc entry to activate the groundlight virtual environment
echo "source /opt/groundlight/gl-py/bin/activate" >> /home/${FIRST_USER_NAME}/.bashrc

# Make the .env dir globally writable AFTER everything's installed
chmod a+rw -R /opt/groundlight/gl-py
