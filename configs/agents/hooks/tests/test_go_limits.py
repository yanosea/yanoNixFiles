import io
import json
import os
import subprocess
import sys
import tempfile
import unittest
import urllib.error
from contextlib import redirect_stdout
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "go-limits"))
import go_limits as go

KEY_BODY = {
    "usage": {
        "rolling": {"status": "ok", "percent": 4, "resetsAt": "2026-10-21T08:00:05Z"},
        "weekly": {
            "status": "ok",
            "percent": 65,
            "resetsAt": "2026-10-24T00:00:00+00:00",
        },
        "monthly": {
            "status": "rate-limited",
            "percent": 99,
            "resetsAt": "2026-11-11T11:31:22Z",
        },
    }
}
CONSOLE_BODY = {
    "access": {
        "endsAt": "2026-11-11T11:31:22Z",
        "meters": {
            "fiveHour": {
                "limitMicroCents": "1000",
                "usedMicroCents": "100",
                "resetsAt": "2026-10-21T08:00:05Z",
            },
            "week": {"limitMicroCents": 1000, "usedMicroCents": 900},
            "month": {"limitMicroCents": 0, "usedMicroCents": 0},
        },
    }
}
SIGNIN = [
    {
        "active": True,
        "value": {
            "type": "oauth",
            "access": "token-a",
            "metadata": {"server": "https://console.test/", "orgID": "org-1"},
        },
    }
]


class Response(io.BytesIO):
    def __enter__(self):
        return self

    def __exit__(self, *args):
        return False


def ok(body):
    return Response(json.dumps(body).encode())


def http_error(code, body=b""):
    return urllib.error.HTTPError("https://x", code, "err", {}, io.BytesIO(body))


class GoLimitsTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        env = mock.patch.dict(
            os.environ, {"XDG_CACHE_HOME": self.tmp.name, "OPENCODE_API_KEY": "key-1"}
        )
        env.start()
        self.addCleanup(env.stop)
        self.requests = []
        self.replies = {}
        urlopen = mock.patch.object(
            go.urllib.request, "urlopen", side_effect=self.urlopen
        )
        urlopen.start()
        self.addCleanup(urlopen.stop)
        self.signin = SIGNIN
        run = mock.patch.object(go.subprocess, "run", side_effect=self.run_export)
        run.start()
        self.addCleanup(run.stop)

    def urlopen(self, request, timeout):
        self.assertLessEqual(timeout, 5)
        self.requests.append(request)
        reply = self.replies[request.full_url]
        if isinstance(reply, BaseException):
            raise reply
        return reply

    def run_export(self, argv, **kwargs):
        self.assertEqual(argv, ["opencode", "auth", "export", "opencode"])
        if isinstance(self.signin, BaseException):
            raise self.signin
        return subprocess.CompletedProcess(argv, 0, json.dumps(self.signin), "")

    def export(self, entries, fetched=1000):
        path = Path(self.tmp.name) / "opencode/quota-export.json"
        path.parent.mkdir(exist_ok=True)
        path.write_text(
            json.dumps(
                {
                    "version": 2,
                    "providers": {
                        "opencode-go": {
                            "status": "ok",
                            "fetchedAt": fetched,
                            "entries": entries,
                        }
                    },
                }
            )
        )

    def main(self, *argv):
        out = io.StringIO()
        with redirect_stdout(out):
            code = go.main(list(argv))
        return code, out.getvalue().strip()

    def test_key_route(self):
        self.replies[go.KEY_URL] = ok(KEY_BODY)
        result = go.collect()
        self.assertEqual(result["source"], "key")
        self.assertEqual(
            [(w["window"], w["used"], w["status"]) for w in result["windows"]],
            [("5h", 4, "ok"), ("weekly", 65, "ok"), ("monthly", 100, "rate-limited")],
        )
        request = self.requests[0]
        self.assertEqual(request.get_header("Authorization"), "Bearer key-1")
        self.assertEqual(request.get_header("User-agent"), "opencode")

    def test_key_401_falls_back_to_console(self):
        self.replies[go.KEY_URL] = http_error(401, b"bad key-1")
        self.replies["https://console.test/api/go/status"] = ok(CONSOLE_BODY)
        result = go.collect()
        self.assertEqual(result["source"], "console")
        self.assertEqual(result["errors"], ["key: HTTP 401"])
        self.assertEqual([w["used"] for w in result["windows"]], [10, 90, 0])
        self.assertEqual(result["windows"][2]["resetAt"], 1794396682)
        request = self.requests[1]
        self.assertEqual(request.get_header("Authorization"), "Bearer token-a")
        self.assertEqual(request.get_header("X-org-id"), "org-1")

    def test_entitlement_error_is_not_subscribed(self):
        self.replies[go.KEY_URL] = http_error(
            403, b'{"type":"error","error":{"type":"EntitlementError"}}'
        )
        code, out = self.main()
        self.assertEqual(code, 2)
        self.assertIn("not subscribed", out)
        self.assertEqual(len(self.requests), 1)

    def test_console_404_is_not_subscribed(self):
        os.environ.pop("OPENCODE_API_KEY")
        self.replies["https://console.test/api/go/status"] = http_error(404)
        self.assertEqual(go.collect()["status"], "not_subscribed")

    def test_timeouts_fall_back_to_export(self):
        self.replies[go.KEY_URL] = urllib.error.URLError(TimeoutError())
        self.signin = subprocess.TimeoutExpired("opencode", 5)
        self.export(
            [
                {
                    "window": "5h",
                    "renderType": "percent",
                    "percentRemaining": 96,
                    "resetAt": 1792569605,
                },
                {"window": "Weekly", "renderType": "percent", "percentRemaining": 0},
                {"name": "Balance", "renderType": "value"},
            ]
        )
        result = go.collect(now=1000 + 600)
        self.assertEqual(result["source"], "export")
        self.assertEqual(result["age"], 600)
        self.assertEqual(
            result["errors"], ["key: timeout", "console: opencode auth export failed"]
        )
        self.assertEqual(
            [(w["window"], w["used"], w["status"]) for w in result["windows"]],
            [("5h", 4, "ok"), ("weekly", 100, "rate-limited")],
        )
        self.assertRegex(
            go.line(result),
            r"^opencode-go via export \(10m old\): 5h 4% used, resets \d\d-\d\d \d\d:\d\d; weekly 100% used RATE-LIMITED$",
        )

    def test_unknown_without_any_route(self):
        os.environ.pop("OPENCODE_API_KEY")
        self.signin = []
        code, out = self.main("--json")
        self.assertEqual(code, 2)
        self.assertEqual(
            json.loads(out)["errors"],
            [
                "key: OPENCODE_API_KEY unset",
                "console: no console sign-in",
                "export: no export",
            ],
        )

    def test_threshold_exit_codes(self):
        body = json.loads(json.dumps(KEY_BODY))
        body["usage"]["monthly"] = {
            "status": "ok",
            "percent": 36,
            "resetsAt": "2026-11-11T11:31:22Z",
        }
        for argv, code in (
            ((), 0),
            (("--threshold", "65"), 1),
            (("--threshold", "66"), 0),
        ):
            self.replies[go.KEY_URL] = ok(body)
            self.assertEqual(self.main(*argv)[0], code, argv)

    def test_no_secret_in_output(self):
        self.replies[go.KEY_URL] = http_error(500, b"echo key-1")
        self.replies["https://console.test/api/go/status"] = http_error(
            500, b"echo token-a"
        )
        _, out = self.main("--json")
        self.assertNotIn("key-1", out)
        self.assertNotIn("token-a", out)


if __name__ == "__main__":
    unittest.main()
