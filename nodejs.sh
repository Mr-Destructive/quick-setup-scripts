#!/usr/bin/env bash

mkdir $1
cd $1

npm init --yes

cat << EOF >> index.js
const http = require('http');
const port = 3000

const server = http.createServer((request, response) => {
    response.statusCode = 200;
    response.setHeader("Content-Type", "text/plain");
    response.write("Hello World");
    response.end();
});

server.listen(port, ()=> {
  console.log("The server is running on port : ",port);
});
EOF

#node $1/index.js
