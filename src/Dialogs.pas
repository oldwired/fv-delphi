{*******************************************************}
{       Free Vision Dialogs Unit                        }
{       Delphi-compatible version                       }
{*******************************************************}

unit Dialogs;

{$I platform.inc}
{$R-}

interface

uses
  {$IFDEF OS_WINDOWS}
  Winapi.Windows,
  {$ENDIF}
  System.SysUtils,
  FVCommon, Objects, Drivers, Views, fvconsts, Validate, HistList;

{***************************************************************************}
{                              PUBLIC CONSTANTS                             }
{***************************************************************************}

const
  { Dialog color palettes }
  CGrayDialog = #32#33#34#35#36#37#38#39#40#41#42#43#44#45#46#47 +
                #48#49#50#51#52#53#54#55#56#57#58#59#60#61#62#63;
  CBlueDialog = #64#65#66#67#68#69#70#71#72#73#74#75#76#77#78#79 +
                #80#81#82#83#84#85#86#87#88#89#90#91#92#92#94#95;
  CCyanDialog = #96#97#98#99#100#101#102#103#104#105#106#107#108 +
                #109#110#111#112#113#114#115#116#117#118#119#120 +
                #121#122#123#124#125#126#127;

  CStaticText    = #6#7#8#9;
  CLabel         = #7#8#9#9;
  CButton        = #10#11#12#13#14#14#14#15;
  CCluster       = #16#17#18#18#31#6;
  CInputLine     = #19#20#20#21#14;  { Passive, Active, Selected, Arrows, Arrows-disabled }
  CHistory       = #22#23;
  CHistoryWindow = #19#19#21#24#25#19#20;
  CHistoryViewer = #6#6#7#6#6;

  CDialog = CGrayDialog;

  { TDialog palette constants }
  dpBlueDialog = 0;
  dpCyanDialog = 1;
  dpGrayDialog = 2;

  { TButton flags }
  bfNormal    = $00;
  bfDefault   = $01;
  bfLeftJust  = $02;
  bfBroadcast = $04;
  bfGrabFocus = $08;

  { Dialog broadcast commands }
  cmRecordHistory = 60;

{***************************************************************************}
{                            TYPE DEFINITIONS                               }
{***************************************************************************}

type
  PSItem = ^TSItem;
  TSItem = record
    Value: PString;
    Next: PSItem;
  end;

{***************************************************************************}
{                            OBJECT DEFINITIONS                             }
{***************************************************************************}

type
  PInputLine = ^TInputLine;
  TInputLine = object(TView)
    MaxLen: Integer;
    CurPos: Integer;
    FirstPos: Integer;
    SelStart: Integer;
    SelEnd: Integer;
    Data: PString;
    Validator: PValidator;
    constructor Init(var Bounds: TRect; AMaxLen: Integer);
    destructor Done; virtual;
    function DataSize: Word; virtual;
    function GetPalette: PPalette; virtual;
    function Valid(Command: Word): Boolean; virtual;
    procedure Draw; virtual;
    procedure DrawCursor; virtual;
    procedure SelectAll(Enable: Boolean);
    procedure SetValidator(AValid: PValidator);
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure GetData(var Rec); virtual;
    procedure SetData(var Rec); virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  private
    function CanScroll(Delta: Integer): Boolean;
    function ScreenCurPos: Integer;
  end;

  PButton = ^TButton;
  TButton = object(TView)
    AmDefault: Boolean;
    Flags: Byte;
    Command: Word;
    Title: PString;
    constructor Init(var Bounds: TRect; ATitle: TTitleStr; ACommand: Word; AFlags: Word);
    destructor Done; virtual;
    function GetPalette: PPalette; virtual;
    procedure Press; virtual;
    procedure Draw; virtual;
    procedure DrawState(Down: Boolean);
    procedure MakeDefault(Enable: Boolean);
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  private
    DownFlag: Boolean;
  end;

  PCluster = ^TCluster;
  TCluster = object(TView)
    Id: Integer;
    Sel: Integer;
    Value: LongInt;
    EnableMask: LongInt;
    Strings: TStringCollection;
    constructor Init(var Bounds: TRect; AStrings: PSItem);
    destructor Done; virtual;
    function DataSize: Word; virtual;
    function GetHelpCtx: Word; virtual;
    function GetPalette: PPalette; virtual;
    function Mark(Item: Integer): Boolean; virtual;
    function MultiMark(Item: Integer): Byte; virtual;
    function ButtonState(Item: Integer): Boolean;
    procedure Draw; virtual;
    procedure Press(Item: Integer); virtual;
    procedure MovedTo(Item: Integer); virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure DrawMultiBox(const Icon, Marker: ShortString);
    procedure DrawBox(const Icon: ShortString; Marker: AnsiChar);
    procedure SetButtonState(AMask: LongInt; Enable: Boolean);
    procedure GetData(var Rec); virtual;
    procedure SetData(var Rec); virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  private
    function FindSel(P: TPoint): Integer;
    function Row(Item: Integer): Integer;
    function Column(Item: Integer): Integer;
  end;

  PRadioButtons = ^TRadioButtons;
  TRadioButtons = object(TCluster)
    function Mark(Item: Integer): Boolean; virtual;
    procedure Draw; virtual;
    procedure Press(Item: Integer); virtual;
    procedure MovedTo(Item: Integer); virtual;
    procedure SetData(var Rec); virtual;
  end;

  PCheckBoxes = ^TCheckBoxes;
  TCheckBoxes = object(TCluster)
    function Mark(Item: Integer): Boolean; virtual;
    procedure Draw; virtual;
    procedure Press(Item: Integer); virtual;
  end;

  PListBox = ^TListBox;
  TListBox = object(TListViewer)
    List: PCollection;
    constructor Init(var Bounds: TRect; ANumCols: Word; AScrollBar: PScrollBar);
    function DataSize: Word; virtual;
    function GetText(Item: Integer; MaxLen: Integer): string; virtual;
    procedure NewList(AList: PCollection); virtual;
    procedure GetData(var Rec); virtual;
    procedure SetData(var Rec); virtual;
  end;

  PStaticText = ^TStaticText;
  TStaticText = object(TView)
    Text: PString;
    constructor Init(var Bounds: TRect; const AText: ShortString);
    constructor Load(var S: TStream);
    destructor Done; virtual;
    function GetPalette: PPalette; virtual;
    procedure Draw; virtual;
    procedure GetText(var S: ShortString); virtual;
    procedure Store(var S: TStream);
  end;

  PParamText = ^TParamText;
  TParamText = object(TStaticText)
    ParamCount: SmallInt;
    ParamList: Pointer;
    constructor Init(var Bounds: TRect; const AText: ShortString; AParamCount: SmallInt);
    constructor Load(var S: TStream);
    function DataSize: Word; virtual;
    procedure GetData(var Rec); virtual;
    procedure SetData(var Rec); virtual;
    procedure Store(var S: TStream);
    procedure GetText(var S: ShortString); virtual;
  end;

  PLabel = ^TLabel;
  TLabel = object(TStaticText)
    Light: Boolean;
    Link: PView;
    constructor Init(var Bounds: TRect; const AText: ShortString; ALink: PView);
    function GetPalette: PPalette; virtual;
    procedure Draw; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

  PDialog = ^TDialog;
  TDialog = object(TWindow)
    constructor Init(var Bounds: TRect; ATitle: TTitleStr);
    function GetPalette: PPalette; virtual;
    function Valid(Command: Word): Boolean; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure Cancel(ACommand: Word); virtual;
    procedure ChangeTitle(ANewTitle: TTitleStr); virtual;
    procedure FreeSubView(ASubView: PView); virtual;
    procedure FreeAllSubViews; virtual;
    function IsSubView(AView: PView): Boolean; virtual;
    function NewButton(X, Y, W, H: Integer; ATitle: TTitleStr;
      ACommand, AHelpCtx: Word; AFlags: Byte): PButton;
    function NewLabel(X, Y: Integer; AText: ShortString; ALink: PView): PLabel;
    function NewInputLine(X, Y, W, AMaxLen: Integer; AHelpCtx: Word;
      AValidator: PValidator): PInputLine;
  end;

  { THistoryViewer - displays history list }
  PHistoryViewer = ^THistoryViewer;
  THistoryViewer = object(TListViewer)
    HistoryId: Word;
    constructor Init(var Bounds: TRect; AHScrollBar, AVScrollBar: PScrollBar;
      AHistoryId: Word);
    function HistoryWidth: Integer;
    function GetPalette: PPalette; virtual;
    function GetText(Item: Integer; MaxLen: Integer): string; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

  { THistoryWindow - popup window for history selection }
  PHistoryWindow = ^THistoryWindow;
  THistoryWindow = object(TWindow)
    Viewer: PListViewer;
    constructor Init(var Bounds: TRect; AHistoryId: Word);
    function GetSelection: ShortString; virtual;
    function GetPalette: PPalette; virtual;
    procedure InitViewer(AHistoryId: Word); virtual;
  end;

  { THistory - history dropdown button for input lines }
  PHistory = ^THistory;
  THistory = object(TView)
    HistoryId: Word;
    Link: PInputLine;
    constructor Init(var Bounds: TRect; ALink: PInputLine; AHistoryId: Word);
    function GetPalette: PPalette; virtual;
    function InitHistoryWindow(var Bounds: TRect): PHistoryWindow; virtual;
    procedure Draw; virtual;
    procedure RecordHistory(const S: ShortString); virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

function NewSItem(const Str: ShortString; ANext: PSItem): PSItem;
function HotKey(const S: ShortString): AnsiChar;
procedure RegisterDialogs;

implementation

const
  LeftArr: AnsiChar = #17;
  RightArr: AnsiChar = #16;

{***************************************************************************}
{                           Utility Functions                               }
{***************************************************************************}

function NewSItem(const Str: ShortString; ANext: PSItem): PSItem;
var
  P: PSItem;
begin
  New(P);
  P^.Value := NewStr(Str);
  P^.Next := ANext;
  Result := P;
end;

function HotKey(const S: ShortString): AnsiChar;
var
  I: Integer;
begin
  Result := #0;
  if S <> '' then begin
    I := Pos('~', S);
    if (I <> 0) and (I < Length(S)) then
      Result := UpCase(S[I + 1]);
  end;
end;

{***************************************************************************}
{                         TInputLine Implementation                         }
{***************************************************************************}

constructor TInputLine.Init(var Bounds: TRect; AMaxLen: Integer);
begin
  inherited Init(Bounds);
  State := State or sfCursorVis;
  Options := Options or ofSelectable or ofFirstClick;
  MaxLen := AMaxLen;
  GetMem(Data, MaxLen + 1);
  Data^ := '';
  CurPos := 0;
  FirstPos := 0;
  SelStart := 0;
  SelEnd := 0;
  Validator := nil;
end;

destructor TInputLine.Done;
begin
  if Data <> nil then FreeMem(Data, MaxLen + 1);
  if Validator <> nil then Validator^.Free;
  inherited Done;
end;

function TInputLine.DataSize: Word;
begin
  Result := MaxLen + 1;
end;

function TInputLine.GetPalette: PPalette;
const
  P: string[Length(CInputLine)] = CInputLine;
begin
  GetPalette := PPalette(@P);
end;

function TInputLine.Valid(Command: Word): Boolean;
begin
  Result := inherited Valid(Command);
  if Result and (Validator <> nil) then begin
    if Command = cmValid then
      Result := Validator^.Status = vsOk
    else if Command <> cmCancel then
      if Validator^.Options and voOnAppend = 0 then
        Result := Validator^.Valid(Data^);
  end;
end;

function TInputLine.CanScroll(Delta: Integer): Boolean;
begin
  if Delta < 0 then
    Result := FirstPos > 0
  else if Delta > 0 then
    Result := (Data <> nil) and (Length(Data^) - FirstPos + 2 > Size.X)
  else
    Result := False;
end;

function TInputLine.ScreenCurPos: Integer;
begin
  Result := CurPos;
end;

procedure TInputLine.Draw;
var
  Color, ArrowColor: Byte;
  L, R: Integer;
  B: TDrawBuffer;
  DataStr: string;
begin
  if Options and ofSelectable = 0 then
    Color := GetColor(5)
  else if State and sfFocused = 0 then
    Color := GetColor(1)
  else
    Color := GetColor(2);
  ArrowColor := GetColor(4);

  { Fill with spaces in the field color }
  MoveChar(B, ' ', Color, Size.X);

  { Always show brackets to indicate input field boundaries }
  if CanScroll(-1) then
    MoveChar(B[0], LeftArr, ArrowColor, 1)
  else
    MoveChar(B[0], '[', ArrowColor, 1);

  if CanScroll(1) then
    MoveChar(B[Size.X - 1], RightArr, ArrowColor, 1)
  else
    MoveChar(B[Size.X - 1], ']', ArrowColor, 1);

  { Draw the data text }
  if Data <> nil then begin
    DataStr := Copy(Data^, FirstPos + 1, Size.X - 2);
    MoveStr(B[1], ShortString(DataStr), Color);
  end;

  { When focused, show selection and cursor }
  if (State and sfFocused <> 0) and (Options and ofSelectable <> 0) then begin
    L := SelStart - FirstPos;
    R := SelEnd - FirstPos;
    if L < 0 then L := 0;
    if R > Size.X - 2 then R := Size.X - 2;
    if L < R then
      MoveChar(B[L + 1], #0, GetColor(3), R - L);
    SetCursor(ScreenCurPos - FirstPos + 1, 0);
  end;
  WriteLine(0, 0, Size.X, Size.Y, B);
end;

procedure TInputLine.DrawCursor;
begin
  if State and sfFocused <> 0 then begin
    Cursor.Y := 0;
    Cursor.X := ScreenCurPos - FirstPos + 1;
    ResetCursor;
  end;
end;

procedure TInputLine.SelectAll(Enable: Boolean);
begin
  CurPos := 0;
  FirstPos := 0;
  SelStart := 0;
  if Enable and (Data <> nil) then
    SelEnd := Length(Data^)
  else
    SelEnd := 0;
  DrawView;
end;

procedure TInputLine.SetValidator(AValid: PValidator);
begin
  if Validator <> nil then Validator^.Free;
  Validator := AValid;
end;

procedure TInputLine.SetState(AState: Word; Enable: Boolean);
begin
  inherited SetState(AState, Enable);
  if (AState = sfSelected) or ((AState = sfActive) and (State and sfSelected <> 0)) then
    SelectAll(Enable)
  else if AState = sfFocused then
    DrawView;
end;

procedure TInputLine.GetData(var Rec);
begin
  if Data <> nil then begin
    FillChar(Rec, DataSize, #0);
    Move(Data^, Rec, Length(Data^) + 1);
  end else
    FillChar(Rec, DataSize, #0);
end;

procedure TInputLine.SetData(var Rec);
begin
  if Data <> nil then
    Move(Rec, Data^[0], DataSize);
  SelectAll(True);
end;

procedure TInputLine.HandleEvent(var Event: TEvent);
var
  Delta, Anchor: Integer;
  Mouse: TPoint;
  ExtendBlock: Boolean;

  function MouseDelta: Integer;
  begin
    MakeLocal(Event.Where, Mouse);
    if Mouse.X <= 0 then
      Result := -1
    else if Mouse.X >= Size.X - 1 then
      Result := 1
    else
      Result := 0;
  end;

  function MousePos: Integer;
  var
    Pos: Integer;
  begin
    MakeLocal(Event.Where, Mouse);
    if Mouse.X < 1 then Mouse.X := 1;
    Pos := Mouse.X + FirstPos - 1;
    if Pos < 0 then Pos := 0;
    if (Data <> nil) and (Pos > Length(Data^)) then Pos := Length(Data^);
    Result := Pos;
  end;

  procedure DeleteSelect;
  begin
    if (SelStart <> SelEnd) and (Data <> nil) then begin
      System.Delete(Data^, SelStart + 1, SelEnd - SelStart);
      CurPos := SelStart;
    end;
  end;

  procedure AdjustSelectBlock;
  begin
    if CurPos < Anchor then begin
      SelStart := CurPos;
      SelEnd := Anchor;
    end else begin
      SelStart := Anchor;
      SelEnd := CurPos;
    end;
  end;

begin
  inherited HandleEvent(Event);
  if State and sfSelected <> 0 then begin
    case Event.What of
      evMouseDown: begin
        Delta := MouseDelta;
        if CanScroll(Delta) then begin
          repeat
            Inc(FirstPos, Delta);
            DrawView;
          until not MouseEvent(Event, evMouseAuto);
        end else if (Event.Buttons and mbLeftButton <> 0) then begin
          Anchor := MousePos;
          repeat
            if Event.Double then SelectAll(True)
            else begin
              CurPos := MousePos;
              if GetShiftState and $03 <> 0 then
                AdjustSelectBlock
              else begin
                SelStart := CurPos;
                SelEnd := CurPos;
              end;
            end;
            DrawView;
          until not MouseEvent(Event, evMouseMove);
        end;
        ClearEvent(Event);
      end;
      evKeyDown: begin
        case CtrlToArrow(Event.KeyCode) of
          kbLeft: if CurPos > 0 then Dec(CurPos);
          kbRight: if (Data <> nil) and (CurPos < Length(Data^)) then Inc(CurPos);
          kbHome: CurPos := 0;
          kbEnd: if Data <> nil then CurPos := Length(Data^);
          kbBack: if CurPos > 0 then begin
            if Data <> nil then System.Delete(Data^, CurPos, 1);
            Dec(CurPos);
            if FirstPos > 0 then Dec(FirstPos);
            SelStart := CurPos;
            SelEnd := CurPos;
          end;
          kbDel: if Data <> nil then begin
            if SelStart = SelEnd then begin
              if CurPos < Length(Data^) then
                System.Delete(Data^, CurPos + 1, 1);
            end else
              DeleteSelect;
            SelStart := CurPos;
            SelEnd := CurPos;
          end;
          kbIns: SetState(sfCursorIns, State and sfCursorIns = 0);
        else
          if (Event.CharCode >= ' ') and (Event.CharCode < #255) then begin
            if (State and sfCursorIns <> 0) and (SelStart = SelEnd) and
               (Data <> nil) and (CurPos < Length(Data^)) then
              System.Delete(Data^, CurPos + 1, 1);
            if SelStart <> SelEnd then DeleteSelect;
            if (Data <> nil) and (Length(Data^) < MaxLen) then begin
              Inc(Data^[0]);
              Move(Data^[CurPos + 1], Data^[CurPos + 2], Length(Data^) - CurPos);
              Data^[CurPos + 1] := Event.CharCode;
              Inc(CurPos);
            end;
            SelStart := CurPos;
            SelEnd := CurPos;
          end else
            Exit;
        end;
        if FirstPos > CurPos then FirstPos := CurPos;
        if CurPos - FirstPos > Size.X - 3 then FirstPos := CurPos - Size.X + 3;
        DrawView;
        ClearEvent(Event);
      end;
    end;
  end;
end;

{***************************************************************************}
{                         TButton Implementation                            }
{***************************************************************************}

constructor TButton.Init(var Bounds: TRect; ATitle: TTitleStr; ACommand: Word; AFlags: Word);
begin
  inherited Init(Bounds);
  Options := Options or ofSelectable or ofFirstClick or ofPreProcess or ofPostProcess;
  EventMask := EventMask or evBroadcast;
  if AFlags and bfDefault <> 0 then begin
    AmDefault := True;
  end else
    AmDefault := False;
  Flags := Byte(AFlags);
  Command := ACommand;
  Title := NewStr(ATitle);
  if not CommandEnabled(Command) then State := State or sfDisabled;
end;

destructor TButton.Done;
begin
  DisposeStr(Title);
  inherited Done;
end;

function TButton.GetPalette: PPalette;
const
  P: string[Length(CButton)] = CButton;
begin
  GetPalette := PPalette(@P);
end;

procedure TButton.Press;
var
  E: TEvent;
begin
  Message(Owner, evBroadcast, cmRecordHistory, nil);
  if Flags and bfBroadcast <> 0 then
    Message(Owner, evBroadcast, Command, @Self)
  else begin
    E.What := evCommand;
    E.Command := Command;
    E.InfoPtr := @Self;
    PutEvent(E);
  end;
end;

procedure TButton.Draw;
begin
  DrawState(DownFlag);
end;

procedure TButton.DrawState(Down: Boolean);
var
  CButton, CShadow, CText: Word;
  Ch: AnsiChar;
  I, S, T, Y: Integer;
  B: TDrawBuffer;
  TitleStr: ShortString;
begin
  if State and sfDisabled <> 0 then
    CButton := GetColor($0401)
  else begin
    CButton := GetColor($0501);
    if State and sfActive <> 0 then
      if State and sfFocused <> 0 then
        CButton := GetColor($0703)
      else if AmDefault then
        CButton := GetColor($0602);
  end;
  CShadow := GetColor(8);
  S := Size.X - 1;
  T := (Size.X - Length(Title^) - 4) div 2;
  if Down then begin
    Ch := ' ';
    Inc(T);
  end else
    Ch := #0;

  for Y := 0 to Size.Y - 2 do begin
    MoveChar(B, ' ', CButton, Size.X);
    MoveChar(B[S], #220, CShadow, 1);
    if (Y = 0) and not Down then
      MoveStr(B, #222, Byte(CButton) shr 8);
    if (Y = Size.Y - 2) and not Down then begin
      if Title <> nil then
        TitleStr := Title^
      else
        TitleStr := '';
      CText := CButton;
      MoveChar(B[1], ' ', CButton, T);
      MoveChar(B[T + 1], '[', CButton, 1);
      MoveStr(B[T + 2], TitleStr, CText);
      MoveChar(B[T + Length(TitleStr) + 2], ']', CButton, 1);
    end;
    WriteLine(0, Y, Size.X, 1, B);
  end;

  MoveChar(B, #223, CShadow, Size.X);
  MoveChar(B[0], ' ', CButton, 1);
  WriteLine(0, Size.Y - 1, Size.X, 1, B);
end;

procedure TButton.MakeDefault(Enable: Boolean);
var
  C: Word;
begin
  if Flags and bfDefault = 0 then begin
    if Enable then
      C := cmGrabDefault
    else
      C := cmReleaseDefault;
    Message(Owner, evBroadcast, C, @Self);
    AmDefault := Enable;
    DrawView;
  end;
end;

procedure TButton.SetState(AState: Word; Enable: Boolean);
begin
  inherited SetState(AState, Enable);
  if AState and (sfSelected + sfActive) <> 0 then
    DrawView;
  if AState and sfFocused <> 0 then
    MakeDefault(Enable);
end;

procedure TButton.HandleEvent(var Event: TEvent);
var
  Down: Boolean;
  C: AnsiChar;
  Mouse: TPoint;
  ClickRect: TRect;
begin
  GetExtent(ClickRect);
  Inc(ClickRect.A.X);
  Dec(ClickRect.B.X);
  Dec(ClickRect.B.Y);
  if Event.What = evMouseDown then begin
    MakeLocal(Event.Where, Mouse);
    if not ClickRect.Contains(Mouse) then
      ClearEvent(Event);
  end;
  inherited HandleEvent(Event);
  case Event.What of
    evMouseDown: begin
      if State and sfDisabled = 0 then begin
        DownFlag := True;
        DrawView;
        repeat
          MakeLocal(Event.Where, Mouse);
          Down := ClickRect.Contains(Mouse);
          if Down <> DownFlag then begin
            DownFlag := Down;
            DrawView;
          end;
        until not MouseEvent(Event, evMouseMove);
        if DownFlag then begin
          Press;
          DownFlag := False;
          DrawView;
        end;
      end;
      ClearEvent(Event);
    end;
    evKeyDown: begin
      if Title <> nil then begin
        C := HotKey(Title^);
        if (Event.KeyCode = GetAltCode(C)) or
           ((Owner^.Phase = phPostProcess) and (C <> #0) and
            (UpCase(Event.CharCode) = C)) or
           ((State and sfFocused <> 0) and (Event.CharCode = ' ')) then begin
          Press;
          ClearEvent(Event);
        end;
      end;
    end;
    evBroadcast: begin
      case Event.Command of
        cmDefault: if AmDefault and (State and sfDisabled = 0) then begin
          Press;
          ClearEvent(Event);
        end;
        cmGrabDefault, cmReleaseDefault: if Flags and bfDefault <> 0 then begin
          AmDefault := Event.Command = cmReleaseDefault;
          DrawView;
        end;
        cmCommandSetChanged: begin
          SetState(sfDisabled, not CommandEnabled(Command));
          DrawView;
        end;
      end;
    end;
  end;
end;

{***************************************************************************}
{                         TCluster Implementation                           }
{***************************************************************************}

constructor TCluster.Init(var Bounds: TRect; AStrings: PSItem);
var
  P: PSItem;
  I: Integer;
begin
  inherited Init(Bounds);
  Options := Options or ofSelectable or ofFirstClick or ofPreProcess or ofPostProcess;
  I := 0;
  P := AStrings;
  while P <> nil do begin
    Inc(I);
    P := P^.Next;
  end;
  Strings.Init(I, 0);
  while AStrings <> nil do begin
    P := AStrings;
    Strings.AtInsert(Strings.Count, P^.Value);
    AStrings := P^.Next;
    Dispose(P);
  end;
  Value := 0;
  EnableMask := $FFFFFFFF;
  Sel := 0;
end;

destructor TCluster.Done;
begin
  Strings.Done;
  inherited Done;
end;

function TCluster.DataSize: Word;
begin
  Result := SizeOf(Word);
end;

function TCluster.GetHelpCtx: Word;
begin
  if HelpCtx = hcNoContext then
    Result := hcNoContext
  else
    Result := HelpCtx + Sel;
end;

function TCluster.GetPalette: PPalette;
const
  P: string[Length(CCluster)] = CCluster;
begin
  GetPalette := PPalette(@P);
end;

function TCluster.Mark(Item: Integer): Boolean;
begin
  Result := False;
end;

function TCluster.MultiMark(Item: Integer): Byte;
begin
  if Mark(Item) then Result := 1 else Result := 0;
end;

function TCluster.ButtonState(Item: Integer): Boolean;
begin
  Result := (EnableMask and (1 shl Item)) <> 0;
end;

function TCluster.Row(Item: Integer): Integer;
begin
  Result := Item mod Size.Y;
end;

function TCluster.Column(Item: Integer): Integer;
begin
  Result := Item div Size.Y;
end;

function TCluster.FindSel(P: TPoint): Integer;
var
  I, S, Col: Integer;
begin
  Result := -1;
  MakeLocal(P, P);
  if P.X >= 0 then begin
    Col := P.X * (Strings.Count div Size.Y + 1) div Size.X;
    S := Col * Size.Y;
    for I := 0 to Size.Y - 1 do
      if Row(S + I) = P.Y then begin
        if S + I < Strings.Count then
          Result := S + I;
        Exit;
      end;
  end;
end;

procedure TCluster.Draw;
begin
  DrawBox(' ( ) ', #7);
end;

procedure TCluster.DrawBox(const Icon: ShortString; Marker: AnsiChar);
var
  I, J, Cur, Col, CNorm, CSel, CDis, Color: Integer;
  B: TDrawBuffer;
  SCOff: Byte;
  S: ShortString;
begin
  CNorm := GetColor($0301);
  CSel := GetColor($0402);
  CDis := GetColor(5);

  for I := 0 to Size.Y - 1 do begin
    MoveChar(B, ' ', CNorm, Size.X);
    Col := 0;
    for J := 0 to (Strings.Count - 1) div Size.Y do begin
      Cur := J * Size.Y + I;
      if Cur < Strings.Count then begin
        if not ButtonState(Cur) then
          Color := CDis
        else if (Cur = Sel) and (State and sfFocused <> 0) then
          Color := CSel
        else
          Color := CNorm;

        MoveStr(B[Col], Icon, Color);
        if Mark(Cur) then
          WordRec(B[Col + 2]).Lo := Byte(Marker);

        S := PShortString(Strings.At(Cur))^;
        MoveStr(B[Col + Length(Icon)], S, Color);
        Inc(Col, Length(Icon) + Length(S) + 2);
      end;
    end;
    WriteLine(0, I, Size.X, 1, B);
  end;
  SetCursor(Column(Sel) * (Size.X div ((Strings.Count - 1) div Size.Y + 1)) + 2, Row(Sel));
end;

procedure TCluster.DrawMultiBox(const Icon, Marker: ShortString);
begin
  DrawBox(Icon, Marker[1]);
end;

procedure TCluster.SetButtonState(AMask: LongInt; Enable: Boolean);
begin
  if Enable then
    EnableMask := EnableMask or AMask
  else
    EnableMask := EnableMask and not AMask;
  DrawView;
end;

procedure TCluster.Press(Item: Integer);
begin
  Value := Value xor (1 shl Item);
end;

procedure TCluster.MovedTo(Item: Integer);
begin
  Sel := Item;
end;

procedure TCluster.SetState(AState: Word; Enable: Boolean);
begin
  inherited SetState(AState, Enable);
  if AState and sfFocused <> 0 then
    DrawView;
end;

procedure TCluster.GetData(var Rec);
begin
  Word(Rec) := Word(Value);
end;

procedure TCluster.SetData(var Rec);
begin
  Value := Word(Rec);
  DrawView;
end;

procedure TCluster.HandleEvent(var Event: TEvent);
var
  I: Integer;
  S: ShortString;
  C: AnsiChar;
begin
  inherited HandleEvent(Event);
  if Options and ofSelectable = 0 then Exit;
  case Event.What of
    evMouseDown: begin
      I := FindSel(Event.Where);
      if (I <> -1) and ButtonState(I) then begin
        Sel := I;
        Press(Sel);
        DrawView;
      end;
      ClearEvent(Event);
    end;
    evKeyDown: begin
      { Only handle arrow keys when we have focus }
      if State and sfFocused <> 0 then
        case CtrlToArrow(Event.KeyCode) of
          kbUp: if Sel > 0 then begin Dec(Sel); Press(Sel); DrawView; ClearEvent(Event); end;
          kbDown: if Sel < Strings.Count - 1 then begin Inc(Sel); Press(Sel); DrawView; ClearEvent(Event); end;
          kbRight: if Sel + Size.Y < Strings.Count then begin
            Inc(Sel, Size.Y);
            Press(Sel);
            DrawView;
            ClearEvent(Event);
          end;
          kbLeft: if Sel >= Size.Y then begin
            Dec(Sel, Size.Y);
            Press(Sel);
            DrawView;
            ClearEvent(Event);
          end;
        end;
      if Event.What = evNothing then Exit;
      { Handle hotkeys in any phase }
      for I := 0 to Strings.Count - 1 do begin
        S := PShortString(Strings.At(I))^;
        C := HotKey(S);
        if (GetAltCode(C) = Event.KeyCode) or
           ((Owner^.Phase = phPostProcess) and (C <> #0) and
            (UpCase(Event.CharCode) = C)) then begin
          if ButtonState(I) then begin
            if Focus then begin
              Sel := I;
              Press(I);
              DrawView;
            end;
          end;
          ClearEvent(Event);
          Exit;
        end;
      end;
      { Handle space only when focused }
      if (State and sfFocused <> 0) and (Event.CharCode = ' ') then begin
        Press(Sel);
        DrawView;
        ClearEvent(Event);
      end;
    end;
  end;
end;

{***************************************************************************}
{                      TRadioButtons Implementation                         }
{***************************************************************************}

function TRadioButtons.Mark(Item: Integer): Boolean;
begin
  Result := Item = Value;
end;

procedure TRadioButtons.Draw;
begin
  DrawBox(' ( ) ', #7);
end;

procedure TRadioButtons.Press(Item: Integer);
begin
  Value := Item;
end;

procedure TRadioButtons.MovedTo(Item: Integer);
begin
  Value := Item;
  inherited MovedTo(Item);
end;

procedure TRadioButtons.SetData(var Rec);
begin
  Sel := Integer(Rec);
  Value := Sel;
  DrawView;
end;

{***************************************************************************}
{                       TCheckBoxes Implementation                          }
{***************************************************************************}

function TCheckBoxes.Mark(Item: Integer): Boolean;
begin
  Result := (Value and (1 shl Item)) <> 0;
end;

procedure TCheckBoxes.Draw;
begin
  DrawBox(' [ ] ', 'X');
end;

procedure TCheckBoxes.Press(Item: Integer);
begin
  Value := Value xor (1 shl Item);
end;

{***************************************************************************}
{                         TListBox Implementation                           }
{***************************************************************************}

constructor TListBox.Init(var Bounds: TRect; ANumCols: Word; AScrollBar: PScrollBar);
begin
  inherited Init(Bounds, ANumCols, nil, AScrollBar);
  List := nil;
end;

function TListBox.DataSize: Word;
begin
  Result := SizeOf(Pointer);
end;

function TListBox.GetText(Item: Integer; MaxLen: Integer): string;
var
  S: PShortString;
begin
  if (List <> nil) and (Item < List^.Count) then begin
    S := List^.At(Item);
    if S <> nil then
      Result := Copy(S^, 1, MaxLen)
    else
      Result := '';
  end else
    Result := '';
end;

procedure TListBox.NewList(AList: PCollection);
begin
  if List <> nil then
    Dispose(List, Done);
  List := AList;
  if AList <> nil then
    SetRange(AList^.Count)
  else
    SetRange(0);
  if Range > 0 then
    FocusItem(0);
  DrawView;
end;

procedure TListBox.GetData(var Rec);
begin
  PCollection(Rec) := List;
end;

procedure TListBox.SetData(var Rec);
begin
  NewList(PCollection(Rec));
end;

{***************************************************************************}
{                       TStaticText Implementation                          }
{***************************************************************************}

constructor TStaticText.Init(var Bounds: TRect; const AText: ShortString);
begin
  inherited Init(Bounds);
  Text := NewStr(AText);
end;

constructor TStaticText.Load(var S: TStream);
begin
  inherited Load(S);
  Text := S.ReadStr;
end;

destructor TStaticText.Done;
begin
  DisposeStr(Text);
  inherited Done;
end;

function TStaticText.GetPalette: PPalette;
const
  P: string[Length(CStaticText)] = CStaticText;
begin
  GetPalette := PPalette(@P);
end;

procedure TStaticText.GetText(var S: ShortString);
begin
  if Text <> nil then
    S := Text^
  else
    S := '';
end;

procedure TStaticText.Store(var S: TStream);
begin
  TView.Store(S);
  S.WriteStr(Text);
end;

procedure TStaticText.Draw;
var
  Color: Byte;
  Center: Boolean;
  I, J, L, P, Y: Integer;
  B: TDrawBuffer;
  S: ShortString;
begin
  Color := GetColor(1);
  GetText(S);
  L := Length(S);
  P := 1;
  Y := 0;
  Center := False;
  while Y < Size.Y do begin
    MoveChar(B, ' ', Color, Size.X);
    if P <= L then begin
      if S[P] = #3 then begin
        Center := True;
        Inc(P);
      end;
      I := P;
      repeat
        J := P;
        while (P <= L) and (S[P] = ' ') do Inc(P);
        while (P <= L) and (S[P] <> ' ') and (S[P] <> #13) do Inc(P);
      until (P > L) or (P >= I + Size.X) or (S[P] = #13);
      if P > I + Size.X then
        if J > I then
          P := J
        else
          P := I + Size.X;
      if Center then
        J := (Size.X - P + I) div 2
      else
        J := 0;
      MoveStr(B[J], Copy(S, I, P - I), Color);
      while (P <= L) and (S[P] = ' ') do Inc(P);
      if (P <= L) and (S[P] = #13) then begin
        Center := False;
        Inc(P);
        if (P <= L) and (S[P] = #10) then Inc(P);
      end;
    end;
    WriteLine(0, Y, Size.X, 1, B);
    Inc(Y);
  end;
end;

{***************************************************************************}
{                         TParamText Implementation                         }
{***************************************************************************}

constructor TParamText.Init(var Bounds: TRect; const AText: ShortString; AParamCount: SmallInt);
begin
  inherited Init(Bounds, AText);
  ParamCount := AParamCount;
  ParamList := nil;
end;

constructor TParamText.Load(var S: TStream);
var
  W: Word;
begin
  inherited Load(S);
  S.Read(W, SizeOf(W));
  ParamCount := W;
  ParamList := nil;
end;

function TParamText.DataSize: Word;
begin
  Result := ParamCount * SizeOf(Pointer);
end;

procedure TParamText.GetData(var Rec);
begin
  Pointer(Rec) := @ParamList;
end;

procedure TParamText.SetData(var Rec);
begin
  ParamList := @Rec;
  DrawView;
end;

procedure TParamText.Store(var S: TStream);
var
  W: Word;
begin
  inherited Store(S);
  W := ParamCount;
  S.Write(W, SizeOf(W));
end;

procedure TParamText.GetText(var S: ShortString);
begin
  if Text = nil then
    S := ''
  else if ParamList = nil then
    S := Text^
  else
    FormatStr(S, Text^, ParamList^);
end;

{***************************************************************************}
{                          TLabel Implementation                            }
{***************************************************************************}

constructor TLabel.Init(var Bounds: TRect; const AText: ShortString; ALink: PView);
begin
  inherited Init(Bounds, AText);
  Link := ALink;
  Light := False;
  Options := Options or ofPreProcess or ofPostProcess;
  EventMask := EventMask or evBroadcast;
end;

function TLabel.GetPalette: PPalette;
const
  P: string[Length(CLabel)] = CLabel;
begin
  GetPalette := PPalette(@P);
end;

procedure TLabel.Draw;
var
  Color: Byte;
  B: TDrawBuffer;
  SCOff: Byte;
  I: Integer;
  S: ShortString;
begin
  if Light then begin
    Color := GetColor($0402);
    SCOff := 0;
  end else begin
    Color := GetColor($0301);
    SCOff := 4;
  end;
  MoveChar(B, ' ', Color, Size.X);
  if Text <> nil then begin
    S := Text^;
    MoveStr(B, S, Color);
    if ShowMarkers then begin
      WordRec(B[0]).Lo := Byte(SpecialChars[SCOff]);
    end;
  end;
  WriteLine(0, 0, Size.X, 1, B);
end;

procedure TLabel.HandleEvent(var Event: TEvent);
var
  C: AnsiChar;
  FocusMe: Boolean;
begin
  inherited HandleEvent(Event);
  if Event.What = evMouseDown then begin
    if Link <> nil then Link^.Focus;
    ClearEvent(Event);
  end else if Event.What = evKeyDown then begin
    if Text <> nil then begin
      C := HotKey(Text^);
      if (GetAltCode(C) = Event.KeyCode) or
         ((Owner^.Phase = phPostProcess) and (C <> #0) and
          (UpCase(Event.CharCode) = C)) then begin
        if Link <> nil then begin
          Link^.Focus;
          ClearEvent(Event);
        end;
      end;
    end;
  end else if Event.What = evBroadcast then begin
    if (Event.Command = cmReceivedFocus) or (Event.Command = cmReleasedFocus) then begin
      if Link <> nil then begin
        FocusMe := (Event.Command = cmReceivedFocus) and (Event.InfoPtr = Link);
        Light := FocusMe;
        DrawView;
      end;
    end;
  end;
end;

{***************************************************************************}
{                          TDialog Implementation                           }
{***************************************************************************}

constructor TDialog.Init(var Bounds: TRect; ATitle: TTitleStr);
begin
  inherited Init(Bounds, ATitle, wnNoNumber);
  Options := Options or ofVersion20;
  GrowMode := 0;
  Flags := wfMove + wfClose;
  Palette := dpGrayDialog;
end;

function TDialog.GetPalette: PPalette;
const
  P: array[dpBlueDialog..dpGrayDialog] of string[Length(CBlueDialog)] =
    (CBlueDialog, CCyanDialog, CGrayDialog);
begin
  GetPalette := PPalette(@P[Palette]);
end;

function TDialog.Valid(Command: Word): Boolean;
begin
  if Command = cmCancel then
    Result := True
  else
    Result := inherited Valid(Command);
end;

procedure TDialog.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);
  case Event.What of
    evNothing: Exit;
    evKeyDown: case Event.KeyCode of
      kbEsc, kbCtrlF4: begin
        Event.What := evCommand;
        Event.Command := cmCancel;
        Event.InfoPtr := nil;
        PutEvent(Event);
        ClearEvent(Event);
      end;
      kbCtrlF5: begin
        if State and sfModal <> 0 then begin
          Event.What := evCommand;
          Event.Command := cmResize;
          Event.InfoPtr := nil;
          PutEvent(Event);
          ClearEvent(Event);
        end;
      end;
      kbEnter: begin
        Event.What := evBroadcast;
        Event.Command := cmDefault;
        Event.InfoPtr := nil;
        PutEvent(Event);
        ClearEvent(Event);
      end;
    end;
    evCommand: case Event.Command of
      cmOk, cmCancel, cmYes, cmNo: if State and sfModal <> 0 then begin
        EndModal(Event.Command);
        ClearEvent(Event);
      end;
    end;
  end;
end;

procedure TDialog.Cancel(ACommand: Word);
begin
  if State and sfModal = sfModal then
    EndModal(ACommand)
  else
    Close;
end;

procedure TDialog.ChangeTitle(ANewTitle: TTitleStr);
begin
  if Title <> nil then
    DisposeStr(Title);
  Title := NewStr(ANewTitle);
  Frame^.DrawView;
end;

procedure TDialog.FreeSubView(ASubView: PView);
begin
  if IsSubView(ASubView) then begin
    Delete(ASubView);
    Dispose(ASubView, Done);
    DrawView;
  end;
end;

procedure TDialog.FreeAllSubViews;
var
  P: PView;
begin
  P := First;
  repeat
    P := First;
    if P <> nil then begin
      Delete(P);
      Dispose(P, Done);
    end;
  until P = nil;
  DrawView;
end;

function TDialog.IsSubView(AView: PView): Boolean;
var
  P: PView;
begin
  P := First;
  while (P <> nil) and (P <> AView) do
    P := P^.Next;
  Result := (P <> nil) and (P = AView);
end;

function TDialog.NewButton(X, Y, W, H: Integer; ATitle: TTitleStr;
  ACommand, AHelpCtx: Word; AFlags: Byte): PButton;
var
  B: PButton;
  R: TRect;
begin
  R.Assign(X, Y, X + W, Y + H);
  B := New(PButton, Init(R, ATitle, ACommand, AFlags));
  if B <> nil then begin
    B^.HelpCtx := AHelpCtx;
    Insert(B);
  end;
  Result := B;
end;

function TDialog.NewLabel(X, Y: Integer; AText: ShortString; ALink: PView): PLabel;
var
  L: PLabel;
  R: TRect;
begin
  R.Assign(X, Y, X + Length(AText) + 1, Y + 1);
  L := New(PLabel, Init(R, AText, ALink));
  if L <> nil then
    Insert(L);
  Result := L;
end;

function TDialog.NewInputLine(X, Y, W, AMaxLen: Integer; AHelpCtx: Word;
  AValidator: PValidator): PInputLine;
var
  P: PInputLine;
  R: TRect;
begin
  R.Assign(X, Y, X + W, Y + 1);
  P := New(PInputLine, Init(R, AMaxLen));
  if P <> nil then begin
    P^.SetValidator(AValidator);
    P^.HelpCtx := AHelpCtx;
    Insert(P);
  end;
  Result := P;
end;

{***************************************************************************}
{                      THistoryViewer Implementation                        }
{***************************************************************************}

constructor THistoryViewer.Init(var Bounds: TRect; AHScrollBar, AVScrollBar: PScrollBar;
  AHistoryId: Word);
begin
  inherited Init(Bounds, 1, AHScrollBar, AVScrollBar);
  HistoryId := AHistoryId;
  SetRange(HistoryCount(AHistoryId));
  if Range > 1 then FocusItem(1);
  if HScrollBar <> nil then
    HScrollBar^.SetRange(1, HistoryWidth - Size.X + 3);
end;

function THistoryViewer.HistoryWidth: Integer;
var
  Width, T, ACount, I: Integer;
begin
  Width := 0;
  ACount := HistoryCount(HistoryId);
  for I := 0 to ACount - 1 do begin
    T := Length(HistoryStr(HistoryId, I));
    if T > Width then Width := T;
  end;
  Result := Width;
end;

function THistoryViewer.GetPalette: PPalette;
const
  P: string[Length(CHistoryViewer)] = CHistoryViewer;
begin
  GetPalette := PPalette(@P);
end;

function THistoryViewer.GetText(Item: Integer; MaxLen: Integer): string;
begin
  Result := HistoryStr(HistoryId, Item);
end;

procedure THistoryViewer.HandleEvent(var Event: TEvent);
begin
  if ((Event.What = evMouseDown) and Event.Double) or
     ((Event.What = evKeyDown) and (Event.KeyCode = kbEnter)) then begin
    EndModal(cmOk);
    ClearEvent(Event);
  end else if ((Event.What = evKeyDown) and (Event.KeyCode = kbEsc)) or
              ((Event.What = evCommand) and (Event.Command = cmCancel)) then begin
    EndModal(cmCancel);
    ClearEvent(Event);
  end else
    inherited HandleEvent(Event);
end;

{***************************************************************************}
{                      THistoryWindow Implementation                        }
{***************************************************************************}

constructor THistoryWindow.Init(var Bounds: TRect; AHistoryId: Word);
begin
  inherited Init(Bounds, '', wnNoNumber);
  Flags := wfClose;
  InitViewer(AHistoryId);
end;

function THistoryWindow.GetSelection: ShortString;
begin
  if Viewer = nil then
    Result := ''
  else
    Result := Viewer^.GetText(Viewer^.Focused, 255);
end;

function THistoryWindow.GetPalette: PPalette;
const
  P: string[Length(CHistoryWindow)] = CHistoryWindow;
begin
  GetPalette := PPalette(@P);
end;

procedure THistoryWindow.InitViewer(AHistoryId: Word);
var
  R: TRect;
begin
  GetExtent(R);
  R.Grow(-1, -1);
  Viewer := New(PHistoryViewer, Init(R,
    StandardScrollBar(sbHorizontal + sbHandleKeyboard),
    StandardScrollBar(sbVertical + sbHandleKeyboard),
    AHistoryId));
  if Viewer <> nil then Insert(Viewer);
end;

{***************************************************************************}
{                         THistory Implementation                           }
{***************************************************************************}

constructor THistory.Init(var Bounds: TRect; ALink: PInputLine; AHistoryId: Word);
begin
  inherited Init(Bounds);
  Options := Options or ofPostProcess;
  EventMask := EventMask or evBroadcast;
  Link := ALink;
  HistoryId := AHistoryId;
end;

function THistory.GetPalette: PPalette;
const
  P: string[Length(CHistory)] = CHistory;
begin
  GetPalette := PPalette(@P);
end;

function THistory.InitHistoryWindow(var Bounds: TRect): PHistoryWindow;
var
  W: PHistoryWindow;
begin
  W := New(PHistoryWindow, Init(Bounds, HistoryId));
  if (W <> nil) and (Link <> nil) then
    W^.HelpCtx := Link^.HelpCtx;
  Result := W;
end;

procedure THistory.Draw;
var
  B: TDrawBuffer;
begin
  MoveCStr(B, #222'~'#25'~'#221, GetColor($0102));
  WriteLine(0, 0, Size.X, Size.Y, B);
end;

procedure THistory.RecordHistory(const S: ShortString);
begin
  HistoryAdd(HistoryId, S);
end;

procedure THistory.HandleEvent(var Event: TEvent);
var
  C: Word;
  Rslt: ShortString;
  R, P: TRect;
  HistoryWindow: PHistoryWindow;
begin
  inherited HandleEvent(Event);
  if Link = nil then Exit;
  if (Event.What = evMouseDown) or
     ((Event.What = evKeyDown) and
      (CtrlToArrow(Event.KeyCode) = kbDown) and
      (Link^.State and sfFocused <> 0)) then begin
    if not Link^.Focus then begin
      ClearEvent(Event);
      Exit;
    end;
    if Link^.Data <> nil then
      RecordHistory(Link^.Data^);
    Link^.GetBounds(R);
    Dec(R.A.X);
    Inc(R.B.X);
    Inc(R.B.Y, 7);
    Dec(R.A.Y, 1);
    Owner^.GetExtent(P);
    R.Intersect(P);
    Dec(R.B.Y, 1);
    HistoryWindow := InitHistoryWindow(R);
    if HistoryWindow <> nil then begin
      C := Owner^.ExecView(HistoryWindow);
      if C = cmOk then begin
        Rslt := HistoryWindow^.GetSelection;
        if Length(Rslt) > Link^.MaxLen then
          SetLength(Rslt, Link^.MaxLen);
        if Link^.Data <> nil then
          Link^.Data^ := Rslt;
        Link^.SelectAll(True);
        Link^.DrawView;
      end;
      Dispose(HistoryWindow, Done);
    end;
    ClearEvent(Event);
  end else if Event.What = evBroadcast then begin
    if ((Event.Command = cmReleasedFocus) and (Event.InfoPtr = Link)) or
       (Event.Command = cmRecordHistory) then begin
      if Link^.Data <> nil then
        RecordHistory(Link^.Data^);
    end;
  end;
end;

{***************************************************************************}
{                           Registration                                    }
{***************************************************************************}

procedure RegisterDialogs;
begin
  { Stream registration would go here }
end;

end.
