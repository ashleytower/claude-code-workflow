"""
Session Registry for Claude Code Task skill.
Tracks background Claude Code sessions with labels, status, and metadata.
Registry file: ~/.openclaw/claude_sessions.json
"""

import json
import os
import time
from datetime import datetime
from typing import Optional

REGISTRY_FILE = os.path.expanduser("~/.openclaw/claude_sessions.json")


class SessionRegistry:
    def __init__(self, registry_file: Optional[str] = None):
        self.registry_file = registry_file or REGISTRY_FILE
        self._ensure_file()

    def _ensure_file(self):
        os.makedirs(os.path.dirname(self.registry_file), exist_ok=True)
        if not os.path.exists(self.registry_file):
            self._write({})

    def _read(self) -> dict:
        try:
            with open(self.registry_file, "r") as f:
                return json.load(f)
        except (json.JSONDecodeError, FileNotFoundError):
            return {}

    def _write(self, data: dict):
        with open(self.registry_file, "w") as f:
            json.dump(data, f, indent=2, default=str)

    def register(self, session_id: str, label: str = "", project: str = "",
                 metadata: Optional[dict] = None):
        """Register a new Claude Code session."""
        data = self._read()
        data[session_id] = {
            "label": label,
            "project": project,
            "status": "running",
            "created_at": datetime.now().isoformat(),
            "last_accessed": datetime.now().isoformat(),
            "metadata": metadata or {},
        }
        self._write(data)

    def update(self, session_id: str, status: Optional[str] = None,
               metadata: Optional[dict] = None):
        """Update an existing session's status and/or metadata."""
        data = self._read()
        if session_id not in data:
            return
        if status:
            data[session_id]["status"] = status
        if metadata:
            data[session_id]["metadata"].update(metadata)
        data[session_id]["last_accessed"] = datetime.now().isoformat()
        self._write(data)

    def get(self, session_id: str) -> Optional[dict]:
        """Get a session by ID."""
        data = self._read()
        return data.get(session_id)

    def recent(self, hours: int = 24) -> list:
        """List sessions from the last N hours."""
        data = self._read()
        cutoff = time.time() - (hours * 3600)
        results = []
        for sid, info in data.items():
            try:
                created = datetime.fromisoformat(info["created_at"]).timestamp()
                if created >= cutoff:
                    results.append({"id": sid, **info})
            except (KeyError, ValueError):
                continue
        return sorted(results, key=lambda x: x.get("created_at", ""), reverse=True)

    def find_by_label(self, label: str) -> list:
        """Fuzzy search sessions by label."""
        data = self._read()
        label_lower = label.lower()
        results = []
        for sid, info in data.items():
            if label_lower in info.get("label", "").lower():
                results.append({"id": sid, **info})
        return results

    def cleanup(self, days: int = 7):
        """Remove sessions older than N days."""
        data = self._read()
        cutoff = time.time() - (days * 86400)
        cleaned = {}
        for sid, info in data.items():
            try:
                created = datetime.fromisoformat(info["created_at"]).timestamp()
                if created >= cutoff:
                    cleaned[sid] = info
            except (KeyError, ValueError):
                cleaned[sid] = info
        self._write(cleaned)
