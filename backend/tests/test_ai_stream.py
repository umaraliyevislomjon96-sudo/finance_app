import json

import httpx
from fastapi.testclient import TestClient

from app.api.v1 import ai_assistant as ai
from app.main import app

client = TestClient(app)


def _events(text: str):
    return [json.loads(line[5:]) for line in text.splitlines() if line.startswith("data:")]


class _FakeStream:
    def __init__(self, status=200, lines=(), exc=None):
        self.status_code, self._lines, self._exc = status, list(lines), exc

    def __enter__(self):
        if self._exc:
            raise self._exc
        return self

    def __exit__(self, *a):
        return False

    def read(self):
        return b""

    def iter_lines(self):
        yield from self._lines


def _chunk(text, thought=False):
    part = {"text": text, **({"thought": True} if thought else {})}
    return "data: " + json.dumps({"candidates": [{"content": {"parts": [part]}}]})


def test_stream_without_key_uses_local_answer(monkeypatch):
    monkeypatch.setattr(ai.settings, "GEMINI_API_KEY", "")
    r = client.post("/api/v1/ai/chat/stream", json={"message": "Привет", "language": "ru"})
    assert r.status_code == 200
    assert r.headers["content-type"].startswith("text/event-stream")
    ev = _events(r.text)
    assert ev[-1]["type"] == "done"
    assert any(e["type"] == "delta" for e in ev)


def test_stream_sends_deltas_and_skips_thoughts(monkeypatch):
    monkeypatch.setattr(ai.settings, "GEMINI_API_KEY", "k")
    monkeypatch.setattr(ai, "gather_live_facts", lambda q: [])
    monkeypatch.setattr(ai, "_gemini_models", lambda: ["m1"])
    monkeypatch.setattr(ai.httpx, "stream", lambda *a, **k: _FakeStream(lines=[_chunk("думаю", True), _chunk("Привет"), _chunk(", мир")]))
    r = client.post("/api/v1/ai/chat/stream", json={"message": "hi"})
    ev = _events(r.text)
    assert [e["text"] for e in ev if e["type"] == "delta"] == ["Привет", ", мир"]
    assert ev[-1] == {"type": "done", "model": "m1", "provider": "gemini"}


def test_stream_falls_back_when_first_model_is_silent(monkeypatch):
    monkeypatch.setattr(ai.settings, "GEMINI_API_KEY", "k")
    monkeypatch.setattr(ai, "gather_live_facts", lambda q: [])
    monkeypatch.setattr(ai, "_gemini_models", lambda: ["slow", "fast"])
    calls = []

    def fake(method, url, **kw):
        calls.append(url)
        if "slow" in url:
            return _FakeStream(exc=httpx.ReadTimeout("no first token"))
        return _FakeStream(lines=[_chunk("Ответ")])

    monkeypatch.setattr(ai.httpx, "stream", fake)
    ai._COOLDOWN_UNTIL.clear()
    ev = _events(client.post("/api/v1/ai/chat/stream", json={"message": "hi"}).text)
    assert ev[-1]["model"] == "fast"
    assert len(calls) == 2
    assert "slow" in ai._COOLDOWN_UNTIL
    ai._COOLDOWN_UNTIL.clear()


def test_stream_reports_error_when_no_model_answers(monkeypatch):
    monkeypatch.setattr(ai.settings, "GEMINI_API_KEY", "k")
    monkeypatch.setattr(ai, "gather_live_facts", lambda q: [])
    monkeypatch.setattr(ai, "_gemini_models", lambda: ["a"])
    monkeypatch.setattr(ai.httpx, "stream", lambda *a, **k: _FakeStream(status=503))
    ev = _events(client.post("/api/v1/ai/chat/stream", json={"message": "hi"}).text)
    assert ev[-1]["type"] == "error"
    ai._COOLDOWN_UNTIL.clear()
