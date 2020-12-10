#!/bin/bash

cat > index.html <<EOF
<h1>Hello, World<h1>
<p>DB Address: ${db_address}</p>
<p>DB port: ${db_port}</p>
EOF

nohup busybox httpd -f -p ${server_port} &

output=$(curl "http://localhost;$server_port")

if [[ $output = "Hello, World"* ]]; then
    echo "Success! Got expected text from server."
else
    echo "Error. Did not get back expected text 'Hello, World'."
fi