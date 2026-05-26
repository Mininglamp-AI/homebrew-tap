class ManoAsr < Formula
  desc "Local speech-to-text service powered by MLX, optimized for Apple Silicon"
  homepage "https://github.com/Mininglamp-AI/mano-asr"
  url "https://github.com/Mininglamp-AI/mano-asr/archive/refs/tags/v0.1.1.tar.gz"
  sha256 "409210c026895359598dbc8de9cf5f06ff23c9a2e5866d0f140d01e984f88d86"
  license "MIT"

  bottle do
    root_url "https://github.com/Mininglamp-AI/mano-asr/releases/download/v0.1.1"
    sha256 cellar: :any_skip_relocation, arm64_tahoe: "fb7f6d249d38abe5693a1e94da01c63c5daeab8a316a70133498425ecb860a10"
  end

  depends_on "ffmpeg"
  depends_on "python@3.13"
  depends_on :macos => :monterey
  depends_on :arch => :arm64

  def install
    venv = libexec/"venv"
    system "python3.13", "-m", "venv", venv
    system venv/"bin/pip", "install", "--upgrade", "pip"
    system venv/"bin/pip", "install", buildpath

    site_packages = Dir[venv/"lib/python*/site-packages"].first
    cp_r "core", site_packages
    cp_r "utils", site_packages
    cp "server.py", site_packages

    (bin/"mano-asr").write <<~SH
      #!/bin/bash
      exec "#{venv}/bin/python3" -m manoasr.cli.main "$@"
    SH
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
    assert_match "0.1.1", shell_output("#{bin}/mano-asr --version")
  end
end
