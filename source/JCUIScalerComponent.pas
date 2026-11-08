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
  JCUIScalerComponent.pas - JCUIScaler 1.0

  TJCScaler: optional IDE integration layer for TJCUIScaler (LCL).
  Drop it on a form; it performs the three standard calls automatically:

    ScalerInit      in Loaded            (after the form has been streamed)
    ScalerOnShow    on every form OnShow (after the user's own OnShow handler)
    ScalerOnResize  on every form resize (after the user's own OnResize handler)

  The component only calls the public methods of TJCUIScaler. It does not
  change the scaler core and registers nothing on the form's controls.

  Usage notes:
  - One component per form. Owner must be a TForm; otherwise the
    component stays inactive (e.g. on a frame or a data module).
  - The form's OnShow is chained in Loaded. If the application assigns a new
    OnShow handler at run time (including in FormCreate), call Attach again
    afterwards, or use the manual integration (three calls) instead.
  - When created in code instead of being dropped on a form, call Attach.
  - SkipBevelScaling and ResetOnShow are linked to the scaler: they can be
    set in the Object Inspector and changed in code at any time.
  - Extension points (the scaler core stays untouched):
      events  BeforeShow, AfterShow, BeforeResize, AfterResize
              (Object Inspector; Sender is the component)
      virtual DoShow, DoResize (for descendants; call inherited to run the
              events and the scaler)
    Order on every show of the form:
      form OnShow -> BeforeShow -> ScalerOnShow -> AfterShow
    Order on every resize of the form:
      form OnResize -> BeforeResize -> ScalerOnResize -> AfterResize

  LCL only (uses LCL handler lists). Under Delphi use the manual integration.
}
unit JCUIScalerComponent;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Forms, JCUIScaler;

type

  { TJCScaler }

  TJCScaler = class(TComponent)
  private
    FScaler: TJCUIScaler;          // the scaler core (object, owned by value)
    FForm: TForm;
    FAttached: boolean;
    FUserOnShow: TNotifyEvent;     // the form's own OnShow, chained
    FSkipBevelScaling: boolean;
    FResetOnShow: boolean;
    FBeforeShow: TNotifyEvent;
    FAfterShow: TNotifyEvent;
    FBeforeResize: TNotifyEvent;
    FAfterResize: TNotifyEvent;
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
    function FormShowIsOurs: boolean;
    procedure Detach;
    function GetSkipBevelScaling: boolean;
    procedure SetSkipBevelScaling(AValue: boolean);
    function GetResetOnShow: boolean;
    procedure SetResetOnShow(AValue: boolean);
  protected
    procedure Loaded; override;
    // Called on every OnShow of the owner form, after the form's own OnShow
    // handler. Default: BeforeShow, ScalerOnShow, AfterShow. Override to add
    // behaviour before and/or after inherited.
    procedure DoShow; virtual;
    // Called on every resize of the owner form, after the form's own OnResize
    // handler. Default: BeforeResize, ScalerOnResize, AfterResize. Override to
    // add behaviour before and/or after inherited.
    procedure DoResize; virtual;
    // True once the component is hooked to its form and the scaler is
    // initialised.
    property Attached: boolean read FAttached;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // Hooks the owner form and initialises the scaler. Called automatically
    // in Loaded; call it yourself when the component is created in code or
    // after replacing the form's OnShow at run time.
    procedure Attach;
    // Re-runs the scaler at the current form size (see Spec, section 13.1).
    procedure Rescale;
    // Emergency reset to the state captured in the reference model.
    procedure RestoreInitialScale;
  published
    property SkipBevelScaling: boolean read GetSkipBevelScaling write SetSkipBevelScaling default True;
    property ResetOnShow: boolean read GetResetOnShow write SetResetOnShow default False;
    // Before the scaler runs on show (on the first show: before the reference
    // model is captured).
    property BeforeShow: TNotifyEvent read FBeforeShow write FBeforeShow;
    // After the scaler ran on show (model captured, or state restored when
    // ResetOnShow = True).
    property AfterShow: TNotifyEvent read FAfterShow write FAfterShow;
    // Before the scaler runs on resize. Geometry of controls in the reference
    // model set here is overwritten by the scaler.
    property BeforeResize: TNotifyEvent read FBeforeResize write FBeforeResize;
    // After the scaler ran on resize: the place for adjustments the scaler
    // does not make (fonts, controls outside the model, custom drawing).
    property AfterResize: TNotifyEvent read FAfterResize write FAfterResize;
  end;

implementation

{ TJCScaler }

constructor TJCScaler.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSkipBevelScaling := True;
  FResetOnShow := False;
  FAttached := False;
end;

destructor TJCScaler.Destroy;
begin
  Detach;
  inherited Destroy;
end;

function TJCScaler.FormShowIsOurs: boolean;
var
  Ours: TNotifyEvent;
begin
  Ours := @FormShow;
  Result := (FForm <> nil) and
    (TMethod(FForm.OnShow).Code = TMethod(Ours).Code) and
    (TMethod(FForm.OnShow).Data = TMethod(Ours).Data);
end;

procedure TJCScaler.Loaded;
begin
  inherited Loaded;
  Attach;
end;

procedure TJCScaler.Attach;
var
  i: integer;
begin
  if csDesigning in ComponentState then Exit;
  if not (Owner is TForm) then Exit;

  // One component per form: only the first instance becomes active.
  for i := 0 to Owner.ComponentCount - 1 do
    if Owner.Components[i] is TJCScaler then
    begin
      if Owner.Components[i] <> Self then Exit;
      Break;
    end;

  FForm := TForm(Owner);

  // Chain OnShow (no handler list for OnShow in LCL). Re-attaching after the
  // application replaced OnShow picks up the new handler.
  if not FormShowIsOurs then
    FUserOnShow := FForm.OnShow;
  FForm.OnShow := @FormShow;

  if not FAttached then
  begin
    // OnResize via the LCL handler list: the user's OnResize stays untouched
    // and is called first. Duplicate registrations are ignored by the LCL.
    FForm.AddHandlerOnResize(@FormResize);

    FScaler.ScalerInit(FForm);
    // Properties must be set after ScalerInit (it resets them to defaults).
    FScaler.SkipBevelScaling := FSkipBevelScaling;
    FScaler.ResetOnShow := FResetOnShow;
    FAttached := True;
  end;
end;

procedure TJCScaler.Detach;
begin
  if not FAttached or (FForm = nil) then Exit;
  // Nothing to undo while the form itself is being destroyed.
  if not (csDestroying in FForm.ComponentState) then
  begin
    FForm.RemoveHandlerOnResize(@FormResize);
    if FormShowIsOurs then
      FForm.OnShow := FUserOnShow;
  end;
  FAttached := False;
  FForm := nil;
end;

procedure TJCScaler.FormShow(Sender: TObject);
begin
  // Same order as the manual integration in the demo: the application's own
  // OnShow code first, then the scaler.
  if Assigned(FUserOnShow) then
    FUserOnShow(Sender);
  DoShow;
end;

procedure TJCScaler.FormResize(Sender: TObject);
begin
  DoResize;
end;

procedure TJCScaler.DoShow;
begin
  if Assigned(FBeforeShow) then
    FBeforeShow(Self);
  FScaler.ScalerOnShow;
  if Assigned(FAfterShow) then
    FAfterShow(Self);
end;

procedure TJCScaler.DoResize;
begin
  if Assigned(FBeforeResize) then
    FBeforeResize(Self);
  FScaler.ScalerOnResize;
  if Assigned(FAfterResize) then
    FAfterResize(Self);
end;

{ Properties linked to the scaler: before Attach the values are kept in the
  component (streamed from the form); from Attach on they are read from and
  written to the scaler object directly. }

function TJCScaler.GetSkipBevelScaling: boolean;
begin
  if FAttached then
    Result := FScaler.SkipBevelScaling
  else
    Result := FSkipBevelScaling;
end;

procedure TJCScaler.SetSkipBevelScaling(AValue: boolean);
begin
  FSkipBevelScaling := AValue;
  if FAttached then
    FScaler.SkipBevelScaling := AValue;
end;

function TJCScaler.GetResetOnShow: boolean;
begin
  if FAttached then
    Result := FScaler.ResetOnShow
  else
    Result := FResetOnShow;
end;

procedure TJCScaler.SetResetOnShow(AValue: boolean);
begin
  FResetOnShow := AValue;
  if FAttached then
    FScaler.ResetOnShow := AValue;
end;

procedure TJCScaler.Rescale;
begin
  if FAttached then
    FScaler.ScalerOnResize;
end;

procedure TJCScaler.RestoreInitialScale;
begin
  if FAttached then
    FScaler.RestoreInitialScale;
end;

end.
