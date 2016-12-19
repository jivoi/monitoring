#!/usr/bin/env python
import argparse
import sys
import requests
import logging, coloredlogs

logger = logging.getLogger(__name__)
coloredlogs.install(level=logging.INFO)

CHECK_HOST = "127.0.0.1"
CHECK_PORT = 11180
CHECK_TIMEOUT = 15


def main():
    parser = argparse.ArgumentParser(description='EnigmaBridge keepalived test')
    parser.add_argument('--host', dest='host', default=CHECK_HOST,
                        help='Host to check')
    parser.add_argument('--port', dest='port', default=CHECK_PORT, type=int,
                        help='port to check')
    parser.add_argument('--timeout', dest='timeout', default=CHECK_TIMEOUT, type=float,
                        help='request timeout')
    args = parser.parse_args()

    host = args.host
    port = int(args.port)
    timeout = float(args.timeout)

    try:
        r = requests.get('https://%s:%d' % (host, port), timeout=timeout)
        if r.status_code != 200:
            raise ValueError('Status code error: %s' % r.status_code)

        js = r.json()
        if js is None:
            raise ValueError('Json response is empty')

        if 'status' not in js:
            raise ValueError('Status not in JSON')

        # Everything OK.
        sys.exit(0)

    except Exception as e:
        logger.info('Exception: %s' % e)
        sys.exit(1)


if __name__ == '__main__':
    main()