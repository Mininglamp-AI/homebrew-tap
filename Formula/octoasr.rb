class Octoasr < Formula
  desc "Local speech-to-text service powered by MLX, optimized for Apple Silicon"
  homepage "https://github.com/Mininglamp-AI/mano-asr"
  url "https://github.com/Mininglamp-AI/mano-asr/archive/refs/tags/v0.1.18.tar.gz"
  sha256 "04e0329595bcfe08558df4eed68022cc57fe83e2ffa58ce7ddafcb8f461b2419"
  license "MIT"

  bottle do
    root_url "https://github.com/Mininglamp-AI/mano-asr/releases/download/v0.1.18"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "de41f4473e7fd800332d889e115386d8168a591bf041da92e6be1a156d9b8efa"
    sha256 cellar: :any_skip_relocation, arm64_sonoma: "5ff6ab4e7fdd5a9e46743bd105a98b7c05c486bb329ca1cded5d99fae13c7836"
  end

  depends_on "ffmpeg"
  depends_on "python@3.13"
  depends_on :macos => :monterey
  depends_on :arch => :arm64

  def install
    venv = libexec/"venv"
    system Formula["python@3.13"].opt_bin/"python3.13", "-m", "venv", venv
    system venv/"bin/pip", "install", "--retries", "3", "--timeout", "120", "--upgrade", "pip"
    system venv/"bin/pip", "install", "--retries", "3", "--timeout", "120", buildpath

    site_packages = Dir[venv/"lib/python*/site-packages"].first
    cp_r "core", site_packages
    cp_r "utils", site_packages
    cp "server.py", site_packages

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
      octoasr installed successfully!

      Models will be downloaded automatically on first run (~1-2 GB).

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
    assert_match "0.1.18", shell_output("#{bin}/octoasr --version")
  end
end

