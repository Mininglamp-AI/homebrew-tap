class Octoasr < Formula
  CIDER_VERSION = "0.8.0.post1"

  desc "Local speech-to-text service powered by MLX, optimized for Apple Silicon"
  homepage "https://github.com/Mininglamp-AI/octoasr"
  url "https://github.com/Mininglamp-AI/octoasr/archive/refs/tags/v0.1.39.tar.gz"
  sha256 "196b93bd5c4b6aa8ea3acda3b55e1a389d7c08fe74b82cc7d35465eeadec3439"
  license "MIT"

  bottle do
    root_url "https://github.com/Mininglamp-AI/octoasr/releases/download/v0.1.39"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "cb4878b25069bad7f6e81223460fff95e27bc115309aa28c527e94817cea5c27"
    sha256 cellar: :any_skip_relocation, arm64_sonoma: "10886f10135ab2c25ea7c6a12ee386181f9b91407290c0fe0e08040cda544fa0"
    sha256 cellar: :any_skip_relocation, arm64_tahoe: "5a742f92bc94c03eb9e2b7646bc3c2a0bb873b240b863f87e91099353e9afb7b"
  end

  depends_on "ffmpeg"
  depends_on "python@3.12"
  depends_on :macos => :monterey
  depends_on :arch => :arm64

  def install
    venv = libexec/"venv"
    system Formula["python@3.12"].opt_bin/"python3.12", "-m", "venv", venv
    system venv/"bin/pip", "install", "--retries", "3", "--timeout", "120", "--upgrade", "pip"
    system venv/"bin/pip", "install", "--retries", "3", "--timeout", "120", buildpath

    if cider_supported?
      system venv/"bin/pip", "install", "--retries", "3", "--timeout", "120", "mininglamp-cider==#{CIDER_VERSION}"
      system venv/"bin/python3", "-c", "import importlib.util; assert importlib.util.find_spec('cider.lib._cider_prim')"
    else
      ohai "Skipping optional Cider acceleration; requires macOS 26 on Apple Silicon"
    end

    site_packages = Dir[venv/"lib/python*/site-packages"].first
    cp_r "core", site_packages
    cp_r "utils", site_packages
    cp "server.py", site_packages

    # The @mention judge reads its system prompt from docs/prompt.txt.
    # docs/ is not otherwise packaged, so copy just this file next to core/.
    (Pathname(site_packages)/"docs").mkpath
    cp "docs/prompt.txt", "#{site_packages}/docs/prompt.txt"

    (bin/"octoasr").write <<~SH
      #!/bin/bash
      SCRIPT_PATH="$0"
      if [ -L "$0" ]; then
          SCRIPT_PATH="$(readlink -f "$0" 2>/dev/null || readlink "$0")"
      fi
      FORMULA_PREFIX="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"
      exec "${FORMULA_PREFIX}/libexec/venv/bin/python3" -m octoasr.cli.main "$@"
    SH
    chmod 0755, bin/"octoasr"
  end

  def caveats
    <<~EOS
      OctoASR installed successfully!

      ASR, VAD, and Mention models will be downloaded automatically on first run (several GB).

      Quick start:
        octoasr start              # Start service (auto-downloads models on first run)
        octoasr transcribe a.wav   # Transcribe audio
        octoasr model list         # List models

      Service management:
        octoasr start / stop / restart / status

      Model storage: ~/.octoasr/models/
      Service address: http://127.0.0.1:8787
    EOS
  end

  test do
    assert_match "0.1.39", shell_output("#{bin}/octoasr --version")
  end

  private

  def cider_supported?
    OS.mac? &&
      MacOS.version.to_s.split(".").first.to_i >= 26 &&
      Hardware::CPU.arm?
  end
end
