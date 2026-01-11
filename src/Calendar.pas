{*******************************************************}
{       Free Vision - Calendar Unit                    }
{       TCalendarView - Text-mode calendar control     }
{*******************************************************}

unit Calendar;

interface

uses
  FVConsts, Objects, Drivers, Views;

type
  { Day color configuration - one color index per day of week }
  TDayColors = array[0..6] of Byte;  { 0=Sunday, 1=Monday, ..., 6=Saturday }

  { Forward declaration for callback type }
  PCalendarView = ^TCalendarView;

  { Callback for date selection events }
  TCalendarDateEvent = procedure(Calendar: PCalendarView) of object;

  TCalendarView = object(TView)
    Year: Word;
    Month: Word;
    Day: Word;
    FirstDayOfWeek: Byte;     { 0=Sunday, 1=Monday, etc. }
    DayColors: TDayColors;    { Color indices for each weekday }
    UseDayColors: Boolean;    { Whether to use custom day colors }
    OnDateSelect: TCalendarDateEvent;  { Called when date is selected }
    constructor Init(var Bounds: TRect);
    constructor InitWithDate(var Bounds: TRect; AYear, AMonth, ADay: Word);
    procedure Draw; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    function GetDate(var AYear, AMonth, ADay: Word): Boolean;
    procedure SetDate(AYear, AMonth, ADay: Word);
    procedure SetFirstDayOfWeek(AFirstDay: Byte);
    procedure SetDayColor(ADayOfWeek: Byte; AColorIndex: Byte);
    procedure NextMonth;
    procedure PrevMonth;
    procedure NextYear;
    procedure PrevYear;
  private
    function DaysInMonth(AYear, AMonth: Word): Word;
    function DayOfWeek(AYear, AMonth, ADay: Word): Word;
    function IsLeapYear(AYear: Word): Boolean;
    procedure SelectDate;
    procedure ClampDay;
    procedure ShowMonthMenu;
    procedure ShowYearMenu;
    function GetDayHeaderStr: ShortString;
  end;

const
  CCalendarView = #6#7#8#4#5;  { Normal, Selected, Title, Arrow, Weekend }

  { Short day names for headers }
  DayNamesShort: array[0..6] of string[2] = (
    'Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'
  );

implementation

uses
  SysUtils, App;

const
  MonthNames: array[1..12] of string[9] = (
    'January', 'February', 'March', 'April',
    'May', 'June', 'July', 'August',
    'September', 'October', 'November', 'December'
  );

  DaysPerMonth: array[1..12] of Byte = (
    31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
  );

type
  { Simple list menu for month/year selection }
  PCalendarMenu = ^TCalendarMenu;
  TCalendarMenu = object(TView)
    Items: array[0..15] of ShortString;
    ItemCount: Integer;
    Selected: Integer;
    Selection: Integer;
    EndState: Word;
    constructor Init(var Bounds: TRect; AItems: array of ShortString);
    procedure Draw; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    function Execute: Word; virtual;
    function GetPalette: PPalette; virtual;
  end;

const
  { Use same palette as menus: indices 2,3,4,5,6,7 from app palette }
  CCalendarMenu = #2#3#4#5#6#7;

constructor TCalendarMenu.Init(var Bounds: TRect; AItems: array of ShortString);
var
  I: Integer;
begin
  inherited Init(Bounds);
  Options := Options or ofSelectable or ofFirstClick or ofTopSelect;
  EventMask := evMouseDown or evKeyDown or evCommand;
  State := State or sfModal;
  ItemCount := High(AItems) - Low(AItems) + 1;
  if ItemCount > 16 then ItemCount := 16;
  for I := 0 to ItemCount - 1 do
    Items[I] := AItems[I];
  Selected := 0;
  Selection := -1;
  EndState := 0;
end;

function TCalendarMenu.Execute: Word;
var
  E: TEvent;
begin
  EndState := 0;
  repeat
    GetEvent(E);
    HandleEvent(E);
  until EndState <> 0;
  Result := EndState;
end;

function TCalendarMenu.GetPalette: PPalette;
const
  P: ShortString = CCalendarMenu;
begin
  GetPalette := @P;
end;

procedure TCalendarMenu.Draw;
var
  B: TDrawBuffer;
  CNormal, CSelect: Word;
  I: Integer;
begin
  { Use menu-style color mapping through palette }
  CNormal := GetColor($0301);  { Normal: indices 1 and 3 }
  CSelect := GetColor($0604);  { Selected: indices 4 and 6 }

  for I := 0 to ItemCount - 1 do begin
    MoveChar(B, ' ', Byte(CNormal), Size.X);
    if I = Selected then
      MoveStr(B[1], Items[I], CSelect)
    else
      MoveStr(B[1], Items[I], CNormal);
    WriteLine(0, I, Size.X, 1, B);
  end;
end;

procedure TCalendarMenu.HandleEvent(var Event: TEvent);
var
  Mouse: TPoint;
begin
  inherited HandleEvent(Event);

  case Event.What of
    evMouseDown: begin
      MakeLocal(Event.Where, Mouse);
      if (Mouse.Y >= 0) and (Mouse.Y < ItemCount) then begin
        Selected := Mouse.Y;
        Selection := Selected;
        DrawView;
        ClearEvent(Event);
        EndState := cmOK;
      end else begin
        ClearEvent(Event);
        EndState := cmCancel;
      end;
    end;

    evKeyDown: begin
      case Event.KeyCode of
        kbUp: begin
          if Selected > 0 then Dec(Selected)
          else Selected := ItemCount - 1;
          DrawView;
          ClearEvent(Event);
        end;
        kbDown: begin
          if Selected < ItemCount - 1 then Inc(Selected)
          else Selected := 0;
          DrawView;
          ClearEvent(Event);
        end;
        kbEnter: begin
          Selection := Selected;
          ClearEvent(Event);
          EndState := cmOK;
        end;
        kbEsc: begin
          Selection := -1;
          ClearEvent(Event);
          EndState := cmCancel;
        end;
      end;
    end;

    evCommand: begin
      if Event.Command = cmCancel then begin
        Selection := -1;
        ClearEvent(Event);
        EndState := cmCancel;
      end;
    end;
  end;
end;

{ TCalendarView }

constructor TCalendarView.Init(var Bounds: TRect);
var
  Y, M, D: Word;
  I: Integer;
begin
  inherited Init(Bounds);
  Options := Options or ofSelectable or ofFirstClick;
  EventMask := EventMask or evMouseDown or evKeyDown;
  DecodeDate(Now, Y, M, D);
  Year := Y;
  Month := M;
  Day := D;
  FirstDayOfWeek := 0;  { Sunday }
  UseDayColors := False;
  OnDateSelect := nil;
  for I := 0 to 6 do
    DayColors[I] := 1;  { Default to normal color }
end;

constructor TCalendarView.InitWithDate(var Bounds: TRect; AYear, AMonth, ADay: Word);
var
  I: Integer;
begin
  inherited Init(Bounds);
  Options := Options or ofSelectable or ofFirstClick;
  EventMask := EventMask or evMouseDown or evKeyDown;
  Year := AYear;
  Month := AMonth;
  Day := ADay;
  FirstDayOfWeek := 0;  { Sunday }
  UseDayColors := False;
  OnDateSelect := nil;
  for I := 0 to 6 do
    DayColors[I] := 1;
  ClampDay;
end;

function TCalendarView.IsLeapYear(AYear: Word): Boolean;
begin
  Result := ((AYear mod 4 = 0) and (AYear mod 100 <> 0)) or (AYear mod 400 = 0);
end;

function TCalendarView.DaysInMonth(AYear, AMonth: Word): Word;
begin
  Result := DaysPerMonth[AMonth];
  if (AMonth = 2) and IsLeapYear(AYear) then
    Inc(Result);
end;

function TCalendarView.DayOfWeek(AYear, AMonth, ADay: Word): Word;
var
  A, Y, M: Integer;
begin
  { Zeller's congruence for Gregorian calendar }
  A := (14 - AMonth) div 12;
  Y := AYear - A;
  M := AMonth + 12 * A - 2;
  Result := (ADay + (31 * M div 12) + Y + (Y div 4) - (Y div 100) + (Y div 400)) mod 7;
  { Result: 0=Sunday, 1=Monday, ..., 6=Saturday }
end;

procedure TCalendarView.ClampDay;
var
  MaxDay: Word;
begin
  MaxDay := DaysInMonth(Year, Month);
  if Day > MaxDay then
    Day := MaxDay;
  if Day < 1 then
    Day := 1;
end;

procedure TCalendarView.SetFirstDayOfWeek(AFirstDay: Byte);
begin
  if AFirstDay <= 6 then
    FirstDayOfWeek := AFirstDay;
  DrawView;
end;

procedure TCalendarView.SetDayColor(ADayOfWeek: Byte; AColorIndex: Byte);
begin
  if ADayOfWeek <= 6 then begin
    DayColors[ADayOfWeek] := AColorIndex;
    UseDayColors := True;
  end;
end;

function TCalendarView.GetDayHeaderStr: ShortString;
var
  I, D: Integer;
  S: ShortString;
begin
  S := '';
  for I := 0 to 6 do begin
    D := (FirstDayOfWeek + I) mod 7;
    if I > 0 then S := S + ' ';
    S := S + DayNamesShort[D];
  end;
  GetDayHeaderStr := S;
end;

procedure TCalendarView.Draw;
var
  B: TDrawBuffer;
  CTitle, CNormal, CSelected, CArrow: Word;
  FirstDay, Days, Row, Col, D, ActualDOW: Integer;
  S: string[20];
  TitleStr, MonthStr, YearStr: ShortString;
  Y, MonthX, YearX, ArrowLeftX, ArrowRightX: Integer;
  DayColor: Word;
begin
  CTitle := GetColor(3);     { Title color }
  CNormal := GetColor(1);    { Normal day color }
  CSelected := GetColor(2);  { Selected day color }
  CArrow := GetColor(4);     { Arrow color }

  { Line 0: < Month Year > with navigation arrows }
  MonthStr := MonthNames[Month];
  YearStr := IntToStr(Year);
  TitleStr := MonthStr + ' ' + YearStr;

  MoveChar(B, ' ', Byte(CTitle), Size.X);

  { Left arrow at position 0 }
  ArrowLeftX := 0;
  MoveStr(B[ArrowLeftX], '<', CArrow);

  { Center the month + year title }
  Col := (Size.X - Length(TitleStr)) div 2;
  if Col < 2 then Col := 2;

  { Remember positions for click detection }
  MonthX := Col;
  MoveStr(B[MonthX], ShortString(MonthStr), CTitle);

  YearX := MonthX + Length(MonthStr) + 1;
  MoveStr(B[YearX], ShortString(YearStr), CTitle);

  { Right arrow at end }
  ArrowRightX := Size.X - 1;
  MoveStr(B[ArrowRightX], '>', CArrow);

  WriteLine(0, 0, Size.X, 1, B);

  { Line 1: Day headers (adjusted for FirstDayOfWeek) }
  MoveChar(B, ' ', Byte(CNormal), Size.X);
  MoveStr(B[0], GetDayHeaderStr, CNormal);
  WriteLine(0, 1, Size.X, 1, B);

  { Lines 2-7: Calendar days }
  { Calculate which column the 1st of the month falls on }
  FirstDay := DayOfWeek(Year, Month, 1);
  { Adjust for FirstDayOfWeek }
  FirstDay := (FirstDay - FirstDayOfWeek + 7) mod 7;

  Days := DaysInMonth(Year, Month);
  D := 1;

  for Row := 0 to 5 do begin
    MoveChar(B, ' ', Byte(CNormal), Size.X);
    Y := Row + 2;

    for Col := 0 to 6 do begin
      if (Row = 0) and (Col < FirstDay) then
        Continue
      else if D > Days then
        Break
      else begin
        Str(D:2, S);

        { Determine color for this day }
        if D = Day then
          DayColor := CSelected
        else if UseDayColors then begin
          { Get actual day of week for this date }
          ActualDOW := DayOfWeek(Year, Month, D);
          DayColor := GetColor(DayColors[ActualDOW]);
        end else
          DayColor := CNormal;

        MoveStr(B[Col * 3], ShortString(S), DayColor);
        Inc(D);
      end;
    end;

    WriteLine(0, Y, Size.X, 1, B);
  end;
end;

procedure TCalendarView.ShowMonthMenu;
var
  R: TRect;
  Menu: PCalendarMenu;
  GX, GY: Integer;
  V: PView;
  MonthItems: array[0..11] of ShortString;
  I: Integer;
  Cmd: Word;
begin
  { Build month list }
  for I := 1 to 12 do
    MonthItems[I - 1] := MonthNames[I];

  { Calculate global position for menu }
  GX := Origin.X + 2;
  GY := Origin.Y + 1;
  V := Owner;
  while V <> nil do begin
    Inc(GX, V^.Origin.X);
    Inc(GY, V^.Origin.Y);
    V := V^.Owner;
  end;

  R.Assign(GX, GY, GX + 12, GY + 12);
  Menu := New(PCalendarMenu, Init(R, MonthItems));
  Menu^.Selected := Month - 1;

  if Desktop <> nil then begin
    Cmd := Desktop^.ExecView(Menu);
    if (Cmd <> cmCancel) and (Menu^.Selection >= 0) then begin
      Month := Menu^.Selection + 1;
      ClampDay;
      DrawView;
      SelectDate;
    end;
    Dispose(Menu, Done);
  end;
end;

procedure TCalendarView.ShowYearMenu;
var
  R: TRect;
  Menu: PCalendarMenu;
  GX, GY: Integer;
  V: PView;
  YearItems: array[0..9] of ShortString;
  I, StartYear, SelectedIdx: Integer;
  Cmd: Word;
begin
  { Show years around current year }
  StartYear := Year - 5;
  if StartYear < 1 then StartYear := 1;
  SelectedIdx := 5;

  for I := 0 to 9 do
    YearItems[I] := IntToStr(StartYear + I);

  { Calculate global position for menu }
  GX := Origin.X + 10;
  GY := Origin.Y + 1;
  V := Owner;
  while V <> nil do begin
    Inc(GX, V^.Origin.X);
    Inc(GY, V^.Origin.Y);
    V := V^.Owner;
  end;

  R.Assign(GX, GY, GX + 8, GY + 10);
  Menu := New(PCalendarMenu, Init(R, YearItems));
  Menu^.Selected := SelectedIdx;

  if Desktop <> nil then begin
    Cmd := Desktop^.ExecView(Menu);
    if (Cmd <> cmCancel) and (Menu^.Selection >= 0) then begin
      Year := StartYear + Menu^.Selection;
      ClampDay;
      DrawView;
      SelectDate;
    end;
    Dispose(Menu, Done);
  end;
end;

procedure TCalendarView.HandleEvent(var Event: TEvent);
var
  Mouse: TPoint;
  Row, Col, FirstDay, ClickedDay: Integer;
  MonthStr, YearStr, TitleStr: ShortString;
  MonthX, YearX, MonthEndX, YearEndX: Integer;
begin
  inherited HandleEvent(Event);

  case Event.What of
    evMouseDown: begin
      MakeLocal(Event.Where, Mouse);

      { Check for title row clicks (row 0) }
      if Mouse.Y = 0 then begin
        { Calculate positions }
        MonthStr := MonthNames[Month];
        YearStr := IntToStr(Year);
        TitleStr := MonthStr + ' ' + YearStr;
        Col := (Size.X - Length(TitleStr)) div 2;
        if Col < 2 then Col := 2;
        MonthX := Col;
        MonthEndX := MonthX + Length(MonthStr);
        YearX := MonthEndX + 1;
        YearEndX := YearX + Length(YearStr);

        { Left arrow clicked }
        if Mouse.X = 0 then begin
          PrevMonth;
          ClampDay;
          DrawView;
          SelectDate;
          ClearEvent(Event);
          Exit;
        end;

        { Right arrow clicked }
        if Mouse.X = Size.X - 1 then begin
          NextMonth;
          ClampDay;
          DrawView;
          SelectDate;
          ClearEvent(Event);
          Exit;
        end;

        { Month name clicked }
        if (Mouse.X >= MonthX) and (Mouse.X < MonthEndX) then begin
          ClearEvent(Event);
          ShowMonthMenu;
          Exit;
        end;

        { Year clicked }
        if (Mouse.X >= YearX) and (Mouse.X < YearEndX) then begin
          ClearEvent(Event);
          ShowYearMenu;
          Exit;
        end;

        ClearEvent(Event);
        Exit;
      end;

      { Check if click is in day area (rows 2-7) }
      if (Mouse.Y >= 2) and (Mouse.Y <= 7) then begin
        Row := Mouse.Y - 2;
        Col := Mouse.X div 3;
        if (Col >= 0) and (Col <= 6) then begin
          FirstDay := DayOfWeek(Year, Month, 1);
          { Adjust for FirstDayOfWeek }
          FirstDay := (FirstDay - FirstDayOfWeek + 7) mod 7;
          ClickedDay := Row * 7 + Col - FirstDay + 1;
          if (ClickedDay >= 1) and (ClickedDay <= DaysInMonth(Year, Month)) then begin
            Day := ClickedDay;
            DrawView;
            SelectDate;
          end;
        end;
      end;
      ClearEvent(Event);
    end;

    evKeyDown: begin
      case Event.KeyCode of
        kbLeft: begin
          if Day > 1 then Dec(Day)
          else begin
            PrevMonth;
            Day := DaysInMonth(Year, Month);
          end;
          DrawView;
          SelectDate;
          ClearEvent(Event);
        end;
        kbRight: begin
          if Day < DaysInMonth(Year, Month) then Inc(Day)
          else begin
            NextMonth;
            Day := 1;
          end;
          DrawView;
          SelectDate;
          ClearEvent(Event);
        end;
        kbUp: begin
          if Day > 7 then Dec(Day, 7)
          else begin
            PrevMonth;
            Day := DaysInMonth(Year, Month) - (7 - Day);
            if Day < 1 then Day := 1;
          end;
          DrawView;
          SelectDate;
          ClearEvent(Event);
        end;
        kbDown: begin
          if Day + 7 <= DaysInMonth(Year, Month) then Inc(Day, 7)
          else begin
            Col := Day + 7 - DaysInMonth(Year, Month);
            NextMonth;
            Day := Col;
            ClampDay;
          end;
          DrawView;
          SelectDate;
          ClearEvent(Event);
        end;
        kbPgUp: begin
          PrevMonth;
          ClampDay;
          DrawView;
          SelectDate;
          ClearEvent(Event);
        end;
        kbPgDn: begin
          NextMonth;
          ClampDay;
          DrawView;
          SelectDate;
          ClearEvent(Event);
        end;
        kbCtrlPgUp: begin
          PrevYear;
          ClampDay;
          DrawView;
          SelectDate;
          ClearEvent(Event);
        end;
        kbCtrlPgDn: begin
          NextYear;
          ClampDay;
          DrawView;
          SelectDate;
          ClearEvent(Event);
        end;
        kbEnter: begin
          SelectDate;
          ClearEvent(Event);
        end;
      end;
    end;
  end;
end;

procedure TCalendarView.SelectDate;
begin
  Message(Owner, evBroadcast, cmCalendarDateSelected, @Self);
  if Assigned(OnDateSelect) then
    OnDateSelect(@Self);
end;

function TCalendarView.GetDate(var AYear, AMonth, ADay: Word): Boolean;
begin
  AYear := Year;
  AMonth := Month;
  ADay := Day;
  Result := True;
end;

procedure TCalendarView.SetDate(AYear, AMonth, ADay: Word);
begin
  Year := AYear;
  Month := AMonth;
  Day := ADay;
  ClampDay;
  DrawView;
end;

procedure TCalendarView.NextMonth;
begin
  Inc(Month);
  if Month > 12 then begin
    Month := 1;
    Inc(Year);
  end;
end;

procedure TCalendarView.PrevMonth;
begin
  Dec(Month);
  if Month < 1 then begin
    Month := 12;
    Dec(Year);
  end;
end;

procedure TCalendarView.NextYear;
begin
  Inc(Year);
end;

procedure TCalendarView.PrevYear;
begin
  if Year > 1 then Dec(Year);
end;

end.
