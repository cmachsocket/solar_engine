import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solar_engine/controller/CGController.dart';
import 'package:flutter/services.dart';

class HistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CGController>(() => CGController());
  }
}

class HistoryPage extends StatelessWidget {
  late final CGController controller;
  HistoryPage({super.key}) {
    controller = Get.find<CGController>();
  }
  @override
  Widget build(BuildContext context) {
    return Material(
        color: Colors.black.withAlpha(150),
        child: KeyboardTackle(
            child: GestureDetector(
          onSecondaryTap: () => Get.back(),
          child: Column(children: [
            Row(
              children: [
                IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Get.back();
                    }),
                Text(
                  "History",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                )
              ],
            ),
            Expanded(
              child: ListView.builder(
                  itemCount: controller.history.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(controller.history_characters[index],
                          style:
                              TextStyle(color: Colors.white70, fontSize: 18)),
                      subtitle: Text(
                        controller.history[index],
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      onTap: () {
                        controller.play_character_audio(controller
                            .currentScenario.value.charactersAudioPath);
                      },
                    );
                  }),
            )
          ]),
        )));
  }
}

class KeyboardTackle extends StatefulWidget {
  final Widget child;
  const KeyboardTackle({super.key, required this.child});
  @override
  State<KeyboardTackle> createState() => _KeyboardTackleState();
}

class _KeyboardTackleState extends State<KeyboardTackle> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
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
