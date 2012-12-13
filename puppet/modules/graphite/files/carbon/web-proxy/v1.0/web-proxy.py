#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import settings

from mod_python import apache
from socket import socket

def metrics_uri_handler(req):
    if req.method != 'POST':
        return apache.HTTP_METHOD_NOT_ALLOWED

    data = req.read()

    # message is normalized, removing \r, extra spaces aroudn the data and appending a final \n
    message = data.strip().replace('\r', '') + '\n'

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