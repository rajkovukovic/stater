#include "include/stater/stater_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "stater_plugin.h"

void StaterPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  stater::StaterPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
