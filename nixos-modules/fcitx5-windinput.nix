{ config, lib, pkgs, ... }:

let
  cfg = config.services.fcitx5-windinput;
  pkg = pkgs.fcitx5-windinput;
in
{
  options.services.fcitx5-windinput = {
    enable = lib.mkEnableOption "清风输入法 (WindInput) Fcitx5 输入法引擎";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkg ];

    # addon 默认按硬编码的 /usr/lib/windinput 找服务与设置程序；
    # 环境变量是兜底覆盖，/usr 下的符号链接让不带环境变量的进程也能工作。
    environment.variables = {
      WIND_INPUT_SERVICE = "${pkg}/lib/windinput/wind_input";
      WIND_INPUT_SETTING = "${pkg}/lib/windinput/wind_setting";
    };

    systemd.tmpfiles.rules = [
      "d /usr/lib 0755 root root -"
      "d /usr/lib/windinput 0755 root root -"
      "L+ /usr/lib/windinput/wind_input - - - - ${pkg}/lib/windinput/wind_input"
      "L+ /usr/lib/windinput/wind_setting - - - - ${pkg}/lib/windinput/wind_setting"
      "L+ /usr/lib/windinput/data - - - - ${pkg}/lib/windinput/data"
    ];
  };
}
