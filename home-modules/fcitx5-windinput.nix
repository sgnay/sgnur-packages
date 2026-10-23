{ config, pkgs, ... }:

let
  pkg = pkgs.fcitx5-windinput;
  # 稳定间接路径：升级包后 session 变量无需重新登录即可指向新版本。
  runtimeDir = "${config.home.homeDirectory}/.local/state/windinput";
in
{
  # 注册 addon：fcitx5-with-addons 的 symlinkJoin 会合并 lib/fcitx5 与 share。
  i18n.inputMethod.fcitx5.addons = [ pkg ];

  # desktop / MIME / 图标关联与 CLI 入口。
  home.packages = [ pkg ];

  # 版本无关的符号链接，随每次 home-manager switch 更新目标。
  home.file.".local/state/windinput/wind_input".source = "${pkg}/lib/windinput/wind_input";
  home.file.".local/state/windinput/wind_setting".source = "${pkg}/lib/windinput/wind_setting";

  # addon 通过 getenv 查找服务与设置程序；写入 environment.d，
  # HM 的 fcitx5-daemon.service 继承用户 manager 环境后生效。
  home.sessionVariables = {
    WIND_INPUT_SERVICE = "${runtimeDir}/wind_input";
    WIND_INPUT_SETTING = "${runtimeDir}/wind_setting";
  };
}
