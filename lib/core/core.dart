import 'package:flutter/material.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

class Core {
  static mainConfigs() async {
    WindowOptions windowOptions = WindowOptions(
      size: Size(400, 500),
      skipTaskbar: false,
      alwaysOnTop: true,
      titleBarStyle: TitleBarStyle.hidden,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      final SystemTray systemTray = SystemTray();
      await systemTray.initSystemTray(iconPath: 'assets/logo/logo.ico');
      final Menu menu = Menu();
      await menu.buildFrom([
        MenuItemLabel(
          label: 'Bloom🍁🌸',
          name: 'Bloom🍁🌸',
          enabled: true,
          onClicked: (p0) => windowManager.show(),
        ),
        MenuSeparator(),
        MenuItemLabel(
          label: 'Show',
          onClicked: (menuItem) => windowManager.show(),
        ),
        MenuItemLabel(
          label: 'Hide',
          onClicked: (menuItem) => windowManager.hide(),
        ),
        MenuItemLabel(
          label: 'Quit',
          onClicked: (menuItem) => windowManager.destroy(),
        ),
      ]);
      // set context menu
      await systemTray.setContextMenu(menu);
      await systemTray.setImage('assets/logo/logo.ico');
      systemTray.setTitle('Bloom🍁🌸');
      systemTray.setToolTip('Bloom🍁🌸');
      systemTray.registerSystemTrayEventHandler((event) async {
        if (event == 'double-click') {
          await windowManager.show();
          await windowManager.setAlwaysOnTop(true);
        } else if (event == 'right-click') {
          await systemTray.popUpContextMenu();
        }
      });
      await windowManager.show();
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setResizable(false);
      await windowManager.setAlignment(Alignment.topRight);
      await windowManager.blur();
    });
  }
}
