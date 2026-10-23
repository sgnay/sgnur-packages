{ pkgs, ... }:

let
  pkg = pkgs.fcitx5-windinput;
in
{
  # 注册 addon：fcitx5-with-addons 的 symlinkJoin 会合并 lib/fcitx5 与 share。
  i18n.inputMethod.fcitx5.addons = [ pkg ];

  # desktop / MIME / 图标关联与 CLI 入口。
  home.packages = [ pkg ];

  # addon 通过 getenv 查找服务与设置程序；写入 environment.d，
  # HM 的 fcitx5-daemon.service 继承用户 manager 环境后生效。
  home.sessionVariables = {
    WIND_INPUT_SERVICE = "${pkg}/lib/windinput/wind_input";
    WIND_INPUT_SETTING = "${pkg}/bin/wind_setting";
  };
}
