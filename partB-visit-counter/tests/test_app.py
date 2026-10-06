"""Unit tests for the Visit-Counter app (no real Redis needed)."""
import sys
from pathlib import Path

import fakeredis
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "app"))
import app as visit_app  # noqa: E402


@pytest.fixture
def client(monkeypatch):
    fake = fakeredis.FakeRedis()
    monkeypatch.setattr(visit_app, "cache", fake)
    visit_app.app.config["TESTING"] = True
    with visit_app.app.test_client() as c:
        yield c


def test_counter_increments(client):
    first = client.get("/").get_data(as_text=True)
    second = client.get("/").get_data(as_text=True)
    assert "vue 1 fois" in first
    assert "vue 2 fois" in second


def test_message_contains_container_id(client, monkeypatch):
    monkeypatch.setattr(visit_app, "container_id", lambda: "abc123")
    body = client.get("/").get_data(as_text=True)
    assert "Bonjour ! Cette page a été vue" in body
    assert "Je suis le conteneur abc123" in body


def test_health(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.get_json()["status"] == "ok"


def test_redis_down_returns_503(monkeypatch):
    def boom(*_a, **_k):
        raise visit_app.redis.exceptions.ConnectionError()
    monkeypatch.setattr(visit_app, "get_hit_count", boom)
    with visit_app.app.test_client() as c:
        assert c.get("/").status_code == 503
