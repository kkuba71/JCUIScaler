{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit jcuiscaler_dsgn;

{$warn 5023 off : no warning about unused units}
interface

uses
  JCUIScalerReg, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('JCUIScalerReg', @JCUIScalerReg.Register);
end;

initialization
  RegisterPackage('jcuiscaler_dsgn', @Register);
end.
