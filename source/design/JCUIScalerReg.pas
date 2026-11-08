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
  JCUIScalerReg.pas - JCUIScaler 1.0
  Design-time registration of TJCScaler (Lazarus IDE).
}
unit JCUIScalerReg;

{$mode objfpc}{$H+}

interface

uses
  Classes, JCUIScalerComponent;

procedure Register;

implementation

{$R jcuiscaler_icons.res}

procedure Register;
begin
  RegisterComponents('JCUI', [TJCScaler]);
end;

end.
