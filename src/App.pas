{*******************************************************}
{       Turbo Pascal App Unit                           }
{       Compatibility layer for Modern Delphi           }
{*******************************************************}

unit App;

{$I platform.inc}

interface

uses
  {$IFDEF OS_WINDOWS}
  Winapi.Windows,
  {$ENDIF}
  System.SysUtils,
  Objects, Drivers, Views, Menus, Dialogs, HistList, fvconsts;

const
  CBackground = #1;
  CColor = #0#0#0#0#0#0#0#0 +
           #0#0#0#0#0#0#0#0 +
           #0#0#0#0#0#0#0#0 +
           #0#0#0#0#0#0#0#0 +
           #0#0#0#0#0#0#0#0 +
           #0#0#0#0#0#0#0#0 +
           #0#0#0#0#0#0#0#0 +
           #0#0#0#0#0#0#0#0;
  CBlackWhite = #0#0#0#0#0#0#0#0 +
                #0#0#0#0#0#0#0#0 +
                #0#0#0#0#0#0#0#0 +
                #0#0#0#0#0#0#0#0 +
                #0#0#0#0#0#0#0#0 +
                #0#0#0#0#0#0#0#0 +
                #0#0#0#0#0#0#0#0 +
                #0#0#0#0#0#0#0#0;
  CMonochrome = #0#0#0#0#0#0#0#0 +
                #0#0#0#0#0#0#0#0 +
                #0#0#0#0#0#0#0#0 +
                #0#0#0#0#0#0#0#0 +
                #0#0#0#0#0#0#0#0 +
                #0#0#0#0#0#0#0#0 +
                #0#0#0#0#0#0#0#0 +
                #0#0#0#0#0#0#0#0;
  CAppColor = #$71#$70#$78#$74#$20#$28#$24#$17#$1F#$1A#$31#$31#$1E#$71#$00 +
              #$37#$3F#$3A#$13#$13#$3E#$21#$00#$70#$7F#$7A#$13#$13#$70#$7F#$00 +
              #$70#$7F#$7A#$13#$13#$70#$70#$7F#$7E#$20#$2B#$2F#$78#$2E#$70#$30 +
              #$3F#$3E#$1F#$2F#$1A#$20#$72#$31#$31#$30#$2F#$3E#$31#$13#$00#$00;
  CAppBlackWhite = #$70#$70#$78#$7F#$07#$07#$0F#$07#$0F#$07#$70#$70#$07#$70#$00 +
                   #$07#$0F#$07#$70#$70#$07#$70#$00#$70#$7F#$7F#$70#$07#$70#$07#$00 +
                   #$70#$7F#$7F#$70#$07#$70#$70#$7F#$7F#$07#$0F#$0F#$78#$0F#$78#$07 +
                   #$0F#$0F#$0F#$70#$0F#$07#$70#$70#$70#$07#$70#$0F#$07#$07#$00#$00;
  CAppMonochrome = #$70#$07#$07#$0F#$70#$70#$70#$07#$0F#$07#$70#$70#$07#$70#$00 +
                   #$07#$0F#$07#$70#$70#$07#$70#$00#$70#$70#$70#$07#$07#$70#$07#$00 +
                   #$70#$70#$70#$07#$07#$70#$70#$70#$0F#$07#$07#$0F#$70#$0F#$70#$07 +
                   #$0F#$0F#$07#$70#$07#$07#$70#$07#$07#$07#$70#$0F#$07#$07#$00#$00;

type
  PBackground = ^TBackground;
  TBackground = object(TView)
    Pattern: AnsiChar;
    constructor Init(var Bounds: TRect; APattern: AnsiChar);
    constructor Load(var S: TStream);
    function GetPalette: PPalette; virtual;
    procedure Draw; virtual;
    procedure Store(var S: TStream);
  end;

  PDesktop = ^TDesktop;
  TDesktop = object(TGroup)
    Background: PBackground;
    TileColumnsFirst: Boolean;
    constructor Init(var Bounds: TRect);
    constructor Load(var S: TStream);
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure InitBackground; virtual;
    function NewBackground(var Bounds: TRect): PBackground; virtual;
    procedure Store(var S: TStream);
    procedure TileError; virtual;
    procedure Tile(var R: TRect); virtual;
    procedure Cascade(var R: TRect); virtual;
  end;

  PProgram = ^TProgram;
  TProgram = object(TGroup)
    constructor Init;
    destructor Done; virtual;
    function ExecuteDialog(P: PDialog; Data: Pointer): Word;
    function GetPalette: PPalette; virtual;
    procedure GetEvent(var Event: TEvent); virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure Idle; virtual;
    procedure InitDesktop; virtual;
    procedure InitMenuBar; virtual;
    procedure InitScreen; virtual;
    procedure InitStatusLine; virtual;
    procedure OutOfMemory; virtual;
    procedure PutEvent(var Event: TEvent); virtual;
    procedure Run; virtual;
    procedure SetScreenMode(Mode: Word); virtual;
  end;

  PApplication = ^TApplication;
  TApplication = object(TProgram)
    constructor Init;
    destructor Done; virtual;
    procedure Cascade;
    procedure DosShell;
    procedure GetTileRect(var R: TRect); virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure Tile;
  end;

const
  RBackground: TStreamRec = (ObjType: idBackground; VmtLink: nil; Load: nil; Store: nil);
  RDesktop: TStreamRec = (ObjType: idDesktop; VmtLink: nil; Load: nil; Store: nil);

var
  Application: PProgram;
  Desktop: PDesktop;
  StatusLine: PStatusLine;
  MenuBar: PMenuBar;
  AppPalette: Integer;

procedure RegisterApp;

implementation

uses Video;

{ TBackground }

constructor TBackground.Init(var Bounds: TRect; APattern: AnsiChar);
begin
  inherited Init(Bounds);
  GrowMode := gfGrowHiX + gfGrowHiY;
  Pattern := APattern;
end;

constructor TBackground.Load(var S: TStream);
begin
  inherited Load(S);
  S.Read(Pattern, SizeOf(Pattern));
end;

function TBackground.GetPalette: PPalette;
const
  P: String[Length(CBackground)] = CBackground;
begin
  GetPalette := PPalette(@P);
end;

procedure TBackground.Draw;
var
  B: TDrawBuffer;
begin
  MoveChar(B, Pattern, GetColor(1), Size.X);
  WriteLine(0, 0, Size.X, Size.Y, B);
end;

procedure TBackground.Store(var S: TStream);
begin
  inherited Store(S);
  S.Write(Pattern, SizeOf(Pattern));
end;

{ TDesktop }

constructor TDesktop.Init(var Bounds: TRect);
begin
  inherited Init(Bounds);
  GrowMode := gfGrowHiX + gfGrowHiY;
  TileColumnsFirst := False;
  InitBackground;
  if Background <> nil then Insert(Background);
end;

constructor TDesktop.Load(var S: TStream);
begin
  inherited Load(S);
  Background := PBackground(GetSubViewPtr(S, @Self));
  S.Read(TileColumnsFirst, SizeOf(TileColumnsFirst));
end;

procedure TDesktop.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);
  if Event.What = evCommand then begin
    case Event.Command of
      cmNext: FocusNext(True);
      cmPrev: begin
        { Send current window to back (just above Background), then select topmost }
        if (Current <> nil) and Valid(cmReleasedFocus) and (Background <> nil) then begin
          Current^.PutInFrontOf(Background^.Next);  { Insert after Background }
          { Select the new topmost selectable window }
          if Last <> nil then
            Last^.Select;
        end;
      end;
    else
      Exit;
    end;
    ClearEvent(Event);
  end;
end;

procedure TDesktop.InitBackground;
var
  R: TRect;
begin
  GetExtent(R);
  Background := NewBackground(R);
end;

function TDesktop.NewBackground(var Bounds: TRect): PBackground;
begin
  NewBackground := New(PBackground, Init(Bounds, #176));
end;

procedure TDesktop.Store(var S: TStream);
begin
  inherited Store(S);
  PutSubViewPtr(S, Background);
  S.Write(TileColumnsFirst, SizeOf(TileColumnsFirst));
end;

procedure TDesktop.TileError;
begin
end;

procedure TDesktop.Tile(var R: TRect);
var
  NumCols, NumRows, NumTileable, LeftOver, TileNum: Integer;
  V, L0: PView;
  NR: TRect;
  PState: Word;

  function Tileable(P: PView): Boolean;
  begin
    Result := (P^.Options and ofTileable <> 0) and (P^.State and sfVisible <> 0);
  end;

  function ISqr(X: Integer): Integer;
  var
    I: Integer;
  begin
    I := 0;
    repeat
      Inc(I);
    until I * I > X;
    Result := I - 1;
  end;

  procedure MostEqualDivisors(N: Integer; var X, Y: Integer; FavorY: Boolean);
  var
    I: Integer;
  begin
    I := ISqr(N);
    if (N mod I) <> 0 then
      if (N mod (I + 1)) = 0 then Inc(I);
    if I < (N div I) then I := N div I;
    if FavorY then begin
      X := N div I;
      Y := I;
    end else begin
      Y := N div I;
      X := I;
    end;
  end;

  function DividerLoc(Lo, Hi, Num, Pos: Integer): Integer;
  begin
    Result := LongInt(LongInt(Hi - Lo) * Pos) div Num + Lo;
  end;

  procedure CalcTileRect(Pos: Integer; var TR: TRect);
  var
    X, Y, D: Integer;
  begin
    D := (NumCols - LeftOver) * NumRows;
    if Pos < D then begin
      X := Pos div NumRows;
      Y := Pos mod NumRows;
    end else begin
      X := (Pos - D) div (NumRows + 1) + (NumCols - LeftOver);
      Y := (Pos - D) mod (NumRows + 1);
    end;
    TR.A.X := DividerLoc(R.A.X, R.B.X, NumCols, X);
    TR.B.X := DividerLoc(R.A.X, R.B.X, NumCols, X + 1);
    if Pos >= D then begin
      TR.A.Y := DividerLoc(R.A.Y, R.B.Y, NumRows + 1, Y);
      TR.B.Y := DividerLoc(R.A.Y, R.B.Y, NumRows + 1, Y + 1);
    end else begin
      TR.A.Y := DividerLoc(R.A.Y, R.B.Y, NumRows, Y);
      TR.B.Y := DividerLoc(R.A.Y, R.B.Y, NumRows, Y + 1);
    end;
  end;

begin
  if Last = nil then Exit;

  { Count tileable views }
  NumTileable := 0;
  V := Last;
  L0 := Last;
  repeat
    V := V^.Next;
    if Tileable(V) then Inc(NumTileable);
  until V = L0;

  if NumTileable > 0 then begin
    { Calculate most equal divisors for grid layout }
    MostEqualDivisors(NumTileable, NumCols, NumRows, not TileColumnsFirst);

    { Check if tiles would be zero-sized }
    if ((R.B.X - R.A.X) div NumCols = 0) or
       ((R.B.Y - R.A.Y) div NumRows = 0) then
      TileError
    else begin
      LeftOver := NumTileable mod NumCols;

      { Tile the views }
      TileNum := NumTileable - 1;
      V := Last;
      repeat
        V := V^.Next;
        if Tileable(V) then begin
          CalcTileRect(TileNum, NR);
          { Temporarily hide view to prevent flicker during relocation }
          PState := V^.State;
          V^.State := V^.State and not sfVisible;
          V^.Locate(NR);
          V^.State := PState;
          Dec(TileNum);
        end;
      until V = L0;

      { Redraw desktop after tiling }
      DrawView;
    end;
  end;
end;

procedure TDesktop.Cascade(var R: TRect);
var
  CascadeNum, Cnt: Integer;
  Min, Max: TPoint;
  NR: TRect;
  V, L0: PView;

  function Cascadeable(P: PView): Boolean;
  begin
    Result := (P^.Options and ofTileable <> 0) and (P^.State and sfVisible <> 0);
  end;

begin
  if Last = nil then Exit;

  { Count cascadeable views }
  CascadeNum := 0;
  V := Last;
  L0 := Last;
  repeat
    V := V^.Next;
    if Cascadeable(V) then Inc(CascadeNum);
  until V = L0;

  if CascadeNum > 0 then begin
    if (R.B.X - R.A.X < CascadeNum) or (R.B.Y - R.A.Y < CascadeNum) then
      TileError
    else begin
      { Cascade all cascadeable views }
      Cnt := 0;
      V := Last;
      repeat
        V := V^.Next;
        if Cascadeable(V) then begin
          NR.A.X := R.A.X + Cnt;
          NR.A.Y := R.A.Y + Cnt;
          V^.SizeLimits(Min, Max);
          NR.B.X := NR.A.X + Max.X;
          if NR.B.X > R.B.X then NR.B.X := R.B.X;
          NR.B.Y := NR.A.Y + Max.Y;
          if NR.B.Y > R.B.Y then NR.B.Y := R.B.Y;
          V^.Locate(NR);
          Inc(Cnt);
        end;
      until V = L0;
    end;
  end;
end;

{ TProgram }

constructor TProgram.Init;
var
  R: TRect;
begin
  Application := @Self;
  InitScreen;
  R.Assign(0, 0, DriversScreenWidth, DriversScreenHeight);
  inherited Init(R);
  State := sfVisible + sfSelected + sfFocused + sfModal + sfExposed;
  Options := 0;
  Buffer := PWordArray(Video.VideoBuf);
  InitDesktop;
  InitStatusLine;
  InitMenuBar;
  if Desktop <> nil then Insert(Desktop);
  if StatusLine <> nil then Insert(StatusLine);
  if MenuBar <> nil then Insert(MenuBar);
end;

destructor TProgram.Done;
begin
  { Note: Do NOT dispose Desktop, MenuBar, StatusLine here.
    They are inserted into this TGroup and will be disposed
    by TGroup.Done when we call inherited Done.
    Manual disposal here would cause a double-free crash. }
  Desktop := nil;
  MenuBar := nil;
  StatusLine := nil;
  inherited Done;
  Application := nil;
end;

function TProgram.ExecuteDialog(P: PDialog; Data: Pointer): Word;
var
  C: Word;
begin
  Result := cmCancel;
  if P <> nil then begin
    if Data <> nil then
      P^.SetData(Data^);
    if Desktop = nil then
      Exit;
    C := Desktop^.ExecView(P);
    if (C <> cmCancel) and (Data <> nil) then
      P^.GetData(Data^);
    Dispose(P, Done);
    Result := C;
  end;
end;

function TProgram.GetPalette: PPalette;
const
  P: array[0..2] of String[Length(CAppColor)] = (CAppColor, CAppBlackWhite, CAppMonochrome);
begin
  GetPalette := PPalette(@P[AppPalette]);
end;

procedure TProgram.GetEvent(var Event: TEvent);
begin
  if StatusLine <> nil then StatusLine^.Update;
  Drivers.GetEvent(Event);
  if Event.What = evNothing then begin
    Idle;
  end;
end;

procedure TProgram.HandleEvent(var Event: TEvent);
var
  Handled: Boolean;
begin
  Handled := False;
  if Event.What = evKeyDown then begin
    case Event.KeyCode of
      kbAltX: begin Event.Command := cmQuit; Handled := True; end;
      kbAltF3: begin Event.Command := cmClose; Handled := True; end;
      kbF10: begin Event.Command := cmMenu; Handled := True; end;
      kbF5: begin Event.Command := cmZoom; Handled := True; end;
      kbCtrlF5: begin Event.Command := cmResize; Handled := True; end;
      kbF6: begin Event.Command := cmNext; Handled := True; end;
      kbShiftF6: begin Event.Command := cmPrev; Handled := True; end;
    end;
    if Handled then begin
      Event.What := evCommand;
      Event.InfoPtr := nil;
      PutEvent(Event);
      ClearEvent(Event);
    end;
  end;
  { Always call inherited to let subviews process the event }
  inherited HandleEvent(Event);
  if Event.What = evCommand then begin
    case Event.Command of
      cmQuit: EndModal(cmQuit);
    end;
  end;
end;

procedure TProgram.Idle;
begin
  if StatusLine <> nil then StatusLine^.Update;
  Video.UpdateScreen(False);
end;

procedure TProgram.InitDesktop;
var
  R: TRect;
begin
  GetExtent(R);
  Inc(R.A.Y);
  Dec(R.B.Y);
  Desktop := New(PDesktop, Init(R));
end;

procedure TProgram.InitMenuBar;
var
  R: TRect;
begin
  GetExtent(R);
  R.B.Y := R.A.Y + 1;
  MenuBar := New(PMenuBar, Init(R, nil));
end;

procedure TProgram.InitScreen;
begin
  if not InitDriversVideo then begin
    WriteLn('Error initializing video');
    Halt(1);
  end;
  InitEvents;
  InitHistory;
end;

procedure TProgram.InitStatusLine;
var
  R: TRect;
begin
  GetExtent(R);
  R.A.Y := R.B.Y - 1;
  StatusLine := New(PStatusLine, Init(R,
    NewStatusDef(0, $FFFF,
      NewStatusKey('~Alt-X~ Exit', kbAltX, cmQuit,
      NewStatusKey('~F10~ Menu', kbF10, cmMenu, nil)), nil)));
end;

procedure TProgram.OutOfMemory;
begin
end;

procedure TProgram.PutEvent(var Event: TEvent);
begin
  Drivers.PutEvent(Event);
end;

procedure TProgram.Run;
begin
  Draw;
  Video.UpdateScreen(True);
  Execute;
end;

procedure TProgram.SetScreenMode(Mode: Word);
begin
end;

{ TApplication }

constructor TApplication.Init;
begin
  inherited Init;
end;

destructor TApplication.Done;
begin
  DoneHistory;
  DoneEvents;
  DoneDriversVideo;
  inherited Done;
end;

procedure TApplication.Cascade;
var
  R: TRect;
begin
  GetTileRect(R);
  if Desktop <> nil then Desktop^.Cascade(R);
end;

procedure TApplication.DosShell;
begin
end;

procedure TApplication.GetTileRect(var R: TRect);
begin
  if Desktop <> nil then Desktop^.GetExtent(R)
  else GetExtent(R);
end;

procedure TApplication.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);
  if Event.What = evCommand then begin
    case Event.Command of
      cmTile: Tile;
      cmCascade: Cascade;
      cmDosShell: DosShell;
    else
      Exit;
    end;
    ClearEvent(Event);
  end;
end;

procedure TApplication.Tile;
var
  R: TRect;
begin
  GetTileRect(R);
  if Desktop <> nil then Desktop^.Tile(R);
end;

procedure RegisterApp;
begin
  RegisterType(RBackground);
  RegisterType(RDesktop);
end;

initialization
  AppPalette := 0;
  Application := nil;
  Desktop := nil;
  StatusLine := nil;
  MenuBar := nil;

end.
