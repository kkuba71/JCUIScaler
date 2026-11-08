{
  JCUIScaler - deterministic UI scaling for Lazarus LCL
  Copyright (c) 2025-2026 Jakub Cebula, Kraków

  This file is part of JCUIScaler.
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.

  The copyright notice above and the name of the original author must not
  be removed from this file or from any modified version of it.
}

{ This file is an include used by JCUIScaler.pas.
  Do not compile standalone. Do not modify structure. }

{
  JCUIScaler.capture.inc — CaptureOriginals
  Builds the reference model using iterative DFS (no recursion).
}

procedure TJCUIScaler.CaptureOriginals;
const
  MAX_CONTROL_COUNT = 8192;
  INITIAL_STACK_SIZE = 256;
type
  TWinControlStack = array of TWinControl;
var
  Stack: TWinControlStack;
  Top: integer;
  Root: TWinControl;
  Ctrl: TControl;
  i, j, k: integer;
  EstimatedCount: integer;

  dg: TDBGridOrig;
  sg: TStringGridOrig;
  co: TCtrlOrig;
  lvRec: TListViewOrig;
  tvRec: TTreeViewOrig;
  sbRec: TStatusBarOrig;
  gbRec: TGroupBoxOrig;
  spRec: TSplitterOrig;
  bRec: TBorderOrig;

  procedure ZeroRecs;
  begin
    SetLength(Stack, 0);
    dg := Default(TDBGridOrig);
    sg := Default(TStringGridOrig);
    co := Default(TCtrlOrig);
    lvRec := Default(TListViewOrig);
    tvRec := Default(TTreeViewOrig);
    sbRec := Default(TStatusBarOrig);
    gbRec := Default(TGroupBoxOrig);
    spRec := Default(TSplitterOrig);
    bRec := Default(TBorderOrig);
  end;

  procedure AppendDBGrid(const R: TDBGridOrig);
  var
    idx: integer;
  begin
    idx := Length(DBGrids);
    SetLength(DBGrids, idx + 1); // ALLOCATION_OK
    DBGrids[idx] := R;
  end;

  procedure AppendStrGrid(const R: TStringGridOrig);
  var
    idx: integer;
  begin
    idx := Length(StrGrids);
    SetLength(StrGrids, idx + 1); // ALLOCATION_OK
    StrGrids[idx] := R;
  end;

  procedure AppendCtrlOrig(const R: TCtrlOrig);
  var
    idx: integer;
  begin
    idx := Length(CtrlOrigs);
    SetLength(CtrlOrigs, idx + 1); // ALLOCATION_OK
    CtrlOrigs[idx] := R;
  end;

  procedure AppendListView(const R: TListViewOrig);
  var
    idx: integer;
  begin
    idx := Length(ListViews);
    SetLength(ListViews, idx + 1); // ALLOCATION_OK
    ListViews[idx] := R;
  end;

  procedure AppendTreeView(const R: TTreeViewOrig);
  var
    idx: integer;
  begin
    idx := Length(TreeViews);
    SetLength(TreeViews, idx + 1); // ALLOCATION_OK
    TreeViews[idx] := R;
  end;

  procedure AppendStatusBar(const R: TStatusBarOrig);
  var
    idx: integer;
  begin
    idx := Length(StatusBars);
    SetLength(StatusBars, idx + 1); // ALLOCATION_OK
    StatusBars[idx] := R;
  end;

  procedure AppendGroupBox(const R: TGroupBoxOrig);
  var
    idx: integer;
  begin
    idx := Length(GroupBoxes);
    SetLength(GroupBoxes, idx + 1); // ALLOCATION_OK
    GroupBoxes[idx] := R;
  end;

  procedure AppendSplitter(const R: TSplitterOrig);
  var
    idx: integer;
  begin
    idx := Length(Splitters);
    SetLength(Splitters, idx + 1); // ALLOCATION_OK
    Splitters[idx] := R;
  end;

  procedure AppendBorder(const R: TBorderOrig);
  var
    idx: integer;
  begin
    idx := Length(BorderOrigs);
    SetLength(BorderOrigs, idx + 1); // ALLOCATION_OK
    BorderOrigs[idx] := R;
  end;

begin
  // Clear all reference arrays
  SetLength(DBGrids, 0);
  SetLength(StrGrids, 0);
  SetLength(CtrlOrigs, 0);
  SetLength(ListViews, 0);
  SetLength(TreeViews, 0);
  SetLength(StatusBars, 0);
  SetLength(GroupBoxes, 0);
  SetLength(Splitters, 0);
  SetLength(BorderOrigs, 0);

  if not Assigned(FForm) then Exit;

  FormOriginalWidth := FForm.Width;
  FormOriginalHeight := FForm.Height;
  FormOriginalLeft := FForm.Left;
  FormOriginalTop := FForm.Top;

  ZeroRecs;

  // Initialise DFS stack
  SetLength(Stack, INITIAL_STACK_SIZE);
  Top := 0;
  Stack[0] := FForm;

  EstimatedCount := 0;

  while Top >= 0 do
  begin
    Root := Stack[Top];
    Dec(Top);

    if Root = nil then Continue;

    // --- TDBGrid ---
    if Root is TDBGrid then
    begin
      dg := Default(TDBGridOrig);
      dg.Grid := TDBGrid(Root);
      SetLength(dg.ColWidths, dg.Grid.Columns.Count);
      for k := 0 to dg.Grid.Columns.Count - 1 do
        dg.ColWidths[k] := dg.Grid.Columns[k].Width;
      dg.OrigGridWidth := dg.Grid.ClientRect.Right - dg.Grid.ClientRect.Left;
      AppendDBGrid(dg);
    end;

    // --- TStringGrid ---
    if Root is TStringGrid then
    begin
      sg := Default(TStringGridOrig);
      sg.Grid := TStringGrid(Root);
      SetLength(sg.ColWidths, sg.Grid.ColCount);
      for k := 0 to sg.Grid.ColCount - 1 do
        sg.ColWidths[k] := sg.Grid.ColWidths[k];
      sg.OrigGridWidth := sg.Grid.ClientRect.Right - sg.Grid.ClientRect.Left;
      AppendStrGrid(sg);
    end;

    // --- TListView ---
    if Root is TListView then
    begin
      lvRec := Default(TListViewOrig);
      lvRec.LV := TListView(Root);
      SetLength(lvRec.ColWidths, lvRec.LV.Columns.Count);
      for k := 0 to lvRec.LV.Columns.Count - 1 do
        lvRec.ColWidths[k] := lvRec.LV.Columns[k].Width;
      lvRec.OrigWidth := lvRec.LV.Width;
      if Assigned(lvRec.LV.Font) then
        lvRec.OrigFontSize := lvRec.LV.Font.Size;
      AppendListView(lvRec);
    end;

    // --- TTreeView ---
    // FS3: OrigItemHeight and OrigIndent are intentionally stored as 0.
    // TreeView height/layout scaling to be implemented deterministically
    // in a future version. OrigFontSize recorded for future font scaling.
    if Root is TTreeView then
    begin
      tvRec := Default(TTreeViewOrig);
      tvRec.TV := TTreeView(Root);
      tvRec.OrigItemHeight := 0;
      tvRec.OrigIndent := 0;
      if Assigned(tvRec.TV.Font) then
        tvRec.OrigFontSize := tvRec.TV.Font.Size;
      AppendTreeView(tvRec);
    end;

    // --- TStatusBar ---
    if Root is TStatusBar then
    begin
      sbRec := Default(TStatusBarOrig);
      sbRec.SB := TStatusBar(Root);
      SetLength(sbRec.PanelWidths, sbRec.SB.Panels.Count);
      for k := 0 to sbRec.SB.Panels.Count - 1 do
        sbRec.PanelWidths[k] := sbRec.SB.Panels[k].Width;
      sbRec.OrigHeight := sbRec.SB.Height;
      AppendStatusBar(sbRec);
    end;

    // --- TGroupBox ---
    // OrigFontSize recorded for future font scaling support.
    // OrigCaptionOffset is 0 (best-effort; not available cross-widgetset).
    // GroupBox has no active exception handler in ApplyControlExceptions (1.0).
    if Root is TGroupBox then
    begin
      gbRec := Default(TGroupBoxOrig);
      gbRec.GB := TGroupBox(Root);
      if Assigned(gbRec.GB.Font) then
        gbRec.OrigFontSize := gbRec.GB.Font.Size;
      gbRec.OrigCaptionOffset := 0;
      AppendGroupBox(gbRec);
    end;

    // --- TSplitter ---
    // LCL: TSplitter descends from TWinControl and is visited by the DFS.
    // VCL: TSplitter descends from TGraphicControl; the cast to TObject keeps
    // the test valid for the Delphi compiler. Under VCL the condition is never
    // true (the DFS visits TWinControl only), so splitters get the generic
    // bounds scaling there.
    if TObject(Root) is TSplitter then
    begin
      spRec := Default(TSplitterOrig);
      spRec.S := TSplitter(TObject(Root));
      spRec.OrigWidth := spRec.S.Width;
      spRec.OrigHeight := spRec.S.Height;
      AppendSplitter(spRec);
    end;

    // --- Generic TCtrlOrig for all direct children ---
    if Root is TWinControl then
      for i := 0 to Root.ControlCount - 1 do
      begin
        Ctrl := Root.Controls[i];
        if Ctrl = nil then Continue;

        co := Default(TCtrlOrig);
        co.Ctrl := Ctrl;
        co.OrigLeft := Ctrl.Left;
        co.OrigTop := Ctrl.Top;
        co.OrigWidth := Ctrl.Width;
        co.OrigHeight := Ctrl.Height;
        // TJCControlAccess: Font is protected on TControl in VCL.
        if Assigned(TJCControlAccess(Ctrl).Font) then
          co.OrigFontSize := TJCControlAccess(Ctrl).Font.Size;
        AppendCtrlOrig(co);
      end;

    // --- BorderSpacing (controls tagged with JCSCALER_BORDER_TAG) ---
    // Records the original BorderSpacing values (not the control's bounds).
    // Only TWinControl descendants are visited by the DFS, so only those
    // can be tagged. LCL only: VCL has no BorderSpacing.
    {$IFDEF FPC}
    if (Root.Tag and JCSCALER_BORDER_TAG) <> 0 then
    begin
      bRec := Default(TBorderOrig);
      bRec.Ctrl := Root;
      bRec.Left := Root.BorderSpacing.Left;
      bRec.Top := Root.BorderSpacing.Top;
      bRec.Right := Root.BorderSpacing.Right;
      bRec.Bottom := Root.BorderSpacing.Bottom;
      AppendBorder(bRec);
    end;
    {$ENDIF}

    // Push TWinControl children onto the DFS stack
    for j := 0 to Root.ControlCount - 1 do
      if Root.Controls[j] is TWinControl then
      begin
        Inc(Top);
        if Top >= Length(Stack) then
          SetLength(Stack, Length(Stack) + INITIAL_STACK_SIZE);
        Stack[Top] := TWinControl(Root.Controls[j]);
      end;

    Inc(EstimatedCount);
    if EstimatedCount >= MAX_CONTROL_COUNT then Break;
  end;

  SetLength(Stack, 0);
end;
