{*******************************************************}
{       Free Vision - Timed Dialogs Unit               }
{       Ported to Modern Delphi                        }
{*******************************************************}

{
  Timed dialogs that automatically close after a specified
  number of seconds. Useful for splash screens, auto-timeout
  message boxes, etc.
}

unit TimedDlg;

interface

uses
  Objects, FVConsts, FVCommon, Dialogs, Drivers, Views;

type
  PTimedDialog = ^TTimedDialog;
  TTimedDialog = object(TDialog)
    Secs: LongInt;
    constructor Init(var Bounds: TRect; ATitle: TTitleStr; ASecs: Word);
    constructor Load(var S: TStream);
    procedure GetEvent(var Event: TEvent); virtual;
    procedure Store(var S: TStream); virtual;
  private
    Secs0: LongInt;
    Secs2: LongInt;
    DayWrap: Boolean;
  end;

  { Must be always included in TTimedDialog! }
  PTimedDialogText = ^TTimedDialogText;
  TTimedDialogText = object(TStaticText)
    constructor Init(var Bounds: TRect);
    procedure GetText(var S: ShortString); virtual;
  end;

const
  RTimedDialog: TStreamRec = (
    ObjType: idTimedDialog;
    VmtLink: nil;
    Load: @TTimedDialog.Load;
    Store: @TTimedDialog.Store
  );

  RTimedDialogText: TStreamRec = (
    ObjType: idTimedDialogText;
    VmtLink: nil;
    Load: @TTimedDialogText.Load;
    Store: @TTimedDialogText.Store
  );

procedure RegisterTimedDialog;

function TimedMessageBox(const Msg: ShortString; Params: Pointer;
  AOptions: Word; ASecs: Word): Word;

function TimedMessageBoxRect(var R: TRect; const Msg: ShortString;
  Params: Pointer; AOptions: Word; ASecs: Word): Word;

implementation

uses
  Time, App, MsgBox;

{ TTimedDialogText }

constructor TTimedDialogText.Init(var Bounds: TRect);
begin
  inherited Init(Bounds, '');
end;

procedure TTimedDialogText.GetText(var S: ShortString);
begin
  if Owner <> nil then
  begin
    Str(PTimedDialog(Owner)^.Secs, S);
    S := #3 + S;  { #3 = center text }
  end
  else
    S := '';
end;

{ TTimedDialog }

constructor TTimedDialog.Init(var Bounds: TRect; ATitle: TTitleStr;
  ASecs: Word);
var
  H, M, Sec, S100: Word;
begin
  inherited Init(Bounds, ATitle);
  GetTime(H, M, Sec, S100);
  Secs0 := H * 3600 + M * 60 + Sec;
  Secs2 := Secs0 + ASecs;
  Secs := ASecs;
  DayWrap := Secs2 > 24 * 3600;
end;

procedure TTimedDialog.GetEvent(var Event: TEvent);
var
  H, M, Sec, S100: Word;
  Secs1: LongInt;
begin
  inherited GetEvent(Event);
  GetTime(H, M, Sec, S100);
  Secs1 := H * 3600 + M * 60 + Sec;
  if DayWrap then Inc(Secs1, 24 * 3600);
  if Secs2 - Secs1 <> Secs then
  begin
    Secs := Secs2 - Secs1;
    if Secs < 0 then
      Secs := 0;
    { If remaining seconds are displayed in one of included views, update them. }
    Redraw;
  end;
  with Event do
    if (Secs = 0) and (What = evNothing) then
    begin
      What := evCommand;
      Command := cmCancel;
    end;
end;

constructor TTimedDialog.Load(var S: TStream);
begin
  inherited Load(S);
  S.Read(Secs, SizeOf(Secs));
  S.Read(Secs0, SizeOf(Secs0));
  S.Read(Secs2, SizeOf(Secs2));
  S.Read(DayWrap, SizeOf(DayWrap));
end;

procedure TTimedDialog.Store(var S: TStream);
begin
  inherited Store(S);
  S.Write(Secs, SizeOf(Secs));
  S.Write(Secs0, SizeOf(Secs0));
  S.Write(Secs2, SizeOf(Secs2));
  S.Write(DayWrap, SizeOf(DayWrap));
end;

{ Helper functions }

function TimedMessageBox(const Msg: ShortString; Params: Pointer;
  AOptions: Word; ASecs: Word): Word;
var
  R: TRect;
begin
  R.Assign(0, 0, 40, 10);
  if (AOptions and mfInsertInApp) = 0 then
    R.Move((Desktop^.Size.X - R.B.X) div 2,
           (Desktop^.Size.Y - R.B.Y) div 2)
  else
    R.Move((Application^.Size.X - R.B.X) div 2,
           (Application^.Size.Y - R.B.Y) div 2);
  Result := TimedMessageBoxRect(R, Msg, Params, AOptions, ASecs);
end;

function TimedMessageBoxRect(var R: TRect; const Msg: ShortString;
  Params: Pointer; AOptions: Word; ASecs: Word): Word;
var
  Dlg: PTimedDialog;
  TimedText: PTimedDialogText;
  TextR: TRect;
begin
  Dlg := New(PTimedDialog, Init(R, MsgBoxTitles[AOptions and $3], ASecs));
  with Dlg^ do
  begin
    TextR.Assign(3, Size.Y - 5, Size.X - 2, Size.Y - 4);
    New(TimedText, Init(TextR));
    Insert(TimedText);
    TextR.Assign(3, 2, Size.X - 2, Size.Y - 5);
  end;
  Result := MessageBoxRectDlg(Dlg, TextR, Msg, Params, AOptions);
  Dispose(Dlg, Done);
end;

procedure RegisterTimedDialog;
begin
  RegisterType(RTimedDialog);
  RegisterType(RTimedDialogText);
end;

end.
