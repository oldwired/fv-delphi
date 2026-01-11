{*******************************************************}
{       Free Vision - Long Integer Input Unit           }
{       Ported to Modern Delphi                         }
{*******************************************************}

{
  TInputLong is a derivative of TInputLine designed to accept LongInt
  numeric input. Since both the upper and lower limit of acceptable numeric
  input can be set, TInputLong may be used for SmallInt, Word, or Byte input
  as well. Option flag bits allow optional hex input and display. A blank
  field may optionally be rejected or interpreted as zero.
}

unit InpLong;

interface

uses
  System.SysUtils, Objects, Drivers, Views, Dialogs, MsgBox, FVCommon, FVConsts;

const
  { Flags for TInputLong constructor }
  ilHex = 1;          { Will enable hex input with leading '$' }
  ilBlankEqZero = 2;  { No input (blank) will be interpreted as '0' }
  ilDisplayHex = 4;   { Number displayed as hex when possible }

type
  PInputLong = ^TInputLong;
  TInputLong = object(TInputLine)
    ILOptions: Word;
    LLim, ULim: LongInt;
    constructor Init(var R: TRect; AMaxLen: Integer;
      LowerLim, UpperLim: LongInt; Flgs: Word);
    constructor Load(var S: TStream);
    procedure Store(var S: TStream);
    function DataSize: Word; virtual;
    procedure GetData(var Rec); virtual;
    procedure SetData(var Rec); virtual;
    function RangeCheck: Boolean; virtual;
    procedure Error; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    function Valid(Cmd: Word): Boolean; virtual;
  end;

const
  RInputLong: TStreamRec = (
    ObjType: idInputLong;
    VmtLink: nil;
    Load: @TInputLong.Load;
    Store: @TInputLong.Store
  );

procedure RegisterInpLong;

implementation

function Hex2(B: Byte): string;
const
  HexArray: array[0..15] of Char = '0123456789ABCDEF';
begin
  Result := HexArray[B shr 4] + HexArray[B and $F];
end;

function Hex4(W: Word): string;
begin
  Result := Hex2(Hi(W)) + Hex2(Lo(W));
end;

function Hex8(L: LongInt): string;
begin
  Result := Hex4(LongRec(L).Hi) + Hex4(LongRec(L).Lo);
end;

function FormHexStr(L: LongInt): string;
var
  Minus: Boolean;
  S: string;
begin
  Minus := L < 0;
  if Minus then L := -L;
  S := Hex8(L);
  while (Length(S) > 1) and (S[1] = '0') do Delete(S, 1, 1);
  S := '$' + S;
  if Minus then System.Insert('-', S, 2);
  Result := S;
end;

constructor TInputLong.Init(var R: TRect; AMaxLen: Integer;
  LowerLim, UpperLim: LongInt; Flgs: Word);
begin
  if not TInputLine.Init(R, AMaxLen) then Fail;
  ULim := UpperLim;
  LLim := LowerLim;
  if (Flgs and ilDisplayHex) <> 0 then Flgs := Flgs or ilHex;
  ILOptions := Flgs;
  if (ILOptions and ilBlankEqZero) <> 0 then Data^ := '0';
end;

constructor TInputLong.Load(var S: TStream);
begin
  TInputLine.Load(S);
  S.Read(ILOptions, SizeOf(ILOptions));
  S.Read(LLim, SizeOf(LLim));
  S.Read(ULim, SizeOf(ULim));
end;

procedure TInputLong.Store(var S: TStream);
begin
  TInputLine.Store(S);
  S.Write(ILOptions, SizeOf(ILOptions));
  S.Write(LLim, SizeOf(LLim));
  S.Write(ULim, SizeOf(ULim));
end;

function TInputLong.DataSize: Word;
begin
  Result := SizeOf(LongInt);
end;

procedure TInputLong.GetData(var Rec);
var
  Code: Integer;
begin
  Val(Data^, LongInt(Rec), Code);
end;

procedure TInputLong.SetData(var Rec);
var
  L: LongInt;
  S: string;
begin
  L := LongInt(Rec);
  if L > ULim then L := ULim
  else if L < LLim then L := LLim;
  if (ILOptions and ilDisplayHex) <> 0 then
    S := FormHexStr(L)
  else
    Str(L, S);
  if Length(S) > MaxLen then SetLength(S, MaxLen);
  Data^ := S;
end;

function TInputLong.RangeCheck: Boolean;
var
  L: LongInt;
  Code: Integer;
begin
  if (Data^ = '') and ((ILOptions and ilBlankEqZero) <> 0) then
    Data^ := '0';
  Val(Data^, L, Code);
  Result := (Code = 0) and (L >= LLim) and (L <= ULim);
end;

procedure TInputLong.Error;
var
  SU, SL: string;
begin
  Str(LLim, SL);
  Str(ULim, SU);
  if (ILOptions and ilHex) <> 0 then
  begin
    SL := SL + '(' + FormHexStr(LLim) + ')';
    SU := SU + '(' + FormHexStr(ULim) + ')';
  end;
  MessageBox('Value not within range ' + SL + ' to ' + SU, nil,
    mfError + mfOKButton);
end;

procedure TInputLong.HandleEvent(var Event: TEvent);
begin
  if Event.What = evKeyDown then
  begin
    case Event.KeyCode of
      kbTab, kbShiftTab:
        if not RangeCheck then
        begin
          Error;
          SelectAll(True);
          ClearEvent(Event);
        end;
    end;
    if Event.CharCode <> #0 then
    begin
      Event.CharCode := UpCase(Event.CharCode);
      case Event.CharCode of
        '0'..'9', #1..#$1B: ; { acceptable }
        '-':
          if (LLim >= 0) or (CurPos <> 0) then
            ClearEvent(Event);
        '$':
          if (ILOptions and ilHex) = 0 then ClearEvent(Event);
        'A'..'F':
          if Pos('$', Data^) = 0 then ClearEvent(Event);
      else
        ClearEvent(Event);
      end;
    end;
  end;
  TInputLine.HandleEvent(Event);
end;

function TInputLong.Valid(Cmd: Word): Boolean;
var
  Rslt: Boolean;
begin
  Rslt := TInputLine.Valid(Cmd);
  if Rslt and (Cmd <> 0) and (Cmd <> cmCancel) then
  begin
    Rslt := RangeCheck;
    if not Rslt then
    begin
      Error;
      Select;
      SelectAll(True);
    end;
  end;
  Result := Rslt;
end;

procedure RegisterInpLong;
begin
  RegisterType(RInputLong);
end;

end.
