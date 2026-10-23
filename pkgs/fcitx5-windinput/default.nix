{
  lib,
  stdenv,
  fetchurl,
  fetchFromGitHub,
  rustPlatform,
  cmake,
  ninja,
  pkg-config,
  wayland-scanner,
  fcitx5,
  libxcb,
  wayland,
  fontconfig,
  dbus,
  libxkbcommon,
  autoPatchelfHook,
  gawk,
  gnugrep,
  git,
}:

let
  pname = "fcitx5-windinput";
  version = "0.127.0";

  # ── 上游源码 ────────────────────────────────────────────────────────────
  # 服务 + addon + 数据工具都在 WindInput 仓；设置程序是独立仓，经 path 依赖
  # 引用 ../WindInput 与 ../wind-ui-rust（发布时 wind-setting v0.127.0 对应
  # wind-ui-rust v0.25.0）。
  windInput = fetchFromGitHub {
    owner = "huanfeng";
    repo = "WindInput";
    rev = "b2b8efb52cec0e947fcc7c39dec35b97e3d93c49"; # v0.127.0
    hash = "sha256-oslXNyVMx9DwPdYIwzL0S8NTHhnB4lv3JSsZKnSfhCo=";
  };
  windSetting = fetchFromGitHub {
    owner = "huanfeng";
    repo = "wind-setting";
    rev = "a363a34941c6c2da97dbb3787bec426301188ae5"; # v0.127.0
    hash = "sha256-Hj/7Ezur85ElKidbvP+mr8vK9s36WjUvzR5rccI0Lv0=";
  };
  windUi = fetchFromGitHub {
    owner = "huanfeng";
    repo = "wind-ui-rust";
    rev = "7594862159e48420bc68d0d41f1e28eaa7839d91"; # v0.25.0
    hash = "sha256-qxgZYMMQagMfOL/cYNC+jyluuw8QTvCt5d6lMTLKZXc=";
  };

  # 设置程序的 path 依赖要求三个仓互为兄弟目录。
  workspace = stdenv.mkDerivation {
    name = "windinput-source-tree";
    dontUnpack = true;
    dontBuild = true;
    installPhase = ''
      mkdir -p $out
      cp -a ${windInput} $out/WindInput
      cp -a ${windSetting} $out/wind-setting
      cp -a ${windUi} $out/wind-ui-rust
    '';
  };

  # ── 词库数据源（构建期下载，不入库）────────────────────────────────────
  # rime-frost 仓约 350MB，只取实际使用的 28 个文件；其余仓用固定 rev 的完整
  # tarball，再按 .cache 布局挑文件。
  rimeFrostRev = "c34bbd820db0a2887aa3f75f4b67d85a01b6a0e1";
  frostBase = "https://raw.githubusercontent.com/gaboolic/rime-frost/${rimeFrostRev}";

  frostFiles = {
    "rime_frost.dict.yaml" = fetchurl {
      name = "rime-frost-rime_frost.dict.yaml";
      url = "${frostBase}/rime_frost.dict.yaml";
      hash = "sha256-li25v7zEugqhjlxqq0xcitctTLnNwZJzgHnbedoPxj4=";
    };
    "cn_dicts/8105.dict.yaml" = fetchurl {
      name = "rime-frost-8105.dict.yaml";
      url = "${frostBase}/cn_dicts/8105.dict.yaml";
      hash = "sha256-Wmu1RdBxQEBiCHKK7tcHBuhCedru4TLxCwac1jh6BCo=";
    };
    "cn_dicts/41448.dict.yaml" = fetchurl {
      name = "rime-frost-41448.dict.yaml";
      url = "${frostBase}/cn_dicts/41448.dict.yaml";
      hash = "sha256-shFerjrqWBkEJMIoJfauoS94GuI+qCtizZUcQfbVdtU=";
    };
    "cn_dicts/base.dict.yaml" = fetchurl {
      name = "rime-frost-base.dict.yaml";
      url = "${frostBase}/cn_dicts/base.dict.yaml";
      hash = "sha256-21gltlMQfrNJYn05rnSDMgjgbVLrAjHOEMO7WblOT4Y=";
    };
    "cn_dicts/ext.dict.yaml" = fetchurl {
      name = "rime-frost-ext.dict.yaml";
      url = "${frostBase}/cn_dicts/ext.dict.yaml";
      hash = "sha256-RLeOT+uKOzAimIRAYWJqpOIZSQG47U7mrOyEJhtqqQ0=";
    };
    "cn_dicts/others.dict.yaml" = fetchurl {
      name = "rime-frost-others.dict.yaml";
      url = "${frostBase}/cn_dicts/others.dict.yaml";
      hash = "sha256-sWC6S6UanqBhHT8W6n4TQqHBLJtzlr2S+RsGoMIxhVg=";
    };
    "cn_dicts/corrections.dict.yaml" = fetchurl {
      name = "rime-frost-corrections.dict.yaml";
      url = "${frostBase}/cn_dicts/corrections.dict.yaml";
      hash = "sha256-GBYaYoaodR2iyuB3fq+6O4tJV9usvjHOKzv6yQR4zCo=";
    };
    "cn_dicts/tencent.dict.yaml" = fetchurl {
      name = "rime-frost-tencent.dict.yaml";
      url = "${frostBase}/cn_dicts/tencent.dict.yaml";
      hash = "sha256-VbGx8ymA0kpZXoqUooj3iWyElQYio08ggdEUcEXdzrc=";
    };
    "opencc/emoji.txt" = fetchurl {
      name = "rime-frost-emoji.txt";
      url = "${frostBase}/opencc/emoji.txt";
      hash = "sha256-vP+ZdpQ9F9HYeDyTOeicAdThzlfeTz5WgBRySItJxLA=";
    };
    "opencc/others.txt" = fetchurl {
      name = "rime-frost-others.txt";
      url = "${frostBase}/opencc/others.txt";
      hash = "sha256-G2lwUhrHJxpa8m3hJYNIS1Zd0KCBm1ClQhOcCpWf5x8=";
    };
    "cn_dicts_cell/exthot.dict.yaml" = fetchurl {
      name = "rime-frost-exthot.dict.yaml";
      url = "${frostBase}/cn_dicts_cell/exthot.dict.yaml";
      hash = "sha256-1fi9pwu2Ifgu2F5Ojb6Dhsge/7hW/4LrtccI0Yrpk8E=";
    };
    "cn_dicts_cell/idiom.dict.yaml" = fetchurl {
      name = "rime-frost-idiom.dict.yaml";
      url = "${frostBase}/cn_dicts_cell/idiom.dict.yaml";
      hash = "sha256-NB13fU/Qd921NOR/i6J6jdgNCF/QuEdUipemZm1kQRM=";
    };
    "cn_dicts_cell/place.dict.yaml" = fetchurl {
      name = "rime-frost-place.dict.yaml";
      url = "${frostBase}/cn_dicts_cell/place.dict.yaml";
      hash = "sha256-ON0ccsQRn0emB/xULFKLVOrZyBnPvV9/UI+LS+Gq6Is=";
    };
    "cn_dicts_cell/history.dict.yaml" = fetchurl {
      name = "rime-frost-history.dict.yaml";
      url = "${frostBase}/cn_dicts_cell/history.dict.yaml";
      hash = "sha256-7yp+COnScp020eJMvT80RMyhsOtPrhHMDg+SXPFSUwU=";
    };
    "cn_dicts_cell/name.dict.yaml" = fetchurl {
      name = "rime-frost-name.dict.yaml";
      url = "${frostBase}/cn_dicts_cell/name.dict.yaml";
      hash = "sha256-oC7mLdOc/bXSvaE3wN+Fhu787W4QFqdzou6o4ovhz18=";
    };
    "cn_dicts_cell/name2.dict.yaml" = fetchurl {
      name = "rime-frost-name2.dict.yaml";
      url = "${frostBase}/cn_dicts_cell/name2.dict.yaml";
      hash = "sha256-VWz5+gYDKmtB+wcn7tHpPdc5pv3mxIpNkLAKmpJy5bQ=";
    };
    "cn_dicts_cell/sport.dict.yaml" = fetchurl {
      name = "rime-frost-sport.dict.yaml";
      url = "${frostBase}/cn_dicts_cell/sport.dict.yaml";
      hash = "sha256-Tkje/ZqxzZnhpDmveo51uVoFoUhBH1uN0hIOrd/tGeQ=";
    };
    "cn_dicts_cell/geography.dict.yaml" = fetchurl {
      name = "rime-frost-geography.dict.yaml";
      url = "${frostBase}/cn_dicts_cell/geography.dict.yaml";
      hash = "sha256-94zsP4j2u8uJcMYXTWiBnfFtDxp3MfqOzzD34VYCuVY=";
    };
    "cn_dicts_cell/animal.dict.yaml" = fetchurl {
      name = "rime-frost-animal.dict.yaml";
      url = "${frostBase}/cn_dicts_cell/animal.dict.yaml";
      hash = "sha256-xXFpoZdjiyXcVQSWQYuj4XMuo/26mB61ZvS2uYowZHk=";
    };
    "cn_dicts_cell/computer.dict.yaml" = fetchurl {
      name = "rime-frost-computer.dict.yaml";
      url = "${frostBase}/cn_dicts_cell/computer.dict.yaml";
      hash = "sha256-qS/mHUi1PR0g8eZr5MqDrC6L4Mqh+j84PFwV3my31eo=";
    };
    "cn_dicts_cell/music.dict.yaml" = fetchurl {
      name = "rime-frost-music.dict.yaml";
      url = "${frostBase}/cn_dicts_cell/music.dict.yaml";
      hash = "sha256-C1gitspc5zi1C9tSTOvIa3SnM8wK/kdCbCTsl7bWXDM=";
    };
    "cn_dicts_cell/media.dict.yaml" = fetchurl {
      name = "rime-frost-media.dict.yaml";
      url = "${frostBase}/cn_dicts_cell/media.dict.yaml";
      hash = "sha256-Ao81E6MykPHYuXshV3UjgpSgCGrw59Z1pEm6IgYJ8iA=";
    };
    "cn_dicts_cell/industry_product.dict.yaml" = fetchurl {
      name = "rime-frost-industry_product.dict.yaml";
      url = "${frostBase}/cn_dicts_cell/industry_product.dict.yaml";
      hash = "sha256-g7rEH5xjfVZTdypKIGZc0Q9zrBdizDqXmyNqZabI2OA=";
    };
    "cn_dicts_cell/inputmethod.dict.yaml" = fetchurl {
      name = "rime-frost-inputmethod.dict.yaml";
      url = "${frostBase}/cn_dicts_cell/inputmethod.dict.yaml";
      hash = "sha256-IACMaZcRLCaQYdRVctNT31ub2DxHu9HFvDXM9kx4VfY=";
    };
    "cn_dicts_cell/chess.dict.yaml" = fetchurl {
      name = "rime-frost-chess.dict.yaml";
      url = "${frostBase}/cn_dicts_cell/chess.dict.yaml";
      hash = "sha256-IjNQVwLdMiP6fHPq2PFdo1Qc2QR1FvqDTh5dfAIrZWg=";
    };
    "cn_dicts_cell/chess2.dict.yaml" = fetchurl {
      name = "rime-frost-chess2.dict.yaml";
      url = "${frostBase}/cn_dicts_cell/chess2.dict.yaml";
      hash = "sha256-lMN8wKzpxnyu1vMIZusG92WqWm3zG/+NTxWZzlszBz8=";
    };
    "en_dicts/en.dict.yaml" = fetchurl {
      name = "rime-frost-en.dict.yaml";
      url = "${frostBase}/en_dicts/en.dict.yaml";
      hash = "sha256-Z9+q7u4sMuT6tUnEDxYpa/WclbaCJGiI8UMBrKnG0d0=";
    };
    "en_dicts/en_ext.dict.yaml" = fetchurl {
      name = "rime-frost-en_ext.dict.yaml";
      url = "${frostBase}/en_dicts/en_ext.dict.yaml";
      hash = "sha256-eK3b5lJbhMmaHVdsnY/sJoTsfff7KrR5kEcfjsHV9TM=";
    };
  };

  pinyinData = fetchFromGitHub {
    owner = "mozillazg";
    repo = "pinyin-data";
    rev = "9e5e9bdfe8add694300e0cc93a27b803b68377f9";
    hash = "sha256-T+jS20RkmGssHvvO1Hoe838DLOlsBuXdtpI9/Q6lxbE=";
  };
  openccDict = fetchFromGitHub {
    owner = "BYVoid";
    repo = "OpenCC";
    rev = "ba09ffb8353f680381200c72452a36c72d540155";
    hash = "sha256-KDCGXp/8jMiFyUzfNAItEkgf/3EX5d1tlAEo73g6u2Q=";
  };
  rimeWubi = fetchFromGitHub {
    owner = "KyleBing";
    repo = "rime-wubi86-jidian";
    rev = "18a6016c3d08a20f713f8f8e1791a2e79e0be081";
    hash = "sha256-NTjBrJ+h+mFsWvkMtjJdI4K2Ven2GoPqDKCUyKdb5Vo=";
  };
  rimeAux = fetchFromGitHub {
    owner = "HowcanoeWang";
    repo = "rime-lua-aux-code";
    rev = "f9780033396f8998697c2a004d40bd543c46308b";
    hash = "sha256-wUqcwey37f4AwkWdj3ihoDdVkuv153dMeNGHLywP1Vw=";
  };
  hanziChars = fetchFromGitHub {
    owner = "zispace";
    repo = "hanzi-chars";
    rev = "6970aa7e4030253e22accfa5297d7e292d75a597";
    hash = "sha256-DzpMiVVDPkaSrBNCn+C12GVOYVOGYSi2Dlnf/U9G3IE=";
  };
  rimeStroke = fetchFromGitHub {
    owner = "rime";
    repo = "rime-stroke";
    rev = "1e8fff9b9494ddec23b0cbc526bcfd8171a6fd48";
    hash = "sha256-Tp0EOaM4uRkEGm9fV4o/lg7ddkj9z+FBn1PdX2o7fgQ=";
  };
  rimeEmoji = fetchFromGitHub {
    owner = "rime";
    repo = "rime-emoji";
    rev = "39d232996de79a95d7bf4b5e8533feed5326b075";
    hash = "sha256-fS9Or4/I8c0N7GFM5JH7p/ficU8+XXUIGnu3d5i9vAI=";
  };

  # ── Rust 工具（词库生成）──────────────────────────────────────────────
  tools = rustPlatform.buildRustPackage {
    pname = "wind-input-tools";
    inherit version;
    src = windInput;
    cargoRoot = "wind_input";
    buildAndTestSubdir = "wind_input";
    cargoLock.lockFile = "${windInput}/wind_input/Cargo.lock";
    cargoBuildFlags = [ "-p" "wind-tools" ];
    doCheck = false;
  };

  # ── 服务 ──────────────────────────────────────────────────────────────
  service = rustPlatform.buildRustPackage {
    pname = "wind-input-service";
    inherit version;
    src = workspace;
    cargoRoot = "WindInput/wind_input";
    buildAndTestSubdir = "WindInput/wind_input";
    cargoLock.lockFile = "${windInput}/wind_input/Cargo.lock";
    cargoBuildFlags = [
      "-p"
      "wind_service"
      "--features"
      "linux-host"
    ];
    doCheck = false;
    nativeBuildInputs = [ git ];
    patches = [ ./source-date-epoch.patch ];
    # 上游用 SystemTime::now() 生成构建戳；补丁改为优先 SOURCE_DATE_EPOCH。
    env.SOURCE_DATE_EPOCH = "1792454400"; # 2026-10-20T00:00:00Z
  };

  # ── 设置程序（wind-setting + ../WindInput + ../wind-ui-rust）──────────
  setting = rustPlatform.buildRustPackage {
    pname = "wind-input-setting";
    inherit version;
    src = workspace;
    cargoRoot = "wind-setting";
    buildAndTestSubdir = "wind-setting";
    cargoLock.lockFile = "${windSetting}/Cargo.lock";
    doCheck = false;
    env.WIND_APP_VERSION = version;
  };

  # ── Fcitx5 addon（C++ / CMake）────────────────────────────────────────
  addon = stdenv.mkDerivation {
    pname = "wind-input-addon";
    inherit version;
    src = windInput;
    cmakeDir = "../wind_linux";
    nativeBuildInputs = [
      cmake
      ninja
      pkg-config
      wayland-scanner
    ];
    buildInputs = [
      fcitx5
      libxcb
      wayland
    ];
    cmakeFlags = [
      "-DCMAKE_BUILD_TYPE=Release"
      "-DWIND_BUILD_ADDON=ON"
    ];
    doCheck = false;
  };

  # ── 词库数据（scripts/dev.sh gd 的等价物）─────────────────────────────
  data = stdenv.mkDerivation {
    pname = "wind-input-data";
    inherit version;
    src = windInput;
    nativeBuildInputs = [
      gawk
      gnugrep
    ];
    dontConfigure = true;
    dontBuild = true;
    installPhase = ''
      runHook preInstall

      cache=$TMPDIR/cache
      mkdir -p $cache/{rime-frost/cn_dicts,rime-frost/cn_dicts_cell,rime-frost/en_dicts,rime-frost/opencc}
      mkdir -p $cache/{pinyin-data,opencc/dictionaries,rime-wubi,aux-code/charset,rime-emoji/opencc}

      ${lib.concatStrings (
        lib.mapAttrsToList (dest: src: ''
          install -Dm644 ${src} "$cache/rime-frost/${dest}"
        '') frostFiles
      )}

      install -Dm644 ${pinyinData}/pinyin.txt $cache/pinyin-data/pinyin.txt
      install -Dm644 ${pinyinData}/kXHC1983.txt $cache/pinyin-data/kXHC1983.txt
      install -Dm644 ${pinyinData}/kTGHZ2013.txt $cache/pinyin-data/kTGHZ2013.txt
      install -Dm644 ${pinyinData}/kMandarin_8105.txt $cache/pinyin-data/kMandarin_8105.txt
      install -Dm644 ${pinyinData}/overwrite.txt $cache/pinyin-data/overwrite.txt

      for f in STCharacters STPhrases TSCharacters TSPhrases TWVariants TWPhrases HKVariants; do
        install -Dm644 ${openccDict}/data/dictionary/$f.txt $cache/opencc/dictionaries/$f.txt
      done

      install -Dm644 ${rimeWubi}/wubi86_jidian.dict.yaml $cache/rime-wubi/wubi86_jidian.dict.yaml
      install -Dm644 ${rimeWubi}/wubi86_jidian_extra.dict.yaml $cache/rime-wubi/wubi86_jidian_extra.dict.yaml
      install -Dm644 ${rimeWubi}/wubi86_jidian_extra_district.dict.yaml $cache/rime-wubi/wubi86_jidian_extra_district.dict.yaml

      install -Dm644 ${rimeAux}/aux_code/flypy_full.txt $cache/aux-code/flypy_full.txt
      install -Dm644 ${rimeAux}/aux_code/ZRM-wanxiang.txt $cache/aux-code/ZRM-wanxiang.txt
      install -Dm644 ${rimeStroke}/stroke.dict.yaml $cache/aux-code/stroke.dict.yaml
      install -Dm644 "${hanziChars}/data-charset/GB 18030-2000.txt" "$cache/aux-code/charset/GB 18030-2000.txt"
      install -Dm644 "${hanziChars}/data-charlist/《通用规范汉字表》（2013年）.txt" "$cache/aux-code/charset/《通用规范汉字表》（2013年）.txt"
      install -Dm644 "${hanziChars}/data-unicode/Unicode-CJK 〇.txt" "$cache/aux-code/charset/Unicode-CJK 〇.txt"

      install -Dm644 ${rimeEmoji}/opencc/emoji_word.txt $cache/rime-emoji/opencc/emoji_word.txt
      install -Dm644 ${rimeEmoji}/opencc/emoji_category.txt $cache/rime-emoji/opencc/emoji_category.txt
      install -Dm644 ${rimeEmoji}/LICENSE $cache/rime-emoji/LICENSE

      # unigram 仅供 gen_dict 给五笔扩展词库赋权
      ${tools}/bin/gen_unigram --rime "$cache/rime-frost/cn_dicts" --out "$cache/pinyin-frost/unigram.txt"
      ${tools}/bin/gen_pinyin --src "$cache/pinyin-data" --out "$cache/pinyin-data/pinyin_map.txt"

      # 组装：源 data/ + 生成物
      mkdir -p $out
      cp -a data/. $out/
      mkdir -p $out/schemas/pinyin/cn_dicts $out/schemas/pinyin/ext $out/schemas/english $out/emoji

      cp $cache/rime-frost/rime_frost.dict.yaml $out/schemas/pinyin/
      for f in 8105 41448 base ext others corrections; do
        cp $cache/rime-frost/cn_dicts/$f.dict.yaml $out/schemas/pinyin/cn_dicts/
      done
      for f in exthot idiom place history name name2 sport geography animal computer music media industry_product inputmethod chess chess2; do
        cp $cache/rime-frost/cn_dicts_cell/$f.dict.yaml $out/schemas/pinyin/ext/
      done
      cp $cache/rime-frost/en_dicts/en.dict.yaml $cache/rime-frost/en_dicts/en_ext.dict.yaml $out/schemas/english/
      cp $cache/pinyin-data/pinyin_map.txt $out/

      ${tools}/bin/gen_opencc --src "$cache/opencc/dictionaries" --out "$out/opencc"
      ${tools}/bin/gen_dict \
        --cache "$cache" --out "$out/schemas/wubi86" --report "$cache/rime-wubi" \
        --config "${windInput}/wind_input/apps/wind-tools/data/gen_dict/gen_dict.toml" \
        --version-date "2026-10-20"
      ${tools}/bin/gen_aux_code --cache "$cache" --out "$out/schemas/aux_code" --schema-out "$out/schemas"

      # emoji：rime-emoji 原样分发（LGPL），rime-frost 分组过滤
      cp $cache/rime-emoji/opencc/emoji_word.txt $cache/rime-emoji/opencc/emoji_category.txt $out/emoji/
      cp $cache/rime-emoji/LICENSE $out/emoji/LICENSE
      cp $cache/rime-frost/opencc/emoji.txt $out/emoji/frost_emoji.txt
      gawk -v excl="著名表演艺术家" '
        BEGIN { n = split(excl, ex, " ") }
        /^----------[^\t]*\t-+[ \t]*$/ {
          name = $0; sub(/^-+/, "", name); sub(/\t.*$/, "", name)
          skip = 0
          for (i = 1; i <= n; i++) if (name == ex[i]) skip = 1
        }
        !skip { print }
      ' $cache/rime-frost/opencc/others.txt > $out/emoji/frost_others.txt

      # 主表裁掉未随包的 import_tables / cn_dicts_cell 细胞词库
      main=$out/schemas/pinyin/rime_frost.dict.yaml
      dir=$(dirname $main)
      gawk -v dir="$dir" '
        /^\.\.\.[[:space:]]*$/ { done = 1 }
        !done && /^import_tables:/ { inblk = 1; print; next }
        !done && inblk && /^[^[:space:]#-]/ { inblk = 0 }
        !done && inblk && match($0, /^[[:space:]]*-[[:space:]]*[^[:space:]#]+/) {
          entry = substr($0, RSTART, RLENGTH); sub(/^[[:space:]]*-[[:space:]]*/, "", entry)
          if (entry ~ /^cn_dicts_cell\//) {
            print "  # [扩展词库] " substr($0, RSTART + RLENGTH - length(entry)); next
          }
          if (system("test -f \"" dir "/" entry ".dict.yaml\"") != 0) {
            print "  # [未随包] " substr($0, RSTART + RLENGTH - length(entry)); next
          }
        }
        { print }
      ' $main > $main.tmp && mv $main.tmp $main

      # Linux 版 compat.toml（Windows 规则不能随包带）
      bash ${windInput}/scripts/lib/gen-compat.sh linux $out/compat.toml $out/compat.toml.new
      mv $out/compat.toml.new $out/compat.toml

      runHook postInstall
    '';
  };
in
stdenv.mkDerivation {
  inherit pname version;

  dontUnpack = true;
  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [
    fcitx5
    libxcb
    wayland
    stdenv.cc.cc.lib
  ];
  # 服务/设置程序 dlopen fontconfig、dbus、xkbcommon；必须写入 RPATH。
  runtimeDependencies = map (p: lib.getLib p) [
    fontconfig
    dbus
    libxkbcommon
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/windinput $out/lib/fcitx5 $out/share/applications $out/share/mime/packages $out/bin

    install -Dm755 ${service}/bin/wind_input $out/lib/windinput/wind_input
    install -Dm755 ${setting}/bin/wind_setting $out/lib/windinput/wind_setting
    cp -a ${data}/. $out/lib/windinput/data/

    install -Dm755 ${addon}/lib/fcitx5/libwindinput.so $out/lib/fcitx5/libwindinput.so
    cp -a ${addon}/share/fcitx5 $out/share/
    cp -a ${addon}/share/icons $out/share/

    install -Dm644 ${windInput}/scripts/linux/pkg/windinput-setting.desktop $out/share/applications/windinput-setting.desktop
    install -Dm644 ${windInput}/scripts/linux/pkg/windinput-import.desktop $out/share/applications/windinput-import.desktop
    install -Dm644 ${windInput}/scripts/linux/pkg/windinput-mime.xml $out/share/mime/packages/windinput.xml
    substituteInPlace $out/share/applications/*.desktop \
      --replace-fail "/usr/lib/windinput/wind_setting" "$out/lib/windinput/wind_setting"

    ln -s $out/lib/windinput/wind_input $out/bin/wind_input
    ln -s $out/lib/windinput/wind_setting $out/bin/wind_setting

    install -Dm644 ${windInput}/LICENSE $out/share/licenses/${pname}/LICENSE
    install -Dm644 ${windInput}/NOTICE.md $out/share/licenses/${pname}/NOTICE.md
    install -Dm644 ${windInput}/wind_linux/README.md $out/share/doc/${pname}/README.md

    runHook postInstall
  '';

  meta = {
    description = "清风输入法 (WindInput) — Fcitx5 输入法引擎（源码构建）";
    homepage = "https://windinput.com";
    license = lib.licenses.gpl3Plus;
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
