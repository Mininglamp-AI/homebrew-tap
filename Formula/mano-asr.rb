class ManoAsr < Formula
    include Language::Python::Virtualenv

    desc "本地语音转写服务，基于 MLX，针对 Apple Silicon 优化"
    homepage "https://github.com/Mininglamp-AI/mano-asr"
    url "https://github.com/Mininglamp-AI/mano-asr/archive/refs/tags/v0.1.0.tar.gz"
    sha256 "81bed69e5d847972c499558a943282b7727a35b59872af940e47522043686c65"
    license "MIT"

    depends_on "ffmpeg"
    depends_on "python@3.13"
    depends_on :macos => :monterey
    depends_on :arch => :arm64

    def install
      venv = virtualenv_create(libexec, "python3.13")
      venv.pip_install_and_link buildpath

      site_packages = Dir[libexec/"lib/python*/site-packages"].first
      cp_r "core", site_packages
      cp_r "utils", site_packages
      cp "server.py", site_packages
    end

    def caveats
      <<~EOS
        mano-asr 安装完成！

        模型将在首次运行时自动下载（约 1-2 GB）。

        快速开始:
          mano-asr start              # 启动服务（首次自动下载模型）
          mano-asr transcribe a.wav   # 转写音频
          mano-asr model list         # 查看模型

        服务管理:
          mano-asr start / stop / restart / status

        模型存储: ~/.mano-asr/models/
        服务地址: http://127.0.0.1:8787
      EOS
    end

    test do
      assert_match "0.1.0", shell_output("#{bin}/mano-asr --version")
    end
  end
