from scripts.config import BuildConfig
from scripts.docker import ensure_image
from scripts.docker import run   as _run
from scripts.docker import shell as _shell
from scripts.targets import BASE_IMAGE


class DockerRunner:
    """Runs commands in the target's docker image, ensuring base + target
    images exist first."""

    def __init__(self, cfg: BuildConfig) -> None:
        self.cfg = cfg
        ensure_image(BASE_IMAGE["image"], BASE_IMAGE["dockerfile"])
        ensure_image(cfg.image,           cfg.dockerfile)

    def run(self, cmd: list[str], *, env: dict[str, str] | None = None) -> None:
        _run(self.cfg.image, cmd, env=env)

    def shell(self) -> None:
        _shell(self.cfg.image)
