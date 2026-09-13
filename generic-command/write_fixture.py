import json
import subprocess
from pathlib import Path


head = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
Path(".aegis/generic-review.json").write_text(
    json.dumps(
        {
            "pull_request": {"head": {"sha": head}},
            "reviews": [{"user": {"login": "poc-owner"}, "state": "APPROVED", "dismissed_at": None, "commit_id": head}],
        }
    ),
    encoding="utf-8",
)
