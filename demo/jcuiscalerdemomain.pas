{
  JCUIScaler - deterministic UI scaling for Lazarus LCL
  Copyright (c) 2025-2026 Jakub Cebula, Kraków

  This file is part of JCUIScaler.
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.

  The copyright notice above and the name of the original author must not
  be removed from this file or from any modified version of it.
}

unit JCUIScalerDemoMain;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Forms, Controls, Graphics, Dialogs,
  ComCtrls, Grids, StdCtrls, ExtCtrls, DateTimePicker,
  JCUIScaler;

type

  { TDemoMainForm }

  TDemoMainForm = class(TForm)
    ButtonFormTest: TButton;
    PageControl1: TPageControl;
    Panel1: TPanel;
    TabSheet1: TTabSheet;
    StringGrid1: TStringGrid;
    TabSheet2: TTabSheet;
    TreeView1: TTreeView;
    ListView1: TListView;
    TabSheet3: TTabSheet;
    GroupBox1: TGroupBox;
    Button1: TButton;
    CheckBox1: TCheckBox;
    RadioGroup1: TRadioGroup;
    ComboBox1: TComboBox;
    DateTimePicker1: TDateTimePicker;
    Edit1: TEdit;
    StatusBar1: TStatusBar;

    procedure ButtonFormTestClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);

  private
    FScaler: TJCUIScaler;
    procedure InitControls;
    procedure FillListAndTree;
  end;

var
  DemoMainForm: TDemoMainForm;

implementation

{$R *.lfm}

uses
  JCUIScalerTestForm;

{ -------------------------------------------- }
{ JCUIScaler integration: three calls          }
{ -------------------------------------------- }

procedure TDemoMainForm.FormCreate(Sender: TObject);
begin
  Caption := 'JCUIScaler Demo';
  InitControls;
  FScaler.ScalerInit(Self);
  // Properties must be set after ScalerInit (it resets them to defaults).
  FScaler.ResetOnShow := True;
end;

procedure TDemoMainForm.FormShow(Sender: TObject);
begin
  PageControl1.ActivePage := TabSheet1;
  // First call builds the reference model; mandatory.
  FScaler.ScalerOnShow;
end;

procedure TDemoMainForm.FormResize(Sender: TObject);
begin
  FScaler.ScalerOnResize;
end;

procedure TDemoMainForm.ButtonFormTestClick(Sender: TObject);
begin
  DemoTestForm.ShowModal;
end;

{ -------------------------------------------- }
{ Fill TreeView and ListView                   }
{ -------------------------------------------- }
procedure TDemoMainForm.FillListAndTree;
var
  i, j: Integer;
  li: TListItem;
  root, child: TTreeNode;
begin
  // ListView
  ListView1.Items.BeginUpdate;
  try
    ListView1.Items.Clear;
    for i := 1 to 20 do
    begin
      li := ListView1.Items.Add;
      li.Caption := IntToStr(i);
      li.SubItems.Add(Format('Lorem ipsum item %d — sample description', [i]));
    end;
  finally
    ListView1.Items.EndUpdate;
  end;

  // TreeView (3 levels)
  TreeView1.Items.BeginUpdate;
  try
    TreeView1.Items.Clear;
    for i := 1 to 6 do
    begin
      root := TreeView1.Items.Add(nil, Format('Chapter %d — Lorem', [i]));
      for j := 1 to 3 do
      begin
        child := TreeView1.Items.AddChild(root, Format('Section %d.%d — Ipsum', [i, j]));
        TreeView1.Items.AddChild(child, Format('Item %d.%d.%d — Dolor', [i, j, 1]));
      end;
    end;
    TreeView1.FullExpand;
  finally
    TreeView1.Items.EndUpdate;
  end;
end;

{ -------------------------------------------- }
{ Initialize visual controls                   }
{ -------------------------------------------- }
procedure TDemoMainForm.InitControls;
var
  i: Integer;
begin
  // StringGrid (Columns[] mode)
  for i := 1 to StringGrid1.RowCount - 1 do
  begin
    StringGrid1.Cells[0,i] := Format('Row %d — Lorem', [i]);
    StringGrid1.Cells[1,i] := Format('Row %d — Ipsum', [i]);
    StringGrid1.Cells[2,i] := Format('Row %d — Dolor', [i]);
    StringGrid1.Cells[3,i] := Format('Row %d — Sit', [i]);
    StringGrid1.Cells[4,i] := Format('Row %d — Amet', [i]);
  end;

  // Tab 3 controls
  GroupBox1.Caption := 'GroupBox — Lorem ipsum';
  Button1.Caption := 'Action — Lorem';
  CheckBox1.Caption := 'Option — Ipsum';

  RadioGroup1.Caption := 'Choice — Dolor';
  RadioGroup1.Items.Clear;
  RadioGroup1.Items.Add('Option 1');
  RadioGroup1.Items.Add('Option 2');
  RadioGroup1.Items.Add('Option 3');

  ComboBox1.Items.Clear;
  ComboBox1.Items.Add('Item A — Lorem');
  ComboBox1.Items.Add('Item B — Ipsum');
  ComboBox1.Items.Add('Item C — Dolor');
  ComboBox1.ItemIndex := 0;

  Edit1.Text := 'Sample text — Lorem ipsum';

  // StatusBar with panels (exercises panel width scaling)
  StatusBar1.Panels[0].Text := 'Panel 1 — Lorem';
  StatusBar1.Panels[1].Text := 'Panel 2 — Ipsum';
  StatusBar1.Panels[2].Text := 'Status: JCUIScaler demo';

  // Fill tree/list
  FillListAndTree;
end;

end.
