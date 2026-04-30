class ManoCua < Formula
  desc "VLA Desktop Automation Client"
  homepage "https://github.com/Mininglamp-AI/mano-skill"
  url "https://github.com/Mininglamp-AI/mano-skill/archive/refs/tags/v1.0.11.tar.gz"
  sha256 "7a7b01d180bbc0af2ed1c61a740cc6342f67365fe25256279faa31459ba53373"
  version "1.0.11"

  depends_on "python@3.13"
  depends_on "python-tk@3.13"

  def install
    venv = libexec/"venv"
    system "python3.13", "-m", "venv", venv
    system venv/"bin/pip", "install", "-r", "requirements.txt"
    (venv/"src").install Dir["visual"]
    (bin/"mano-cua").write <<~SH
      #!/bin/bash
      export PYTHONPATH="#{venv}/src"
      exec "#{venv}/bin/python3" "#{venv}/src/visual/vla.py" "$@"
    SH
  end

  test do
    assert_match "usage", shell_output("#{bin}/mano-cua --help")
  end
end
