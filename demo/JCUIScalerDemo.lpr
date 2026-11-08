{
  JCUIScaler - deterministic UI scaling for Lazarus LCL
  Copyright (c) 2025-2026 Jakub Cebula, Kraków

  This file is part of JCUIScaler.
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.

  The copyright notice above and the name of the original author must not
  be removed from this file or from any modified version of it.
}

program JCUIScalerDemo;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, datetimectrls, JCUIScalerDemoMain, JCUIScalerTestForm;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TDemoMainForm, DemoMainForm);
  Application.CreateForm(TDemoTestForm, DemoTestForm);
  Application.Run;
end.
