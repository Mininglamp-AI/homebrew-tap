class ManoCua < Formula
  desc "VLA Desktop Automation Client"
  homepage "https://github.com/Mininglamp-AI/mano-skill"
  url "https://github.com/Mininglamp-AI/mano-skill/archive/refs/tags/v1.0.13.tar.gz"
  sha256 "69da3f7ab642b046c5814788f63ba2d40444013eb716bbf8288520d2476d7f26"
  version "1.0.13"

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
