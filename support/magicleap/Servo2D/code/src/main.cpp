/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

#include <Servo2D.h>
#include <ml_lifecycle.h>
#include <ml_logging.h>

static std::string join_path(const char *prefix, const char *suffix)
{
  std::string str = prefix;
  if (str.back() != '/')
    str.push_back ('/');
  return str + suffix;
}

int main(int argc, char **argv)
{
  ML_LOG(Debug, "Servo2D Starting.");

  // Handle optional initialization string passed via 'mldb launch'
  MLLifecycleInitArgList* list = NULL;
  MLLifecycleGetInitArgList(&list);
  const char* uri = NULL;
  if (nullptr != list) {
    int64_t list_length = 0;
    MLLifecycleGetInitArgListLength(list, &list_length);
    if (list_length > 0) {
      const MLLifecycleInitArg* iarg = NULL;
      MLLifecycleGetInitArgByIndex(list, 0, &iarg);
      if (nullptr != iarg) {
        MLLifecycleGetInitArgUri(iarg, &uri);
      }
    }
  }

  MLLifecycleSelfInfo *info;
  MLLifecycleGetSelfInfo(&info);
  auto gst_plugins_dir = join_path(info->package_dir_path, "bin");
  auto gst_registry_path = join_path(info->writable_dir_path, "gstreamer-registry.bin");
  setenv("GST_PLUGIN_SYSTEM_PATH", gst_plugins_dir.c_str(), 1);
  setenv("GST_REGISTRY", gst_registry_path.c_str(), 1);
  setenv("XDG_CACHE_HOME", info->tmp_dir_path, 1);
  // setenv("GST_DEBUG", "4", 1);
  MLLifecycleFreeSelfInfo(&info);

  const char* args = getenv("SERVO_ARGS");

  Servo2D myApp(uri, args);
  int rv = myApp.run();

  MLLifecycleFreeInitArgList(&list);
  return rv;
}
