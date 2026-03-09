class BranchesDecide {
  static void branches_tackle(
      String branchesId,
      int choose,
      Map<String, dynamic> gameVariables,
      Map<String, dynamic> globalVariables) {
    //infer the type of gameVariables and globalVariables from the game engine
    if (branchesId == "1") {
      globalVariables["branch1"] = choose;
    }
  }

  static int jump_decide(String scenario, Map<String, dynamic> gameVariables,
      Map<String, dynamic> globalVariables) {
    // TODO implement jump decide,it should return the index of the scenario to jump to, and it should also update the values map if necessary
    if (scenario == "start.sce") {
      return 0;
    }
    return 0;
  }

  static void input_decide(
      String id,
      String input,
      Map<String, dynamic> gameVariables,
      Map<String, dynamic> globalVariables) {
    // TODO implement input decide,it should return the index of the scenario to jump to based on the input, and it should also update the values map if necessary
    if (id == "1") {
      globalVariables["name"] = input;
    }
  }
}
//It's a demo. The real implementation should be in the game engine, and it should be able to handle different types of branches, such as jump branches, variable branches, etc.
