"""Read-only smoke test of the project's Godot AI editor connection.

This is a development diagnostic, not a requirement for launching the game.
Open this project in the Godot editor before running it.
"""
import json
import os
import queue
import shutil
import subprocess
import threading
import time


def main():
    launcher = shutil.which("uvx") or os.path.expanduser(r"~\.local\bin\uvx.exe")
    command = [launcher, "--offline", "--isolated", "--no-config", "--no-build",
               "--from", "godot-ai==4.3.1", "godot-ai", "attach"]
    process = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE, text=True, encoding="utf-8",
                               creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
    lines = queue.Queue()

    def read_stdout():
        for line in process.stdout:
            lines.put(line)

    def drain_stderr():
        for _ in process.stderr:
            pass

    threading.Thread(target=read_stdout, daemon=True).start()
    threading.Thread(target=drain_stderr, daemon=True).start()

    def send(payload):
        process.stdin.write(json.dumps(payload) + "\n")
        process.stdin.flush()

    def receive(request_id):
        deadline = time.monotonic() + 45
        while time.monotonic() < deadline:
            if process.poll() is not None and lines.empty():
                raise RuntimeError("Godot AI bridge exited before responding")
            try:
                line = lines.get(timeout=0.3)
            except queue.Empty:
                continue
            try:
                response = json.loads(line)
            except json.JSONDecodeError:
                continue
            if response.get("id") == request_id:
                if "error" in response:
                    raise RuntimeError(str(response["error"]))
                return response["result"]
        raise TimeoutError("Godot AI editor response timed out")

    try:
        send({"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {
            "protocolVersion": "2024-11-05", "capabilities": {},
            "clientInfo": {"name": "elemental-survival-probe", "version": "1"}}})
        receive(1)
        send({"jsonrpc": "2.0", "method": "notifications/initialized"})
        send({"jsonrpc": "2.0", "id": 2, "method": "tools/call", "params": {
            "name": "editor_state", "arguments": {}}})
        result = receive(2)
        if result.get("isError"):
            raise RuntimeError(str(result))
        print(json.dumps({"mcp_connected": True, "editor_state": result.get("structuredContent", result)},
                         ensure_ascii=False, indent=2))
    finally:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()


if __name__ == "__main__":
    main()
