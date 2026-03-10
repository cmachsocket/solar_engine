import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solar_engine/backend/game.dart';
import 'package:solar_engine/controller/CGController.dart';

class BranchesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CGController>(() => CGController());
  }
}

class BranchesPage extends StatelessWidget {
  late final CGController controller;
  BranchesPage({super.key}) {
    controller = Get.find<CGController>();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Material(
          color: Colors.black.withAlpha(150),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 20,
            children: [
              if (controller.currentScenario.value.type ==
                  CommandType.branches.index)
                for (int i = 0;
                    i < controller.currentScenario.value.sourceList.length;
                    i++)
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                      onPressed: () async {
                        await controller.select_branch(i);
                        Get.back();
                      },
                      child: Text(
                        controller.currentScenario.value.sourceList[i],
                        style: TextStyle(fontSize: 30),
                      ),
                    ),
                  ),
              if (controller.currentScenario.value.type ==
                  CommandType.input.index)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50.0),
                  child: TextField(
                    onSubmitted: (value) async {
                      await controller.select_input(value);
                      Get.back();
                    },
                    style: TextStyle(fontSize: 24, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: controller.inputText.value,
                      hintStyle: TextStyle(fontSize: 24, color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54, width: 2),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                )
            ],
          ),
        ));
  }
}
