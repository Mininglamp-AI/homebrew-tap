class ManoAsr < Formula
  desc "Local speech-to-text service powered by MLX, optimized for Apple Silicon"
  homepage "https://github.com/Mininglamp-AI/mano-asr"
  url "https://github.com/Mininglamp-AI/mano-asr/archive/refs/tags/v0.1.5.tar.gz"
  sha256 "a15ebcdaac315ac979f3b59ad487080ba5cc3e65ea26243767c74209b572676f"
  license "MIT"

  bottle do
    root_url "https://github.com/Mininglamp-AI/mano-asr/releases/download/v0.1.5"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "779cc9770af7b54a14a286df35453e1e6840a0c7bd39f4238bd98fef8d0d8d1d"
    sha256 cellar: :any_skip_relocation, arm64_sonoma: "04898633b0385f61f010ecbcea2b84d2d0e7a3b1950ab52735c75b97ca6f9767"
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

    (bin/"mano-asr").write <<~SH
      #!/bin/bash
      SCRIPT_PATH="$0"
      if [ -L "$0" ]; then
          SCRIPT_PATH="$(readlink -f "$0" 2>/dev/null || readlink "$0")"
      fi
      FORMULA_PREFIX="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"
      exec "${FORMULA_PREFIX}/libexec/venv/bin/python3" -m manoasr.cli.main "$@"
    SH
    chmod 0755, bin/"mano-asr"
  end

  def caveats
    <<~EOS
      mano-asr installed successfully!

      Models will be downloaded automatically on first run (~1-2 GB).

      Quick start:
        mano-asr start              # Start service (auto-downloads models on first run)
        mano-asr transcribe a.wav   # Transcribe audio
        mano-asr model list         # List models

      Service management:
        mano-asr start / stop / restart / status

      Model storage: ~/.mano-asr/models/
      Service address: http://127.0.0.1:8787
    EOS
  end

  test do
    assert_match "0.1.5", shell_output("#{bin}/mano-asr --version")
  end
end
