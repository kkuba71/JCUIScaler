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
  Find* helper functions — reference model lookups.
  All functions perform linear search by pointer comparison and return
  the array index, or -1 if not found.
}

function TJCUIScaler.FindDBGridOrigIndex(g: TDBGrid): integer;
var
  i: integer;
begin
  Result := -1;
  for i := 0 to High(DBGrids) do
    if DBGrids[i].Grid = g then Exit(i);
end;

function TJCUIScaler.FindStrGridOrigIndex(g: TStringGrid): integer;
var
  i: integer;
begin
  Result := -1;
  for i := 0 to High(StrGrids) do
    if StrGrids[i].Grid = g then Exit(i);
end;

function TJCUIScaler.FindCtrlOrigIndex(c: TControl): integer;
var
  i: integer;
begin
  Result := -1;
  for i := 0 to High(CtrlOrigs) do
    if CtrlOrigs[i].Ctrl = c then Exit(i);
end;

function TJCUIScaler.FindListViewOrigIndex(lv: TListView): integer;
var
  i: integer;
begin
  Result := -1;
  for i := 0 to High(ListViews) do
    if Assigned(ListViews[i].LV) and (ListViews[i].LV = lv) then Exit(i);
end;

function TJCUIScaler.FindStatusBarOrigIndex(sb: TStatusBar): integer;
var
  i: integer;
begin
  Result := -1;
  for i := 0 to High(StatusBars) do
    if Assigned(StatusBars[i].SB) and (StatusBars[i].SB = sb) then Exit(i);
end;

function TJCUIScaler.FindTreeViewOrigIndex(tv: TTreeView): integer;
var
  i: integer;
begin
  Result := -1;
  for i := 0 to High(TreeViews) do
    if Assigned(TreeViews[i].TV) and (TreeViews[i].TV = tv) then Exit(i);
end;
