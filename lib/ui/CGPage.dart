import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:solar_engine/main.dart';
import 'package:solar_engine/ui/SettingsPage.dart';
import 'package:solar_engine/controller/CGController.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:solar_engine/controller/SettingsController.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_markdown_plus_latex/flutter_markdown_plus_latex.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:toastification/toastification.dart';
import 'historyPage.dart';

enum CommandType {
  text,
  image,
  audio,
  cg,
  jump,
  branches,
  input,
  markdown,
  page
}

class CGBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CGController>(() => CGController());
    Get.lazyPut<SettingsController>(() => SettingsController());
  }
}

class CGPage extends StatefulWidget {
  const CGPage({
    super.key,
  });

  @override
  State<CGPage> createState() => _CGPageState();
}

class _CGPageState extends State<CGPage> {
  // 使用 Get.put 实例化控制器，并使其在整个应用程序中可用
  late final CGController controller;
  late final SystemUIAutoHideManager uiManager;
  final String defaultBackgroundImagePath = "assets/images/default_cg.png";
  final Duration scrollNextCooldown = Duration(milliseconds: 300);
  final RxInt _lastScrollNextMs = 0.obs;
  late Timer bgmChnagedTimer;

  @override
  void initState() {
    super.initState();
    controller = Get.find<CGController>();
    uiManager = SystemUIAutoHideManager();
    if (isMobileDevice()) {
      uiManager.showAndResetTimer();
    }
    bgmChnagedTimer = Timer(const Duration(seconds: 1), () {
      if (controller.isBgmChanged.value) {
        toastification.show(
          context: context, // optional if you use ToastificationWrapper
          icon: const Icon(Icons.music_note),
          title:
              Text(controller.bgmPath.value.split('/').last.split('.').first),
          autoCloseDuration: const Duration(seconds: 5),
        );
        controller.isBgmChanged.value = false;
      }
    });
  }

  @override
  void dispose() {
    if (isMobileDevice()) {
      uiManager.dispose();
    }
    bgmChnagedTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardTackle(
      child: Listener(
        onPointerSignal: (pointerSignal) {
          // 1. 判断是否是鼠标滚轮事件
          if (pointerSignal is PointerScrollEvent) {
            // 2. 获取滚动的偏移量
            if (controller.state.value == PageState.main.index) {
              final scrollDelta = pointerSignal.scrollDelta;
              // 3. 根据滚动的方向和距离执行相应的操作

              if (scrollDelta.dy > 0) {
                final nowMs = DateTime.now().millisecondsSinceEpoch;
                if (nowMs - _lastScrollNextMs.value <
                    scrollNextCooldown.inMilliseconds) {
                  return;
                }
                _lastScrollNextMs.value = nowMs;
                // 向下滚动，执行下一步操作
                controller.all_stop();
                controller.next();
              } else if (scrollDelta.dy < 0) {
                Get.to(
                  () => HistoryPage(),
                  binding: HistoryBinding(),
                  opaque: false,
                );
                // 向上滚动，执行历史记录查看操作
              }
            }
          }
        },
        onPointerDown: (_) {
          // 触摸时显示系统UI并重置隐藏计时器
          if (isMobileDevice()) {
            uiManager.showAndResetTimer();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Obx(
              () => Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                        controller.backgroundImagePath.value.isEmpty
                            ? defaultBackgroundImagePath
                            : controller.backgroundImagePath.value),
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
            CharacterRow(),
            Obx(() => Offstage(
                  offstage: controller.state.value == PageState.hiddenBar.index,
                  child: DialDock(),
                )),
            NavigationContainer(),
            // Obx(() => Offstage(
            //       offstage: controller.state.value != PageState.history.index,
            //       child: Focus(
            //         skipTraversal: true,
            //         onKeyEvent: (node, event) {
            //           if (event is KeyDownEvent &&
            //               event.logicalKey == LogicalKeyboardKey.escape) {
            //             controller.state.value = PageState.main.index;
            //             return KeyEventResult.handled;
            //           }
            //           return KeyEventResult.ignored;
            //         },
            //         child: HistoryContainer(),
            //       ),
            //     )),
            // Obx(() => Offstage(
            //       offstage: controller.state.value != PageState.branch.index &&
            //           controller.state.value != PageState.input.index,
            //       child: BrachesContainer(),
            //     )),
          ],
        ),
      ),
    );
  }
}

class CharacterRow extends StatelessWidget {
  late final CGController controller;
  late final SettingsController settingsController;

  CharacterRow({super.key}) {
    controller = Get.find<CGController>();
    settingsController = Get.find<SettingsController>();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.currentScenario.value.type != CommandType.text.index &&
          controller.currentScenario.value.type != CommandType.markdown.index) {
        return const SizedBox.shrink();
      }

      final rawCharacterPaths = controller.currentScenario.value.charactersPath;
      final characterPaths = (rawCharacterPaths is List
              ? rawCharacterPaths.whereType<String>()
              : const <String>[])
          .where((String path) => path.isNotEmpty)
          .toList(growable: false);

      return FractionallySizedBox(
        heightFactor: settingsController.characterRowHeight.value,
        alignment: Alignment.bottomLeft,
        child: Align(
          alignment: Alignment.bottomLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final path in characterPaths)
                  Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: Image.asset(
                      path,
                      fit: BoxFit.contain,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class DialDock extends StatelessWidget {
  late final CGController controller;
  late final SettingsController settingsController;
  DialDock({super.key}) {
    controller = Get.find<CGController>();
    settingsController = Get.find<SettingsController>();
  }
  @override
  Widget build(BuildContext context) {
    return Obx(() => FractionallySizedBox(
          heightFactor: settingsController.dialogDockHeight.value, // 父容器高度的比例
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            color: Colors.black.withAlpha(100),
            child: Column(
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    controller.charactersName.value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                Expanded(
                    child: Container(
                        alignment: Alignment.topLeft,
                        child: controller.currentScenario.value.type ==
                                CommandType.markdown.index
                            ? MarkdownText()
                            : NormalText())),
              ],
            ),
          ),
        ));
  }
}

class NormalText extends StatelessWidget {
  late final CGController controller;
  late final SettingsController settingsController;
  NormalText({super.key}) {
    controller = Get.find<CGController>();
    settingsController = Get.find<SettingsController>();
  }
  @override
  Widget build(BuildContext context) {
    return Obx(() => AnimatedTextKit(
          key: ValueKey(
              controller.currentScenario.value.type == CommandType.text.index
                  ? controller.currentScenario.value.text
                  : ""),
          displayFullTextOnTap: true,
          isRepeatingAnimation: false,
          onFinished: () => controller.isTextAnimating = false,
          animatedTexts: [
            TyperAnimatedText(
              controller.currentScenario.value.type == CommandType.text.index
                  ? controller.currentScenario.value.text
                  : "",
              speed: Duration(
                  milliseconds: settingsController.textAnimationSpeed.value),
              textStyle: TextStyle(
                color: Colors.white,
                fontSize: 18,
                decoration: TextDecoration.none,
              ),
            )
          ],
        ));
  }
}

class MarkdownText extends StatelessWidget {
  late final CGController controller;
  late final SettingsController settingsController;
  MarkdownText({
    super.key,
  }) {
    controller = Get.find<CGController>();
    settingsController = Get.find<SettingsController>();
  }
  @override
  Widget build(BuildContext context) {
    return Obx(() => Markdown(
          builders: {
            'latex': LatexElementBuilder(
              textStyle: const TextStyle(color: Colors.white, fontSize: 18),
              textScaleFactor: 1.2,
            ),
          },
          extensionSet: md.ExtensionSet(
            [LatexBlockSyntax()],
            [LatexInlineSyntax()],
          ),
          data: (controller.currentScenario.value.type ==
                  CommandType.markdown.index
              ? controller.currentScenario.value.text
              : ""),
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(
              color: Colors.white,
              fontSize: 18,
              decoration: TextDecoration.none,
            ),
          ),
        ));
  }
}

class KeyboardTackle extends StatefulWidget {
  final Widget child;
  const KeyboardTackle({super.key, required this.child});
  @override
  State<KeyboardTackle> createState() => _KeyboardTackleState();
}

class _KeyboardTackleState extends State<KeyboardTackle> {
  late final CGController controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    controller = Get.find<CGController>();
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
    final isCtrl = event.logicalKey == LogicalKeyboardKey.controlLeft ||
        event.logicalKey == LogicalKeyboardKey.controlRight;
    if (event is KeyDownEvent) {
      if (controller.is_in_main_page()) {
        if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
            event.logicalKey == LogicalKeyboardKey.space ||
            event.logicalKey == LogicalKeyboardKey.enter) {
          controller.all_stop();
          controller.next();
          return true;
        } else if (isCtrl) {
          controller.state.value == PageState.fastForward.index
              ? controller.stopFastForward()
              : controller.startFastForward();
          return true;
        } else if (event.logicalKey == LogicalKeyboardKey.keyS) {
          controller.save_load_jump(true);
          return true;
        } else if (event.logicalKey == LogicalKeyboardKey.keyL) {
          controller.save_load_jump(false);
          return true;
        }
      }
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        Get.to(
          () => SettingsPage(),
          binding: SettingsBinding(),
        );

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
        child: widget.child);
  }
}

class NavigationContainer extends StatelessWidget {
  late final CGController controller;
  NavigationContainer({super.key}) {
    controller = Get.find<CGController>();
  }
  dynamic switch_hide_method(bool isMobile) {
    controller.stop_auto_mode();
    return isMobile
        ? () {
            controller.stopFastForward();
            controller.state.value == PageState.hiddenBar.index
                ? controller.stop_hiden_bar()
                : controller.start_hide_status();
          }
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () async {
          if (controller.is_in_main_page()) {
            controller.all_stop();
            await controller.next();
          }
        },
        onLongPressStart: (_) {
          if (controller.state.value != PageState.main.index) {
            return;
          }
          controller.startFastForward();
        },
        onLongPressEnd: (_) {
          controller.stopFastForward();
        },
        // Use correct named gesture callbacks based on device type
        onDoubleTap: switch_hide_method(isMobileDevice()),
        onSecondaryTap: switch_hide_method(!isMobileDevice()),
        onVerticalDragUpdate: (details) {},
        child: IconBar());
  }
}

class IconBar extends StatelessWidget {
  late final CGController controller;
  IconBar({super.key}) {
    controller = Get.find<CGController>();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Offstage(
        offstage: controller.state.value == PageState.hiddenBar.index,
        child: Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    //Obx(
                    IconButton(
                      onPressed: () =>
                          controller.state.value == PageState.fastForward.index
                              ? controller.stopFastForward()
                              : controller.startFastForward(),
                      icon: Icon(
                          controller.state.value == PageState.fastForward.index
                              ? Icons.pause
                              : Icons.skip_next),
                      color: Colors.white,
                    ),
                    IconButton(
                      onPressed: () {
                        controller.all_stop();
                        controller.state.value == PageState.auto.index
                            ? controller.stop_auto_mode()
                            : controller.start_auto_mode();
                      },
                      icon: Icon(Icons.auto_mode),
                      color: Colors.white,
                      style: ButtonStyle(
                        backgroundColor:
                            controller.state.value == PageState.auto.index
                                ? WidgetStateColor.resolveWith(
                                    (states) => Colors.white.withAlpha(30))
                                : null,
                      ),
                    ),
                    IconButton(
                      //TODO: save page
                      onPressed: () async {
                        controller.save_load_jump(true);
                      },
                      icon: Icon(Icons.save),
                      color: Colors.white,
                    ),
                    IconButton(
                      //TODO: load page
                      onPressed: () async {
                        controller.save_load_jump(false);
                      },
                      icon: Icon(Icons.file_upload),
                      color: Colors.white,
                    ),
                    IconButton(
                      //TODO: volume control
                      onPressed: () => controller.switch_mute(),
                      icon: Icon(controller.isMute.value
                          ? Icons.volume_off
                          : Icons.volume_up),
                      color: Colors.white,
                    ),
                    IconButton(
                      //TODO: settings page
                      onPressed: () {
                        controller.all_stop();
                        Get.to(
                          () => SettingsPage(),
                          binding: SettingsBinding(),
                        );
                      },
                      icon: Icon(Icons.settings),
                      color: Colors.white,
                    ),
                    IconButton(
                      //return to home page
                      onPressed: () {
                        controller.all_stop();
                        Get.offAll(() => MainPage());
                      },
                      icon: Icon(Icons.home),
                      color: Colors.white,
                    ),
                    IconButton(
                        onPressed: () {
                          controller.all_stop();
                          Get.to(
                            () => HistoryPage(),
                            binding: HistoryBinding(),
                            opaque: false,
                          );
                        },
                        icon: Icon(
                          Icons.history,
                          color: Colors.white,
                        )),
                    IconButton(
                      // TODO: hide/show dilaogue dock
                      onPressed: () {
                        controller.all_stop();
                        controller.state.value == PageState.hiddenBar.index
                            ? controller.stop_hiden_bar()
                            : controller.start_hide_status();
                      },
                      icon: Icon(Icons.hide_image),
                      color: Colors.white,
                    ),
                    Offstage(
                        offstage: !controller.isCharacterAudioPlaying.value,
                        child: SizedBox(
                            width: 120,
                            child: LinearProgressIndicator(
                              value: controller.characterAudioRatio.value,
                            )))
                  ],
                ),
              ),
            ))));
  }
}
