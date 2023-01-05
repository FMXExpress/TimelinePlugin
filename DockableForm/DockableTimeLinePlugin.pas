//**********************************************************
// Developed by TheUnkownOnes.net
//
// for more information look at www.TheUnknownOnes.net
//**********************************************************
unit DockableTimeLinePlugin;

interface

uses
  ToolsAPI,
  DesignIntf,
  Classes,
  SysUtils,
  DockableTimeLineForm,
  Fmx.Dialogs,
  FMX.Forms,
  Fmx.types;

type

  TTimeLinePlugin = class(TInterfacedObject, IDesignNotification )
  private
    function IsTimeLineChild(AControl : TFmxObject; out ATimeLine : TFmxObject) : Boolean;
  protected
    procedure ItemDeleted(const ADesigner: IDesigner; AItem: TPersistent);
    procedure ItemInserted(const ADesigner: IDesigner; AItem: TPersistent);
    procedure ItemsModified(const ADesigner: IDesigner);
    procedure SelectionChanged(const ADesigner: IDesigner; const ASelection: IDesignerSelections);
    procedure DesignerOpened(const ADesigner: IDesigner; AResurrecting: Boolean);
    procedure DesignerClosed(const ADesigner: IDesigner; AGoingDormant: Boolean);
end;

var
  fPlugin : TTimeLinePlugin;
  wstep : string;
implementation




{ Tcna2FormEditorHook }

procedure TTimeLinePlugin.DesignerClosed(const ADesigner: IDesigner;
  AGoingDormant: Boolean);
begin
  try
    TDockableTimeLineForm.HideDesignerForm;
  except
  end;
end;

procedure TTimeLinePlugin.DesignerOpened(const ADesigner: IDesigner; AResurrecting: Boolean);
begin
end;

function TTimeLinePlugin.IsTimeLineChild(AControl: TFmxObject; out ATimeLine : TFmxObject): Boolean;
var wParent : TFmxObject;
    wStrparent : string;
begin
  try
    // Need more test to avoid all special case
      Result := False;
      if AControl = nil  then
        Exit;
      wParent := AControl;
      wStrparent := '';
      while (wParent <> nil ) and (wParent.HasParent) do
      begin
        Result := CompareText(wParent.ClassName, 'TTimeLine') = 0;
        if Result then
        begin
          ATimeLine := wParent;
          Break;
        end;
      (*  else if CompareText(wParent.ClassName, 'TTimeLineItem') = 0 then
          begin
            Result := True;
            ATimeLine := TFmxObject(wParent.Parent);
            Break;
          end;*)
        wStrparent := wStrparent + ' ; ' + wParent.ClassName;
        wParent := wParent.parent;
      end;
  except
    On E:Exception do
      Raise Exception.create('[TTimeLinePlugin.IsTimeLineChild] : '+E.message);
  end;
end;

procedure TTimeLinePlugin.ItemDeleted(const ADesigner: IDesigner;
  AItem: TPersistent);
begin
end;

procedure TTimeLinePlugin.ItemInserted(const ADesigner: IDesigner;
  AItem: TPersistent);
begin

end;

procedure TTimeLinePlugin.ItemsModified(const ADesigner: IDesigner);
begin

end;

procedure TTimeLinePlugin.SelectionChanged(const ADesigner: IDesigner;
  const ASelection: IDesignerSelections);
var
  i : integer;
  wSelection : IDesignerSelections;
  wTimeLine : TFmxObject;
begin
  try
    if (ADesigner <> nil) and (ASelection <> nil) and (ASelection.Count > 0) then
    begin
      wTimeLine := nil;
      for i := 0 to ASelection.Count -1 do
      begin
        if (ASelection.Items[i] <> nil ) then
        begin
          if (comparetext( ASelection.Items[i].ClassName , 'TTimeLine') = 0) then
          begin
            wTimeLine := TFmxObject(ASelection.Items[i]);
            Break;
          end
          else begin
            if IsTimeLineChild(TFmxObject(ASelection.Items[i]), wTimeLine) then
            begin
              Break;
            end;
          end;
        end;
      end;
      if wTimeLine <> nil then
        TDockableTimeLineForm.ShowDesignerForm(wTimeLine)
      else begin
        TDockableTimeLineForm.HideDesignerForm;
      end;
    end;
  except
    On E:Exception do
      Raise Exception.create('[TTimeLinePlugin.SelectionChanged] : ' +E.message);
  end;
end;

initialization
  try
    fPlugin := nil;
    fPlugin := TTimeLinePlugin.Create;
    TDockableTimeLineForm.CreateDesignerForm;
    RegisterDesignNotification( fPlugin );
  except
    On E:Exception do
      Raise Exception.create('[initialization : '+E.message);
  end;


finalization
  try
    TDockableTimeLineForm.RemoveDesignerForm;
    if assigned(fPlugin) then
    begin
      UnregisterDesignNotification(fPlugin);
      FreeAndNil(fPlugin);
    end;
  except
  end;
end.
