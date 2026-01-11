{*******************************************************}
{       Free Vision Validate Unit                       }
{       Delphi-compatible version                       }
{*******************************************************}

unit Validate;

{$R-}

interface

uses
  System.SysUtils,
  FVCommon, Objects, fvconsts;

{***************************************************************************}
{                              PUBLIC CONSTANTS                             }
{***************************************************************************}

const
  vsOk     = 0;
  vsSyntax = 1;

  voFill     = $0001;
  voTransfer = $0002;
  voOnAppend = $0004;
  voReserved = $00F8;

{***************************************************************************}
{                            TYPE DEFINITIONS                               }
{***************************************************************************}

type
  TVTransfer = (vtDataSize, vtSetData, vtGetData);
  TPicResult = (prComplete, prIncomplete, prEmpty, prError, prSyntax,
    prAmbiguous, prIncompNoFill);

  CharSet = set of AnsiChar;
  TCharSet = CharSet;

{***************************************************************************}
{                            OBJECT DEFINITIONS                             }
{***************************************************************************}

type
  PValidator = ^TValidator;
  TValidator = object(TObject)
    Status: Word;
    Options: Word;
    constructor Init;
    constructor Load(var S: TStream);
    function Valid(const S: string): Boolean;
    function IsValid(const S: string): Boolean; virtual;
    function IsValidInput(var S: string; SuppressFill: Boolean): Boolean; virtual;
    function Transfer(var S: string; Buffer: Pointer; Flag: TVTransfer): Word; virtual;
    procedure Error; virtual;
    procedure Store(var S: TStream);
  end;

  PPXPictureValidator = ^TPXPictureValidator;
  TPXPictureValidator = object(TValidator)
    Pic: PString;  { Use Objects.PString for compatibility }
    constructor Init(const APic: string; AutoFill: Boolean);
    constructor Load(var S: TStream);
    destructor Done; virtual;
    function IsValid(const S: string): Boolean; virtual;
    function IsValidInput(var S: string; SuppressFill: Boolean): Boolean; virtual;
    function Picture(var Input: string; AutoFill: Boolean): TPicResult; virtual;
    procedure Error; virtual;
    procedure Store(var S: TStream);
  end;

  PFilterValidator = ^TFilterValidator;
  TFilterValidator = object(TValidator)
    ValidChars: CharSet;
    constructor Init(AValidChars: CharSet);
    constructor Load(var S: TStream);
    function IsValid(const S: string): Boolean; virtual;
    function IsValidInput(var S: string; SuppressFill: Boolean): Boolean; virtual;
    procedure Error; virtual;
    procedure Store(var S: TStream);
  end;

  PRangeValidator = ^TRangeValidator;
  TRangeValidator = object(TFilterValidator)
    Min: LongInt;
    Max: LongInt;
    constructor Init(AMin, AMax: LongInt);
    constructor Load(var S: TStream);
    function IsValid(const S: string): Boolean; virtual;
    function Transfer(var S: string; Buffer: Pointer; Flag: TVTransfer): Word; virtual;
    procedure Error; virtual;
    procedure Store(var S: TStream);
  end;

  PLookupValidator = ^TLookupValidator;
  TLookupValidator = object(TValidator)
    function IsValid(const S: string): Boolean; virtual;
    function Lookup(const S: string): Boolean; virtual;
  end;

  PStringLookupValidator = ^TStringLookupValidator;
  TStringLookupValidator = object(TLookupValidator)
    Strings: PStringCollection;
    constructor Init(AStrings: PStringCollection);
    constructor Load(var S: TStream);
    destructor Done; virtual;
    function Lookup(const S: string): Boolean; virtual;
    procedure Error; virtual;
    procedure NewStringList(AStrings: PStringCollection);
    procedure Store(var S: TStream);
  end;

procedure RegisterValidate;

implementation

{***************************************************************************}
{                         TValidator Implementation                         }
{***************************************************************************}

constructor TValidator.Init;
begin
  inherited Init;
  Status := vsOk;
  Options := 0;
end;

constructor TValidator.Load(var S: TStream);
begin
  inherited Init;
  S.Read(Options, SizeOf(Options));
end;

function TValidator.Valid(const S: string): Boolean;
begin
  Result := False;
  if not IsValid(S) then Error
  else Result := True;
end;

function TValidator.IsValid(const S: string): Boolean;
begin
  Result := True;
end;

function TValidator.IsValidInput(var S: string; SuppressFill: Boolean): Boolean;
begin
  Result := True;
end;

function TValidator.Transfer(var S: string; Buffer: Pointer; Flag: TVTransfer): Word;
begin
  Result := 0;
end;

procedure TValidator.Error;
begin
  { Abstract - override in descendants }
end;

procedure TValidator.Store(var S: TStream);
begin
  S.Write(Options, SizeOf(Options));
end;

{***************************************************************************}
{                    TPXPictureValidator Implementation                     }
{***************************************************************************}

constructor TPXPictureValidator.Init(const APic: string; AutoFill: Boolean);
begin
  inherited Init;
  Pic := NewStr(APic);
  Options := voOnAppend;
  if AutoFill then Options := Options or voFill;
end;

constructor TPXPictureValidator.Load(var S: TStream);
begin
  inherited Load(S);
  Pic := S.ReadStr;
end;

destructor TPXPictureValidator.Done;
begin
  if Pic <> nil then DisposeStr(Pic);
  inherited Done;
end;

function TPXPictureValidator.IsValid(const S: string): Boolean;
var
  Str: string;
begin
  Str := S;
  Result := Picture(Str, False) in [prComplete, prEmpty];
end;

function TPXPictureValidator.IsValidInput(var S: string; SuppressFill: Boolean): Boolean;
var
  Rslt: TPicResult;
begin
  Rslt := Picture(S, (Options and voFill <> 0) and not SuppressFill);
  Result := Rslt in [prComplete, prIncomplete, prEmpty];
end;

function TPXPictureValidator.Picture(var Input: string; AutoFill: Boolean): TPicResult;
begin
  { Simplified implementation }
  if Input = '' then Result := prEmpty
  else Result := prComplete;
end;

procedure TPXPictureValidator.Error;
begin
  { Would show message box in full implementation }
end;

procedure TPXPictureValidator.Store(var S: TStream);
begin
  inherited Store(S);
  S.WriteStr(Pic);
end;

{***************************************************************************}
{                     TFilterValidator Implementation                       }
{***************************************************************************}

constructor TFilterValidator.Init(AValidChars: CharSet);
begin
  inherited Init;
  ValidChars := AValidChars;
end;

constructor TFilterValidator.Load(var S: TStream);
begin
  inherited Load(S);
  S.Read(ValidChars, SizeOf(ValidChars));
end;

function TFilterValidator.IsValid(const S: string): Boolean;
var
  I: Integer;
begin
  Result := True;
  for I := 1 to Length(S) do
    if not (S[I] in ValidChars) then begin
      Result := False;
      Exit;
    end;
end;

function TFilterValidator.IsValidInput(var S: string; SuppressFill: Boolean): Boolean;
begin
  Result := IsValid(S);
end;

procedure TFilterValidator.Error;
begin
  { Would show message box in full implementation }
end;

procedure TFilterValidator.Store(var S: TStream);
begin
  inherited Store(S);
  S.Write(ValidChars, SizeOf(ValidChars));
end;

{***************************************************************************}
{                      TRangeValidator Implementation                       }
{***************************************************************************}

constructor TRangeValidator.Init(AMin, AMax: LongInt);
begin
  inherited Init(['0'..'9', '+', '-']);
  Min := AMin;
  Max := AMax;
end;

constructor TRangeValidator.Load(var S: TStream);
begin
  inherited Load(S);
  S.Read(Min, SizeOf(Min));
  S.Read(Max, SizeOf(Max));
end;

function TRangeValidator.IsValid(const S: string): Boolean;
var
  Value: LongInt;
  Code: Integer;
begin
  Result := inherited IsValid(S);
  if Result then begin
    Val(string(S), Value, Code);
    Result := (Code = 0) and (Value >= Min) and (Value <= Max);
  end;
end;

function TRangeValidator.Transfer(var S: string; Buffer: Pointer; Flag: TVTransfer): Word;
var
  Value: LongInt;
  Code: Integer;
begin
  Result := SizeOf(LongInt);
  case Flag of
    vtGetData: begin
      Val(string(S), Value, Code);
      if Code = 0 then LongInt(Buffer^) := Value;
    end;
    vtSetData: begin
      Str(LongInt(Buffer^), S);
    end;
  end;
end;

procedure TRangeValidator.Error;
begin
  { Would show message box in full implementation }
end;

procedure TRangeValidator.Store(var S: TStream);
begin
  inherited Store(S);
  S.Write(Min, SizeOf(Min));
  S.Write(Max, SizeOf(Max));
end;

{***************************************************************************}
{                     TLookupValidator Implementation                       }
{***************************************************************************}

function TLookupValidator.IsValid(const S: string): Boolean;
begin
  Result := Lookup(S);
end;

function TLookupValidator.Lookup(const S: string): Boolean;
begin
  Result := True;
end;

{***************************************************************************}
{                  TStringLookupValidator Implementation                    }
{***************************************************************************}

constructor TStringLookupValidator.Init(AStrings: PStringCollection);
begin
  inherited Init;
  Strings := AStrings;
end;

constructor TStringLookupValidator.Load(var S: TStream);
begin
  inherited Load(S);
  Strings := PStringCollection(S.Get);
end;

destructor TStringLookupValidator.Done;
begin
  NewStringList(nil);
  inherited Done;
end;

function TStringLookupValidator.Lookup(const S: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  if Strings <> nil then begin
    Result := Strings^.Search(@S, I);
  end;
end;

procedure TStringLookupValidator.Error;
begin
  { Would show message box in full implementation }
end;

procedure TStringLookupValidator.NewStringList(AStrings: PStringCollection);
begin
  if Strings <> nil then Dispose(Strings, Done);
  Strings := AStrings;
end;

procedure TStringLookupValidator.Store(var S: TStream);
begin
  inherited Store(S);
  S.Put(Strings);
end;

{***************************************************************************}
{                           Registration                                    }
{***************************************************************************}

procedure RegisterValidate;
begin
  { Stream registration would go here }
end;

end.
