unit Unit2;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, TimeLine, FMX.Objects;

type
  TForm2 = class(TForm)
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    Button9: TButton;
    Button10: TButton;
    TimeLine1: TTimeLine;
    Circle1: TCircle;
    Circle2: TCircle;
    Circle3: TCircle;
    Circle4: TCircle;
    Circle5: TCircle;
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button10Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation

{$R *.fmx}

procedure TForm2.Button10Click(Sender: TObject);
begin
TimeLine1.Prev;
end;

procedure TForm2.Button4Click(Sender: TObject);
begin
TimeLine1.GotoAndPlay(0);
end;

procedure TForm2.Button5Click(Sender: TObject);
begin
TimeLine1.Stop;
end;

procedure TForm2.Button6Click(Sender: TObject);
begin
TimeLine1.Play;
end;

procedure TForm2.Button7Click(Sender: TObject);
begin
if TimeLine1._CurrentFrame<TimeLine1._FrameCount-1 then
 begin
  TimeLine1.GotoAndStop(TimeLine1._CurrentFrame+1);
 end
 else
 begin
  TimeLine1.GotoAndStop(0);
 end;
end;

procedure TForm2.Button9Click(Sender: TObject);
begin
TimeLine1.Next;
end;

end.
