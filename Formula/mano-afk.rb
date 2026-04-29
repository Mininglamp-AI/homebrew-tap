class ManoAfk < Formula
  desc "Mano AFK — Desktop Automation CLI (Cloud + Local VLM)"
  homepage "https://github.com/Mininglamp-AI/mano-afk"
  url "https://github.com/Mininglamp-AI/mano-afk/archive/refs/tags/v0.2.3.tar.gz"
  sha256 "06ec3275a90e05dd51eeedde9593beb3a9ad8ec57f289a20caebe009211084d3"
  version "0.2.3"

  depends_on "python@3.13"
  depends_on "python-tk@3.13"

  def install
    venv = libexec/"venv"
    system "python3.13", "-m", "venv", venv
    system venv/"bin/pip", "install", "-r", "requirements.txt"
    (venv/"src/scripts").install Dir["scripts/*"]
    (bin/"mano-afk").write <<~SH
      #!/bin/bash
      export PYTHONPATH="#{venv}/src/scripts"
      exec "#{venv}/bin/python3" "#{venv}/src/scripts/main.py" "$@"
    SH
  end

  test do
    assert_match "usage", shell_output("#{bin}/mano-afk --help")
  end
end
