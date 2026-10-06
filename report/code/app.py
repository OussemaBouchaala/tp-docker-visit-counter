"""Visit-Counter web service.

Connects to a Redis server (host name ``db-service`` by default),
increments the key ``hits`` on every visit and returns the counter
together with the ID (hostname) of the container that answered.
"""
import os
import socket
import time

import redis
from flask import Flask

app = Flask(__name__)

REDIS_HOST = os.getenv("REDIS_HOST", "db-service")
REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))

# The client is lazy: no connection is opened until the first command.
cache = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, socket_connect_timeout=2)


PAGE = """<!doctype html>
<html lang="fr"><head><meta charset="utf-8"><title>Visit-Counter</title>
<style>
 body{{font-family:Segoe UI,Arial,sans-serif;background:#f4f6f9;margin:0;
      display:flex;align-items:center;justify-content:center;height:100vh}}
 .card{{background:#fff;padding:32px 40px;border-radius:12px;
       box-shadow:0 4px 18px rgba(0,0,0,.08);max-width:640px}}
 h1{{font-size:22px;color:#1d63ed;margin:0 0 12px}}
 p{{font-size:18px;color:#222;margin:0}}
 small{{display:block;margin-top:16px;color:#777}}
</style></head><body><div class="card">
<h1>Visit-Counter (Flask + Redis)</h1>
<p>{message}</p>
<small>Redis host: {host} &middot; TP Docker</small>
</div></body></html>"""


def get_hit_count(client=None, retries=5):
    """Atomically increment and return the 'hits' counter.

    Retries a few times so that the app survives a restart of the
    Redis container (stale pooled connections / DNS not yet updated).
    """
    client = client or cache
    while True:
        try:
            return client.incr("hits")
        except redis.exceptions.ConnectionError:
            if retries == 0:
                raise
            retries -= 1
            time.sleep(0.5)


def container_id():
    """Inside Docker the hostname is the short container ID."""
    return socket.gethostname()


@app.route("/")
def index():
    try:
        count = get_hit_count()
    except redis.exceptions.ConnectionError:
        return (f"Database unavailable (redis://{REDIS_HOST}:{REDIS_PORT}). "
                f"Je suis le conteneur {container_id()}"), 503
    message = (f"Bonjour ! Cette page a été vue {count} fois. "
               f"Je suis le conteneur {container_id()}")
    return PAGE.format(message=message, host=REDIS_HOST)


@app.route("/health")
def health():
    return {"status": "ok", "container": container_id()}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("APP_PORT", "5000")))
