import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:solar_engine/controller/CGController.dart';
import 'package:solar_engine/controller/SaveLoadController.dart';
import 'package:solar_engine/ui/CGPage.dart';

class SaveLoadBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SaveLoadController>(() => SaveLoadController());
  }
}

class SaveLoadPage extends StatelessWidget {
  // 使用 Get.put 实例化控制器，并使其在整个应用程序中可用
  late final SaveLoadController controller;
  final bool isSave;
  SaveLoadPage({super.key, required this.isSave}) {
    controller = Get.find<SaveLoadController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isSave ? "Save" : "Load"),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: KeyboardTackle(
        child: Row(
          children: [
            Expanded(
              child: Obx(
                () => ListView.builder(
                  itemCount: controller.saveCount.value,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text('Save Slot ${index + 1}'),
                      subtitle: Text(controller.loadedDescriptions[index]),
                      onTap: () async {
                        final confirmed = await Get.dialog<bool>(
                          AlertDialog(
                            title: Text(isSave ? "Save Game" : "Load Game"),
                            content: Text(
                              isSave
                                  ? "Do you want to save the game in this slot?"
                                  : "Do you want to load the game from this slot?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Get.back(result: false),
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Get.back(result: true),
                                child: Text('Confirm'),
                              ),
                            ],
                          ),
                          barrierDismissible: true,
                        );

                        if (confirmed == true) {
                          if (isSave) {
                            controller.save_game(
                              index + 1,
                            );
                          } else {
                            await controller.load_game(index + 1);
                          }
                          if (Get.isRegistered<CGController>()) {
                            Get.back(result: true); // 关闭 SaveLoadPage，返回上一页
                          } else {
                            Get.to(
                              () => CGPage(),
                              binding: CGBinding(),
                            ); // 关闭 SaveLoadPage，返回上一页
                          }
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Visibility(
        visible: isSave,
        child: FloatingActionButton(
          onPressed: () {
            controller.save_game(
              controller.saveCount.value + 1,
            ); // 刷新保存游戏列表
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}

class KeyboardTackle extends StatefulWidget {
  final Widget child;
  const KeyboardTackle({super.key, required this.child});
  @override
  State<KeyboardTackle> createState() => _KeyboardTackleState();
}

class _KeyboardTackleState extends State<KeyboardTackle> {
  late final SaveLoadController controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    controller = Get.find<SaveLoadController>();
    _focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  bool _handleKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        Get.back();
        return true;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: widget.child,
    );
  }
}
