#ifndef FLUTTER_PLUGIN_STATER_PLUGIN_H_
#define FLUTTER_PLUGIN_STATER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace stater {

class StaterPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  StaterPlugin();

  virtual ~StaterPlugin();

  // Disallow copy and assign.
  StaterPlugin(const StaterPlugin&) = delete;
  StaterPlugin& operator=(const StaterPlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace stater

#endif  // FLUTTER_PLUGIN_STATER_PLUGIN_H_
