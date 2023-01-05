unit DockableTimeLineForm;

interface

uses
  Windows, SysUtils, Classes, Fmx.Graphics, Fmx.Controls, Fmx.Forms, Fmx.ExtCtrls,
  DockableBaseTimeLineForm, Vcl.Controls, Vcl.ExtCtrls, Vcl.StdCtrls, fmx.dialogs;

type
  TDockableTimeLineForm = class(TDockableBaseTimeLineForm)
  public
    class procedure RemoveDesignerForm;
    class procedure ShowDesignerForm(APersistant : TPersistent);
    class procedure HideDesignerForm;
    class procedure CreateDesignerForm;
  end;

implementation

{$R *.dfm}

var
  FormInstance: TDockableBaseTimeLineForm = nil;

{ TExampleDockableForm }

class procedure TDockableTimeLineForm.CreateDesignerForm;
begin
  CreateDockableForm(FormInstance, TDockableTimeLineForm);
end;

class procedure TDockableTimeLineForm.ShowDesignerForm(APersistant : TPersistent);
begin
  ShowDockableForm(FormInstance, APersistant );
end;

class procedure TDockableTimeLineForm.HideDesignerForm;
begin
  if assigned(FormInstance) then
    HideDockableForm(FormInstance);
end;

class procedure TDockableTimeLineForm.RemoveDesignerForm;
begin
  FreeDockableForm(FormInstance);
end;

end.
