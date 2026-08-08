class Octoasr < Formula
  CIDER_VERSION = "0.8.0.post1"

  desc "Local speech-to-text service powered by MLX, optimized for Apple Silicon"
  homepage "https://github.com/Mininglamp-AI/octoasr"
  url "https://github.com/Mininglamp-AI/octoasr/archive/refs/tags/v0.1.41.tar.gz"
  sha256 "99b9fb8c62e5d9dd0aecd76701ba56f0f187403f64f99bc5f6b94a574d65bd53"
  license "MIT"

  bottle do
    root_url "https://github.com/Mininglamp-AI/octoasr/releases/download/v0.1.41"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "4c176d4d8986faffbd50e6201928d3a2f118a6ecd631b31f725a6d9e740b191a"
    sha256 cellar: :any_skip_relocation, arm64_sonoma: "9ca753988eafee9dd663fb5413234263e908af28e63ea43cb68a8b16233e8e67"
    sha256 cellar: :any_skip_relocation, arm64_tahoe: "48dc37eed62dc3afce3da183259582144a00c5cac894e9a665407a1a7c5551c4"
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

    site_packages = Dir[venv/"lib/python*/site-packages"].first

    if cider_supported?
      system venv/"bin/pip", "install", "--retries", "3", "--timeout", "120", "mininglamp-cider==#{CIDER_VERSION}"
      repair_cider_rpaths(site_packages)
      system venv/"bin/python3", "-c", "import cider.lib._cider_prim"
    else
      ohai "Skipping optional Cider acceleration; requires macOS 26 on Apple Silicon"
    end

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
    assert_match "0.1.41", shell_output("#{bin}/octoasr --version")
  end

  private

  def cider_supported?
    OS.mac? &&
      MacOS.version.to_s.split(".").first.to_i >= 26 &&
      Hardware::CPU.arm?
  end

  def repair_cider_rpaths(site_packages)
    cider_lib = Pathname(site_packages)/"cider/lib"
    ["_cider_prim.cpython-312-darwin.so", "libcider_prim_lib.dylib"].each do |name|
      binary = cider_lib/name
      system "install_name_tool", "-add_rpath", "@loader_path/../../mlx/lib", binary
      system "codesign", "--force", "--sign", "-", binary
    end
  end
end
