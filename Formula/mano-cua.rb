class ManoCua < Formula
  desc "VLA Desktop Automation Client"
  homepage "https://github.com/Mininglamp-AI/mano-skill"
  url "https://github.com/Mininglamp-AI/mano-skill/archive/refs/tags/v1.1.3.tar.gz"
  sha256 "ee7e105c5d4ddee1b8ef7ee6fa6d3d32fc4786e0d154402851490a60db8f66c0"
  version "1.1.3"

  depends_on "python@3.13"
  depends_on "python-tk@3.13"

  def install
    venv = libexec/"venv"
    system "python3.13", "-m", "venv", venv
    system venv/"bin/pip", "install", "-r", "requirements.txt"
    (venv/"src").install Dir["visual"]
    (bin/"mano-cua").write <<~SH
      #!/bin/bash
      SRC="#{venv}/src"
      export PYTHONPATH="$SRC"
      CUSTOM_PY=""
      CFG="$HOME/.mano/config.json"
      if [ -f "$CFG" ]; then
        CUSTOM_PY=$(python3 -c "import json; print(json.load(open('$CFG')).get('python-path',''))" 2>/dev/null)
      fi
      if [ -n "$CUSTOM_PY" ] && [ -f "$CUSTOM_PY" ]; then
        exec "$CUSTOM_PY" "$SRC/visual/vla.py" "$@"
      else
        exec "#{venv}/bin/python3" "$SRC/visual/vla.py" "$@"
      fi
    SH
  end

  test do
    assert_match "usage", shell_output("#{bin}/mano-cua --help")
  end
end
