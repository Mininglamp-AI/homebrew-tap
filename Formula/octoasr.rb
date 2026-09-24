class Octoasr < Formula
  CIDER_VERSION = "0.8.0.post1"
  MLX_PACKAGES = %w[
    mlx==0.32.0
    mlx-metal==0.32.0
    mlx-lm==0.31.3
    mlx-audio==0.4.7
    mlx-vlm==0.6.10
  ].freeze

  desc "Local speech-to-text service powered by MLX, optimized for Apple Silicon"
  homepage "https://github.com/Mininglamp-AI/octoasr"
  url "https://github.com/Mininglamp-AI/octoasr/archive/refs/tags/v0.1.46.tar.gz"
  sha256 "eac605faf3af0ddb5cf4dd840841d95b3bdf306224715174b1cff01c67c81d99"
  license "MIT"

  bottle do
    root_url "https://github.com/Mininglamp-AI/octoasr/releases/download/v0.1.46"
    sha256 cellar: :any_skip_relocation, arm64_golden_gate: "cc42dabf1d6da585270b207cc3f407880aaae1a5b72ed845cf11845a09a95f55"
    sha256 cellar: :any_skip_relocation, arm64_tahoe: "3690fcae45e2e0373b7663d735bffce3ba53c1b2d9bcc35b7ff5758a70778467"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "76b1e130f1d11be7f20afc5bf1dfac7f6343a3b117eecbaea4dbd51f87a7eb7c"
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
    system venv/"bin/pip", "install", "--retries", "3", "--timeout", "120", *MLX_PACKAGES

    site_packages = Dir[venv/"lib/python*/site-packages"].first

    if cider_supported?
      system venv/"bin/pip", "install", "--retries", "3", "--timeout", "120", "mininglamp-cider==#{CIDER_VERSION}"
      system venv/"bin/python3", "-m", "pip", "freeze"
      repair_cider_rpaths(site_packages)
      system venv/"bin/python3", "-c", "import cider.lib._cider_prim"
    else
      ohai "Skipping optional Cider acceleration; requires macOS 26 on Apple Silicon"
    end

    cp_r "core", site_packages
    cp_r "utils", site_packages
    cp "server.py", site_packages

    # The @mention judge reads versioned prompts from docs/mention_prompts/.
    # Keep docs/prompt.txt as a fallback for custom/unknown mention models.
    (Pathname(site_packages)/"docs").mkpath
    cp "docs/prompt.txt", "#{site_packages}/docs/prompt.txt"
    cp_r "docs/mention_prompts", "#{site_packages}/docs/mention_prompts"

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
    assert_match "0.1.46", shell_output("#{bin}/octoasr --version")
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
