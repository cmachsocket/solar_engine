import 'dart:async';

import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:solar_engine/backend/game.dart';
import 'package:solar_engine/ui/SaveLoadPage.dart';

enum PageState { main, history, fastForward, auto, branch, input, hiddenBar }

class CGController extends GetxController {
  final GameEngine _gameEngine = Get.find<GameEngine>();
  Timer? _fastForwardTimer;
  Timer? _autoModeTimer;
  Timer? _audioStateTimer;
  var state = PageState.main.index.obs;
  var _isAdvancing = false;
  var currentIndex = 0.obs;
  var currentScenarios = <dynamic>[];
  var currentScenario = Rx<dynamic>(null);
  var charactersName = "".obs;
  var backgroundImagePath = "".obs;
  var bgmPath = "".obs;
  var scenarioPath = "";
  var isMute = false.obs;
  var isTextAnimating = false;
  var isCharacterAudioPlaying = false.obs;
  var isBgmChanged = false.obs;
  RxDouble characterAudioRatio = 0.0.obs;
  var inputText = "".obs;
  var characterVoiceVolume = 100.obs; // percentage
  var musicVolume = 100.obs; // percentage
  List<String> history = [];
  List<String> history_characters = [];
  final AudioPlayer characterPlayer = AudioPlayer();
  final AudioPlayer bgmPlayer = AudioPlayer();
  CGController() {
    logger.info("Initializing CGController");

    initialize();
    _autoModeTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (state.value == PageState.auto.index) {
        if (!isTextAnimating && !await is_character_audio_playing()) {
          next();
        }
      }
    });
    _audioStateTimer =
        Timer.periodic(const Duration(milliseconds: 10), (timer) async {
      isCharacterAudioPlaying.value = await is_character_audio_playing();
      characterAudioRatio.value = await get_character_audio_ratio();
    });
  }
  Future<void> next() async {
    if (currentIndex.value < currentScenarios.length - 1) {
      currentIndex.value++;
      _gameEngine.gameIndex = currentIndex.value;
      await updateStates();
    } else {
      stopFastForward();
    }
  }

  void startFastForward(
      {Duration interval = const Duration(milliseconds: 120)}) {
    all_stop();
    if (_fastForwardTimer?.isActive ?? false) {
      return;
    }
    state.value = PageState.fastForward.index;
    _fastForwardTimer = Timer.periodic(interval, (_) {
      _advanceStep();
    });
  }

  void stopFastForward() {
    _fastForwardTimer?.cancel();
    _fastForwardTimer = null;
    if (state.value == PageState.fastForward.index) {
      state.value = PageState.main.index;
    }
  }

  Future<void> _advanceStep() async {
    if (_isAdvancing) {
      return;
    }
    if (currentIndex.value >= currentScenarios.length - 1) {
      stopFastForward();
      return;
    }
    _isAdvancing = true;
    try {
      await next();
    } finally {
      _isAdvancing = false;
    }
  }

  Future<void> updateStates() async {
    currentScenario.value = currentScenarios[currentIndex.value];
    if (currentScenario.value.type == CommandType.image.index ||
        currentScenario.value.type == CommandType.cg.index) {
      backgroundImagePath.value =
          imagePath + currentScenario.value.resourcePath;
      _gameEngine.setBackground = currentScenario.value.resourcePath;
      if (currentScenario.value.type == CommandType.cg.index) {
        _gameEngine.add_cg_to_state(currentScenario.value.resourcePath);
      }
      await next();
    } else if (currentScenario.value.type == CommandType.audio.index) {
      bgmPath.value = audioPath + currentScenario.value.resourcePath;
      if (currentScenario.value.resourcePath.isNotEmpty) {
        _gameEngine.setAudio = currentScenario.value.resourcePath;
        play_bgm(bgmPath.value);
      }

      await next();
    } else if (currentScenario.value.type == CommandType.jump.index) {
      await _gameEngine.jump_to_scenario(currentScenario.value.sourceList);
      currentIndex.value = 0;
      currentScenarios = _gameEngine.currentScenario;
      await updateStates();
    } else if (currentScenario.value.type == CommandType.branches.index ||
        currentScenario.value.type == CommandType.input.index) {
      // do nothing,wait for user to select branch
      all_stop();
      if (currentScenario.value.type == CommandType.input.index) {
        inputText.value = currentScenario.value.text;
      }
      state.value = CommandType.branches.index;
    } else {
      _gameEngine.gameIndex = currentIndex.value;
      charactersName.value = currentScenario.value.characters.join(", ");
      play_character_audio(currentScenario.value.charactersAudioPath.isNotEmpty
          ? audioPath + currentScenario.value.charactersAudioPath
          : "");
      history.add(currentScenario.value.text);
      history_characters.add(charactersName.value);
      if (currentScenario.value.type == CommandType.text.index) {
        isTextAnimating = true;
      }
    }
  }

  void load_initial_scenario() {
    backgroundImagePath.value = imagePath + _gameEngine.gameBackground;
    bgmPath.value = audioPath + _gameEngine.gameAudio;
    if (_gameEngine.gameAudio.isNotEmpty) {
      play_bgm(bgmPath.value);
    }
  }

  Future<void> play_bgm(String bgmPath) async {
    await bgmPlayer.stop();
    // 可以设置为循环播放
    await bgmPlayer.setReleaseMode(ReleaseMode.loop);
    isBgmChanged.value = true;
    await bgmPlayer.play(AssetSource(bgmPath),
        volume: isMute.value ? 0 : musicVolume.value / 100);
  }

  Future<double> get_character_audio_ratio() async {
    Duration? totalDuration = await characterPlayer.getDuration();
    Duration? currentPosition = await characterPlayer.getCurrentPosition();
    if (totalDuration != null && currentPosition != null) {
      return currentPosition.inMilliseconds / totalDuration.inMilliseconds;
    }
    return 0.0;
  }

  Future<void> play_character_audio(String path) async {
    if (path.isEmpty) return;
    await characterPlayer.stop();
    await characterPlayer.play(AssetSource(path),
        volume: isMute.value ? 0 : characterVoiceVolume.value / 100);
  }

  Future<bool> is_character_audio_playing() async {
    PlayerState state = await characterPlayer.state;
    return state == PlayerState.playing;
  }

  void start_hide_status() {
    if (state.value != PageState.hiddenBar.index) {
      state.value = PageState.hiddenBar.index;
    }
  }

  void start_auto_mode() {
    if (state.value != PageState.auto.index) {
      state.value = PageState.auto.index;
    }
  }

  void stop_auto_mode() {
    if (state.value == PageState.auto.index) {
      state.value = PageState.main.index;
    }
  }

  void stop_hiden_bar() {
    if (state.value == PageState.hiddenBar.index) {
      state.value = PageState.main.index;
    }
  }

  void switch_mute() {
    isMute.value = !isMute.value;
    if (isMute.value) {
      characterPlayer.setVolume(0);
      bgmPlayer.setVolume(0);
    } else {
      characterPlayer.setVolume(characterVoiceVolume.value / 100);
      bgmPlayer.setVolume(musicVolume.value / 100);
    }
  }

  // stop auto,fastforward,hidenbar
  void all_stop() {
    stopFastForward();
    state.value = PageState.main.index;
  }

  bool is_in_main_page() {
    return state.value == PageState.main.index ||
        state.value == PageState.hiddenBar.index ||
        state.value == PageState.auto.index ||
        state.value == PageState.fastForward.index;
  }

  @override
  void onClose() {
    stopFastForward();
    _autoModeTimer?.cancel();
    _audioStateTimer?.cancel();
    characterPlayer.dispose();
    bgmPlayer.dispose();
    super.onClose();
  }

  Future<void> select_branch(int index) async {
    state.value = PageState.main.index;
    // Handle branch selection logic here
    history_characters.add("branch ${currentScenario.value.id}");
    history.add(currentScenario.value.sourceList[index]);
    await _gameEngine.select_branch(currentScenario.value.id, index);
    await next();
  }

  Future<void> select_input(String input) async {
    state.value = PageState.main.index;
    // Handle input logic here
    history_characters.add(currentScenario.value.text);
    history.add(input);
    await _gameEngine.select_input(currentScenario.value.id, input);
    await next();
  }

  Future<void> save_load_jump(bool isSave) async {
    all_stop();
    var result = await Get.to(
      () => SaveLoadPage(isSave: isSave),
      binding: SaveLoadBinding(),
    );
    if (result == true) {
      initialize();
    }
  }

  void initialize() {
    load_initial_scenario();
    currentScenarios = _gameEngine.currentScenario;
    currentIndex.value = _gameEngine.gameIndex;
    scenarioPath = _gameEngine.scenarioPath;
    updateStates();
  }
}
