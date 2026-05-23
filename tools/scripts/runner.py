import platform
import subprocess
import os

class NativeRunner:
    """Executes commands directly on the host machine."""
    def run(self, cmd, env=None):
        # Merge host env with tool-provided env
        full_env = {**os.environ, **(env or {})}
        subprocess.run(cmd, env=full_env, check=True)

class DockerRunner:
    """Existing Docker-based runner."""
    # ... your existing Docker logic ...

def get_runner(cfg):
    """Factory that returns the appropriate runner."""
    if platform.system() == "Darwin":
        return NativeRunner()
    return DockerRunner(cfg)
