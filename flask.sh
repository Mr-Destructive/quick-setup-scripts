#!/usr/bin/env bash

mkdir $1
cd $1
pip install virtualenv
virtualenv venv
source venv/bin/activate.sh

pip install flask
pip freeze >requirements.txt

cat << EOF >> app.py
from flask import Flask 

app = Flask(__name__)

if __name__ == "__main__":
    app.run()
EOF

export FLASK_APP=app

mkdir templates static

