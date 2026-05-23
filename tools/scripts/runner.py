import platform
import subprocess
from scripts.config import BuildConfig
from scripts.docker import ensure_image
from scripts.docker import run   as _run
from scripts.docker import shell as _shell
from scripts.targets import BASE_IMAGE

class DockerRunner:
    """Runs commands in the target's docker image, or natively on host if on macOS."""

    def __init__(self, cfg: BuildConfig) -> None:
        self.cfg = cfg
        self.use_docker = platform.system() != "Darwin"

        if self.use_docker:
            ensure_image(BASE_IMAGE["image"], BASE_IMAGE["dockerfile"])
            ensure_image(cfg.image,           cfg.dockerfile)

    def run(self, cmd: list[str], *, env: dict[str, str] | None = None) -> None:
        if self.use_docker:
            _run(self.cfg.image, cmd, env=env)
        else:
            # Run natively on macOS
            subprocess.run(cmd, env=env, check=True)

    def shell(self) -> None:
        if self.use_docker:
            _shell(self.cfg.image)
        else:
            print("Native macOS environment — no shell to enter.")
