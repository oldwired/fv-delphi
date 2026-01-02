{*******************************************************}
{       Free Vision - Color Selection Unit             }
{       Ported to Modern Delphi                        }
{*******************************************************}

{
  Color selection dialogs for customizing application palettes.
  Based on original Turbo Vision design.

  Ported to Delphi: January 2026
}

unit ColorSel;

{$I platform.inc}

interface

uses
  FVCommon, FVConsts, Objects, Drivers, Views, Dialogs;

const
  { Color selector palettes }
  CColorSelector = #6#6#6#6#6#6;
  CMonoSelector = #6#6#6#6#6#6;
  CColorDisplay = #6#6;
  CColorGroupList = #6#6#6#6#6;
  CColorItemList = #6#6#6#6#6;
  CColorDialog = #32#33#34#35#36#37#38#39#40#41#42#43#44#45#46#47 +
                 #48#49#50#51#52#53#54#55#56#57#58#59#60#61#62#63;

type
  { Forward declarations }
  PColorItem = ^TColorItem;
  PColorGroup = ^TColorGroup;
  PColorSelector = ^TColorSelector;
  PMonoSelector = ^TMonoSelector;
  PColorDisplay = ^TColorDisplay;
  PColorGroupList = ^TColorGroupList;
  PColorItemList = ^TColorItemList;
  PColorDialog = ^TColorDialog;

  { TColorItem - Record for individual color settings }
  TColorItem = record
    Name: Objects.PString;
    Index: Byte;
    Next: PColorItem;
  end;

  { TColorGroup - Record for groups of color settings }
  TColorGroup = record
    Name: Objects.PString;
    Index: Byte;
    Items: PColorItem;
    Next: PColorGroup;
  end;

  { TColorSelector - 16-color selector grid }
  TColorSelector = object(TView)
    Color: Byte;
    SelType: Byte;  { 0 = foreground, 1 = background }
    constructor Init(var Bounds: TRect; ASelType: Byte);
    constructor Load(var S: TStream);
    procedure Draw; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure Store(var S: TStream);
    procedure ColorChanged; virtual;
  private
    function GetPalette: PPalette; virtual;
  end;

  { TMonoSelector - Monochrome attribute selector }
  TMonoSelector = object(TView)
    Color: Byte;
    SelType: Byte;
    constructor Init(var Bounds: TRect; ASelType: Byte);
    constructor Load(var S: TStream);
    procedure Draw; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure Store(var S: TStream);
    procedure ColorChanged; virtual;
  private
    function GetPalette: PPalette; virtual;
  end;

  { TColorDisplay - Shows current color selection }
  TColorDisplay = object(TView)
    Color: PByte;
    Text: Objects.PString;
    constructor Init(var Bounds: TRect; const AText: ShortString);
    constructor Load(var S: TStream);
    destructor Done; virtual;
    procedure Draw; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetColor(AColor: PByte); virtual;
    procedure Store(var S: TStream);
  private
    function GetPalette: PPalette; virtual;
  end;

  { TColorGroupList - List of color groups }
  TColorGroupList = object(TListViewer)
    Groups: PColorGroup;
    constructor Init(var Bounds: TRect; AScrollBar: PScrollBar; AGroups: PColorGroup);
    constructor Load(var S: TStream);
    destructor Done; virtual;
    procedure FocusItem(Item: Integer); virtual;
    function GetText(Item: Integer; MaxLen: Integer): string; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure Store(var S: TStream);
  private
    function GetPalette: PPalette; virtual;
    function GetGroup(Item: Integer): PColorGroup;
    function GetNumGroups: Integer;
  end;

  { TColorItemList - List of items in selected group }
  TColorItemList = object(TListViewer)
    Items: PColorItem;
    constructor Init(var Bounds: TRect; AScrollBar: PScrollBar);
    constructor Load(var S: TStream);
    procedure FocusItem(Item: Integer); virtual;
    function GetText(Item: Integer; MaxLen: Integer): string; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetGroupItems(AItems: PColorItem);
    procedure Store(var S: TStream);
    function GetItem(Index: Integer): PColorItem;
  private
    function GetPalette: PPalette; virtual;
    function GetNumItems: Integer;
  end;

  { TColorDialog - Main color selection dialog }
  TColorDialog = object(TDialog)
    GroupList: PColorGroupList;
    ItemList: PColorItemList;
    ForeSel: PColorSelector;
    BackSel: PColorSelector;
    Display: PColorDisplay;
    Pal: TPalette;
    Groups: PColorGroup;
    constructor Init(APalette: TPalette; AGroups: PColorGroup);
    constructor Load(var S: TStream);
    destructor Done; virtual;
    function DataSize: Word; virtual;
    procedure GetData(var Rec); virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetData(var Rec); virtual;
    procedure Store(var S: TStream);
  private
    function GetPalette: PPalette; virtual;
    procedure SetupItems(AGroup: PColorGroup);
  end;

{ Helper functions to create color items and groups }
function ColorItem(const Name: ShortString; Index: Byte; Next: PColorItem): PColorItem;
function ColorGroup(const Name: ShortString; Items: PColorItem; Next: PColorGroup): PColorGroup;

{ Dispose functions }
procedure DisposeColorItem(Item: PColorItem);
procedure DisposeColorGroup(Group: PColorGroup);

{ Standard color item builders }
function DesktopColorItems(Next: PColorItem): PColorItem;
function MenuColorItems(Next: PColorItem): PColorItem;
function DialogColorItems(Palette: Word; Next: PColorItem): PColorItem;
function WindowColorItems(Palette: Word; Next: PColorItem): PColorItem;

{ Registration }
procedure RegisterColorSel;

{ Broadcast commands for color selection }
const
  cmColorForegroundChanged = 71;
  cmColorBackgroundChanged = 72;
  cmColorSet = 73;
  cmNewColorItem = 74;
  cmNewColorIndex = 75;
  cmSaveColorIndex = 76;

  { Selector types }
  csForeground = 0;
  csBackground = 1;

implementation

uses
  System.SysUtils;

{****************************************************************************}
{ Helper Functions                                                           }
{****************************************************************************}

function ColorItem(const Name: ShortString; Index: Byte; Next: PColorItem): PColorItem;
var
  Item: PColorItem;
begin
  New(Item);
  Item^.Name := Objects.NewStr(Name);
  Item^.Index := Index;
  Item^.Next := Next;
  Result := Item;
end;

function ColorGroup(const Name: ShortString; Items: PColorItem; Next: PColorGroup): PColorGroup;
var
  Group: PColorGroup;
begin
  New(Group);
  Group^.Name := Objects.NewStr(Name);
  Group^.Items := Items;
  Group^.Next := Next;
  Group^.Index := 0;
  Result := Group;
end;

procedure DisposeColorItem(Item: PColorItem);
var
  Next: PColorItem;
begin
  while Item <> nil do
  begin
    Next := Item^.Next;
    if Item^.Name <> nil then
      Objects.DisposeStr(Item^.Name);
    Dispose(Item);
    Item := Next;
  end;
end;

procedure DisposeColorGroup(Group: PColorGroup);
var
  Next: PColorGroup;
begin
  while Group <> nil do
  begin
    Next := Group^.Next;
    if Group^.Name <> nil then
      Objects.DisposeStr(Group^.Name);
    DisposeColorItem(Group^.Items);
    Dispose(Group);
    Group := Next;
  end;
end;

{ Standard color items for Desktop }
function DesktopColorItems(Next: PColorItem): PColorItem;
begin
  Result :=
    ColorItem('Color', 1, Next);
end;

{ Standard color items for Menus }
function MenuColorItems(Next: PColorItem): PColorItem;
begin
  Result :=
    ColorItem('Normal', 2,
    ColorItem('Disabled', 3,
    ColorItem('Shortcut', 4,
    ColorItem('Selected', 5,
    ColorItem('Selected disabled', 6,
    ColorItem('Shortcut selected', 7,
    Next))))));
end;

{ Standard color items for Dialogs }
function DialogColorItems(Palette: Word; Next: PColorItem): PColorItem;
var
  Offset: Byte;
begin
  Offset := Palette * 32;
  Result :=
    ColorItem('Frame/background', 32 + Offset,
    ColorItem('Frame icons', 33 + Offset,
    ColorItem('Scroll bar page', 34 + Offset,
    ColorItem('Scroll bar icons', 35 + Offset,
    ColorItem('Static text', 36 + Offset,
    ColorItem('Label normal', 37 + Offset,
    ColorItem('Label highlight', 38 + Offset,
    ColorItem('Label shortcut', 39 + Offset,
    ColorItem('Button normal', 40 + Offset,
    ColorItem('Button default', 41 + Offset,
    ColorItem('Button selected', 42 + Offset,
    ColorItem('Button disabled', 43 + Offset,
    ColorItem('Button shortcut', 44 + Offset,
    ColorItem('Button shadow', 45 + Offset,
    ColorItem('Cluster normal', 46 + Offset,
    ColorItem('Cluster selected', 47 + Offset,
    ColorItem('Cluster shortcut', 48 + Offset,
    ColorItem('Input normal', 49 + Offset,
    ColorItem('Input selected', 50 + Offset,
    ColorItem('Input arrow', 51 + Offset,
    ColorItem('History button', 52 + Offset,
    ColorItem('History sides', 53 + Offset,
    ColorItem('History bar page', 54 + Offset,
    ColorItem('History bar icons', 55 + Offset,
    ColorItem('List normal', 56 + Offset,
    ColorItem('List focused', 57 + Offset,
    ColorItem('List selected', 58 + Offset,
    ColorItem('List divider', 59 + Offset,
    ColorItem('Information pane', 60 + Offset,
    Next)))))))))))))))))))))))))))));
end;

{ Standard color items for Windows }
function WindowColorItems(Palette: Word; Next: PColorItem): PColorItem;
var
  Offset: Byte;
begin
  Offset := Palette * 8;
  Result :=
    ColorItem('Frame passive', 8 + Offset,
    ColorItem('Frame active', 9 + Offset,
    ColorItem('Frame icons', 10 + Offset,
    ColorItem('Scroll bar page', 11 + Offset,
    ColorItem('Scroll bar icons', 12 + Offset,
    ColorItem('Scroller normal', 13 + Offset,
    ColorItem('Scroller selected', 14 + Offset,
    ColorItem('Reserved', 15 + Offset,
    Next))))))));
end;

{****************************************************************************}
{ TColorSelector Object                                                      }
{****************************************************************************}

constructor TColorSelector.Init(var Bounds: TRect; ASelType: Byte);
begin
  inherited Init(Bounds);
  Options := Options or ofSelectable or ofFirstClick;
  EventMask := EventMask or evBroadcast;
  SelType := ASelType;
  Color := 0;
end;

constructor TColorSelector.Load(var S: TStream);
begin
  inherited Load(S);
  S.Read(Color, SizeOf(Color));
  S.Read(SelType, SizeOf(SelType));
end;

procedure TColorSelector.Store(var S: TStream);
begin
  inherited Store(S);
  S.Write(Color, SizeOf(Color));
  S.Write(SelType, SizeOf(SelType));
end;

function TColorSelector.GetPalette: PPalette;
const
  P: ShortString = CColorSelector;
begin
  Result := PPalette(@P);
end;

procedure TColorSelector.Draw;
const
  Icon: AnsiChar = #219;  { Full block character }
var
  B: TDrawBuffer;
  C, I, J: Integer;
begin
  MoveChar(B, ' ', $70, Size.X);
  for I := 0 to Size.Y - 1 do
  begin
    if I < 4 then
    begin
      for J := 0 to 3 do
      begin
        C := I * 4 + J;
        { Each color cell is 3 characters wide }
        MoveChar(B[J * 3], Icon, Byte(C), 3);
        if C = Color then
        begin
          { Mark selected color with character 8 (bullet) }
          WordRec(B[J * 3 + 1]).Lo := 8;
          if C = 0 then
            WordRec(B[J * 3 + 1]).Hi := $70;  { Visible marker on black }
        end;
      end;
    end;
    WriteLine(0, I, Size.X, 1, B);
  end;
end;

procedure TColorSelector.HandleEvent(var Event: TEvent);
const
  Width = 4;
var
  Mouse: TPoint;
  OldColor: Byte;
  MaxCol: Byte;
begin
  inherited HandleEvent(Event);

  OldColor := Color;
  if SelType = csBackground then
    MaxCol := 7
  else
    MaxCol := 15;

  case Event.What of
    evMouseDown:
    begin
      repeat
        if MouseInView(Event.Where) then
        begin
          MakeLocal(Event.Where, Mouse);
          Color := Mouse.Y * 4 + Mouse.X div 3;
          if Color > MaxCol then
            Color := MaxCol;
        end
        else
          Color := OldColor;
        ColorChanged;
        DrawView;
      until not MouseEvent(Event, evMouseMove);
      ClearEvent(Event);
    end;

    evKeyDown:
    begin
      case CtrlToArrow(Event.KeyCode) of
        kbLeft:
          if Color > 0 then Dec(Color) else Color := MaxCol;
        kbRight:
          if Color < MaxCol then Inc(Color) else Color := 0;
        kbUp:
          if Color > Width - 1 then
            Dec(Color, Width)
          else if Color = 0 then
            Color := MaxCol
          else
            Inc(Color, MaxCol - Width);
        kbDown:
          if Color < MaxCol - (Width - 1) then
            Inc(Color, Width)
          else if Color = MaxCol then
            Color := 0
          else
            Dec(Color, MaxCol - Width);
      else
        Exit;
      end;
      DrawView;
      ColorChanged;
      ClearEvent(Event);
    end;

    evBroadcast:
      case Event.Command of
        cmColorSet:
        begin
          if SelType = csBackground then
            Color := (PByte(Event.InfoPtr)^ shr 4) and $0F
          else
            Color := PByte(Event.InfoPtr)^ and $0F;
          DrawView;
          Exit;
        end;
      else
        Exit;
      end;
  end;
end;

procedure TColorSelector.ColorChanged;
begin
  if SelType = csBackground then
    Message(Owner, evBroadcast, cmColorBackgroundChanged, Pointer(NativeUInt(Color)))
  else
    Message(Owner, evBroadcast, cmColorForegroundChanged, Pointer(NativeUInt(Color)));
end;

{****************************************************************************}
{ TMonoSelector Object                                                       }
{****************************************************************************}

constructor TMonoSelector.Init(var Bounds: TRect; ASelType: Byte);
begin
  inherited Init(Bounds);
  Options := Options or ofSelectable or ofFirstClick;
  EventMask := EventMask or evBroadcast;
  SelType := ASelType;
  Color := 0;
end;

constructor TMonoSelector.Load(var S: TStream);
begin
  inherited Load(S);
  S.Read(Color, SizeOf(Color));
  S.Read(SelType, SizeOf(SelType));
end;

procedure TMonoSelector.Store(var S: TStream);
begin
  inherited Store(S);
  S.Write(Color, SizeOf(Color));
  S.Write(SelType, SizeOf(SelType));
end;

function TMonoSelector.GetPalette: PPalette;
const
  P: ShortString = CMonoSelector;
begin
  Result := PPalette(@P);
end;

procedure TMonoSelector.Draw;
const
  Button = ' ( ) ';
var
  B: TDrawBuffer;
  C, I: Integer;
  S: ShortString;
begin
  MoveChar(B, ' ', $07, Size.X);
  for I := 0 to 4 do
  begin
    if I < Size.Y then
    begin
      MoveChar(B, ' ', $07, Size.X);
      MoveStr(B[0], Button, $07);
      if I = Color then
        WordRec(B[2]).Lo := Byte(#7);  { Bullet marker }
      case I of
        0: S := 'Normal';
        1: S := 'Highlight';
        2: S := 'Underline';
        3: S := 'Inverse';
        4: S := 'Inv+High';
      else
        S := '';
      end;
      MoveStr(B[Length(Button)], S, $07);
      WriteLine(0, I, Size.X, 1, B);
    end;
  end;
end;

procedure TMonoSelector.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);

  case Event.What of
    evMouseDown:
    begin
      var Mouse: TPoint;
      MakeLocal(Event.Where, Mouse);
      if (Mouse.Y >= 0) and (Mouse.Y < 5) then
      begin
        Color := Mouse.Y;
        DrawView;
        ColorChanged;
      end;
      ClearEvent(Event);
    end;

    evKeyDown:
    begin
      case CtrlToArrow(Event.KeyCode) of
        kbUp:
          if Color > 0 then Dec(Color) else Color := 4;
        kbDown:
          if Color < 4 then Inc(Color) else Color := 0;
      else
        Exit;
      end;
      DrawView;
      ColorChanged;
      ClearEvent(Event);
    end;
  end;
end;

procedure TMonoSelector.ColorChanged;
begin
  if SelType = csBackground then
    Message(Owner, evBroadcast, cmColorBackgroundChanged, @Color)
  else
    Message(Owner, evBroadcast, cmColorForegroundChanged, @Color);
end;

{****************************************************************************}
{ TColorDisplay Object                                                       }
{****************************************************************************}

constructor TColorDisplay.Init(var Bounds: TRect; const AText: ShortString);
begin
  inherited Init(Bounds);
  EventMask := EventMask or evBroadcast;
  if AText <> '' then
    Text := Objects.NewStr(AText)
  else
    Text := Objects.NewStr('Text Text ');
  Color := nil;
end;

constructor TColorDisplay.Load(var S: TStream);
begin
  inherited Load(S);
  Text := S.ReadStr;
  Color := nil;
end;

destructor TColorDisplay.Done;
begin
  if Text <> nil then
    Objects.DisposeStr(Text);
  inherited Done;
end;

procedure TColorDisplay.Store(var S: TStream);
begin
  inherited Store(S);
  S.WriteStr(Text);
end;

function TColorDisplay.GetPalette: PPalette;
const
  P: ShortString = CColorDisplay;
begin
  Result := PPalette(@P);
end;

procedure TColorDisplay.Draw;
var
  B: TDrawBuffer;
  C: Byte;
  S: ShortString;
  I, Len: Integer;
begin
  if Color <> nil then
    C := Color^
  else
    C := $4E;  { Default: yellow on red (error indicator) }

  if C = 0 then
    C := $4E;  { Error attribute if color is 0 }

  if Text <> nil then
    S := Text^
  else
    S := 'Text';

  Len := Length(S);
  if Len = 0 then
  begin
    S := 'Text';
    Len := 4;
  end;

  { Fill buffer by repeating text pattern }
  for I := 0 to (Size.X div Len) do
    MoveStr(B[I * Len], S, C);

  WriteLine(0, 0, Size.X, Size.Y, B);
end;

procedure TColorDisplay.HandleEvent(var Event: TEvent);
var
  ColorValue: Byte;
begin
  inherited HandleEvent(Event);
  if Event.What = evBroadcast then
    case Event.Command of
      cmColorBackgroundChanged:
      begin
        if Color <> nil then
        begin
          ColorValue := Byte(NativeUInt(Event.InfoPtr));
          Color^ := (Color^ and $0F) or ((ColorValue shl 4) and $F0);
          DrawView;
        end;
      end;
      cmColorForegroundChanged:
      begin
        if Color <> nil then
        begin
          ColorValue := Byte(NativeUInt(Event.InfoPtr));
          Color^ := (Color^ and $F0) or (ColorValue and $0F);
          DrawView;
        end;
      end;
    end;
end;

procedure TColorDisplay.SetColor(AColor: PByte);
begin
  Color := AColor;
  if Color <> nil then
    Message(Owner, evBroadcast, cmColorSet, Pointer(NativeUInt(Color^)));
  DrawView;
end;

{****************************************************************************}
{ TColorGroupList Object                                                     }
{****************************************************************************}

constructor TColorGroupList.Init(var Bounds: TRect; AScrollBar: PScrollBar; AGroups: PColorGroup);
var
  G: PColorGroup;
  I: Integer;
begin
  inherited Init(Bounds, 1, nil, AScrollBar);
  Groups := AGroups;

  { Count groups and assign indices }
  I := 0;
  G := AGroups;
  while G <> nil do
  begin
    G^.Index := I;
    Inc(I);
    G := G^.Next;
  end;

  SetRange(I);
  if I > 0 then FocusItem(0);
end;

constructor TColorGroupList.Load(var S: TStream);
begin
  inherited Load(S);
  Groups := nil;
end;

destructor TColorGroupList.Done;
begin
  inherited Done;
end;

procedure TColorGroupList.Store(var S: TStream);
begin
  inherited Store(S);
end;

function TColorGroupList.GetPalette: PPalette;
const
  P: ShortString = CColorGroupList;
begin
  Result := PPalette(@P);
end;

function TColorGroupList.GetGroup(Item: Integer): PColorGroup;
var
  G: PColorGroup;
  I: Integer;
begin
  Result := nil;
  G := Groups;
  I := 0;
  while G <> nil do
  begin
    if I = Item then
    begin
      Result := G;
      Exit;
    end;
    Inc(I);
    G := G^.Next;
  end;
end;

function TColorGroupList.GetNumGroups: Integer;
var
  G: PColorGroup;
  Count: Integer;
begin
  Count := 0;
  G := Groups;
  while G <> nil do
  begin
    Inc(Count);
    G := G^.Next;
  end;
  Result := Count;
end;

function TColorGroupList.GetText(Item: Integer; MaxLen: Integer): string;
var
  G: PColorGroup;
begin
  G := GetGroup(Item);
  if (G <> nil) and (G^.Name <> nil) then
    Result := Copy(G^.Name^, 1, MaxLen)
  else
    Result := '';
end;

procedure TColorGroupList.FocusItem(Item: Integer);
var
  G: PColorGroup;
begin
  inherited FocusItem(Item);
  G := GetGroup(Item);
  if G <> nil then
    Message(Owner, evBroadcast, cmNewColorItem, G);
end;

procedure TColorGroupList.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);
  if Event.What = evBroadcast then
    if Event.Command = cmSaveColorIndex then
      Event.InfoPtr := Groups;
end;

{****************************************************************************}
{ TColorItemList Object                                                      }
{****************************************************************************}

constructor TColorItemList.Init(var Bounds: TRect; AScrollBar: PScrollBar);
begin
  inherited Init(Bounds, 1, nil, AScrollBar);
  Items := nil;
end;

constructor TColorItemList.Load(var S: TStream);
begin
  inherited Load(S);
  Items := nil;
end;

procedure TColorItemList.Store(var S: TStream);
begin
  inherited Store(S);
end;

function TColorItemList.GetPalette: PPalette;
const
  P: ShortString = CColorItemList;
begin
  Result := PPalette(@P);
end;

function TColorItemList.GetItem(Index: Integer): PColorItem;
var
  Item: PColorItem;
  I: Integer;
begin
  Result := nil;
  Item := Items;
  I := 0;
  while Item <> nil do
  begin
    if I = Index then
    begin
      Result := Item;
      Exit;
    end;
    Inc(I);
    Item := Item^.Next;
  end;
end;

function TColorItemList.GetNumItems: Integer;
var
  Item: PColorItem;
  Count: Integer;
begin
  Count := 0;
  Item := Items;
  while Item <> nil do
  begin
    Inc(Count);
    Item := Item^.Next;
  end;
  Result := Count;
end;

function TColorItemList.GetText(Item: Integer; MaxLen: Integer): string;
var
  P: PColorItem;
begin
  P := GetItem(Item);
  if (P <> nil) and (P^.Name <> nil) then
    Result := Copy(P^.Name^, 1, MaxLen)
  else
    Result := '';
end;

procedure TColorItemList.FocusItem(Item: Integer);
var
  P: PColorItem;
begin
  inherited FocusItem(Item);
  P := GetItem(Item);
  if P <> nil then
    Message(Owner, evBroadcast, cmNewColorIndex, @P^.Index);
end;

procedure TColorItemList.SetGroupItems(AItems: PColorItem);
begin
  Items := AItems;
  SetRange(GetNumItems);
  if Range > 0 then
    FocusItem(0);
  DrawView;  { Always redraw after changing items }
end;

procedure TColorItemList.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);

  case Event.What of
    evBroadcast:
      case Event.Command of
        cmNewColorItem:
          SetGroupItems(PColorGroup(Event.InfoPtr)^.Items);
      end;
  end;
end;

{****************************************************************************}
{ TColorDialog Object                                                        }
{****************************************************************************}

constructor TColorDialog.Init(APalette: TPalette; AGroups: PColorGroup);
var
  R: TRect;
  SB: PScrollBar;
begin
  R.Assign(0, 0, 61, 18);
  inherited Init(R, 'Colors');
  Options := Options or ofCentered;
  Pal := APalette;
  Groups := AGroups;

  { Group list - left side }
  R.Assign(3, 3, 18, 14);
  SB := StandardScrollBar(sbVertical + sbHandleKeyboard);
  GroupList := New(PColorGroupList, Init(R, SB, AGroups));
  Insert(GroupList);
  R.Assign(2, 2, 18, 3);
  Insert(New(PLabel, Init(R, '~G~roup', GroupList)));

  { Item list - middle }
  R.Assign(20, 3, 40, 14);
  SB := StandardScrollBar(sbVertical + sbHandleKeyboard);
  ItemList := New(PColorItemList, Init(R, SB));
  Insert(ItemList);
  R.Assign(19, 2, 40, 3);
  Insert(New(PLabel, Init(R, '~I~tem', ItemList)));

  { Foreground selector - 16 colors in 4x4 grid (12 wide = 4 colors * 3 chars) }
  R.Assign(45, 3, 57, 7);
  ForeSel := New(PColorSelector, Init(R, csForeground));
  Insert(ForeSel);
  R.Assign(45, 2, 57, 3);
  Insert(New(PStaticText, Init(R, 'Foreground')));

  { Background selector - 8 colors in 2x4 grid (12 wide = 4 colors * 3 chars) }
  R.Assign(45, 9, 57, 11);
  BackSel := New(PColorSelector, Init(R, csBackground));
  Insert(BackSel);
  R.Assign(45, 8, 57, 9);
  Insert(New(PStaticText, Init(R, 'Background')));

  { Color display preview }
  R.Assign(44, 12, 58, 14);
  Display := New(PColorDisplay, Init(R, 'Text Text '));
  Insert(Display);

  { Buttons }
  R.Assign(3, 15, 13, 17);
  Insert(New(PButton, Init(R, 'O~K~', cmOK, bfDefault)));
  R.Assign(15, 15, 27, 17);
  Insert(New(PButton, Init(R, 'Cancel', cmCancel, bfNormal)));

  { Initialize with first group }
  if AGroups <> nil then
    SetupItems(AGroups);
end;

constructor TColorDialog.Load(var S: TStream);
begin
  inherited Load(S);
  Pal := S.ReadStr^;
  Groups := nil;
end;

destructor TColorDialog.Done;
begin
  DisposeColorGroup(Groups);
  inherited Done;
end;

procedure TColorDialog.Store(var S: TStream);
var
  P: Objects.PString;
begin
  inherited Store(S);
  P := @Pal;
  S.WriteStr(P);
end;

function TColorDialog.GetPalette: PPalette;
const
  P: ShortString = CColorDialog;
begin
  Result := PPalette(@P);
end;

function TColorDialog.DataSize: Word;
begin
  Result := Length(Pal);
end;

procedure TColorDialog.GetData(var Rec);
begin
  Move(Pal[1], Rec, Length(Pal));
end;

procedure TColorDialog.SetData(var Rec);
begin
  Move(Rec, Pal[1], Length(Pal));
end;

procedure TColorDialog.SetupItems(AGroup: PColorGroup);
begin
  if AGroup <> nil then
    ItemList^.SetGroupItems(AGroup^.Items);
end;

procedure TColorDialog.HandleEvent(var Event: TEvent);
var
  C: Byte;
  Index: Byte;
  P: PColorItem;
begin
  { Handle cmNewColorItem BEFORE inherited - like C++ version }
  if (Event.What = evBroadcast) and (Event.Command = cmNewColorItem) then
    SetupItems(PColorGroup(Event.InfoPtr));

  inherited HandleEvent(Event);

  case Event.What of
    evBroadcast:
      case Event.Command of
        cmNewColorIndex:
        begin
          Index := PByte(Event.InfoPtr)^;
          if Index <= Length(Pal) then
          begin
            C := Byte(Pal[Index]);
            ForeSel^.Color := C and $0F;
            BackSel^.Color := (C shr 4) and $0F;
            ForeSel^.DrawView;
            BackSel^.DrawView;
            Display^.SetColor(@Pal[Index]);
          end;
        end;

        cmColorForegroundChanged:
        begin
          if ItemList^.Range > 0 then
          begin
            P := ItemList^.GetItem(ItemList^.Focused);
            if P <> nil then
            begin
              Index := P^.Index;
              if Index <= Length(Pal) then
              begin
                C := Byte(Pal[Index]);
                C := (C and $F0) or (Byte(NativeUInt(Event.InfoPtr)) and $0F);
                Pal[Index] := AnsiChar(C);
                Display^.DrawView;
              end;
            end;
          end;
        end;

        cmColorBackgroundChanged:
        begin
          if ItemList^.Range > 0 then
          begin
            P := ItemList^.GetItem(ItemList^.Focused);
            if P <> nil then
            begin
              Index := P^.Index;
              if Index <= Length(Pal) then
              begin
                C := Byte(Pal[Index]);
                C := (C and $0F) or ((Byte(NativeUInt(Event.InfoPtr)) and $0F) shl 4);
                Pal[Index] := AnsiChar(C);
                Display^.DrawView;
              end;
            end;
          end;
        end;
      end;
  end;
end;

{****************************************************************************}
{ Registration                                                               }
{****************************************************************************}

const
  RColorSelector: TStreamRec = (
    ObjType: idColorSelector;
    VmtLink: nil;
    Load: @TColorSelector.Load;
    Store: @TColorSelector.Store);

  RMonoSelector: TStreamRec = (
    ObjType: idMonoSelector;
    VmtLink: nil;
    Load: @TMonoSelector.Load;
    Store: @TMonoSelector.Store);

  RColorDisplay: TStreamRec = (
    ObjType: idColorDisplay;
    VmtLink: nil;
    Load: @TColorDisplay.Load;
    Store: @TColorDisplay.Store);

  RColorGroupList: TStreamRec = (
    ObjType: idColorGroupList;
    VmtLink: nil;
    Load: @TColorGroupList.Load;
    Store: @TColorGroupList.Store);

  RColorItemList: TStreamRec = (
    ObjType: idColorItemList;
    VmtLink: nil;
    Load: @TColorItemList.Load;
    Store: @TColorItemList.Store);

  RColorDialog: TStreamRec = (
    ObjType: idColorDialog;
    VmtLink: nil;
    Load: @TColorDialog.Load;
    Store: @TColorDialog.Store);

procedure RegisterColorSel;
begin
  RegisterType(RColorSelector);
  RegisterType(RMonoSelector);
  RegisterType(RColorDisplay);
  RegisterType(RColorGroupList);
  RegisterType(RColorItemList);
  RegisterType(RColorDialog);
end;

end.
