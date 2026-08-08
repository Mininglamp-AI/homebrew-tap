class Octoasr < Formula
  CIDER_VERSION = "0.8.0.post1"

  desc "Local speech-to-text service powered by MLX, optimized for Apple Silicon"
  homepage "https://github.com/Mininglamp-AI/octoasr"
  url "https://github.com/Mininglamp-AI/octoasr/archive/refs/tags/v0.1.38.tar.gz"
  sha256 "9379b3a8e47d6ff775c4a64bd1d464e2cb586cf2d39b8fd1c8fb100e6e99bad3"
  license "MIT"

  bottle do
    root_url "https://github.com/Mininglamp-AI/octoasr/releases/download/v0.1.38"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "13cd5fa49fb4b2766fa5c5d451c913b858a91a9f82a7d0257c525cd38e4879ad"
    sha256 cellar: :any_skip_relocation, arm64_sonoma: "cf1384a27df4cd8047a521bf03fc7d892288191986c19c4334ee02b75bce512e"
    sha256 cellar: :any_skip_relocation, arm64_tahoe: "cf2eb266b21f7563c9ebaff9fb95c0cc8b6f36920aa1dde98b50ed2fefeb7fa2"
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
      system venv/"bin/python3", "-c", "import cider; assert cider.is_available()"
    else
      ohai "Skipping optional Cider acceleration; requires macOS 26 on Apple M5+"
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
    assert_match "0.1.38", shell_output("#{bin}/octoasr --version")
  end

  private

  def cider_supported?
    OS.mac? &&
      MacOS.version.to_s.split(".").first.to_i >= 26 &&
      Hardware::CPU.arm? &&
      apple_chip_generation >= 5
  end

  def apple_chip_generation
    brand = Utils.safe_popen_read("sysctl", "-n", "machdep.cpu.brand_string").strip
    match = brand.match(/Apple M(\d+)/)
    match ? match[1].to_i : 0
  rescue
    0
  end
end
