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
  JCUIScaler.controls.inc — ApplyControlExceptions
  Per-type scaling exceptions for controls with internal structure.
  Font scaling is not active in 1.0.
}

{==============================================================================}
{  APPLY CONTROL EXCEPTIONS                                                    }
{==============================================================================}

procedure TJCUIScaler.ApplyControlExceptions(ctrl: TControl;
  overallScaleX, overallScaleY: double);
var
  i, j: integer;
  totalWidth: integer;
  leftPos, rightPos: integer;
  newW, cumOrig: integer;
  scaleFactor: double;
  lastW, sumNew: integer;
  cIdx: integer;

  db: TDBGrid;
  dg: TDBGridOrig;

  sg: TStringGrid;
  so: TStringGridOrig;

  lv: TListView;
  lvRec: TListViewOrig;

  tv: TTreeView;

  sb: TStatusBar;
  sbRec: TStatusBarOrig;

  sp: TSplitter;

begin
  if ctrl = nil then Exit;

  {---------------- BORDERSPACING (controls tagged with JCSCALER_BORDER_TAG) ----------------}
  // Applied first and without Exit, so that it works for every tagged control,
  // including the types handled below (each of which ends with Exit).
  // Grids/ListView/StatusBar then see the final client width.
  // LCL only: VCL has no BorderSpacing.
  {$IFDEF FPC}
  for i := 0 to High(BorderOrigs) do
    if Assigned(BorderOrigs[i].Ctrl) and (BorderOrigs[i].Ctrl = ctrl) then
    begin
      ctrl.BorderSpacing.Left   := LocalRound(BorderOrigs[i].Left   * overallScaleX);
      ctrl.BorderSpacing.Top    := LocalRound(BorderOrigs[i].Top    * overallScaleY);
      ctrl.BorderSpacing.Right  := LocalRound(BorderOrigs[i].Right  * overallScaleX);
      ctrl.BorderSpacing.Bottom := LocalRound(BorderOrigs[i].Bottom * overallScaleY);
      Break;
    end;
  {$ENDIF}

  {---------------- DBGRID (proportional + last-column correction) ----------------}
  if ctrl is TDBGrid then
  begin
    db   := TDBGrid(ctrl);
    cIdx := FindDBGridOrigIndex(db);

    if cIdx >= 0 then
    begin
      dg := DBGrids[cIdx];

      if (dg.OrigGridWidth > 0) and (db.Columns.Count > 0) then
      begin
        totalWidth  := db.ClientRect.Right - db.ClientRect.Left;
        scaleFactor := totalWidth / dg.OrigGridWidth;
        sumNew      := 0;
        newW        := 0;

        for i := 0 to db.Columns.Count - 1 do
        begin
          newW := LocalRound(dg.ColWidths[i] * scaleFactor);
          db.Columns[i].Width := Max(1, newW);
          sumNew := sumNew + db.Columns[i].Width;
        end;

        // Last column correction: absorb rounding remainder
        lastW := newW + (totalWidth - sumNew);
        if Max(1, lastW) - GridLastWOffset > 0 then
          db.Columns[db.Columns.Count - 1].Width := Max(1, lastW) - GridLastWOffset
        else
          db.Columns[db.Columns.Count - 1].Width := Max(1, lastW);
      end;
    end;

    Exit;
  end;

  {---------------- STRINGGRID (proportional + last-column correction) ----------------}
  if ctrl is TStringGrid then
  begin
    sg   := TStringGrid(ctrl);
    cIdx := FindStrGridOrigIndex(sg);

    if (cIdx >= 0) and (sg.ColCount > 0) then
    begin
      so := StrGrids[cIdx];

      if so.OrigGridWidth > 0 then
      begin
        totalWidth  := sg.ClientRect.Right - sg.ClientRect.Left;
        scaleFactor := totalWidth / so.OrigGridWidth;
        sumNew      := 0;
        newW        := 0;

        for i := 0 to sg.ColCount - 1 do
        begin
          newW := LocalRound(so.ColWidths[i] * scaleFactor);
          sg.ColWidths[i] := Max(1, newW);
          sumNew := sumNew + sg.ColWidths[i];
        end;

        // Last column correction: absorb rounding remainder
        lastW := newW + (totalWidth - sumNew);
        if Max(1, lastW) - GridLastWOffset > 0 then
          sg.ColWidths[sg.ColCount - 1] := Max(1, lastW) - GridLastWOffset
        else
          sg.ColWidths[sg.ColCount - 1] := Max(1, lastW);
      end;
    end;

    Exit;
  end;

  {---------------- LISTVIEW (cumulative column scaling) ----------------}
  if ctrl is TListView then
  begin
    lv   := TListView(ctrl);
    cIdx := FindListViewOrigIndex(lv);

    if (cIdx >= 0) and (lv.Columns.Count > 0) then
    begin
      lvRec := ListViews[cIdx];

      if lvRec.OrigWidth > 0 then
      begin
        scaleFactor := lv.ClientWidth / lvRec.OrigWidth;
        totalWidth  := lv.ClientWidth;
        cumOrig     := 0;

        for j := 0 to High(lvRec.ColWidths) do
        begin
          if j >= lv.Columns.Count then Break;
          cumOrig := cumOrig + lvRec.ColWidths[j];

          leftPos := LocalRound((cumOrig - lvRec.ColWidths[j]) * scaleFactor);
          if j < lv.Columns.Count - 1 then
          begin
            rightPos := LocalRound(cumOrig * scaleFactor);
            lv.Columns[j].Width := Max(1, rightPos - leftPos);
          end
          else
            lv.Columns[j].Width := Max(1, totalWidth - leftPos);
        end;
      end;
    end;

    Exit;
  end;

  {---------------- TREEVIEW (Indent; DefaultItemHeight on GTK2 only) ----------------}
  if ctrl is TTreeView then
  begin
    tv   := TTreeView(ctrl);
    cIdx := FindTreeViewOrigIndex(tv);

    if cIdx >= 0 then
    begin
      try
        if TreeViews[cIdx].OrigIndent > 0 then
          tv.Indent := Max(0, LocalRound(TreeViews[cIdx].OrigIndent * overallScaleX));
      except
        // Indent assignment may fail on some widgetset configurations.
        // Silently ignored — scaling continues without it.
      end;

      {$IFDEF LCLGTK2}
      try
        // LCL TTreeView exposes DefaultItemHeight (there is no ItemHeight
        // property; the previous name did not compile under LCLGTK2).
        if TreeViews[cIdx].OrigItemHeight > 0 then
          tv.DefaultItemHeight := Max(1, LocalRound(TreeViews[cIdx].OrigItemHeight * overallScaleY));
      except
        // DefaultItemHeight may not be honoured on all GTK2 configurations.
        // Silently ignored — scaling continues without it.
      end;
      {$ENDIF}
    end;

    Exit;
  end;

  {---------------- STATUSBAR (cumulative panel scaling) ----------------}
  if ctrl is TStatusBar then
  begin
    sb   := TStatusBar(ctrl);
    cIdx := FindStatusBarOrigIndex(sb);

    if (cIdx >= 0) and (sb.Panels.Count > 0) then
    begin
      sbRec := StatusBars[cIdx];
      i     := FindCtrlOrigIndex(sb);

      if (i >= 0) and (CtrlOrigs[i].OrigWidth > 0) then
      begin
        scaleFactor := sb.ClientWidth / CtrlOrigs[i].OrigWidth;
        totalWidth  := sb.ClientWidth;
        cumOrig     := 0;

        for j := 0 to High(sbRec.PanelWidths) do
        begin
          if j >= sb.Panels.Count then Break;
          cumOrig := cumOrig + sbRec.PanelWidths[j];

          leftPos := LocalRound((cumOrig - sbRec.PanelWidths[j]) * scaleFactor);
          if j < sb.Panels.Count - 1 then
          begin
            rightPos := LocalRound(cumOrig * scaleFactor);
            sb.Panels[j].Width := Max(1, rightPos - leftPos);
          end
          else
            sb.Panels[j].Width := Max(1, totalWidth - leftPos);
        end;
      end;
    end;

    Exit;
  end;

  {---------------- SPLITTER ----------------}
  if ctrl is TSplitter then
  begin
    sp   := TSplitter(ctrl);
    cIdx := -1;

    for i := 0 to High(Splitters) do
      if Assigned(Splitters[i].S) and (Splitters[i].S = sp) then
      begin
        cIdx := i;
        Break;
      end;

    if cIdx >= 0 then
    begin
      if sp.Align in [alLeft, alRight] then
        sp.Width  := Max(1, LocalRound(Splitters[cIdx].OrigWidth  * overallScaleX))
      else if sp.Align in [alTop, alBottom] then
        sp.Height := Max(1, LocalRound(Splitters[cIdx].OrigHeight * overallScaleY));
    end;

    Exit;
  end;
end;
