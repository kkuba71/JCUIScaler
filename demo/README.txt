JCUIScaler — demo project (Lazarus only)

Open JCUIScalerDemo.lpi in Lazarus and run. No package installation needed:
the demo uses manual integration (three calls) and takes the library sources
from ../source via the project search paths.

Requires: DateTimeCtrls package (installed in Lazarus by default).

Lazarus only: the demo does not work with Delphi. Apart from the missing .dfm
files it relies on LCL-specific parts (.lfm/.lpi project files, the LCL
DateTimeCtrls package, LCL property names in the forms). The library itself
compiles under Delphi VCL; see the documentation for manual integration.

Main form   : PageControl with StringGrid, TreeView/ListView and a GroupBox
              with standard controls; StatusBar with panels; ResetOnShow = True.
Second form : StringGrid and a bottom-aligned panel tagged with
              JCSCALER_BORDER_TAG (BorderSpacing scaling); ResetOnShow = True.

Note: leave control Anchors at their defaults ([akLeft, akTop]). Clearing them
(Anchors = []) makes LCL move controls on its own when the form is scaled for
a DPI different from DesignTimePPI, before JCUIScaler captures the layout.

Scrollbars: TreeView1, ListView1 and StringGrid1 use ScrollBars = ssVertical.
This is the recommended setting for TListView (vsReport) with JCUIScaler; see
the documentation, section on scrollbars. In short: the scaler fits the columns
to the control width, so a horizontal scrollbar is never needed, and with it
disabled a TListView scaled while its tab sheet was hidden shows no horizontal
scrollbar after the tab is shown.
