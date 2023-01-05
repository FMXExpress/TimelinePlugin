unit DockableBaseTimeLineForm;

interface

uses
  Windows, SysUtils, Classes, Fmx.Graphics, Fmx.Controls, Fmx.Forms, Fmx.Types,
  // You must link to the DesignIde/DsnIdeXX package to compile this unit
  DockForm,FMX.Platform.Win, FMX.Dialogs, FmxContainer, vcl.Controls,TimeLine,
  TimeLineDsgn, Vcl.StdCtrls, Vcl.ExtCtrls, winapi.Messages;


type

  TDockableBaseTimeLineForm = class(TDockableForm)
    procedure FormEndDock(Sender, Target: TObject; X, Y: Integer);
  private

    fTimeLine : TTimeLine;
    procedure SetTimeLine(ATimeLine : Ttimeline);
    procedure WMMove(var Message: TMessage) ; message WM_MOVE;
  public
    Container : TFireMonkeyContainer;
    DsgnForm: TTimelineDsgnDialog;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property TimeLine : TTimeline read fTimeLine write SetTimeLine;
  end;

  TDockableBaseTimeLineFormClass = class of TDockableBaseTimeLineForm;


procedure ShowDockableForm(ATimeLineForm: TDockableBaseTimeLineForm; APersistent : TPersistent);
procedure HideDockableForm(ATimeLineForm: TDockableBaseTimeLineForm);
procedure CreateDockableForm(var ATimeLineForm: TDockableBaseTimeLineForm; AATimeLineFormClass: TDockableBaseTimeLineFormClass);
procedure FreeDockableForm(var ATimeLineForm: TDockableBaseTimeLineForm);

implementation

{$R *.dfm}

uses DeskUtil;

procedure HideDockableForm(ATimeLineForm: TDockableBaseTimeLineForm);
begin
  try
    if not Assigned(ATimeLineForm) then
      Exit;
    ATimeLineForm.Hide;
  except
    On E:Exception do
      Raise Exception.create('[HideDockableForm] : '+E.message);
  end;
end;

procedure ShowDockableForm(ATimeLineForm: TDockableBaseTimeLineForm; APersistent : TPersistent);
begin
  try
    if not Assigned(ATimeLineForm) then
      Exit;

    if ATimeLineForm.Showing then
      Exit;

    ATimeLineForm.TimeLine := TTimeline(APersistent);

    if not ATimeLineForm.Floating then
    begin
      ATimeLineForm.ForceShow;
      FocusWindow(ATimeLineForm);
    end
    else begin
      ATimeLineForm.Show;
    end;

  except
    On E:Exception do
      Raise Exception.create('[ShowDockableForm] : '+E.message);
  end;
end;

procedure RegisterDockableForm(ATimeLineFormClass: TDockableBaseTimeLineFormClass;
  var FormVar; const FormName: string);
begin
  try
    if @RegisterFieldAddress <> nil then
      RegisterFieldAddress(FormName, @FormVar);

    RegisterDesktopFormClass(ATimeLineFormClass, FormName, FormName);
  except
    On E:Exception do
      Raise Exception.create('[RegisterDockableForm] : '+E.message);
  end;
end;

procedure UnRegisterDockableForm(var ATimeLineForm; const FormName: string);
begin
  try
    if @UnregisterFieldAddress <> nil then
      UnregisterFieldAddress(@ATimeLineForm);
  except
    On E:Exception do
      Raise Exception.create('[UnRegisterDockableForm] : '+E.message);
  end;
end;

procedure CreateDockableForm(var ATimeLineForm: TDockableBaseTimeLineForm; AATimeLineFormClass: TDockableBaseTimeLineFormClass);
begin
  try
    ATimeLineForm := TDockableBaseTimeLineForm.Create(nil);
    RegisterDockableForm(AATimeLineFormClass, ATimeLineForm, TCustomForm(ATimeLineForm).Name);
  except
    On E:Exception do
      Raise Exception.create('[CreateDockableForm] : '+E.message);
  end;
end;

procedure FreeDockableForm(var ATimeLineForm: TDockableBaseTimeLineForm);
begin
  try
    if Assigned(ATimeLineForm) then
    begin
      UnRegisterDockableForm(ATimeLineForm, ATimeLineForm.Name);
      FreeAndNil(ATimeLineForm);
    end;
  except
    On E:Exception do
      Raise Exception.create('[FreeDockableForm] : '+E.message);
  end;
end;

{ TIDEDockableForm }

constructor TDockableBaseTimeLineForm.Create(AOwner: TComponent);
begin
  try
    inherited;
    DeskSection := Name;
    AutoSave := True;
    SaveStateNecessary := True;
  Except
    On E:Exception do
      raise Exception.Create('[TDockableBaseTimeLineForm.Create] : ' + E.message);
  end;
end;

destructor TDockableBaseTimeLineForm.Destroy;
begin
  try
    if assigned(Container) then
    begin
      Container.Parent := nil;
      Container.Free;
      Container := nil;
    end;
    SaveStateNecessary := False;
    inherited;
  except
    On E:Exception do
      Raise Exception.create('[TDockableBaseTimeLineForm.Destroy] : '+E.message);
  end;
end;

procedure TDockableBaseTimeLineForm.FormEndDock(Sender, Target: TObject; X,
  Y: Integer);
begin
  SetTimeLine(fTimeLine);
end;

procedure TDockableBaseTimeLineForm.SetTimeLine(ATimeLine: Ttimeline);
begin
  try
    SendMessage(Handle, WM_SETREDRAW, 0, 0);
    try
      fTimeLine := ATimeLine;
      if Assigned(Container) then
      begin
        Container.Parent := nil;
        Container.Free;
        Container := nil;
      end;
      Container := TFireMonkeyContainer.Create(nil);
      Container.Align := TAlign.alClient;
      DsgnForm := TTimelineDsgnDialog.Create(Container);
      Container.Parent := Self;
      Container.FireMonkeyForm := DsgnForm;
    finally
      SendMessage(Handle, WM_SETREDRAW, 1, 0);
      InvalidateRect(Handle, nil, True);
    end;

    DsgnForm.TimeLine := ATimeLine;
  except
    On E:Exception do
      Raise Exception.create('[TDockableBaseTimeLineForm.SetTimeLine] : '+E.message);
  end;
end;

procedure TDockableBaseTimeLineForm.WMMove(var Message: TMessage);
begin

end;

end.
