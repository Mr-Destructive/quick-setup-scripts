#!/bin/usr/env bash

npx degit sveltejs/template $1
cd $1
npm install

npm run dev
