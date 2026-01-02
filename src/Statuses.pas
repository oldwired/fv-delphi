{*******************************************************}
{       Free Vision - Status Views Unit                 }
{       Ported to Modern Delphi                         }
{*******************************************************}

{
  The Statuses unit implements several views for providing information to
  the user which needs to be updated during program execution, such as a
  progress indicator, gauges, spinners, etc. All status views respond to
  a new message event class, evStatus. An individual status view only
  processes an event with its associated command.

  Original: Written by Brad Williams, DVM
  Ported to Delphi: December 2025
}

unit Statuses;

{$I platform.inc}

interface

uses
  FVCommon, FVConsts, Objects, Drivers, Views, Dialogs;

const
  { Event class for status views }
  evStatus = $8000;

  { Palette for status views in windows/dialogs }
  CStatus = #1#2#3;

  { Palette for status views in application }
  CAppStatus = #2#5#4;

  { Palette for bar gauge - adds empty and filled bar colors }
  CBarGauge: ShortString = #1#2#3#16#19;

  { Button flags for TStatusDlg }
  sdNone         = $0000;
  sdCancelButton = $0001;
  sdPauseButton  = $0002;
  sdResumeButton = $0004;
  sdAllButtons   = sdCancelButton or sdPauseButton or sdResumeButton;

  { Spinner animation characters: | / - \ }
  SpinChars: ShortString = #179'/'#196'\';

  { State flag for paused status }
  sfPause = $F000;

type
  { Forward declarations }
  PStatus = ^TStatus;
  PStatusDlg = ^TStatusDlg;
  PStatusMessageDlg = ^TStatusMessageDlg;
  PGauge = ^TGauge;
  PArrowGauge = ^TArrowGauge;
  PPercentGauge = ^TPercentGauge;
  PBarGauge = ^TBarGauge;
  PSpinnerGauge = ^TSpinnerGauge;
  PAppStatus = ^TAppStatus;

  { TStatus - Base status view object }
  TStatus = object(TParamText)
    Command: Word;
    constructor Init(var R: TRect; ACommand: Word; const AText: ShortString;
                     AParamCount: SmallInt);
    constructor Load(var S: TStream);
    function Cancel: Boolean; virtual;
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure Pause; virtual;
    procedure Reset; virtual;
    procedure Resume; virtual;
    procedure Store(var S: TStream);
    procedure Update(Data: Pointer); virtual;
  end;

  { TStatusDlg - Dialog with status view and optional buttons }
  TStatusDlg = object(TDialog)
    Status: PStatus;
    constructor Init(const ATitle: TTitleStr; AStatus: PStatus; AFlags: Word);
    constructor Load(var S: TStream);
    procedure Cancel(ACommand: Word); virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure InsertButtons(AFlags: Word); virtual;
    procedure Store(var S: TStream);
  end;

  { TStatusMessageDlg - Status dialog with message text }
  TStatusMessageDlg = object(TStatusDlg)
    constructor Init(const ATitle: TTitleStr; AStatus: PStatus; AFlags: Word;
                     const AMessage: ShortString);
  end;

  { TGaugeRec - Record for TGauge data }
  PGaugeRec = ^TGaugeRec;
  TGaugeRec = record
    Min, Max, Current: LongInt;
  end;

  { TGauge - Numerical gauge }
  TGauge = object(TStatus)
    Min: LongInt;
    Max: LongInt;
    Current: LongInt;
    constructor Init(var R: TRect; ACommand: Word; AMin, AMax: LongInt);
    constructor Load(var S: TStream);
    procedure Draw; virtual;
    procedure GetData(var Rec); virtual;
    procedure Reset; virtual;
    procedure SetData(var Rec); virtual;
    procedure Store(var S: TStream);
    procedure Update(Data: Pointer); virtual;
  end;

  { TArrowGaugeRec - Record for TArrowGauge data }
  PArrowGaugeRec = ^TArrowGaugeRec;
  TArrowGaugeRec = record
    Min, Max, Count: LongInt;
    Right: Boolean;
  end;

  { TArrowGauge - Arrow-based progress indicator }
  TArrowGauge = object(TGauge)
    Right: Boolean;
    constructor Init(var R: TRect; ACommand: Word; AMin, AMax: Word;
                     RightArrow: Boolean);
    constructor Load(var S: TStream);
    procedure Draw; virtual;
    procedure GetData(var Rec); virtual;
    procedure SetData(var Rec); virtual;
    procedure Store(var S: TStream);
  end;

  { TPercentGauge - Percentage display gauge }
  TPercentGauge = object(TGauge)
    function Percent: SmallInt; virtual;
    procedure Draw; virtual;
  end;

  { TBarGauge - Progress bar with percentage }
  TBarGauge = object(TPercentGauge)
    procedure Draw; virtual;
    function GetPalette: PPalette; virtual;
  end;

  { TSpinnerGauge - Spinning animation indicator }
  TSpinnerGauge = object(TGauge)
    constructor Init(X, Y: SmallInt; ACommand: Word);
    procedure Draw; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure Update(Data: Pointer); virtual;
  end;

  { TAppStatus - Status for application (different palette) }
  TAppStatus = object(TStatus)
    function GetPalette: PPalette; virtual;
  end;

{ Stream registration records }
{ Note: Only types with their own Load/Store have registration records }
const
  RStatus: TStreamRec = (
    ObjType: idStatus;
    VmtLink: nil;
    Load: @TStatus.Load;
    Store: @TStatus.Store);

  RStatusDlg: TStreamRec = (
    ObjType: idStatusDlg;
    VmtLink: nil;
    Load: @TStatusDlg.Load;
    Store: @TStatusDlg.Store);

  RGauge: TStreamRec = (
    ObjType: idGauge;
    VmtLink: nil;
    Load: @TGauge.Load;
    Store: @TGauge.Store);

  RArrowGauge: TStreamRec = (
    ObjType: idArrowGauge;
    VmtLink: nil;
    Load: @TArrowGauge.Load;
    Store: @TArrowGauge.Store);

procedure RegisterStatuses;

implementation

uses
  System.SysUtils, MsgBox, App;

{****************************************************************************}
{ TStatus Object                                                             }
{****************************************************************************}

constructor TStatus.Init(var R: TRect; ACommand: Word; const AText: ShortString;
                         AParamCount: SmallInt);
begin
  inherited Init(R, AText, AParamCount);
  EventMask := EventMask or evStatus;
  Command := ACommand;
end;

constructor TStatus.Load(var S: TStream);
begin
  inherited Load(S);
  S.Read(Command, SizeOf(Command));
end;

function TStatus.Cancel: Boolean;
begin
  Result := True;
end;

function TStatus.GetPalette: PPalette;
const
  P: ShortString = CStatus;
begin
  Result := PPalette(@P);
end;

procedure TStatus.HandleEvent(var Event: TEvent);
begin
  if (Event.What = evCommand) and (Event.Command = cmStatusPause) then
  begin
    Pause;
    ClearEvent(Event);
  end;

  case Event.What of
    evStatus:
      case Event.Command of
        cmStatusDone:
          if Event.InfoPtr = @Self then
          begin
            Message(Owner, evStatus, cmStatusDone, @Self);
            ClearEvent(Event);
          end;
        cmStatusUpdate:
          if (Event.InfoWord = Command) and ((State and sfPause) = 0) then
          begin
            Update(Event.InfoPtr);
            { Don't clear event so multiple status views can respond }
          end;
        cmStatusResume:
          if (Event.InfoWord = Command) and ((State and sfPause) = sfPause) then
          begin
            Resume;
            ClearEvent(Event);
          end;
        cmStatusPause:
          if (Event.InfoWord = Command) and ((State and sfPause) = 0) then
          begin
            Pause;
            ClearEvent(Event);
          end;
      end;
  end;

  inherited HandleEvent(Event);
end;

procedure TStatus.Pause;
begin
  SetState(sfPause, True);
end;

procedure TStatus.Reset;
begin
  DrawView;
end;

procedure TStatus.Resume;
begin
  SetState(sfPause, False);
end;

procedure TStatus.Store(var S: TStream);
begin
  inherited Store(S);
  S.Write(Command, SizeOf(Command));
end;

procedure TStatus.Update(Data: Pointer);
begin
  Objects.DisposeStr(Text);
  if Data <> nil then
    Text := Objects.NewStr(ShortString(PAnsiChar(Data)))
  else
    Text := nil;
  DrawView;
end;

{****************************************************************************}
{ TStatusDlg Object                                                          }
{****************************************************************************}

constructor TStatusDlg.Init(const ATitle: TTitleStr; AStatus: PStatus; AFlags: Word);
var
  R: TRect;
begin
  R.A := AStatus^.Origin;
  R.B := AStatus^.Size;
  Inc(R.B.Y, R.A.Y + 4);
  Inc(R.B.X, R.A.X + 5);

  inherited Init(R, ATitle);
  EventMask := EventMask or evStatus;
  Status := AStatus;
  Status^.MoveTo(2, 2);
  Insert(Status);
  InsertButtons(AFlags);
end;

constructor TStatusDlg.Load(var S: TStream);
begin
  inherited Load(S);
  Status := PStatus(GetSubViewPtr(S, @Self));
end;

procedure TStatusDlg.Cancel(ACommand: Word);
begin
  if Status^.Cancel then
    inherited Cancel(ACommand);
end;

procedure TStatusDlg.HandleEvent(var Event: TEvent);
begin
  case Event.What of
    evStatus:
      case Event.Command of
        cmStatusDone:
          if Event.InfoPtr = Status then
          begin
            inherited Cancel(cmOK);
            ClearEvent(Event);
          end;
      end;
    evBroadcast, evCommand:
      case Event.Command of
        cmCancel, cmClose:
          begin
            Cancel(cmCancel);
            ClearEvent(Event);
          end;
        cmStatusPause:
          begin
            Status^.Pause;
            ClearEvent(Event);
          end;
        cmStatusResume:
          begin
            Status^.Resume;
            ClearEvent(Event);
          end;
      end;
  end;

  inherited HandleEvent(Event);
end;

procedure TStatusDlg.InsertButtons(AFlags: Word);
var
  P: PButton;
  Buttons: Byte;
  X, Y, Gap: SmallInt;
begin
  Buttons := Byte((AFlags and sdCancelButton) = sdCancelButton);
  { Add 2 for Pause and Resume buttons }
  Inc(Buttons, 2 * Byte((AFlags and sdPauseButton) = sdPauseButton));

  if Buttons > 0 then
  begin
    Status^.GrowMode := gfGrowHiX;

    { Resize dialog to hold all requested buttons }
    if Size.X < (Buttons * 12) + 2 then
      GrowTo((Buttons * 12) + 2, Size.Y + 2)
    else
      GrowTo(Size.X, Size.Y + 2);

    { Find correct starting position for first button }
    Gap := Size.X - (Buttons * 10) - 2;
    Gap := Gap div (Buttons + 1);
    X := Gap;
    if X < 2 then
      X := 2;
    Y := Size.Y - 3;

    { Insert buttons }
    if (AFlags and sdCancelButton) = sdCancelButton then
    begin
      P := NewButton(X, Y, 10, 2, 'Cancel', cmCancel, hcCancel, bfDefault);
      P^.GrowMode := gfGrowHiY or gfGrowLoY;
      Inc(X, 12 + Gap);
    end;

    if (AFlags and sdPauseButton) = sdPauseButton then
    begin
      P := NewButton(X, Y, 10, 2, '~P~ause', cmStatusPause, hcStatusPause, bfNormal);
      P^.GrowMode := gfGrowHiY or gfGrowLoY;
      Inc(X, 12 + Gap);
      P := NewButton(X, Y, 10, 2, '~R~esume', cmStatusResume, hcStatusResume, bfBroadcast);
      P^.GrowMode := gfGrowHiY or gfGrowLoY;
    end;
  end;

  SelectNext(False);
end;

procedure TStatusDlg.Store(var S: TStream);
begin
  inherited Store(S);
  PutSubViewPtr(S, Status);
end;

{****************************************************************************}
{ TStatusMessageDlg Object                                                   }
{****************************************************************************}

constructor TStatusMessageDlg.Init(const ATitle: TTitleStr; AStatus: PStatus;
                                   AFlags: Word; const AMessage: ShortString);
var
  P: PStaticText;
  X, Y: SmallInt;
  R: TRect;
begin
  inherited Init(ATitle, AStatus, AFlags);

  Status^.GrowMode := gfGrowLoY or gfGrowHiY;
  GetExtent(R);

  X := R.B.X - R.A.X;
  if X < Size.X then
    X := Size.X;
  Y := R.B.Y - R.A.Y;
  if Y < Size.Y then
    Y := Size.Y;
  GrowTo(X, Y);

  R.Assign(2, 2, Size.X - 2, Size.Y - 3);
  P := New(PStaticText, Init(R, AMessage));
  GrowTo(Size.X, Size.Y + P^.Size.Y + 1);
  Insert(P);
end;

{****************************************************************************}
{ TGauge Object                                                              }
{****************************************************************************}

constructor TGauge.Init(var R: TRect; ACommand: Word; AMin, AMax: LongInt);
begin
  inherited Init(R, ACommand, '', 1);
  Min := AMin;
  Max := AMax;
  Current := Min;
end;

constructor TGauge.Load(var S: TStream);
begin
  inherited Load(S);
  S.Read(Min, SizeOf(Min));
  S.Read(Max, SizeOf(Max));
  S.Read(Current, SizeOf(Current));
end;

procedure TGauge.Draw;
var
  S: ShortString;
  B: TDrawBuffer;
begin
  { Blank the gauge }
  MoveChar(B, ' ', GetColor(1), Size.X);
  { Write current status }
  FormatStr(S, '%d', Current);
  MoveStr(B, S, GetColor(1));
  WriteBuf(0, 0, Size.X, Size.Y, B);
end;

procedure TGauge.GetData(var Rec);
begin
  TGaugeRec(Rec).Min := Min;
  TGaugeRec(Rec).Max := Max;
  TGaugeRec(Rec).Current := Current;
end;

procedure TGauge.Reset;
begin
  Current := Min;
  DrawView;
end;

procedure TGauge.SetData(var Rec);
begin
  Min := TGaugeRec(Rec).Min;
  Max := TGaugeRec(Rec).Max;
  Current := TGaugeRec(Rec).Current;
end;

procedure TGauge.Store(var S: TStream);
begin
  inherited Store(S);
  S.Write(Min, SizeOf(Min));
  S.Write(Max, SizeOf(Max));
  S.Write(Current, SizeOf(Current));
end;

procedure TGauge.Update(Data: Pointer);
begin
  if Current < Max then
  begin
    Inc(Current);
    DrawView;
  end
  else
    Message(@Self, evStatus, cmStatusDone, @Self);
end;

{****************************************************************************}
{ TArrowGauge Object                                                         }
{****************************************************************************}

constructor TArrowGauge.Init(var R: TRect; ACommand: Word; AMin, AMax: Word;
                             RightArrow: Boolean);
begin
  inherited Init(R, ACommand, AMin, AMax);
  Right := RightArrow;
end;

constructor TArrowGauge.Load(var S: TStream);
begin
  inherited Load(S);
  S.Read(Right, SizeOf(Right));
end;

procedure TArrowGauge.Draw;
const
  Arrows: array[Boolean] of AnsiChar = ('<', '>');
var
  B: TDrawBuffer;
  C: Word;
  Len: SmallInt;
  Range: LongInt;
begin
  C := GetColor(1);
  Range := Max - Min;
  if Range <= 0 then Range := 1;
  Len := Round(Size.X * Current / Range);
  if Len > Size.X then Len := Size.X;
  if Len < 0 then Len := 0;

  MoveChar(B, ' ', C, Size.X);
  if Right then
    MoveChar(B, Arrows[Right], C, Len)
  else
    MoveChar(B[Size.X - Len], Arrows[Right], C, Len);
  WriteLine(0, 0, Size.X, 1, B);
end;

procedure TArrowGauge.GetData(var Rec);
begin
  TArrowGaugeRec(Rec).Min := Min;
  TArrowGaugeRec(Rec).Max := Max;
  TArrowGaugeRec(Rec).Count := Current;
  TArrowGaugeRec(Rec).Right := Right;
end;

procedure TArrowGauge.SetData(var Rec);
begin
  Min := TArrowGaugeRec(Rec).Min;
  Max := TArrowGaugeRec(Rec).Max;
  Current := TArrowGaugeRec(Rec).Count;
  Right := TArrowGaugeRec(Rec).Right;
end;

procedure TArrowGauge.Store(var S: TStream);
begin
  inherited Store(S);
  S.Write(Right, SizeOf(Right));
end;

{****************************************************************************}
{ TPercentGauge Object                                                       }
{****************************************************************************}

function TPercentGauge.Percent: SmallInt;
begin
  if Max = 0 then
    Result := 0
  else
    Result := Round((Current / Max) * 100);
end;

procedure TPercentGauge.Draw;
var
  B: TDrawBuffer;
  C: Word;
  S: ShortString;
  PercentDone: LongInt;
  CenterPos: SmallInt;
begin
  C := GetColor(1);
  MoveChar(B, ' ', C, Size.X);
  PercentDone := Percent;
  FormatStr(S, '%d%%', PercentDone);
  CenterPos := (Size.X - Length(S)) div 2;
  if CenterPos < 0 then CenterPos := 0;
  MoveStr(B[CenterPos], S, C);
  WriteLine(0, 0, Size.X, Size.Y, B);
end;

{****************************************************************************}
{ TBarGauge Object                                                           }
{****************************************************************************}

procedure TBarGauge.Draw;
var
  B: TDrawBuffer;
  C: Word;
  FillSize: SmallInt;
  PercentDone: LongInt;
  S: ShortString;
  CenterPos: SmallInt;
begin
  { Fill entire view with empty bar color }
  MoveChar(B, ' ', GetColor(4), Size.X);

  { Make progress bar with filled color }
  C := GetColor(5);
  if Max > 0 then
    FillSize := Round(Size.X * (Current / Max))
  else
    FillSize := 0;
  if FillSize > Size.X then FillSize := Size.X;
  if FillSize < 0 then FillSize := 0;
  MoveChar(B, ' ', C, FillSize);

  { Display percent done in center }
  PercentDone := Percent;
  FormatStr(S, '%d%%', PercentDone);
  { Use empty bar color for text if less than 50% }
  if PercentDone < 50 then
    C := GetColor(4);
  CenterPos := (Size.X - Length(S)) div 2;
  if CenterPos < 0 then CenterPos := 0;
  MoveStr(B[CenterPos], S, C);

  WriteLine(0, 0, Size.X, Size.Y, B);
end;

function TBarGauge.GetPalette: PPalette;
const
  S: ShortString = #1#2#3#16#19;  { CBarGauge }
begin
  Result := PPalette(@S);
end;

{****************************************************************************}
{ TSpinnerGauge Object                                                       }
{****************************************************************************}

constructor TSpinnerGauge.Init(X, Y: SmallInt; ACommand: Word);
var
  R: TRect;
begin
  R.Assign(X, Y, X + 1, Y + 1);
  inherited Init(R, ACommand, 1, 4);
end;

procedure TSpinnerGauge.Draw;
var
  B: TDrawBuffer;
  C: Word;
begin
  C := GetColor(1);
  MoveChar(B, ' ', C, Size.X);
  { SpinChars is 1-based in Pascal, Current ranges from 1 to 4 }
  if (Current >= 1) and (Current <= Length(SpinChars)) then
    MoveChar(B[Size.X div 2], SpinChars[Current], C, 1);
  WriteLine(0, 0, Size.X, Size.Y, B);
end;

procedure TSpinnerGauge.HandleEvent(var Event: TEvent);
begin
  { Call TStatus.HandleEvent directly to avoid cmStatusDone when Current = Max }
  TStatus.HandleEvent(Event);
end;

procedure TSpinnerGauge.Update(Data: Pointer);
begin
  if Current = Max then
    Current := Min
  else
    Inc(Current);
  DrawView;
end;

{****************************************************************************}
{ TAppStatus Object                                                          }
{****************************************************************************}

function TAppStatus.GetPalette: PPalette;
const
  P: ShortString = CAppStatus;
begin
  Result := PPalette(@P);
end;

{****************************************************************************}
{ Global procedures                                                          }
{****************************************************************************}

procedure RegisterStatuses;
begin
  RegisterType(RStatus);
  RegisterType(RStatusDlg);
  RegisterType(RGauge);
  RegisterType(RArrowGauge);
end;

end.
