#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import settings
import re
import time

from mod_python import apache
from socket import socket

LINE_PATTERN = re.compile('\n')
WHITESPACE_PATTERN = re.compile('\s+')

def metrics_uri_handler(req):
    if req.method != 'POST':
        return apache.HTTP_METHOD_NOT_ALLOWED

    data = req.read().strip()
    lines = []

    for line in LINE_PATTERN.split(data):
        line = line.strip()
        fields = WHITESPACE_PATTERN.split(line)
        if len(fields) == 2:
            fields.append(str(long(time.time())))
        elif len(fields) != 3:
            return apache.HTTP_BAD_REQUEST
        lines.append(' '.join(fields))

    message = '\n'.join(lines) + '\n'

    try :
        sock = socket()
        sock.connect((settings.carbon_host, settings.carbon_port))
        sock.sendall(message)

        # echo the written data back to the client
        req.write(message)

        return apache.OK
    
    except Exception, e:
        return apache.HTTP_BAD_GATEWAY

    
def default_uri_handler(req):
    return apache.HTTP_NOT_FOUND


uri_handlers = {
    '/v1.0/metrics': metrics_uri_handler
}

def handler(req):
    req.content_type = "text/plain"
    return uri_handlers.get(req.path_info, default_uri_handler)(req)