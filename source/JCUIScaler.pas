{
  JCUIScaler - deterministic UI scaling for Lazarus LCL
  Copyright (c) 2025-2026 Jakub Cebula, Kraków

  This file is part of JCUIScaler.
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.

  The copyright notice above and the name of the original author must not
  be removed from this file or from any modified version of it.
}

{
  JCUIScaler.pas - JCUIScaler 1.0

  JCUIScaler is a deterministic UI scaling system for Lazarus/FPC.
  Source-level compatible with Delphi VCL (unofficial, manual integration only;
  see HISTORY.txt for limitations).
  It preserves an object model operating on the stack and provides deterministic
  scaling based on recorded original control dimensions.
}

unit JCUIScaler;

{$IFDEF FPC}
  {$mode objfpc}{$H+}
{$ENDIF}

interface

uses
  Classes, SysUtils, Math, Controls, Forms, Graphics, ExtCtrls, ComCtrls,
  Grids, DBGrids, StdCtrls;

const
  // Minimum form size below which scaling is suppressed
  MIN_FORM_WIDTH = 200;
  MIN_FORM_HEIGHT = 200;

  // Set this bit in a control's Tag to enable automatic BorderSpacing scaling.
  // Example: MyPanel.Tag := MyPanel.Tag or JCSCALER_BORDER_TAG;
  // Applies to TWinControl descendants only. LCL only: ignored under Delphi.
  JCSCALER_BORDER_TAG = $10000000;

type

  TDBGridOrig = record
    Grid: TDBGrid;
    ColWidths: array of integer;
    OrigGridWidth: integer;
  end;

  TStringGridOrig = record
    Grid: TStringGrid;
    ColWidths: array of integer;
    OrigGridWidth: integer;
  end;

  TCtrlOrig = record
    Ctrl: TControl;
    OrigLeft: integer;
    OrigTop: integer;
    OrigWidth: integer;
    OrigHeight: integer;
    OrigFontSize: integer;
  end;

  TListViewOrig = record
    LV: TListView;
    ColWidths: array of integer;
    OrigWidth: integer;
    OrigFontSize: integer;
  end;

  TTreeViewOrig = record
    TV: TTreeView;
    OrigItemHeight: integer;
    OrigIndent: integer;
    OrigFontSize: integer;
  end;

  TStatusBarOrig = record
    SB: TStatusBar;
    PanelWidths: array of integer;
    OrigHeight: integer;
  end;

  TGroupBoxOrig = record
    GB: TGroupBox;
    OrigCaptionOffset: integer; // best-effort, may be 0 if not available
    OrigFontSize: integer;
  end;

  TSplitterOrig = record
    S: TSplitter;
    OrigWidth: integer;
    OrigHeight: integer;
  end;

  TBorderOrig = record
    Ctrl: TControl;
    Left, Top, Right, Bottom: integer; // original BorderSpacing values
  end;

  TJCUIScaler = object

  private
    FForm: TForm;

    // Original form dimensions
    FFirstShow: boolean;
    FormOriginalWidth: integer;
    FormOriginalHeight: integer;
    FormOriginalLeft: integer;
    FormOriginalTop: integer;

    FLastWindowState: TWindowState;
    FLastMaxWidth: integer;
    FLastMaxHeight: integer;

    // Skip bevel scaling on TPanel
    FSkipBevels: boolean;

    // GridLastWOffset: correction applied to the last grid column width.
    // Normally 0. Can be set manually if a specific widgetset or DPI configuration
    // causes a consistent 1-2px overflow in the last column.
    // Retained for cross-platform safety — do not remove.
    GridLastWOffset: integer;

    // Reference model arrays
    DBGrids: array of TDBGridOrig;
    StrGrids: array of TStringGridOrig;
    CtrlOrigs: array of TCtrlOrig;
    ListViews: array of TListViewOrig;
    TreeViews: array of TTreeViewOrig;
    StatusBars: array of TStatusBarOrig;
    GroupBoxes: array of TGroupBoxOrig;
    Splitters: array of TSplitterOrig;
    BorderOrigs: array of TBorderOrig;

    FResetOnShow: boolean;

    procedure CaptureOriginals;
    procedure ScaleForm;
    procedure ScaleControl(ctrl: TControl; overallScaleX, overallScaleY: double);
    procedure ApplyControlExceptions(ctrl: TControl;
      overallScaleX, overallScaleY: double);

    function LocalRound(const V: double): integer;

    function FindDBGridOrigIndex(g: TDBGrid): integer;
    function FindStrGridOrigIndex(g: TStringGrid): integer;
    function FindCtrlOrigIndex(c: TControl): integer;
    function FindListViewOrigIndex(lv: TListView): integer;
    function FindStatusBarOrigIndex(sb: TStatusBar): integer;
    function FindTreeViewOrigIndex(tv: TTreeView): integer;
  public
    procedure ScalerInit(AForm: TForm);
    procedure ScalerOnShow;
    procedure ScalerOnResize;
    procedure RestoreInitialScale;
    property SkipBevelScaling: boolean read FSkipBevels write FSkipBevels;
    property ResetOnShow: boolean read FResetOnShow write FResetOnShow;

  end;

implementation

type
  // Access class: TControl.Font is public in LCL but protected in VCL.
  // Casting through this class compiles identically on both.
  TJCControlAccess = class(TControl);

procedure TJCUIScaler.ScalerInit(AForm: TForm);
begin
  FForm := AForm;
  FSkipBevels := True;
  FResetOnShow := False;
  GridLastWOffset := 0;
  FFirstShow := True;
end;

procedure TJCUIScaler.ScalerOnShow;
begin
  if FFirstShow then
  begin
    FFirstShow := True;
    CaptureOriginals;
  end
  else if FResetOnShow then
    RestoreInitialScale;
  // Reserved for future extensions of the show-time behaviour.
  if FFirstShow then FFirstShow := False;
end;

procedure TJCUIScaler.ScalerOnResize;
begin
  if FFirstShow then Exit;
  FLastMaxWidth := FForm.Width;
  FLastMaxHeight := FForm.Height;
  FLastWindowState := FForm.WindowState;
  ScaleForm;
end;

{==============================================================================}
{  SCALEFORM and SCALECONTROL — MAIN SCALING (bounds + recursion)              }
{==============================================================================}

function TJCUIScaler.LocalRound(const V: double): integer;
begin
  // Deterministic rounding: always rounds 0.5 up (towards +infinity),
  // regardless of rounding mode. Used consistently across all scaling
  // calculations instead of built-in Round, which uses banker's rounding and
  // may produce asymmetric pixel results.
  // Floor instead of Trunc: identical for V >= 0, correct for negative values
  // (e.g. Left/Top of controls inside a scrolled TScrollBox).
  Result := Floor(V + 0.5);
end;

procedure TJCUIScaler.ScaleForm;
var
  overallScaleX, overallScaleY: double;
  i: integer;
begin
  // Safety: avoid division by zero if originals not captured
  if (FormOriginalWidth <= 0) or (FormOriginalHeight <= 0) then Exit;

  // Don't scale when window is extremely small
  if (FForm.Width < MIN_FORM_WIDTH) or (FForm.Height < MIN_FORM_HEIGHT) then
    Exit;

  overallScaleX := FForm.Width / FormOriginalWidth;
  overallScaleY := FForm.Height / FormOriginalHeight;

  for i := 0 to FForm.ControlCount - 1 do
    ScaleControl(FForm.Controls[i], overallScaleX, overallScaleY);
end;

procedure TJCUIScaler.ScaleControl(ctrl: TControl; overallScaleX, overallScaleY: double);
var
  coIdx: integer;
  co: TCtrlOrig;
  newL, newT, newW, newH: integer;
  SavedBevel: integer;
  SavedBorder: integer;
  i: integer;
begin
  // Explicit initialisation (initialised local variables in a var section
  // are an FPC extension, not supported by Delphi).
  SavedBevel := 0;
  SavedBorder := 0;

  if ctrl = nil then Exit;

  if (ctrl is TToolButton) then
    Exit;

  coIdx := FindCtrlOrigIndex(ctrl);
  if coIdx < 0 then Exit;
  co := CtrlOrigs[coIdx];

  // Calculate new bounds from reference model (never from current state)
  newL := LocalRound(co.OrigLeft * overallScaleX);
  newT := LocalRound(co.OrigTop * overallScaleY);
  newW := LocalRound(co.OrigWidth * overallScaleX);
  newH := LocalRound(co.OrigHeight * overallScaleY);

  // Save bevel/border before SetBounds modifies the panel visually
  if ctrl is TPanel then
  begin
    SavedBevel := TPanel(ctrl).BevelWidth;
    SavedBorder := TPanel(ctrl).BorderWidth;
  end;

  // Main scaling — single entry point for all controls
  ctrl.SetBounds(newL, newT, newW, newH);

  // Restore bevel and border if flag is active
  if FSkipBevels and (ctrl is TPanel) then
  begin
    TPanel(ctrl).BevelWidth := SavedBevel;
    TPanel(ctrl).BorderWidth := SavedBorder;
  end;

  // Recurse into children (main scaling pass)
  if ctrl is TWinControl then
    for i := 0 to TWinControl(ctrl).ControlCount - 1 do
      ScaleControl(TWinControl(ctrl).Controls[i], overallScaleX, overallScaleY);

  // Apply per-type exceptions after main scaling and recursion
  ApplyControlExceptions(ctrl, overallScaleX, overallScaleY);
end;

procedure TJCUIScaler.RestoreInitialScale;
var
  ScaleBackX: double;
  ScaleBackY: double;
  CurrentWidth: integer;
  CurrentHeight: integer;
   i: integer;
  NeedReset: boolean;
begin

  if FFirstShow then Exit;

  // Guard: detect a call made right after leaving wsMaximized, while the form
  // still reports the maximized size.
   if (FForm.WindowState = wsNormal) and (FLastWindowState = wsMaximized) and
      (FForm.Width = FLastMaxWidth) and (FForm.Height = FLastMaxHeight) then
   begin
     FForm.WindowState := wsMaximized;
     FForm.WindowState := wsNormal;
     FLastWindowState := wsNormal;
   end;

  CurrentWidth := FForm.Width;
  CurrentHeight := FForm.Height;


  if (CurrentWidth <= 0) or (CurrentHeight <= 0) then
    Exit;

  // Do nothing if the form is already at its original size and position
  NeedReset :=
    (CurrentWidth <> FormOriginalWidth) or (CurrentHeight <> FormOriginalHeight) or
    (FForm.Left <> FormOriginalLeft) or (FForm.Top <> FormOriginalTop);

  if not NeedReset then
    Exit;

  // Brute-force proportional restore (design decision F-01): the form is set
  // back to its original bounds and the current bounds of every control in
  // the reference model (CtrlOrigs) are scaled back by the inverse ratio.
  // Controls outside the model are not modified directly. The subsequent
  // OnResize -> ScalerOnResize recomputes all model controls at scale 1, so
  // the final state matches the reference model (verified on Windows and
  // GTK2). Font size is restored from the reference model where available,
  // to prepare for future font scaling support.
  ScaleBackX := FormOriginalWidth / CurrentWidth;
  ScaleBackY := FormOriginalHeight / CurrentHeight;

  FForm.SetBounds(
    FormOriginalLeft,
    FormOriginalTop,
    FormOriginalWidth,
    FormOriginalHeight
    );

  for i := 0 to High(CtrlOrigs) do
  begin
    if not Assigned(CtrlOrigs[i].Ctrl) then
      Continue;
    CtrlOrigs[i].Ctrl.Left := LocalRound(CtrlOrigs[i].Ctrl.Left * ScaleBackX);
    CtrlOrigs[i].Ctrl.Top := LocalRound(CtrlOrigs[i].Ctrl.Top * ScaleBackY);
    CtrlOrigs[i].Ctrl.Width := LocalRound(CtrlOrigs[i].Ctrl.Width * ScaleBackX);
    CtrlOrigs[i].Ctrl.Height := LocalRound(CtrlOrigs[i].Ctrl.Height * ScaleBackY);
    // Restore original font size where recorded.
    // Has no visible effect in 1.0 (font scaling not yet active),
    // but ensures correctness once font scaling is implemented.
    if CtrlOrigs[i].OrigFontSize > 0 then
      TJCControlAccess(CtrlOrigs[i].Ctrl).Font.Size := CtrlOrigs[i].OrigFontSize;
  end;
  FForm.Repaint;
end;

(*  Implementation map — included sections ({$I} includes, part of this unit):

  JCUIScaler.capture.inc   - CaptureOriginals: builds the reference model
  JCUIScaler.controls.inc  - ApplyControlExceptions: per-type scaling exceptions
  JCUIScaler.find.inc      - Find*OrigIndex helper functions

  Included here to preserve direct access to private fields of TJCUIScaler.
*)
{$I JCUIScaler.capture.inc}
{$I JCUIScaler.controls.inc}
{$I JCUIScaler.find.inc}

end.
