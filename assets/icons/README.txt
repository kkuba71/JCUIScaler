Component palette icons for TJCScaler (Lazarus IDE).

  TJCScaler.png       24x24  (100 %)
  TJCScaler_150.png   36x36  (150 %)
  TJCScaler_200.png   48x48  (200 %)
  jcuiscaler_icons.res           all three, built with lazres:
      lazres jcuiscaler_icons.res TJCScaler.png TJCScaler_150.png TJCScaler_200.png

Resource names: TJCSCALER, TJCSCALER_150, TJCSCALER_200.
Link the .res in the design-time registration unit:  {$R jcuiscaler_icons.res}
