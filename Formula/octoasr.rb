class Octoasr < Formula
  desc "Local speech-to-text service powered by MLX, optimized for Apple Silicon"
  homepage "https://github.com/Mininglamp-AI/octoasr"
  url "https://github.com/Mininglamp-AI/octoasr/archive/refs/tags/v0.1.36.tar.gz"
  sha256 "aa4d4f5479d9098f8487c3ba5cb5222f8634d6366b577eb398dcbc053b27a2f5"
  license "MIT"

  bottle do
    root_url "https://github.com/Mininglamp-AI/octoasr/releases/download/v0.1.36"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "2c8420a1e8ec185145917b68da9863fec3adfb1be982f9072b81a265fa54033b"
    sha256 cellar: :any_skip_relocation, arm64_sonoma: "1d0b50010b2d28312653ffa07f282ce8145a325d87d259ea7abc9417f9b01176"
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

    # Cider is optional acceleration; keep OctoASR installable if it is unavailable here.
    begin
      system venv/"bin/pip", "install", "--retries", "3", "--timeout", "120", "mininglamp-cider==0.8.0"
    rescue
      opoo "Optional Cider install failed; continuing without Cider acceleration"
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
    assert_match "0.1.36", shell_output("#{bin}/octoasr --version")
  end
end
