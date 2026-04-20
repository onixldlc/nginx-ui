#!/bin/sh

# if nginx folder is empty then copy default files
if [ -z "$(ls -A /etc/nginx)" ]; then
    echo "Copying default nginx configuration files..."
    cp -r /etc/nginx-default/* /etc/nginx/
fi

# start nginx
echo "Starting nginx..."
nginx &

# start nginx-ui
echo "Starting nginx-ui..."
/usr/local/bin/nginx-ui