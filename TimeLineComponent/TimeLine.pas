unit TimeLine;

interface

uses System.SysUtils, System.Classes, System.Generics.Collections, System.Math, System.UITypes,
  FMX.Types, FMX.Controls, FMX.Layouts, FMX.Forms, FMX.Dialogs;

type
  [ComponentPlatformsAttribute(pidWin32 or pidWin64 or pidOSX32 or pidiOSSimulator or pidiOSDevice or pidAndroid)]
  TTimeLine = class;

  TOnFrame = procedure(Sender : TObject; AFrameIdx : integer) of Object;
  TTimeLineItem = class(TControl)
  private
    FTimeLine: TTimeLine;
    FFrameIndex: Word;
    FLayerIndex: Word;
    fVisibilty : Boolean;
    procedure SetFrameIndex(const Value: Word);
    procedure SetLayerIndex(const Value: Word);
  protected
  {$IF CompilerVersion >= 28.0}
    procedure ParentChanged; override;
  {$ELSE}
    procedure ChangeParent; override;
  {$ENDIF}
    function GetCanFocus: boolean; override;

    procedure DoActivate; override;
    procedure DoEnter; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property FrameIndex: Word read FFrameIndex write SetFrameIndex stored True;
    property LayerIndex: Word read FLayerIndex write SetLayerIndex stored True;
    property Visibility : Boolean read fVisibilty write fVisibilty default true;
  end;

  TTimeLine = class(TLayout)
  private
    FFrameRate: Word;
    FFrameCount: Word;
    FLayerCount: Word;
    FActiveFrame: Word;
    FActiveLayer: Word;
    FCurrentFrame: Word;
    FTimeLineItems: TList<Pointer>;
    FUpdatingItems: Boolean;
    FLayerVisible : Boolean;

    FContinue: Boolean;
    FTimer: TTimer;
    FReady: Boolean;
    fOnFrame : TOnFrame;

    FParentForm: TCommonCustomForm;

    procedure TimerTimer(Sender: TObject);

    procedure SetFrameRate(const Value: Word);
    procedure SetFrameCount(const Value: Word);
    procedure SetLayerCount(const Value: Word);
    procedure SetActiveFrame(const Value: Word);
    procedure SetActiveLayer(const Value: Word);
    procedure SetCurrentFrame(const Value: Word);

    procedure CheckFrameVisibility;
    procedure CheckActiveLayout;
    procedure DataChanged;
    procedure UpdateItemContentBounds(LItem: TTimeLineItem);
    procedure ItemIndexChanged(AItem: TTimeLineItem);
    procedure FindComponentClass(Reader: TReader; const ClassName: string; var ComponentClass: TComponentClass);
    procedure UpdateComponentNames;
    function GetTimeLineItemsCount : integer;
  protected
    procedure DoAddObject(const AObject: TFmxObject); override;
    procedure DoRealign; override;
    procedure Resize; override;
    procedure ReadState(Reader: TReader); override;
  {$IF CompilerVersion >= 28.0}
    procedure ParentChanged; override;
  {$ELSE}
    procedure ChangeParent; override;
  {$ENDIF}
    procedure Loaded;override;
  public
    DesignPreview : Boolean;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Item(AFrame, ALayer: Word): TTimeLineItem;
    procedure DeleteLayer(ALayerIndex: Word);
    procedure DeleteFrame(AFrameIndex: Word);
    procedure GotoAndPlay(AFrameIndex: Word);
    procedure GotoAndStop(AFrameIndex: Word);
    procedure ExchangeLayers(ALayer1,ALayer2 : Integer);
    procedure ReplaceItem(AOldItem, ANewItem : TTimeLineItem);

    procedure Play;
    procedure Stop;
    procedure Next;
    procedure Prev;

    property Itemscount : integer read GetTimeLineItemsCount;
  published
    property _FrameRate: Word read FFrameRate write SetFrameRate Stored 24;
    property _FrameCount: Word read FFrameCount write SetFrameCount Stored True default 1;
    property _LayerCount: Word read FLayerCount write SetLayerCount Stored True default 1;
    property _ActiveFrame: Word read FActiveFrame write SetActiveFrame Stored False;
    property _ActiveLayer: Word read FActiveLayer write SetActiveLayer Stored False;
    property _CurrentFrame: Word read FCurrentFrame write SetCurrentFrame Stored True;
    property OnFrame : TOnFrame read fOnFrame write fOnFrame;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('xComponent', [TTimeLine]);
end;


{ TTimeLine }

{$IF CompilerVersion >= 28.0}
procedure TTimeLine.ParentChanged;
{$ELSE}
procedure TTimeLine.ChangeParent;
{$ENDIF}
  function FindParentForm: TCommonCustomForm;
  var
    P: TFmxObject;
  begin
    P := Parent;
    while Assigned(P) do
    begin
      if P is TCommonCustomForm then
      begin
        Result := P as TCommonCustomForm;
        Exit;
      end;
      P := P.Parent;
    end;
    Result := nil;
  end;

begin
  inherited;
  FParentForm := FindParentForm;
end;



procedure TTimeLine.Loaded;
begin
  if csDesigning in ComponentState then
  begin
 // {$IFDEF MSWINDOWS}
    TTimeLineItem(FTimeLineItems[0]).Free;  // a small hack to avoid Framecount and Layercount initialization in the constructor
    FTimeLineItems.Delete(0);               // testing the csupdate didn't work
  end;
 // {$ENDIF}
  inherited;
end;

procedure TTimeLine.CheckActiveLayout;
begin
  if FActiveFrame > FFrameCount then
    FActiveFrame := FFrameCount;
  if FActiveLayer > FLayerCount then
    FActiveLayer := FLayerCount;
end;

procedure TTimeLine.CheckFrameVisibility;
var
  I: Integer;
begin
  if csDestroying in ComponentState then
    Exit;

  if csDesigning in ComponentState then
  begin
    if DesignPreview then
    begin
      for I := 0 to FTimeLineItems.Count - 1 do
        TTimeLineItem(FTimeLineItems[I]).Visible := (TTimeLineItem(FTimeLineItems[I]).FFrameIndex = FActiveFrame);
    end
    else begin
      for I := 0 to FTimeLineItems.Count - 1 do
        TTimeLineItem(FTimeLineItems[I]).Visible := (TTimeLineItem(FTimeLineItems[I]).FFrameIndex = FActiveFrame) and (TTimeLineItem(FTimeLineItems[I]).FLayerIndex = FActiveLayer);
    end;
  end
  else
  begin
    for I := 0 to FTimeLineItems.Count - 1 do
    begin
      TTimeLineItem(FTimeLineItems[I]).Visible := (TTimeLineItem(FTimeLineItems[I]).Visibility) and  (TTimeLineItem(FTimeLineItems[I]).FFrameIndex = FCurrentFrame);
    end
  end;
end;

constructor TTimeLine.Create(AOwner: TComponent);
begin
  inherited;

  FTimeLineItems := TList<Pointer>.Create;
  FTimer := TTimer.Create(nil);
  FFrameRate := 24;
  FTimer.Interval := Round(1000/FFrameRate);
  FTimer.OnTimer := TimerTimer;

  if ([csDesigning, csLoading] * ComponentState<>[]) then
  begin
    _FrameCount := 1;
    _LayerCount := 1;
  end;

  FTimer.Enabled := True;
  FContinue := True;
  AutoCapture := True;
  Play;
end;

procedure TTimeLine.TimerTimer(Sender: TObject);
begin
  if FReady AND FContinue then
   begin
    FReady := False;

    if FCurrentFrame<FFrameCount-1 then
      begin
        GotoAndPlay(FCurrentFrame+1);
      end
    else
     begin
        GotoAndPlay(0);
     end;
   end
   else
   begin
    FReady := False;
   end;
end;


procedure TTimeLine.DataChanged;
begin
  CheckFrameVisibility;
  CheckActiveLayout;
  if FContinue then
   begin
    FReady := True;
   end
  else
   begin
    FReady := False;
   end;
end;



procedure TTimeLine.DeleteFrame(AFrameIndex: Word);
var
  I: Integer;
begin
  if AFrameIndex > FFrameCount - 1 then
    raise Exception.Create('Out of bounds');
  if FFrameCount = 0 then
    Exit;

  FUpdatingItems := True;

  for I := FTimeLineItems.Count - 1 downto 0 do
  begin
    if TTimeLineItem(FTimeLineItems.Items[I]).FrameIndex = AFrameIndex then
    begin
      TTimeLineItem(FTimeLineItems.Items[I]).Free;
      FTimeLineItems.Delete(I);
    end
    else if TTimeLineItem(FTimeLineItems.Items[I]).FrameIndex > AFrameIndex then
    begin
      TTimeLineItem(FTimeLineItems.Items[I]).FrameIndex := TTimeLineItem(FTimeLineItems.Items[I]).FrameIndex - 1;
    end;
  end;
  FFrameCount := FFrameCount - 1;
  FActiveFrame := Max(0, FActiveFrame - 1);

  UpdateComponentNames;
  DataChanged;
  FUpdatingItems := False;
end;

procedure TTimeLine.DeleteLayer(ALayerIndex: Word);
var
  I: Integer;
begin
  if ALayerIndex > FLayerCount - 1 then
    raise Exception.Create('Out of bounds');
  if FLayerCount = 0 then
    Exit;

  FUpdatingItems := True;

  for I := FTimeLineItems.Count - 1 downto 0 do
  begin
    if TTimeLineItem(FTimeLineItems.Items[I]).LayerIndex = ALayerIndex then
    begin
      TTimeLineItem(FTimeLineItems.Items[I]).Free;
      FTimeLineItems.Delete(I);
    end
    else if TTimeLineItem(FTimeLineItems.Items[I]).LayerIndex > ALayerIndex then
    begin
      TTimeLineItem(FTimeLineItems.Items[I]).LayerIndex := TTimeLineItem(FTimeLineItems.Items[I]).LayerIndex - 1;
    end;
  end;
  FLayerCount := FLayerCount - 1;
  FActiveLayer := Max(0, FActiveLayer - 1);

  UpdateComponentNames;
  DataChanged;
  FUpdatingItems := False;
end;

destructor TTimeLine.Destroy;
var
  I: Integer;
begin
  for I := FTimeLineItems.Count - 1 downto 0 do
    TTimeLineItem(FTimeLineItems.Items[I]).Free;
  FTimeLineItems.Free;
  FTimer.Free;
  inherited;
end;

procedure TTimeLine.DoAddObject(const AObject: TFmxObject);
var
  ActiveItem: TTimeLineItem;
begin
  if AObject is TTimeLineItem then
  begin
    if not FUpdatingItems then
      FTimeLineItems.Add(Pointer(AObject));

    inherited DoAddObject(AObject);
  end
  else
  begin
    ActiveItem := Item(_ActiveFrame, _ActiveLayer);
    if ActiveItem <> nil then
      ActiveItem.AddObject(AObject)
    else
      inherited DoAddObject(AObject);
  end;
end;

procedure TTimeLine.DoRealign;
var
  I: Integer;
begin
  if FDisableAlign or FUpdatingItems then
    Exit;
  FDisableAlign := True;
  try
    CheckFrameVisibility;

    for I := 0 to FTimeLineItems.Count - 1 do
      UpdateItemContentBounds(TTimeLineItem(FTimeLineItems[I]));
  finally
    FDisableAlign := False;
  end;
end;

function TTimeLine.Item(AFrame, ALayer: Word): TTimeLineItem;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to FTimeLineItems.Count - 1 do
    if (TTimeLineItem(FTimeLineItems[I]).FrameIndex = AFrame) and (TTimeLineItem(FTimeLineItems[I]).LayerIndex = ALayer) then
    begin
      Result := TTimeLineItem(FTimeLineItems[I]);
      Break;
    end;
end;

procedure TTimeLine.ItemIndexChanged(AItem: TTimeLineItem);
begin
  if (not FUpdatingItems) and (not (csLoading in ComponentState)) then
  begin
    FFrameCount := Max(FFrameCount, AItem.FrameIndex + 1);
    FLayerCount := Max(FLayerCount, AItem.LayerIndex + 1);
  end;
end;

procedure TTimeLine.ReadState(Reader: TReader);
begin
  Reader.OnFindComponentClass := FindComponentClass;
  inherited;
end;

procedure TTimeLine.FindComponentClass(Reader: TReader; const ClassName: string; var ComponentClass: TComponentClass);
begin
  if ClassName = 'TTimeLineItem' then
    ComponentClass := TTimeLineItem;
end;

procedure TTimeLine.Resize;
begin
  inherited;

  DoRealign;
end;

procedure TTimeLine.SetFrameRate(const Value: Word);
begin
  FFrameRate := Value;
  FTimer.Enabled := False;
  FTimer.Interval := Round(1000/FFrameRate);
  FTimer.Enabled := True;
end;


procedure TTimeLine.SetActiveFrame(const Value: Word);
begin
  if (Value > FFrameCount - 1) and (Value <> 0) then
    raise Exception.Create('Out of bounds');
  FActiveFrame := Value;
  DataChanged;
end;

procedure TTimeLine.SetActiveLayer(const Value: Word);
begin
  if Value < FLayerCount then
  begin
    FActiveLayer := Value;
    DataChanged;
  end;
end;

procedure TTimeLine.SetCurrentFrame(const Value: Word);
begin
  if FCurrentFrame = Value then
    Exit;

  FCurrentFrame := Value;
  DataChanged;
end;

procedure TTimeLine.GotoAndPlay(AFrameIndex: Word);
begin
  FContinue := True;
  FCurrentFrame := AFrameIndex;
  DataChanged;
  if Assigned(fOnFrame) then
    fOnFrame(Self, AFrameIndex);
end;

procedure TTimeLine.GotoAndStop(AFrameIndex: Word);
begin
  FContinue := False;
  SetCurrentFrame(AFrameIndex);
end;

procedure TTimeLine.ExchangeLayers(ALayer1,ALayer2 : Integer);
var i : integer;
begin
  for i := 0 to FTimeLineItems.count -1 do
  begin
    if TTimeLineItem( FTimeLineItems[i] ).LayerIndex = ALayer1 then
      TTimeLineItem( FTimeLineItems[i] ).LayerIndex := ALayer2
    else if TTimeLineItem( FTimeLineItems[i] ).LayerIndex = ALayer2 then
      TTimeLineItem( FTimeLineItems[i] ).LayerIndex := ALayer1
  end;

  UpdateComponentNames;
end;


procedure TTimeLine.ReplaceItem(AOldItem, ANewItem : TTimeLineItem);
var wIdx : integer;
begin
  try
  //  wIdx := FTimeLineItems.IndexOf(Pointer(AOldItem));
  //  FTimeLineItems.Delete(wIdx);
    RemoveObject(AOldItem);
    wIdx := FTimeLineItems.Remove(AOldItem);
    AOldItem.Parent := nil;
    AOldItem.Free;

  //  FTimeLineItems.Add(POINTER(ANewItem));
  //  ANewItem.parent := Self;
  except
    On E:Exception do
      Raise Exception.create('[TTimeLine.ReplaceItem] : '+E.message);
  end;
end;


procedure TTimeLine.Play;
begin
  if FCurrentFrame<FFrameCount-1 then
    begin
      GotoAndPlay(FCurrentFrame+1);
    end
  else
   begin
      GotoAndPlay(0);
   end;
end;

procedure TTimeLine.Next;
begin
  if FCurrentFrame<FFrameCount-1 then
    begin
      GotoAndStop(FCurrentFrame+1);
    end
  else
   begin
      GotoAndStop(0);
   end;
end;

procedure TTimeLine.Prev;
begin
  if FCurrentFrame>0 then
    begin
      GotoAndStop(FCurrentFrame-1);
    end
  else
   begin
      GotoAndStop(FFrameCount-1);
   end;
end;

procedure TTimeLine.Stop;
begin
  FContinue := False;
end;


procedure TTimeLine.SetFrameCount(const Value: Word);
var
  I, J, T: Integer;
begin

  try
    if csLoading in ComponentState then
    begin
      FFrameCount := Value;
      Exit;
    end;
    if FFrameCount = Value then
      Exit;
    if FLayerCount = 0 then
    begin
      FFrameCount := Value;
      Exit;
    end;

    FUpdatingItems := True;

    if FFrameCount > Value then
    begin
      for I := FTimeLineItems.Count - 1 downto 0 do
      begin
        if TTimeLineItem(FTimeLineItems.Items[I]).FFrameIndex >= Value then
        begin
          TTimeLineItem(FTimeLineItems.Items[I]).Free;
          FTimeLineItems.Delete(I);
        end;
      end;
    end
    else
    begin
      if not (csLoading in ComponentState) then
      begin
        for I := FFrameCount to Value - 1 do
          for J := 0 to FLayerCount - 1 do
          begin
              T := FTimeLineItems.Add(Pointer(TTimeLineItem.Create(Self)));
              TTimeLineItem(FTimeLineItems[T]).Parent := Self;
              TTimeLineItem(FTimeLineItems[T]).FrameIndex := I;
              TTimeLineItem(FTimeLineItems[T]).LayerIndex := J;
              TTimeLineItem(FTimeLineItems[T]).Visible := TTimeLineItem(FTimeLineItems[T]).Visibility;
              TTimeLineItem(FTimeLineItems[T]).Name := 'F' + IntToStr(TTimeLineItem(FTimeLineItems[T]).FrameIndex) +
                                                       '_L' + IntToStr(TTimeLineItem(FTimeLineItems[T]).LayerIndex);
          end;
      end;
    end;
    FFrameCount := Value;
    DataChanged;
    FUpdatingItems := False;
  except
    On E:Exception do
      Raise Exception.create('[TTimeLine.SetFrameCount] : '+E.message);
  end;
end;

procedure TTimeLine.SetLayerCount(const Value: Word);
var
  I, J, T: Integer;
begin
  try
    // to enable once the debug finish
    if csLoading in ComponentState then
    begin
      FLayerCount := Value;
      Exit;
    end;

    if FLayerCount = Value then
      Exit;

    if (FFrameCount = 0) then
    begin
      FLayerCount := Value;
      Exit;
    end;

    FUpdatingItems := True;

    if FLayerCount > Value then
    begin
      for I := FTimeLineItems.Count - 1 downto 0 do
      begin
        if TTimeLineItem(FTimeLineItems.Items[I]).FLayerIndex >= Value then
        begin
          TTimeLineItem(FTimeLineItems.Items[I]).Free;
          FTimeLineItems.Delete(I);
        end;
      end;
    end
    else
    begin
      if not (csLoading in ComponentState) then
      begin
        for I := 0 to FFrameCount - 1 do
          for J := FLayerCount to Value - 1 do
          begin
              T := FTimeLineItems.Add(Pointer(TTimeLineItem.Create(Self)));
              TTimeLineItem(FTimeLineItems[T]).Parent := Self;
              TTimeLineItem(FTimeLineItems[T]).Visible := TTimeLineItem(FTimeLineItems[T]).Visibility;
              TTimeLineItem(FTimeLineItems[T]).FrameIndex := I;
              TTimeLineItem(FTimeLineItems[T]).LayerIndex := J;
              TTimeLineItem(FTimeLineItems[T]).Name := 'F' + IntToStr(TTimeLineItem(FTimeLineItems[T]).FrameIndex) +
                                                       '_L' + IntToStr(TTimeLineItem(FTimeLineItems[T]).LayerIndex);
          end;
      end;
    end;

    FLayerCount := Value;
    DataChanged;
    FUpdatingItems := False;
  except
    On E:Exception do
      Raise Exception.create('[TTimeLine.SetLayerCount] : '+E.message);
  end;
end;

procedure TTimeLine.UpdateComponentNames;
var
  I: Integer;
begin
  for I := 0 to FTimeLineItems.Count - 1 do
  begin
    TTimeLineItem(FTimeLineItems[I]).Name := 'x_' + TTimeLineItem(FTimeLineItems[I]).Name;
  end;

  for I := 0 to FTimeLineItems.Count - 1 do
  begin
    TTimeLineItem(FTimeLineItems[I]).Name := 'F' + IntToStr(TTimeLineItem(FTimeLineItems[I]).FrameIndex) +
                                             '_L' + IntToStr(TTimeLineItem(FTimeLineItems[I]).LayerIndex);
  end;
end;


function TTimeLine.GetTimeLineItemsCount: integer; // Added bu khalid 29/05/2014
begin
  Result := FTimeLineItems.Count;
end;


procedure TTimeLine.UpdateItemContentBounds(LItem: TTimeLineItem);
begin
  LItem.SetBounds(0, 0, Self.Width, Self.Height);
end;

{ TTimeLineLayout }

{$IF CompilerVersion >= 28.0}
  procedure TTimeLineItem.ParentChanged;
{$ELSE}
  procedure TTimeLineItem.ChangeParent;
{$ENDIF}
  function FindTimeLine: TTimeLine;
  var
    P: TFmxObject;
  begin
    P := Parent;
    while Assigned(P) do
    begin
      if P is TTimeLine then
      begin
        Result := P as TTimeLine;
        Exit;
      end;
      P := P.Parent;
    end;
    Result := nil;
  end;

begin
  inherited;
  FTimeLine := FindTimeLine;
end;

constructor TTimeLineItem.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  HitTest := False;
  FDesignInteractive := False;
  Locked := True;
  CanFocus := False;
  Align := TAlignLayout.Client;
  Visibility := True;
end;

procedure TTimeLineItem.DoActivate;
begin
  inherited;

  FTimeLine.CheckFrameVisibility;
end;

procedure TTimeLineItem.DoEnter;
begin
  inherited;

  FTimeLine.CheckFrameVisibility;
end;

function TTimeLineItem.GetCanFocus: boolean;
begin
  Result := True;
end;

procedure TTimeLineItem.SetFrameIndex(const Value: Word);
begin
  FFrameIndex := Value;
  if Assigned(FTimeLine) then
    FTimeLine.ItemIndexChanged(Self);
end;

procedure TTimeLineItem.SetLayerIndex(const Value: Word);
begin
  FLayerIndex := Value;
  if Assigned(FTimeLine) then
    FTimeLine.ItemIndexChanged(Self);
end;

end.
