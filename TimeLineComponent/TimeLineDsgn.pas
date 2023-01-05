unit TimeLineDsgn;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, System.Math,
  FMX.Types, FMX.Forms, System.Generics.Collections, FMX.StdCtrls, FMX.Layouts, FMX.Graphics,
  FMX.Controls, TimeLine, FMX.Colors, System.Actions, FMX.ActnList, FMX.Dialogs,
  FMX.TreeView,FMX.Objects, FMX.Menus, FMX.Edit, FMX.Controls.Presentation,
  FMX.EditBox, FMX.SpinBox
  {$IFDEF DESIGN},DesignEditors{$ENDIF};

type

  TRuler = class(TPanel)
  private
    FLabels: TList<TLabel>;
  protected
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

type
  TItemButton = class(TColorButton)
  private
    FFrameIndex: Word;
  public
    property FrameIndex: Word read FFrameIndex write FFrameIndex;
  end;

type
  TTimelineLayer = class(TTreeViewItem)
    ItemsPanel: TPanel;
    ItemButtons: TList<TItemButton>;
    procedure OnClickProc(Sender : TObject);
  public
    LayerIndex : integer;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

type
  TTimelineDsgnDialog = class(TForm)
    ScrollBox: TScrollBox;
    ActionList: TActionList;
    ActionNewLayer: TAction;
    ActionDeleteLayer: TAction;
    ActionNewFrame: TAction;
    ActionDeleteFrame: TAction;
    btnDeleteLayer: TSpeedButton;
    btnNewFrame: TSpeedButton;
    btnDeleteFrame: TSpeedButton;
    pnlRuler: TPanel;
    TreeView1: TTreeView;
    LayersRootItem: TTreeViewItem;
    btnNewLayer: TSpeedButton;
    StyleBook1: TStyleBook;
    FramePopupMenu: TPopupMenu;
    LeftLayout: TLayout;
    LeftFooterLayout: TLayout;
    Splitter1: TSplitter;
    FramesLayout: TLayout;
    FramesFooterLayout: TLayout;
    NewMenuItem: TMenuItem;
    DeleteMenuItem: TMenuItem;
    PlayHeadRect: TRectangle;
    CurrentFrameSpinBox: TSpinBox;
    SecondsSpinBox: TSpinBox;
    FPSSpinBox: TSpinBox;
    Label1: TLabel;
    TimelineTimer: TTimer;
    PlayButton: TSpeedButton;
    ActionPlay: TAction;
    ActionStop: TAction;
    StopButton: TSpeedButton;
    Rectangle1: TRectangle;
    Label2: TLabel;
    InsertMenuItem: TMenuItem;
    procedure ActionNewLayerExecute(Sender: TObject);
    procedure ActionDeleteLayerExecute(Sender: TObject);
    procedure ActionNewFrameExecute(Sender: TObject);
    procedure ActionDeleteFrameExecute(Sender: TObject);
    procedure ActionDeleteLayerUpdate(Sender: TObject);
    procedure ActionDeleteFrameUpdate(Sender: TObject);
    procedure LayersRootItemClick(Sender: TObject);
    procedure TreeView1DragChange(SourceItem, DestItem: TTreeViewItem;
      var Allow: Boolean);
    procedure ActionNewFrameUpdate(Sender: TObject);
    procedure TreeView1ChangeCheck(Sender: TObject);
    procedure PlayHeadRectMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure PlayHeadRectMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure PlayHeadRectMouseLeave(Sender: TObject);
    procedure PlayHeadRectMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Single);
    procedure FPSSpinBoxChange(Sender: TObject);
    procedure CurrentFrameSpinBoxChange(Sender: TObject);
    procedure ActionPlayExecute(Sender: TObject);
    procedure ActionStopExecute(Sender: TObject);
    procedure TimelineTimerTimer(Sender: TObject);
    procedure ScrollBoxResize(Sender: TObject);
    procedure pnlRulerMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure InsertMenuItemClick(Sender: TObject);
  private
    FTimeLine: TTimeLine;
    FRuler: TRuler;
    FSelectedFrame: Integer;
    FSelectedLayer: Integer;
    PlayHeadMouseDown: Boolean;
    PlayHeadMouseX: Single;
    PlayHeadMouseY: Single;
    procedure MovePlayHead(Position: Integer);
    procedure SetTimeLine(const Value: TTimeLine);
    procedure CleanUp;
    procedure OnItemButtonClick(Sender: TObject);
    procedure OnItemButtonMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure UpdateScrollBarHeight;
    procedure AddTimeLineLayer(ALayerIndex : integer);
    procedure AddFrameButton(ATimeLineLayer : TTimelineLayer; AFrameIndex : integer);
    procedure SelectChild(AChild : TTreeViewItem); overload;
    procedure SelectChild(AChildName : string); overload;
    function FmxControlExist(AParent : TFmxObject; AControlName : string) : Boolean;
  public
    procedure UpdateZOrder;
    property TimeLine: TTimeLine read FTimeLine write SetTimeLine;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

{$IFDEF DESIGN}
type
  TTimelineComponentEditor = class(TComponentEditor)
  private
    procedure ShowEditor;
  public
    function GetVerbCount: Integer; override;
    function GetVerb(Index: Integer): string; override;
    procedure ExecuteVerb(Index: Integer); override;
  end;
{$ENDIF]}

const
  LAYER_HEIGHT = 30;
  LAYER_LABEL_WIDTH = 0;
  LAYER_BUTTON_WIDTH = 20;

implementation

{$R *.fmx}
{ TTimelineLayer }

constructor TTimelineLayer.Create(AOwner: TComponent);
begin
  try
    inherited Create(AOwner);
    ItemsPanel := TPanel.Create(Self);
    ItemsPanel.Position.X := LAYER_LABEL_WIDTH;
    ItemsPanel.Height := LAYER_HEIGHT;
    Height := LAYER_HEIGHT;
    OnClick := OnClickProc;

    ItemButtons := TList<TItemButton>.Create;
  except
    On E:Exception do
      Raise Exception.create('[TTimelineLayer.Create] : '+E.message);
  end;
end;

destructor TTimelineLayer.Destroy;
var i : integer;
begin
  try
    ItemButtons.Free;
    inherited;
  except
    On E:Exception do
      Raise Exception.create('[TTimelineLayer.Destroy] : '+E.message);
  end;
end;



procedure TTimelineLayer.OnClickProc(Sender: TObject);
begin
  try
    if ItemButtons.count > 0 then
      TItemButton(ItemButtons[0]).Click;
  except
    On E:Exception do
      Raise Exception.create('[TTimelineLayer.OnClickProc] : '+E.message);
  end;
end;

{ TTimelineDsgnDialog }

procedure TTimelineDsgnDialog.ActionDeleteFrameExecute(Sender: TObject);
var i : integer;
    wIdx : integer;
begin
  try
    if MessageDlg('Delete "Frame' + IntToStr(FSelectedFrame) + '"?', TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes , TMsgDlgBtn.mbCancel], 0) <> idOK then
      Exit;

    if TreeView1.Selected <> nil then
      wIdx := TreeView1.Selected.Index
    else
      wIdx := 1;

    FTimeLine.DeleteFrame(FSelectedFrame);

    CleanUp;
    SetTimeLine(FTimeLine);

    if FSelectedFrame > 0 then
      TItemButton(TTimelineLayer(LayersRootItem.ItemByIndex(FSelectedLayer)).ItemButtons[FSelectedFrame]).Click
    else if FTimeLine._FrameCount > 0 then
      TItemButton(TTimelineLayer(LayersRootItem.ItemByIndex(FSelectedLayer)).ItemButtons[0]).Click
    else FSelectedFrame := -1;

    if wIdx < LayersRootItem.Count then
      SelectChild(LayersRootItem.Items[wIdx]);

    UpdateScrollBarHeight
  except
    On E:Exception do
      Raise Exception.create('[TTimelineDsgnDialog.ActionDeleteFrameExecute] : '+E.message);
  end;
end;

procedure TTimelineDsgnDialog.ActionDeleteFrameUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled := (FSelectedFrame >= 0) and (FSelectedLayer >= 0) and (LayersRootItem.Count > 0) and (TTimelineLayer(LayersRootItem.ItemByIndex(0)).ItemButtons.count > 0);
end;

procedure TTimelineDsgnDialog.ActionDeleteLayerUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled := (FSelectedLayer >= 0) and (TreeView1.Enabled) ;
end;


procedure TTimelineDsgnDialog.ActionDeleteLayerExecute(Sender: TObject);
var wIdx : integer;
    i : integer;
begin

  try
    if (LayersRootItem.Count > 0) and (TreeView1.Selected <> nil) then
    begin
      if MessageDlg('Delete "' + TreeView1.Selected.Text + '"?', TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes , TMsgDlgBtn.mbCancel], 0) <> idOK then
        Exit;

      wIdx := TreeView1.Selected.Index;

      FTimeLine.DeleteLayer(TTimelineLayer(TreeView1.Selected).LayerIndex);
      CleanUp;
      SetTimeLine(FTimeLine);
      UpdateScrollBarHeight;

      TreeView1.Enabled := LayersRootItem.Count > 0;
      if wIdx < LayersRootItem.Count -1 then
        SelectChild( LayersRootItem.Items[wIdx] )
      else if LayersRootItem.Count > 0 then
        SelectChild(LayersRootItem.Items[LayersRootItem.Count -1]);
    end;
  except
    On E:Exception do
      Raise Exception.create('[TTimelineDsgnDialog.ActionDeleteLayerExecute] : '+E.message);
  end;
end;


procedure TTimelineDsgnDialog.ActionNewFrameExecute(Sender: TObject);
var i : integer;
    wIdx : integer;
begin

  try
    if TreeView1.Selected <> nil then
      wIdx := TreeView1.Selected.Index
    else
      wIdx := 1;
    FTimeLine._FrameCount := FTimeLine._FrameCount + 1;
    CleanUp;
    SetTimeLine(FTimeLine);
    UpdateScrollBarHeight;
    if wIdx < LayersRootItem.count then
      SelectChild(LayersRootItem.Items[wIdx]);
  //  PlayHeadRect.BringToFront;
  except
    On E:Exception do
      Raise Exception.create('[TTimelineDsgnDialog.ActionNewFrameExecute] : '+E.message);
  end;
end;

procedure TTimelineDsgnDialog.ActionNewFrameUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled := (LayersRootItem.Count > 0);
end;

procedure TTimelineDsgnDialog.ActionNewLayerExecute(Sender: TObject);
begin
  try
    Self.BeginUpdate;
    try
      FTimeLine._LayerCount := FTimeLine._LayerCount + 1;
      CleanUp;
      SetTimeLine(FTimeLine);
      UpdateScrollBarHeight;
      if TreeView1.Count = 1 then
        TreeView1.Enabled := True;
      SelectChild(LayersRootItem.Items[LayersRootItem.Count -1]);
    finally
      Self.EndUpdate;
    end;
  except
    On E:Exception do
      Raise Exception.create('[TTimelineDsgnDialog.ActionNewLayerExecute] : '+E.message);
  end;
end;

procedure TTimelineDsgnDialog.ActionPlayExecute(Sender: TObject);
begin
  TimeLineTimer.Enabled := True;
end;

procedure TTimelineDsgnDialog.ActionStopExecute(Sender: TObject);
begin
  TimeLineTimer.Enabled := False;
end;

procedure TTimelineDsgnDialog.AddFrameButton(ATimeLineLayer : TTimelineLayer; AFrameIndex : integer);
var
  wButton: TItemButton;
begin
  try
    try
      wButton := TItemButton.Create(ATimeLineLayer);
    //  wButton.PopupMenu := FramePopupMenu;
      wButton.FrameIndex := AFrameIndex;
      wButton.Name := 'Item_' + intToStr(AFrameIndex) + '_' + intToStr(ATimeLineLayer.LayerIndex);
      wButton.Text := '';
      wButton.Width := LAYER_BUTTON_WIDTH;
      wButton.Height := LAYER_HEIGHT;
      wButton.OnClick := OnItemButtonClick;
      wButton.OnMouseDown := OnItemButtonMouseDown;
      if FTimeLine.Item(AFrameIndex, ATimeLineLayer.LayerIndex) <> nil then
        wButton.Color := TAlphaColors.Blue
      else
        wButton.Color := TAlphaColors.White;
      wButton.Parent := ATimeLineLayer.ItemsPanel;
      wButton.Position.X := LAYER_BUTTON_WIDTH * (AFrameIndex + 1) + 10;
      wButton.Align := TAlignLayout.Left;
      ATimeLineLayer.ItemButtons.Add(wButton);
    except
      On E:Exception do
        Raise Exception.create('[TTimelineDsgnDialog.AddFrameButton] : '+E.message);
    end;
  except
    On E:Exception do
      Raise Exception.create('[TTimelineDsgnDialog.AddFrameButton] : '+E.message);
  end;
end;

procedure TTimelineDsgnDialog.AddTimeLineLayer(ALayerIndex: integer);
var
  wTimelineLayer: TTimelineLayer;
  wText : string;
  wItem : TTimeLineItem;
  J : Integer;
begin
  try
     wTimelineLayer := TTimelineLayer.Create(Self);

     wTimelineLayer.parent := LayersRootItem;
     wTimelineLayer.ItemsPanel.parent := ScrollBox;

     wItem := FTimeLine.item(0, ALayerIndex);
     if wItem = nil  then
     begin
       wTimelineLayer.LayerIndex := ALayerIndex;
       TreeView1.AllowDrag := False;
       wTimelineLayer.IsChecked := True;
       wText := Format('Layer%d',[ALayerIndex]);
     end
     else begin
       wTimelineLayer.LayerIndex := wItem.LayerIndex;
       TreeView1.AllowDrag := True;
       wTimelineLayer.IsChecked := wItem.Visibility;
       wText := Format('Layer%d',[wItem.LayerIndex]);
     end;

     wTimelineLayer.Text := wText;
     wTimelineLayer.Position.X := 0;
     wTimelineLayer.ItemsPanel.Position.Y := LAYER_HEIGHT + LAYER_HEIGHT * (LayersRootItem.Count -1);
     wTimelineLayer.ItemsPanel.Width := ScrollBox.Width;
     CurrentFrameSpinBox.Max := FTimeLine._FrameCount-1;
     for J := 0 to FTimeLine._FrameCount - 1 do
     begin
       AddFrameButton(wTimelineLayer, j);
     end;
     PlayHeadRect.BringToFront;
  except
    On E:Exception do
      Raise Exception.create('[TTimelineDsgnDialog.AddTimeLineLayer] : '+E.message);
  end;
end;


procedure TTimelineDsgnDialog.CleanUp;
var
  I: Integer;
  wLayer : TTimelineLayer;
begin
 // for i := LayersRootItem.Count-1 downto 0 do
 //   TreeView1.RemoveObject(LayersRootItem.Items[0]);

   try
     for I := LayersRootItem.Count - 1 downto 0 do
     begin
       wLayer := TTimelineLayer(LayersRootItem.ItemByIndex(I));
       wLayer.Parent := nil;
       wLayer.Free;
     end;
   except
     On E:Exception do
       Raise Exception.create('[TTimelineDsgnDialog.CleanUp] : '+E.message);
   end;
end;

constructor TTimelineDsgnDialog.Create(AOwner: TComponent);
begin
  try
    inherited Create(AOwner);
    FSelectedFrame := -1;
    FSelectedLayer := -1;
    FRuler := TRuler.Create(Self);
    FRuler.Parent := pnlRuler;
    FRuler.OnMouseUp := pnlRulerMouseUp;
    FRuler.Align := TAlignLayout.Client;
    TreeView1.ItemHeight := LAYER_HEIGHT;
  except
    On E:Exception do
      Raise Exception.create('[TTimelineDsgnDialog.Create] : '+E.message);
  end;
end;

procedure TTimelineDsgnDialog.CurrentFrameSpinBoxChange(Sender: TObject);
begin
  if Sender <> nil then
  begin
    FTimeLine.DesignPreview := true;
    MovePlayHead(Round(CurrentFrameSpinBox.Value));
  end;
  SecondsSpinBox.Value :=  FTimeLine._ActiveFrame / FPSSpinBox.Value;
end;

destructor TTimelineDsgnDialog.Destroy;
begin
  try
    inherited;
  except
    On E:Exception do
      Raise Exception.create('[TTimelineDsgnDialog.Destroy] : '+E.message);
  end;
end;


function TTimelineDsgnDialog.FmxControlExist(APArent : TFmxObject; AControlName: string): Boolean;
var i : integer;
    wfound : Boolean;
begin
  try
    Result := False;
    if Trim(AControlName) = '' then
      Exit;
    for I := 0 to APArent.ChildrenCount -1 do
    begin
      if Trim(APArent.Children[i].Name) = '' then continue;
      if Sametext(AControlName, APArent.Children[i].Name) then
      begin
        Result := True;
        Break;
      end
      else begin
        if APArent.Children[i].ChildrenCount > 0 then
        begin
          Result := FmxControlExist(APArent.Children[i], AControlName);
          if Result then Break;
        end;
      end;
    end;
  except
    On E:Exception do
      Raise Exception.create('[TTimelineDsgnDialog.FmxComponentExist] : '+E.message);
  end;
end;

procedure TTimelineDsgnDialog.FPSSpinBoxChange(Sender: TObject);
begin
  FTimeLine._FrameRate := Round(FPSSpinBox.Value);
  TimelineTimer.Interval := 1000 div FTimeLine._FrameRate;
  SecondsSpinBox.Value :=  FTimeLine._ActiveFrame / FPSSpinBox.Value;
end;

procedure TTimelineDsgnDialog.InsertMenuItemClick(Sender: TObject);
var
  i,j, wIdx : integer;
  wRefButton, wNewButton : TItemButton;
  wRefItem : TTimeLineItem;
  wNewItem : TTimeLineItem;
//  wTmpControl : TTimeLineItem;
  wMem : TMemoryStream;
  wControlName : String;
  wExist : Boolean;
  wFrameIdxToMove : integer;
  wRefName, wNewName : string;
  wOldName : string;
  wOldFrame, wOldLayer : integer;
begin
  try
    wRefButton := TItemButton(TTimelineLayer(LayersRootItem.ItemByIndex(FSelectedLayer)).ItemButtons[FSelectedFrame]);
    if wRefButton <> nil then
    begin
      FTimeLine._FrameCount := FTimeLine._FrameCount + 1;

      CleanUp;
      SetTimeLine(FTimeLine);
      UpdateScrollBarHeight;

      for i := 0 to FTimeLine._LayerCount -1 do
      begin
        wRefButton := TItemButton(TTimelineLayer(LayersRootItem.ItemByIndex(i)).ItemButtons[FSelectedFrame]);
        for j := FTimeLine._FrameCount -1 downto wRefButton.FrameIndex + 2 do
        begin
          wRefItem := FTimeLine.Item(j  , i);
          wNewItem := FTimeLine.Item(j-1, i);

          wRefName := wRefItem.Name;     // backup name
          wNewName := wNewItem.Name;

          wRefItem.FrameIndex := j-1;
          wNewItem.FrameIndex := j;
          wRefItem.Name := 'azertyuiopqsdfghjklmwxcvbn';

          wNewItem.Name := wRefName;    // inverse name
          wRefItem.Name := wNewName;
        end;
      end;

      for i := 0 to FTimeLine._LayerCount -1 do
      begin
        wRefButton := TItemButton(TTimelineLayer(LayersRootItem.ItemByIndex(i)).ItemButtons[FSelectedFrame]);
        wRefItem := FTimeLine.Item(wRefButton.FrameIndex   , i);
        wNewItem := FTimeLine.Item(wRefButton.FrameIndex + 1, i);
        wNewItem.DeleteChildren;

        wOldName := wNewItem.Name;
        wOldFrame := wNewItem.FrameIndex;
        wOldLayer := wNewItem.LayerIndex;

        wMem := TMemoryStream.Create;
        try
          wMem.WriteComponent(wRefItem);
          wMem.Position := 0;
          wMem.ReadComponent(wNewItem);
        finally
          wMem.Free;
        end;


        wNewItem.Name := wOldName;
        wNewItem.FrameIndex := wOldFrame;
        wNewItem.LayerIndex := wOldLayer;

        for j := 0 to wNewItem.ChildrenCount -1 do
        begin
          if Trim(wNewItem.Children[j].Name) = '' then Continue;
          wIdx := 1;
          repeat
            wControlName := wNewItem.Children[j].ClassName + inttostr(wIdx);
            wControlName := copy(wControlName, 2 , Length(wControlName));
            inc(wIdx);
            wExist := FmxControlExist(FTimeLine, wControlName);
          until not wExist;
          wNewItem.Children[j].Name := wControlName;
        end;
      end;

      CleanUp;
      SetTimeLine(FTimeLine);
      UpdateScrollBarHeight;
    end;
  except
    On E:Exception do
      Raise Exception.create('[TTimelineDsgnDialog.InsertMenuItemClick] : '+E.message);
  end;
end;

procedure TTimelineDsgnDialog.OnItemButtonMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var wPoint, wPoint2 : TPointF;
begin
  if Button=TMouseButton.mbRight then
   begin
     TItemButton(Sender).Click;

     wPoint.X := X;
     wPoint.Y := Y;

     wPoint2 :=  ClienttoScreen(wPoint);
     wPoint2.X := LeftLayout.width + Splitter1.Width + TItemButton(Sender).Position.X + wPoint2.X;
     wPoint2.Y := pnlRuler.Height + ScrollBox.Position.Y + TPanel(TItemButton(Sender).Parent).Position.Y + wPoint2.Y;
     FramePopupMenu.Popup(wPoint2.X , wPoint2.Y);
   end;

end;

procedure TTimelineDsgnDialog.PlayHeadRectMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  PlayHeadMouseX := X;
  PlayHeadMouseX := Y;
  PlayHeadMouseDown := True;
end;

procedure TTimelineDsgnDialog.PlayHeadRectMouseLeave(Sender: TObject);
begin
   PlayHeadMouseDown := False;
end;

procedure TTimelineDsgnDialog.PlayHeadRectMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Single);
begin
  FTimeLine.DesignPreview := true;
  if (PlayHeadMouseX-5)<X then
    MovePlayHead(FSelectedFrame-1)
  else if (PlayHeadMouseX+5)>X then
    MovePlayHead(FSelectedFrame+1);
end;

procedure TTimelineDsgnDialog.PlayHeadRectMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
   PlayHeadMouseDown := False;
end;

procedure TTimelineDsgnDialog.pnlRulerMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  wPosition : integer;
begin
  FTimeLine.DesignPreview := true;
  wPosition :=  Trunc(X / LAYER_BUTTON_WIDTH);
  if wPosition < fTimeLine._FrameCount then
  begin
    MovePlayHead(wPosition);
    CurrentFrameSpinBox.Value := wPosition;
    SecondsSpinBox.Value :=  wPosition  / FPSSpinBox.Value;
  end;
end;

procedure TTimelineDsgnDialog.OnItemButtonClick(Sender: TObject);
var
  I, J: Integer;
  wLayerIdx : integer;
  wItem : TTimeLineItem;
begin
  try


    FSelectedFrame := -1;
    FSelectedLayer := -1;

    if FTimeLine = nil then
      Exit;

    if TItemButton(Sender).Color = TAlphaColors.White then
      Exit;

    for I := 0 to LayersRootItem.Count - 1 do
    begin
      wLayerIdx := TTimelineLayer(LayersRootItem.ItemByIndex(I)).LayerIndex;
      for J := 0 to TTimelineLayer(LayersRootItem.ItemByIndex(I)).ItemButtons.Count - 1 do
        if FTimeLine.Item(J, wLayerIdx) <> nil then
          TTimelineLayer(LayersRootItem.ItemByIndex(I)).ItemButtons[J].Color := TAlphaColors.Blue
        else
          TTimelineLayer(LayersRootItem.ItemByIndex(I)).ItemButtons[J].Color := TAlphaColors.White;
    end;
    wItem := FTimeLine.Item(TItemButton(Sender).FrameIndex, TTimelineLayer(TItemButton(Sender).Owner).LayerIndex);
    if wItem <> nil then
    begin
      FTimeLine._ActiveFrame := wItem.FrameIndex;
      FTimeLine._ActiveLayer := wItem.LayerIndex;
      FSelectedFrame := wItem.FrameIndex;
      FSelectedLayer := wItem.LayerIndex;
      CurrentFrameSpinBox.Value := FSelectedFrame;
      SecondsSpinBox.Value :=  FTimeLine._ActiveFrame / FPSSpinBox.Value;
      FTimeLine.DesignPreview := False;
      MovePlayHead(FSelectedFrame);
      TItemButton(Sender).Color := TAlphaColors.Red;

      SelectChild(TTimelineLayer(TItemButton(Sender).Owner).Text);
    end;
  except
    On E:Exception do
      Raise Exception.create('[TTimelineDsgnDialog.OnItemButtonClick] : '+E.message);
  end;
end;

procedure TTimelineDsgnDialog.MovePlayHead(Position: Integer);
begin

  PlayHeadRect.Position.X := Position * LAYER_BUTTON_WIDTH;
  FTimeLine._ActiveFrame := Position;
  FTimeLine.Repaint;
end;

procedure TTimelineDsgnDialog.SelectChild(AChild: TTreeViewItem);
var i : integer;
begin
  try
    for i := 0 to LayersRootItem.Count -1 do
      LayersRootItem.Items[i].Deselect;
    Achild.Select;
    TreeView1.Repaint;
  except
    On E:Exception do
      Raise Exception.create('[TTimelineDsgnDialog.SelectChild] : '+E.message);
  end;
end;

procedure TTimelineDsgnDialog.ScrollBoxResize(Sender: TObject);
begin
  PlayHeadRect.Height := ScrollBox.Height;
end;

procedure TTimelineDsgnDialog.SelectChild(AChildName: string);
var i : integer;
    wChild : TTreeViewItem;
begin
  try
    for i := 0 to LayersRootItem.Count -1 do
    begin
      LayersRootItem.Items[i].Deselect;
      if CompareText(LayersRootItem.Items[i].Text, AChildName) = 0 then
        wChild := LayersRootItem.Items[i];
    end;
    wChild.Select;
    TreeView1.Repaint;
  except
    On E:Exception do
      Raise Exception.create('[TTimelineDsgnDialog.SelectChild] : '+E.message);
  end;
end;

procedure TTimelineDsgnDialog.SetTimeLine(const Value: TTimeLine);
var
  I, J: Integer;
  wLayer : TTimelineLayer;
  wItem : TTimeLineItem;
begin
  try
    Self.BeginUpdate;
    try
      FTimeLine := Value;
      FPSSpinBox.Value := FTimeLine._FrameRate;

      if (FTimeLine._LayerCount = 0) then
        Exit;

      if FTimeLine._FrameCount > 0 then
      begin
        for I :=  FTimeLine.ControlsCount -1 downto 0 do
        begin
          wItem := TTimeLineItem(FTimeLine.Controls[i]);
          if wItem.FrameIndex = 0 then
            AddTimeLineLayer(wItem.LayerIndex);
        end;
      end
      else begin
        for I := 0 to FTimeLine._LayerCount - 1 do
          AddTimeLineLayer(i);
      end;

      if FTimeLine._FrameCount > 0 then
      begin
        for i := 0 to LayersRootItem.Count -1 do
          if TTimelineLayer(LayersRootItem.ItemByIndex(i)).LayerIndex = FTimeLine._ActiveLayer then
          begin
            wLayer := TTimelineLayer(LayersRootItem.ItemByIndex(i));
            wLayer.ItemButtons.Items[FTimeLine._ActiveFrame].Click;
          end;
      end;

      FSelectedFrame := FTimeLine._ActiveFrame;
      FSelectedLayer := FTimeLine._ActiveLayer;
    finally
      Self.EndUpdate;
    end;
  except
    On E:Exception do
      Raise Exception.create('[TTimelineDsgnDialog.SetTimeLine] : '+E.message);
  end;
end;

procedure TTimelineDsgnDialog.TimelineTimerTimer(Sender: TObject);
begin
  FTimeLine.DesignPreview := true;
  if (FTimeLine._ActiveFrame < FTimeLine._FrameCount - 1) then
  begin
//    MovePlayHead(FTimeLine._ActiveFrame + 1);
    CurrentFrameSpinBox.Value := CurrentFrameSpinBox.Value + 1;
  end
  else begin
//    MovePlayHead(0);
    CurrentFrameSpinBox.Value := 0;
  end;
end;

procedure TTimelineDsgnDialog.TreeView1ChangeCheck(Sender: TObject);
var i,j : Integer;
begin
  try
    if TTreeviewItem(Sender).name = LayersRootItem.Name then
    begin
      for i := 0 to LayersRootItem.Count -1 do
        LayersRootItem.Items[i].IsChecked := TTreeviewItem(Sender).IsChecked;
      for i := 0 to LayersRootItem.Count -1 do
        for j := 0 to FTimeLine._FrameCount -1 do
        begin
          FTimeLine.Item(j,TTimelineLayer(LayersRootItem.Items[i]).LayerIndex).Visibility := TTimelineLayer(LayersRootItem.Items[i]).IsChecked;
          FTimeLine.Item(j,TTimelineLayer(LayersRootItem.Items[i]).LayerIndex).Visible := TTimelineLayer(LayersRootItem.Items[i]).IsChecked;
        end;
    end
    else begin
        for j := 0 to FTimeLine._FrameCount -1 do
        begin
          FTimeLine.Item(j,TTimelineLayer(Sender).LayerIndex).Visibility    := TTimelineLayer(Sender).IsChecked;
          FTimeLine.Item(j,TTimelineLayer(Sender).LayerIndex).Visible := TTimelineLayer(Sender).IsChecked;
        end;
    end;
  except
    On E:Exception do
      Raise Exception.create('[TTimelineDsgnDialog.TreeView1ChangeCheck] : '+E.message);
  end;
end;

procedure TTimelineDsgnDialog.TreeView1DragChange(SourceItem,
  DestItem: TTreeViewItem; var Allow: Boolean);
var
  wTmpIndex : integer;
  wTmpY : Single;
  wTmpTxt : string;
begin
  try
    Allow := False;
    if (SourceItem is TTreeViewItem) and (DestItem is TTreeViewItem) and (SourceItem.Level= 2) and (DestItem.Level = 2)  then
    begin
      wTmpIndex := TTimelineLayer(SourceItem).LayerIndex;
      TTimelineLayer(SourceItem).LayerIndex := TTimelineLayer(DestItem).LayerIndex;
      TTimelineLayer(DestItem).LayerIndex := wTmpIndex;

      wTmpTxt := SourceItem.Text;
      SourceItem.Text := DestItem.Text;
      DestItem.Text := wTmpTxt;

      if (FTimeLine.Item(0,TTimelineLayer(DestItem).LayerIndex) <> nil) then
        TTimelineLayer(DestItem).ItemButtons[0].Click;
    end;
  except
    On E:Exception do
      Raise Exception.create('[TTimelineDsgnDialog.TreeView1DragChange] : '+E.message);
  end;
end;


procedure TTimelineDsgnDialog.LayersRootItemClick(Sender: TObject);
begin

end;

// fix scrollbar bug
procedure TTimelineDsgnDialog.UpdateScrollBarHeight;
var i : integer ;
begin
  try
    ScrollBox.Height := ScrollBox.Height + 1;
    ScrollBox.Height := ScrollBox.Height - 1;
    ScrollBox.Width := ScrollBox.Width - 1;
    for i := 0 to LayersRootItem.Count -1 do
      TTimelineLayer(LayersRootItem.ItemByIndex(i)).ItemsPanel.Position.Y := LAYER_HEIGHT + LAYER_HEIGHT * I;
  except
    On E:Exception do
      Raise Exception.create('[TTimelineDsgnDialog.UpdateScrollBarHeight] : '+E.message);
  end;
end;

procedure TTimelineDsgnDialog.UpdateZOrder;
var i,j,k : integer;
    wItem : TTimeLineItem;
begin
  try
    for i := LayersRootItem.Count -1 downto 0 do
    begin
      for j := 0 to FTimeLine._FrameCount -1 do
        for k := 0 to FTimeLine.ControlsCount -1 do
        begin
          wItem := TTimeLineItem(FTimeLine.Controls[k]);
          if (wItem.FrameIndex = j) and (wItem.LayerIndex = TTimelineLayer(LayersRootItem.ItemByIndex(i)).LayerIndex) then
          begin
            wItem.BringToFront;
            Break;
          end;
        end;
    end;
  except
    On E:Exception do
      Raise Exception.create('[TTimelineDsgnDialog.UpdateZOrder] : '+E.message);
  end;
end;

{ TRuler }

constructor TRuler.Create(AOwner: TComponent);
begin
  inherited;

  FLabels := TList<TLabel>.Create;
end;

destructor TRuler.Destroy;
begin
  FLabels.Free;

  inherited;
end;

procedure TRuler.Resize;
var
  W, I: Integer;
  T: Single;
begin
  inherited;

  W := Round(Self.Width) div LAYER_BUTTON_WIDTH;

  for I := 0 to W do
  begin
    if I > FLabels.Count - 1 then
    begin
      FLabels.Add(TLabel.Create(Self));
      FLabels.Items[I].Parent := Self;
      if I mod 5 = 0 then
        FLabels.Items[I].Text := intToStr(I)
      else
        FLabels.Items[I].Text := '|';
      T := (LAYER_BUTTON_WIDTH - FLabels.Items[I].Canvas.TextWidth(FLabels.Items[I].Text)) / 2;
      FLabels.Items[I].AutoSize := True;
      FLabels.Items[I].Position.Y := 0;
      FLabels.Items[I].Position.X := LAYER_LABEL_WIDTH + 5 + LAYER_BUTTON_WIDTH * (I) + T;
    end;
  end;
end;

{ TTimelineComponentEditor }
{$IFDEF DESIGN}
procedure TTimelineComponentEditor.ExecuteVerb(Index: Integer);
begin
  case Index of
    0: ShowEditor;
  else
    raise ENotImplemented.Create('TTimeline has only one verb (index = 0) supported.');
  end;
end;

function TTimelineComponentEditor.GetVerb(Index: Integer): string;
begin
  case Index of
    0: Result := '&Show Editor';
  else
    raise ENotImplemented.Create('TTimeline has only one verb (index = 0) supported.');
  end;
end;

function TTimelineComponentEditor.GetVerbCount: Integer;
begin
  Result := 1;
end;

procedure TTimelineComponentEditor.ShowEditor;
var
  EditorForm: TTimelineDsgnDialog;
begin
  EditorForm := TTimelineDsgnDialog.Create(nil);
  try
    EditorForm.TimeLine := TTimeline(Component);
    EditorForm.ShowModal;
    EditorForm.UpdateZOrder;
    Designer.Modified;
  finally
    EditorForm.Free;
  end;
end;
{$ENDIF}

end.
