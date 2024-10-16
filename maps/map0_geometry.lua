local map0 = {
    nodes = {
      {y = 0,    x = {0, 6, 28}},
      {y = 2,    x = {1, 17.5}},
      {y = 5,    x = {4, 6, 18, 21}},
      {y = 6.5,  x = {9, 11, 13, 13.5, 17.5}},
      {y = 7,    x = {5, 7, 8, 9, 11, 13, 13.5, 15, 17, 19, 21}},
      {y = 7.5,  x = {4, 6}},
      {y = 10.5, x = {4, 6}},
      {y = 11,   x = {5, 7, 8, 9, 11, 13, 13.5, 15, 17, 19, 21}},
      {y = 11.5, x = {9, 11, 13, 13.5, 17.5}},
      {y = 13,   x = {4, 6, 18, 21}},
      {y = 16,   x = {1, 17.5}},
      {y = 18,   x = {0, 6, 28}}
    },
    sector = {
      {slanted = true,  floor = {3, 0.65, 0},  ceil = {20, 0, 0}, nodes = {3, 14, 29, 49}, links = {{}, {1},  {11}, {22}}},
      {slanted = false, floor = 0,  ceil = 20, nodes = {17, 15, 14, 3, 9},           links = {{}, {12}, {11}, {0}, {21}}},
      {slanted = false, floor = 0,  ceil = 20, nodes = {41, 42, 43, 44, 50, 49, 40}, links = {{}, {20}, {}, {3}, {}, {}, {22}}},
      {slanted = false, floor = 0,  ceil = 14, nodes = {12, 13, 44, 43, 35, 20},     links = {{}, {21}, {}, {2}, {}, {25, 4}}},
      {slanted = false, floor = 0,  ceil = 5,  nodes = {16, 20, 35, 31},             links = {{}, {}, {3}, {}}},
      {slanted = false, floor = 16, ceil = 28, nodes = {24, 8, 2, 53, 48, 39},       links = {{18}, {}, {7}, {}, {6}, {}}},
      {slanted = false, floor = 16, ceil = 28, nodes = {53, 52, 46, 47, 48},         links = {{5}, {}, {8}, {10}, {}}},
      {slanted = false, floor = 16, ceil = 28, nodes = {1, 2, 8, 7, 6},              links = {{23}, {}, {5}, {}, {10}}},
      {slanted = false, floor = 16, ceil = 36, nodes = {46, 52, 51, 45},             links = {{}, {6}, {}, {24}}},
      {slanted = false, floor = 16, ceil = 36, nodes = {25, 26, 28, 27},             links = {{24}, {}, {10}, {}}},
      {slanted = false, floor = 16, ceil = 26, nodes = {6, 7, 47, 46, 28, 26},       links = {{}, {7}, {}, {6}, {}, {9}}},
      {slanted = false, floor = 2,  ceil = 20, nodes = {14, 15, 30, 29},             links = {{0}, {1}, {12}, {22}}},
      {slanted = false, floor = 4,  ceil = 20, nodes = {15, 17, 32, 30},             links = {{11}, {1}, {13}, {22}}},
      {slanted = false, floor = 6,  ceil = 20, nodes = {17, 18, 33, 32},             links = {{12}, {}, {14}, {}}},
      {slanted = false, floor = 8,  ceil = 20, nodes = {18, 19, 34, 33},             links = {{13}, {19}, {15}, {20}}},
      {slanted = false, floor = 10, ceil = 24, nodes = {19, 21, 36, 34},             links = {{14}, {}, {16}, {}}},
      {slanted = false, floor = 12, ceil = 24, nodes = {21, 22, 37, 36},             links = {{15}, {}, {17}, {}}},
      {slanted = false, floor = 14, ceil = 28, nodes = {22, 23, 38, 37},             links = {{16}, {}, {18}, {}}},
      {slanted = false, floor = 16, ceil = 28, nodes = {23, 24, 39, 38},             links = {{17}, {}, {5}, {}}},
      {slanted = false, floor = 8,  ceil = 14, nodes = {10, 11, 19, 18},             links = {{}, {21}, {}, {14}}},
      {slanted = false, floor = 8,  ceil = 14, nodes = {33, 34, 42, 41},             links = {{}, {14}, {}, {2}}},
      {slanted = false, floor = 0,  ceil = 20, nodes = {4, 13, 12, 11, 10, 9, 3},    links = {{}, {}, {3}, {}, {19}, {}, {1}}},
      {slanted = false, floor = 0,  ceil = 20, nodes = {29, 30, 32, 40, 49},         links = {{0}, {11}, {12}, {}, {2}}},
      {slanted = false, floor = 16, ceil = 36, nodes = {1, 6, 5, 0},                 links = {{}, {7}, {}, {24}}},
      {slanted = false, floor = 16, ceil = 36, nodes = {0, 5, 25, 27, 45, 51},       links = {{}, {23}, {}, {9}, {}, {8}}},
      {slanted = false, floor = 10, ceil = 12, nodes = {16, 20, 35, 31},             links = {{}, {}, {3}, {}}}
    },
    player = {x = 3, y = 9, angle = 0.4, sector = 0}
  }

return map0