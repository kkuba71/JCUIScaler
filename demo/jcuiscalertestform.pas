{
  JCUIScaler - deterministic UI scaling for Lazarus LCL
  Copyright (c) 2025-2026 Jakub Cebula, Kraków

  This file is part of JCUIScaler.
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.

  The copyright notice above and the name of the original author must not
  be removed from this file or from any modified version of it.
}

unit JCUIScalerTestForm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Grids, JCUIScaler;

type

  { TDemoTestForm }

  TDemoTestForm = class(TForm)
    Button1: TButton;
    PanelBorder: TPanel;
    StringGrid1: TStringGrid;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FScaler: TJCUIScaler;
  end;

var
  DemoTestForm: TDemoTestForm;

implementation

{$R *.lfm}

{ TDemoTestForm }

procedure TDemoTestForm.FormCreate(Sender: TObject);
begin
  // PanelBorder is aligned to the bottom with BorderSpacing.
  // Setting JCSCALER_BORDER_TAG makes the scaler scale its BorderSpacing too.
  PanelBorder.Tag := PanelBorder.Tag or JCSCALER_BORDER_TAG;

  FScaler.ScalerInit(Self);
  FScaler.ResetOnShow := True;
end;

procedure TDemoTestForm.FormShow(Sender: TObject);
begin
  FScaler.ScalerOnShow;
end;

procedure TDemoTestForm.FormResize(Sender: TObject);
begin
  FScaler.ScalerOnResize;
end;

procedure TDemoTestForm.Button1Click(Sender: TObject);
begin
  Close;
end;

end.
