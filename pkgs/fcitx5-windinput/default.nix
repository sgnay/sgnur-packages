{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  fcitx5,
  libxcb,
  wayland,
  libxkbcommon,
  fontconfig,
  dbus,
  stdenvCC ? stdenv.cc.cc.lib,
}:

let
  pname = "fcitx5-windinput";
  version = "0.127.0";

  # 上游只发布 .deb；每个架构单独取 hash（arm64 未在 CI 覆盖，按官方 .sha256 核对）。
  srcs = {
    x86_64-linux = {
      arch = "amd64";
      hash = "sha256-Z4hA8qpFjJJUvpv9+7kp3rJiouS24/kQpkBH71C1A9A=";
    };
    aarch64-linux = {
      arch = "arm64";
      hash = "sha256-E+OmnNgGE/3gIIkkxrPptEap0n8WMjPvRQYm8zxRC9Y=";
    };
  };
  sys =
    srcs.${stdenv.hostPlatform.system}
      or (throw "fcitx5-windinput: unsupported platform ${stdenv.hostPlatform.system}");

  # deb 内只有 wind_linux 的 README，本体 LICENSE 需按 tag 从源码仓取。
  licenseSrc = fetchurl {
    url = "https://raw.githubusercontent.com/huanfeng/WindInput/v${version}/LICENSE";
    hash = "sha256-OXLcl0T2SZ8Pmy2/dmlvKuetivmyPd5m1q+Gyd+zaYY=";
  };
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://github.com/huanfeng/WindInput/releases/download/v${version}/WindInput-${version}-linux-${sys.arch}.deb";
    inherit (sys) hash;
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
  ];

  buildInputs = [
    fcitx5
    libxcb
    wayland
    libxkbcommon
    stdenvCC
  ];

  # wind_input / wind_setting 通过 dlopen 使用这些库（不在 DT_NEEDED 里），
  # 必须显式写进 RPATH，否则设置程序会静默失败、候选窗字体异常。
  runtimeDependencies = [
    fontconfig
    dbus
    libxkbcommon
    wayland
  ];

  unpackPhase = ''
    dpkg-deb -x $src .
  '';

  dontBuild = true;
  # 上游二进制已 strip；再处理只会扩大与 AUR 参考实现的差异面。
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    # 服务按 exe 同目录查找 data/（install_root = exe 所在目录），
    # 因此 wind_input / wind_setting / data 必须保持同一目录布局。
    install -d $out/lib $out/share $out/bin
    cp -r usr/lib/windinput $out/lib/windinput

    # deb 把 addon 装进 multiarch 目录；NixOS 统一为 $out/lib/fcitx5。
    install -Dm755 usr/lib/*/fcitx5/libwindinput.so $out/lib/fcitx5/libwindinput.so

    cp -r usr/share/fcitx5 usr/share/icons usr/share/mime usr/share/applications $out/share/
    install -Dm644 usr/share/doc/windinput/README.md $out/share/doc/${pname}/README.md

    # desktop 内的绝对路径指向 /usr/lib/windinput，换成 store 路径。
    substituteInPlace $out/share/applications/*.desktop \
      --replace-fail "/usr/lib/windinput/wind_setting" "$out/lib/windinput/wind_setting"

    # CLI 入口：symlink 即可，/proc/self/exe 会解析到 store 真实路径，data/ 仍能找到。
    ln -s $out/lib/windinput/wind_input $out/bin/wind_input
    ln -s $out/lib/windinput/wind_setting $out/bin/wind_setting

    install -Dm644 ${licenseSrc} $out/share/licenses/${pname}/LICENSE

    runHook postInstall
  '';

  meta = {
    description = "清风输入法 (WindInput) — Fcitx5 输入法引擎";
    homepage = "https://windinput.com";
    license = lib.licenses.gpl3Plus;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "wind_setting";
    maintainers = [ {
      name = "sgnay";
      github = "sgnay";
    } ];
  };
}
