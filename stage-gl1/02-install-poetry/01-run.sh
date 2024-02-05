#!/bin/bash -e

POETRY_HOME="/opt/poetry"
POETRY_VERSION=1.7.1

curl -sSL https://install.python-poetry.org | python -

chmod a+rw -R $POETRY_HOME

echo 'export PATH=$PATH:${POETRY_HOME}/bin' >> /home/${FIRST_USER_NAME}/.bashrc


