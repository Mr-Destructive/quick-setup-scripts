#!/usr/bin/env bash

mkdir $1
cd $1
pip install virtualenv
virtualenv venv
source venv/Scripts/activate

pip install fastapi uvicorn
pip freeze >requirements.txt

cat << EOF >> main.py
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
async def root():
    return {"message": "Hello World"}
EOF

uvicorn main:app --reload
