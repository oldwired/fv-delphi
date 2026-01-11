{*******************************************************}
{       Free Vision - Gadgets Unit                      }
{       Ported to Modern Delphi                         }
{*******************************************************}

{
  THeapView - displays current heap memory usage
  TClockView - displays current time

  Based on original FPC Free Vision GADGETS.PAS by Leon de Boer.
}

unit Gadgets;

interface

uses
  FVConsts, Time, Objects, Drivers, Views, App;

{***************************************************************************}
{                        PUBLIC OBJECT DEFINITIONS                          }
{***************************************************************************}

{---------------------------------------------------------------------------}
{                  THeapView OBJECT - ANCESTOR VIEW OBJECT                  }
{---------------------------------------------------------------------------}
TYPE
   THeapViewMode=(HVNormal,HVComma,HVKb,HVMb);

   THeapView = OBJECT (TView)
         Mode   : THeapViewMode;
         OldMem: LongInt;                             { Last memory count }
      constructor Init(var Bounds: TRect);
      constructor InitComma(var Bounds: TRect);
      constructor InitKb(var Bounds: TRect);
      constructor InitMb(var Bounds: TRect);
      PROCEDURE Update;
      PROCEDURE Draw; Virtual;
      Function  Comma ( N : LongInt ) : String;
   END;
   PHeapView = ^THeapView;                            { Heapview pointer }

{---------------------------------------------------------------------------}
{                 TClockView OBJECT - ANCESTOR VIEW OBJECT                  }
{---------------------------------------------------------------------------}
TYPE
   TClockView = OBJECT (TView)
         am : AnsiChar;
         Refresh : Byte;                              { Refresh rate }
         LastTime: Longint;                           { Last time displayed }
         TimeStr : String[10];                        { Time string }
      CONSTRUCTOR Init (Var Bounds: TRect);
      FUNCTION FormatTimeStr (H, M, S: Word): String; Virtual;
      PROCEDURE Update; Virtual;
      PROCEDURE Draw; Virtual;
   END;
   PClockView = ^TClockView;                          { Clockview ptr }

{<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>}
                             IMPLEMENTATION
{<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>}

{***************************************************************************}
{                              OBJECT METHODS                               }
{***************************************************************************}

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
{                          THeapView OBJECT METHODS                         }
{+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}

constructor THeapView.Init(var Bounds: TRect);
begin
  inherited Init(Bounds);
  mode:=HVNormal;
  OldMem := 0;
end;

constructor THeapView.InitComma(var Bounds: TRect);
begin
  inherited Init(Bounds);
  mode:=HVComma;
  OldMem := 0;
end;

constructor THeapView.InitKb(var Bounds: TRect);
begin
  inherited Init(Bounds);
  mode:=HVKb;
  OldMem := 0;
end;

constructor THeapView.InitMb(var Bounds: TRect);
begin
  inherited Init(Bounds);
  mode:=HVMb;
  OldMem := 0;
end;

procedure THeapView.Update;
var
  NewMem: LongInt;
begin
  { In Delphi, use GetHeapStatus or memory manager info }
  {$IFDEF MSWINDOWS}
  NewMem := GetHeapStatus.TotalAllocated;
  {$ELSE}
  NewMem := 0;
  {$ENDIF}
  if OldMem <> NewMem then
  begin
    OldMem := NewMem;
    DrawView;
  end;
end;

procedure THeapView.Draw;
var
  C: Byte;
  S: string;
  B: TDrawBuffer;
begin
  case Mode of
    HVNormal:
      Str(OldMem:Size.X, S);
    HVComma:
      S := Comma(OldMem);
    HVKb:
      begin
        Str(OldMem shr 10:Size.X-1, S);
        S := S + 'K';
      end;
    HVMb:
      begin
        Str(OldMem shr 20:Size.X-1, S);
        S := S + 'M';
      end;
  end;
  C := GetColor(2);
  MoveChar(B, ' ', C, Size.X);
  MoveStr(B, S, C);
  WriteLine(0, 0, Size.X, 1, B);
end;

function THeapView.Comma(N: LongInt): string;
var
  Num, Loc: Byte;
  S, T: string;
begin
  Str(N, S);
  Str(N:Size.X, T);

  Num := Length(S) div 3;
  if (Length(S) mod 3) = 0 then Dec(Num);

  Delete(T, 1, Num);
  Loc := Length(T) - 2;

  while Num > 0 do
  begin
    Insert(',', T, Loc);
    Dec(Num);
    Dec(Loc, 3);
  end;

  Result := T;
end;

{ TClockView }

constructor TClockView.Init(var Bounds: TRect);
begin
  inherited Init(Bounds);
  FillChar(LastTime, SizeOf(LastTime), $FF);
  TimeStr := '';
  Refresh := 1;
end;

function TClockView.FormatTimeStr(H, M, S: Word): string;
var
  Hs, Ms, Ss: string;
begin
  Str(H, Hs);
  while Length(Hs) < 2 do Hs := '0' + Hs;
  Str(M, Ms);
  while Length(Ms) < 2 do Ms := '0' + Ms;
  Str(S, Ss);
  while Length(Ss) < 2 do Ss := '0' + Ss;
  Result := Hs + ':' + Ms + ':' + Ss;
end;

procedure TClockView.Update;
var
  Hour, Min, Sec, Sec100: Word;
begin
  GetTime(Hour, Min, Sec, Sec100);
  if Abs(Sec - LastTime) >= Refresh then
  begin
    LastTime := Sec;
    TimeStr := FormatTimeStr(Hour, Min, Sec);
    DrawView;
  end;
end;

procedure TClockView.Draw;
var
  C: Byte;
  B: TDrawBuffer;
begin
  C := GetColor(2);
  MoveChar(B, ' ', C, Size.X);
  MoveStr(B, TimeStr, C);
  WriteLine(0, 0, Size.X, 1, B);
end;

end.
