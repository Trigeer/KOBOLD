local map0 = {
    vertex = {
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
      {floor = 0,  ceil = 20, vertex = {3, 14, 29, 49},              neighbor = {-1, 1, 11, 22}},
      {floor = 0,  ceil = 20, vertex = {17, 15, 14, 3, 9},           neighbor = {-1, 12, 11, 0, 21}}, 
      {floor = 0,  ceil = 20, vertex = {41, 42, 43, 44, 50, 49, 40}, neighbor = {-1, 20, -1, 3, -1, -1, 22}}, 
      {floor = 0,  ceil = 14, vertex = {12, 13, 44, 43, 35, 20},     neighbor = {-1, 21, -1, 2, -1, 4}}, 
      {floor = 0,  ceil = 12, vertex = {16, 20, 35, 31},             neighbor = {-1, -1, 3, -1}}, 
      {floor = 16, ceil = 28, vertex = {24, 8, 2, 53, 48, 39},       neighbor = {18, -1, 7, -1, 6, -1}}, 
      {floor = 16, ceil = 28, vertex = {53, 52, 46, 47, 48},         neighbor = {5, -1, 8, 10, -1}}, 
      {floor = 16, ceil = 28, vertex = {1, 2, 8, 7, 6},              neighbor = {23, -1, 5, -1, 10}}, 
      {floor = 16, ceil = 36, vertex = {46, 52, 51, 45},             neighbor = {-1, 6, -1, 24}}, 
      {floor = 16, ceil = 36, vertex = {25, 26, 28, 27},             neighbor = {24, -1, 10, -1}}, 
      {floor = 16, ceil = 26, vertex = {6, 7, 47, 46, 28, 26},       neighbor = {-1, 7, -1, 6, -1, 9}}, 
      {floor = 2,  ceil = 20, vertex = {14, 15, 30, 29},             neighbor = {0, 1, 12, 22}}, 
      {floor = 4,  ceil = 20, vertex = {15, 17, 32, 30},             neighbor = {11, 1, 13, 22}}, 
      {floor = 6,  ceil = 20, vertex = {17, 18, 33, 32},             neighbor = {12, -1, 14, -1}}, 
      {floor = 8,  ceil = 20, vertex = {18, 19, 34, 33},             neighbor = {13, 19, 15, 20}}, 
      {floor = 10, ceil = 24, vertex = {19, 21, 36, 34},             neighbor = {14, -1, 16, -1}}, 
      {floor = 12, ceil = 24, vertex = {21, 22, 37, 36},             neighbor = {15, -1, 17, -1}}, 
      {floor = 14, ceil = 28, vertex = {22, 23, 38, 37},             neighbor = {16, -1, 18, -1}}, 
      {floor = 16, ceil = 28, vertex = {23, 24, 39, 38},             neighbor = {17, -1, 5, -1}}, 
      {floor = 8,  ceil = 14, vertex = {10, 11, 19, 18},             neighbor = {-1, 21, -1, 14}}, 
      {floor = 8,  ceil = 14, vertex = {33, 34, 42, 41},             neighbor = {-1, 14, -1, 2}}, 
      {floor = 0,  ceil = 20, vertex = {4, 13, 12, 11, 10, 9, 3},    neighbor = {-1, -1, 3, -1, 19, -1, 1}}, 
      {floor = 0,  ceil = 20, vertex = {29, 30, 32, 40, 49},         neighbor = {0, 11, 12, -1, 2}}, 
      {floor = 16, ceil = 36, vertex = {1, 6, 5, 0},                 neighbor = {-1, 7, -1, 24}}, 
      {floor = 16, ceil = 36, vertex = {0, 5, 25, 27, 45, 51},       neighbor = {-1, 23, -1, 9, -1, 8}}
    },
    player = {x = 3, y = 9, angle = 0.4, sector = 0},
    clone = {x = 25, y = 9, angle = 0.4, sector = 5}
  }

return map0