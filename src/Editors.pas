{*******************************************************}
{       Free Vision - Text Editor Unit                  }
{       Ported to Modern Delphi                         }
{*******************************************************}

{
  The main source editor components.
  Based on FPC Free Vision implementation.

  Ported to Delphi: January 2026
}

unit Editors;

{$I platform.inc}

{$X+,R-,Q-}

interface

uses
  Objects, Drivers, Views, Dialogs, FVCommon, FVConsts;

const
  { Length constants. }
  Tab_Stop_Length = 74;

  MaxLineLength  = 4096;
  MinBufLength   = $1000;
  MaxBufLength   = $7fffff00;
  NotFoundValue  = $ffffffff;
  LineInfoGrow   = 1024;
  MaxLines       = $7ffffff;

  { Editor constants for dialog boxes. }
  edOutOfMemory   = 0;
  edReadError     = 1;
  edWriteError    = 2;
  edCreateError   = 3;
  edSaveModify    = 4;
  edSaveUntitled  = 5;
  edSaveAs        = 6;
  edFind          = 7;
  edSearchFailed  = 8;
  edReplace       = 9;
  edReplacePrompt = 10;
  edJumpToLine         = 11;
  edPasteNotPossible   = 12;
  edReformatDocument   = 13;
  edReformatNotAllowed = 14;
  edReformNotPossible  = 15;
  edReplaceNotPossible = 16;
  edRightMargin        = 17;
  edSetTabStops        = 18;
  edWrapNotPossible    = 19;

  { Editor flag constants for dialog options. }
  efCaseSensitive   = $0001;
  efWholeWordsOnly  = $0002;
  efPromptOnReplace = $0004;
  efReplaceAll      = $0008;
  efDoReplace       = $0010;
  efBackupFiles     = $0100;

  { Constants for object palettes. }
  CIndicator = #2#3;
  CEditor    = #6#7;
  CMemo      = #26#27;

type
  PPoint = ^TPoint;  { Pointer to TPoint }

  TEditorDialog = function(Dialog: SmallInt; Info: Pointer): Word;

  PIndicator = ^TIndicator;
  TIndicator = object(TView)
    Location   : TPoint;
    Modified   : Boolean;
    AutoIndent : Boolean;
    WordWrap   : Boolean;
    constructor Init(var Bounds: TRect);
    procedure   Draw; virtual;
    function    GetPalette: PPalette; virtual;
    procedure   SetState(AState: Word; Enable: Boolean); virtual;
    procedure   SetValue(ALocation: TPoint; IsAutoIndent: Boolean;
                         IsModified: Boolean; IsWordWrap: Boolean);
  end;

  TLineInfoRec = record
    Len, Attr: Sw_Word;
  end;
  TLineInfoArr = array[0..MaxLines] of TLineInfoRec;
  PLineInfoArr = ^TLineInfoArr;

  PLineInfo = ^TLineInfo;
  TLineInfo = object
    Info: PLineInfoArr;
    MaxPos: Sw_Word;
    constructor Init;
    destructor Done;
    procedure Grow(Pos: Sw_Word);
    procedure SetLen(Pos, Val: Sw_Word);
    procedure SetAttr(Pos, Val: Sw_Word);
    function  GetLen(Pos: Sw_Word): Sw_Word;
    function  GetAttr(Pos: Sw_Word): Sw_Word;
  end;

  PEditBuffer = ^TEditBuffer;
  TEditBuffer = array[0..MaxBufLength] of AnsiChar;

  PEditor = ^TEditor;
  TEditor = object(TView)
    HScrollBar         : PScrollBar;
    VScrollBar         : PScrollBar;
    Indicator          : PIndicator;
    Buffer             : PEditBuffer;
    BufSize            : Sw_Word;
    BufLen             : Sw_Word;
    GapLen             : Sw_Word;
    SelStart           : Sw_Word;
    SelEnd             : Sw_Word;
    CurPtr             : Sw_Word;
    CurPos             : TPoint;
    Delta              : TPoint;
    Limit              : TPoint;
    DrawLine           : Sw_Integer;
    DrawPtr            : Sw_Word;
    DelCount           : Sw_Word;
    InsCount           : Sw_Word;
    Flags              : LongInt;
    IsReadOnly         : Boolean;
    IsValid            : Boolean;
    CanUndo            : Boolean;
    Modified           : Boolean;
    Selecting          : Boolean;
    Overwrite          : Boolean;
    AutoIndent         : Boolean;
    NoSelect           : Boolean;
    TabSize            : Sw_Word;
    BlankLine          : Sw_Word;
    Word_Wrap          : Boolean;
    Line_Number        : String[8];
    Right_Margin       : Sw_Integer;
    Tab_Settings       : String[Tab_Stop_Length];

    constructor Init(var Bounds: TRect; AHScrollBar, AVScrollBar: PScrollBar;
                     AIndicator: PIndicator; ABufSize: Sw_Word);
    destructor Done; virtual;
    function   BufChar(P: Sw_Word): AnsiChar;
    function   BufPtr(P: Sw_Word): Sw_Word;
    procedure  ChangeBounds(var Bounds: TRect); virtual;
    procedure  ConvertEvent(var Event: TEvent); virtual;
    function   CursorVisible: Boolean;
    procedure  DeleteSelect;
    procedure  DoneBuffer; virtual;
    procedure  Draw; virtual;
    procedure  FormatLine(var DrawBuf; LinePtr: Sw_Word; Width: Sw_Integer; Colors: Word); virtual;
    function   GetPalette: PPalette; virtual;
    procedure  HandleEvent(var Event: TEvent); virtual;
    procedure  InitBuffer; virtual;
    function   InsertBuffer(var P: PEditBuffer; Offset, Length: Sw_Word;
                            AllowUndo, SelectText: Boolean): Boolean;
    function   InsertFrom(Editor: PEditor): Boolean; virtual;
    function   InsertText(Text: Pointer; Length: Sw_Word; SelectText: Boolean): Boolean;
    procedure  ScrollTo(X, Y: Sw_Integer);
    function   Search(const FindStr: String; Opts: Word): Boolean;
    function   SetBufSize(NewSize: Sw_Word): Boolean; virtual;
    procedure  SetCmdState(Command: Word; Enable: Boolean);
    procedure  SetSelect(NewStart, NewEnd: Sw_Word; CurStart: Boolean);
    procedure  SetCurPtr(P: Sw_Word; SelectMode: Byte);
    procedure  SetState(AState: Word; Enable: Boolean); virtual;
    procedure  TrackCursor(Center: Boolean);
    procedure  Undo;
    procedure  UpdateCommands; virtual;
    function   Valid(Command: Word): Boolean; virtual;

  private
    KeyState       : SmallInt;
    LockCount      : Byte;
    UpdateFlags    : Byte;
    Place_Marker   : array[1..10] of Sw_Word;
    Search_Replace : Boolean;

    procedure  Center_Text(Select_Mode: Byte);
    function   CharPos(P, Target: Sw_Word): Sw_Integer;
    function   CharPtr(P: Sw_Word; Target: Sw_Integer): Sw_Word;
    procedure  Check_For_Word_Wrap(Select_Mode: Byte; Center_Cursor: Boolean);
    function   ClipCopy: Boolean;
    procedure  ClipCut;
    procedure  ClipPaste;
    procedure  DeleteRange(StartPtr, EndPtr: Sw_Word; DelSelect: Boolean);
    procedure  DoSearchReplace;
    procedure  DoUpdate;
    function   Do_Word_Wrap(Select_Mode: Byte; Center_Cursor: Boolean): Boolean;
    procedure  DrawLines(Y, Count: Sw_Integer; LinePtr: Sw_Word);
    procedure  Find;
    function   GetMousePtr(Mouse: TPoint): Sw_Word;
    function   HasSelection: Boolean;
    procedure  HideSelect;
    procedure  Insert_Line(Select_Mode: Byte);
    function   IsClipboard: Boolean;
    procedure  Jump_Place_Marker(Element: Byte; Select_Mode: Byte);
    procedure  Jump_To_Line(Select_Mode: Byte);
    function   LineEnd(P: Sw_Word): Sw_Word;
    function   LineMove(P: Sw_Word; Count: Sw_Integer): Sw_Word;
    function   LineStart(P: Sw_Word): Sw_Word;
    function   LineNr(P: Sw_Word): Sw_Word;
    procedure  Lock;
    function   NewLine(Select_Mode: Byte): Boolean;
    function   NextChar(P: Sw_Word): Sw_Word;
    function   NextLine(P: Sw_Word): Sw_Word;
    function   NextWord(P: Sw_Word): Sw_Word;
    function   PrevChar(P: Sw_Word): Sw_Word;
    function   PrevLine(P: Sw_Word): Sw_Word;
    function   PrevWord(P: Sw_Word): Sw_Word;
    procedure  Reformat_Document(Select_Mode: Byte; Center_Cursor: Boolean);
    function   Reformat_Paragraph(Select_Mode: Byte; Center_Cursor: Boolean): Boolean;
    procedure  Remove_EOL_Spaces(Select_Mode: Byte);
    procedure  Replace;
    procedure  Scroll_Down;
    procedure  Scroll_Up;
    procedure  Select_Word;
    procedure  SetBufLen(Length: Sw_Word);
    procedure  Set_Place_Marker(Element: Byte);
    procedure  Set_Right_Margin;
    procedure  Set_Tabs;
    procedure  StartSelect;
    procedure  Tab_Key(Select_Mode: Byte);
    procedure  ToggleInsMode;
    procedure  Unlock;
    procedure  Update(AFlags: Byte);
    procedure  Update_Place_Markers(AddCount: Word; KillCount: Word; StartPtr, EndPtr: Sw_Word);
  end;

  TMemoData = record
    Length: Sw_Word;
    Buffer: TEditBuffer;
  end;

  PMemo = ^TMemo;
  TMemo = object(TEditor)
    function    DataSize: Word; virtual;
    procedure   GetData(var Rec); virtual;
    function    GetPalette: PPalette; virtual;
    procedure   HandleEvent(var Event: TEvent); virtual;
    procedure   SetData(var Rec); virtual;
  end;

  PFileEditor = ^TFileEditor;
  TFileEditor = object(TEditor)
    FileName: FNameStr;
    constructor Init(var Bounds: TRect; AHScrollBar, AVScrollBar: PScrollBar;
                     AIndicator: PIndicator; AFileName: FNameStr);
    procedure   DoneBuffer; virtual;
    procedure   HandleEvent(var Event: TEvent); virtual;
    procedure   InitBuffer; virtual;
    function    LoadFile: Boolean;
    function    Save: Boolean;
    function    SaveAs: Boolean;
    function    SaveFile: Boolean;
    function    SetBufSize(NewSize: Sw_Word): Boolean; virtual;
    procedure   UpdateCommands; virtual;
    function    Valid(Command: Word): Boolean; virtual;
  end;

  PEditWindow = ^TEditWindow;
  TEditWindow = object(TWindow)
    Editor: PFileEditor;
    constructor Init(var Bounds: TRect; FileName: FNameStr; ANumber: SmallInt);
    procedure   Close; virtual;
    function    GetTitle(MaxSize: Sw_Integer): TTitleStr; virtual;
    procedure   HandleEvent(var Event: TEvent); virtual;
    procedure   SizeLimits(var Min, Max: TPoint); virtual;
  end;

function DefEditorDialog(Dialog: SmallInt; Info: Pointer): Word;
function CreateFindDialog: PDialog;
function CreateReplaceDialog: PDialog;
function JumpLineDialog: PDialog;
function ReformDocDialog: PDialog;
function RightMarginDialog: PDialog;
function TabStopDialog: PDialog;
function StdEditorDialog(Dialog: SmallInt; Info: Pointer): Word;

const
  WordChars: set of AnsiChar = ['!'..#255];

  LineBreak: String[2] = #13#10;

  Allow_Reformat: Boolean = True;

  EditorDialog: TEditorDialog = DefEditorDialog;
  EditorFlags: Word = efBackupFiles + efPromptOnReplace;
  FindStr: String[80] = '';
  ReplaceStr: String[80] = '';
  Clipboard: PEditor = nil;

type
  TEditorDebugLog = procedure(const Msg: string);

var
  EditorDebugLog: TEditorDebugLog = nil;

  ToClipCmds: TCommandSet = ([cmCut, cmCopy, cmClear]);
  FromClipCmds: TCommandSet = ([cmPaste]);
  UndoCmds: TCommandSet = ([cmUndo, cmRedo]);

type
  TFindDialogRec = packed record
    Find: String[80];
    Options: Word;
  end;

  TReplaceDialogRec = packed record
    Find: String[80];
    Replace: String[80];
    Options: Word;
  end;

  TRightMarginRec = packed record
    Margin_Position: String[3];
  end;

  TTabStopRec = packed record
    Tab_String: String[Tab_Stop_Length];
  end;

{ String constants (replacing FPC resourcestrings) }
const
  sClipboard = 'Clipboard';
  sFileCreateError = 'Error creating file %s';
  sFileReadError = 'Error reading file %s';
  sFileUntitled = 'Save untitled file?';
  sFileWriteError = 'Error writing to file %s';
  sFind = 'Find';
  sJumpTo = 'Jump To';
  sModified = #3'%s'#13#10#13#3'has been modified.  Save?';
  sOutOfMemory = 'Not enough memory for this operation.';
  sPasteNotPossible = 'Wordwrap on:  Paste not possible in current margins when at end of line.';
  sReformatDocument = 'Reformat Document';
  sReformatNotPossible = 'Paragraph reformat not possible while trying to wrap current line with current margins.';
  sReformattingTheDocument = 'Reformatting the document:';
  sReplaceNotPossible = 'Wordwrap on:  Replace not possible in current margins when at end of line.';
  sReplaceThisOccurence = 'Replace this occurrence?';
  sRightMargin = 'Right Margin';
  sSearchStringNotFound = 'Search string not found.';
  sSelectWhereToBegin = 'Please select where to begin.';
  sSetting = 'Setting:';
  sTabSettings = 'Tab Settings';
  sUnknownDialog = 'Unknown dialog requested!';
  sUntitled = 'Untitled';
  sWordWrapNotPossible = 'Wordwrap on:  Wordwrap not possible in current margins with continuous line.';
  sWordWrapOff = 'You must turn on wordwrap before you can reformat.';

  slCaseSensitive = '~C~ase sensitive';
  slCurrentLine = '~C~urrent line';
  slEntireDocument = '~E~ntire document';
  slLineNumber = '~L~ine number';
  slName = '~N~ame';
  slNewText = '~N~ew text';
  slOK = 'O~K~';
  slCancel = 'Cancel';
  slPromptOnReplace = '~P~rompt on replace';
  slReplace = '~R~eplace';
  slReplaceAll = '~R~eplace all';
  slSaveFileAs = 'Save File As';
  slTextToFind = '~T~ext to find';
  slWholeWordsOnly = '~W~hole words only';

implementation

uses
  SysUtils, App, StdDlg, MsgBox;

const
  { Update flag constants. }
  ufUpdate = $01;
  ufLine   = $02;
  ufView   = $04;
  ufStats  = $05;

  { SelectMode constants. }
  smExtend = $01;
  smDouble = $02;

  sfSearchFailed = NotFoundValue;

  { Arrays that hold all the command keys and options. }
  FirstKeys: array[0..46 * 2] of Word = (46,
    Ord(^A), cmWordLeft,
    Ord(^B), cmReformPara,
    Ord(^C), cmPageDown,
    Ord(^D), cmCharRight,
    Ord(^E), cmLineUp,
    Ord(^F), cmWordRight,
    Ord(^G), cmDelChar,
    Ord(^H), cmBackSpace,
    Ord(^J), $FF04,
    Ord(^K), $FF02,
    Ord(^L), cmSearchAgain,
    Ord(^M), cmNewLine,
    Ord(^N), cmInsertLine,
    Ord(^O), $FF03,
    Ord(^Q), $FF01,
    Ord(^R), cmPageUp,
    Ord(^S), cmCharLeft,
    Ord(^T), cmDelWord,
    Ord(^U), cmUndo,
    Ord(^V), cmInsMode,
    Ord(^X), cmLineDown,
    Ord(^Y), cmDelLine,
    kbLeft, cmCharLeft,
    kbRight, cmCharRight,
    kbCtrlLeft, cmWordLeft,
    kbCtrlRight, cmWordRight,
    kbHome, cmLineStart,
    kbEnd, cmLineEnd,
    kbUp, cmLineUp,
    kbDown, cmLineDown,
    kbPgUp, cmPageUp,
    kbPgDn, cmPageDown,
    kbCtrlPgUp, cmTextStart,
    kbCtrlPgDn, cmTextEnd,
    kbIns, cmInsMode,
    kbDel, cmDelChar,
    kbShiftIns, cmPaste,
    kbShiftDel, cmCut,
    kbCtrlIns, cmCopy,
    kbCtrlDel, cmClear,
    kbCtrlBack, cmDelStart,
    kbCtrlEnter, cmNewLine,
    kbCtrlEnd, cmDelEnd,
    kbCtrlHome, cmDelStart,
    kbBack, cmBackSpace,
    kbTab, cmTabKey);

  QuickKeys: array[0..9 * 2] of Word = (9,
    Ord('A'), cmReplace,
    Ord('C'), cmTextEnd,
    Ord('D'), cmLineEnd,
    Ord('F'), cmFind,
    Ord('H'), cmDelStart,
    Ord('R'), cmTextStart,
    Ord('S'), cmLineStart,
    Ord('Y'), cmDelEnd,
    Ord('G'), cmJumpMark0);

  BlockKeys: array[0..20 * 2] of Word = (20,
    Ord('B'), cmStartSelect,
    Ord('C'), cmPaste,
    Ord('D'), cmSaveDone,
    Ord('F'), cmSaveAs,
    Ord('H'), cmHideSelect,
    Ord('K'), cmEndSelect,
    Ord('S'), cmSave,
    Ord('T'), cmSelectWord,
    Ord('X'), cmSave,
    Ord('Y'), cmCut,
    Ord('0'), cmSetMark0,
    Ord('1'), cmSetMark1,
    Ord('2'), cmSetMark2,
    Ord('3'), cmSetMark3,
    Ord('4'), cmSetMark4,
    Ord('5'), cmSetMark5,
    Ord('6'), cmSetMark6,
    Ord('7'), cmSetMark7,
    Ord('8'), cmSetMark8,
    Ord('9'), cmSetMark9);

  FormatKeys: array[0..5 * 2] of Word = (5,
    Ord('C'), cmCenterText,
    Ord('T'), cmCenterText,
    Ord('I'), cmSetTabs,
    Ord('R'), cmRightMargin,
    Ord('W'), cmWordWrap);

  JumpKeys: array[0..1 * 2] of Word = (1,
    Ord('L'), cmJumpLine);

  KeyMap: array[0..4] of Pointer = (@FirstKeys, @QuickKeys, @BlockKeys, @FormatKeys, @JumpKeys);

{****************************************************************************
                                 Dialogs
****************************************************************************}

function DefEditorDialog(Dialog: SmallInt; Info: Pointer): Word;
begin
  Result := cmCancel;
end;

function CreateFindDialog: PDialog;
var
  D: PDialog;
  Control: PView;
  R: TRect;
begin
  R.Assign(0, 0, 38, 12);
  D := New(PDialog, Init(R, sFind));
  with D^ do
  begin
    Options := Options or ofCentered;

    R.Assign(3, 3, 32, 4);
    Control := New(PInputLine, Init(R, 80));
    Control^.HelpCtx := hcDFindText;
    Insert(Control);
    R.Assign(2, 2, 15, 3);
    Insert(New(PLabel, Init(R, slTextToFind, Control)));
    R.Assign(32, 3, 35, 4);
    Insert(New(PHistory, Init(R, PInputLine(Control), 10)));

    R.Assign(3, 5, 35, 7);
    Control := New(PCheckBoxes, Init(R,
      NewSItem(slCaseSensitive,
      NewSItem(slWholeWordsOnly, nil))));
    Control^.HelpCtx := hcCCaseSensitive;
    Insert(Control);

    R.Assign(14, 9, 24, 11);
    Control := New(PButton, Init(R, slOK, cmOk, bfDefault));
    Control^.HelpCtx := hcDOk;
    Insert(Control);

    Inc(R.A.X, 12);
    Inc(R.B.X, 12);
    Control := New(PButton, Init(R, slCancel, cmCancel, bfNormal));
    Control^.HelpCtx := hcDCancel;
    Insert(Control);

    SelectNext(False);
  end;
  Result := D;
end;

function CreateReplaceDialog: PDialog;
var
  D: PDialog;
  Control: PView;
  R: TRect;
begin
  R.Assign(0, 0, 40, 16);
  D := New(PDialog, Init(R, slReplace));
  with D^ do
  begin
    Options := Options or ofCentered;

    R.Assign(3, 3, 34, 4);
    Control := New(PInputLine, Init(R, 80));
    Control^.HelpCtx := hcDFindText;
    Insert(Control);
    R.Assign(2, 2, 15, 3);
    Insert(New(PLabel, Init(R, slTextToFind, Control)));
    R.Assign(34, 3, 37, 4);
    Insert(New(PHistory, Init(R, PInputLine(Control), 10)));

    R.Assign(3, 6, 34, 7);
    Control := New(PInputLine, Init(R, 80));
    Control^.HelpCtx := hcDReplaceText;
    Insert(Control);
    R.Assign(2, 5, 12, 6);
    Insert(New(PLabel, Init(R, slNewText, Control)));
    R.Assign(34, 6, 37, 7);
    Insert(New(PHistory, Init(R, PInputLine(Control), 11)));

    R.Assign(3, 8, 37, 12);
    Control := New(PCheckBoxes, Init(R,
      NewSItem(slCaseSensitive,
      NewSItem(slWholeWordsOnly,
      NewSItem(slPromptOnReplace,
      NewSItem(slReplaceAll, nil))))));
    Control^.HelpCtx := hcCCaseSensitive;
    Insert(Control);

    R.Assign(8, 13, 18, 15);
    Control := New(PButton, Init(R, slOK, cmOk, bfDefault));
    Control^.HelpCtx := hcDOk;
    Insert(Control);

    R.Assign(22, 13, 32, 15);
    Control := New(PButton, Init(R, slCancel, cmCancel, bfNormal));
    Control^.HelpCtx := hcDCancel;
    Insert(Control);

    SelectNext(False);
  end;
  Result := D;
end;

function JumpLineDialog: PDialog;
var
  D: PDialog;
  R: TRect;
  Control: PView;
begin
  R.Assign(0, 0, 26, 8);
  D := New(PDialog, Init(R, sJumpTo));
  with D^ do
  begin
    Options := Options or ofCentered;

    R.Assign(3, 2, 15, 3);
    Control := New(PStaticText, Init(R, slLineNumber));
    Insert(Control);

    R.Assign(15, 2, 21, 3);
    Control := New(PInputLine, Init(R, 4));
    Control^.HelpCtx := hcDLineNumber;
    Insert(Control);

    R.Assign(21, 2, 24, 3);
    Insert(New(PHistory, Init(R, PInputLine(Control), 12)));

    R.Assign(2, 5, 12, 7);
    Control := New(PButton, Init(R, slOK, cmOK, bfDefault));
    Control^.HelpCtx := hcDOk;
    Insert(Control);

    R.Assign(14, 5, 24, 7);
    Control := New(PButton, Init(R, slCancel, cmCancel, bfNormal));
    Control^.HelpCtx := hcDCancel;
    Insert(Control);

    SelectNext(False);
  end;
  Result := D;
end;

function ReformDocDialog: PDialog;
var
  R: TRect;
  D: PDialog;
  Control: PView;
begin
  R.Assign(0, 0, 32, 11);
  D := New(PDialog, Init(R, sReformatDocument));
  with D^ do
  begin
    Options := Options or ofCentered;

    R.Assign(2, 2, 30, 3);
    Control := New(PStaticText, Init(R, sSelectWhereToBegin));
    Insert(Control);

    R.Assign(3, 3, 29, 6);
    Control := New(PRadioButtons, Init(R,
      NewSItem(slCurrentLine,
      NewSItem(slEntireDocument, nil))));
    Insert(Control);

    R.Assign(4, 8, 14, 10);
    Control := New(PButton, Init(R, slOK, cmOK, bfDefault));
    Control^.HelpCtx := hcDOk;
    Insert(Control);

    R.Assign(18, 8, 28, 10);
    Control := New(PButton, Init(R, slCancel, cmCancel, bfNormal));
    Control^.HelpCtx := hcDCancel;
    Insert(Control);

    SelectNext(False);
  end;
  Result := D;
end;

function RightMarginDialog: PDialog;
var
  R: TRect;
  D: PDialog;
  Control: PView;
begin
  R.Assign(0, 0, 30, 8);
  D := New(PDialog, Init(R, sRightMargin));
  with D^ do
  begin
    Options := Options or ofCentered;

    R.Assign(3, 2, 12, 3);
    Control := New(PStaticText, Init(R, sSetting));
    Insert(Control);

    R.Assign(14, 2, 20, 3);
    Control := New(PInputLine, Init(R, 3));
    Control^.HelpCtx := hcDRightMargin;
    Insert(Control);

    R.Assign(20, 2, 23, 3);
    Insert(New(PHistory, Init(R, PInputLine(Control), 13)));

    R.Assign(4, 5, 14, 7);
    Control := New(PButton, Init(R, slOK, cmOK, bfDefault));
    Control^.HelpCtx := hcDOk;
    Insert(Control);

    R.Assign(16, 5, 26, 7);
    Control := New(PButton, Init(R, slCancel, cmCancel, bfNormal));
    Control^.HelpCtx := hcDCancel;
    Insert(Control);

    SelectNext(False);
  end;
  Result := D;
end;

function TabStopDialog: PDialog;
var
  R: TRect;
  D: PDialog;
  Control: PView;
begin
  R.Assign(0, 0, 80, 8);
  D := New(PDialog, Init(R, sTabSettings));
  with D^ do
  begin
    Options := Options or ofCentered;

    R.Assign(2, 2, 78, 3);
    Control := New(PStaticText, Init(R,
      '....+....1....+....2....+....3....+....4....+....5....+....6....+....7....'));
    Insert(Control);

    R.Assign(2, 3, 78, 4);
    Control := New(PInputLine, Init(R, 74));
    Control^.HelpCtx := hcDTabStops;
    Insert(Control);

    R.Assign(38, 5, 41, 6);
    Insert(New(PHistory, Init(R, PInputLine(Control), 14)));

    R.Assign(27, 5, 37, 7);
    Control := New(PButton, Init(R, slOK, cmOK, bfDefault));
    Control^.HelpCtx := hcDOk;
    Insert(Control);

    R.Assign(42, 5, 52, 7);
    Control := New(PButton, Init(R, slCancel, cmCancel, bfNormal));
    Control^.HelpCtx := hcDCancel;
    Insert(Control);

    SelectNext(False);
  end;
  Result := D;
end;

function GetFileNameFromInfo(Info: Pointer): string;
type
  PFNameStr = ^FNameStr;  { Pointer to string (UnicodeString), not ShortString }
begin
  Result := '(unknown)';
  if Info = nil then
    Exit;
  try
    Result := PFNameStr(Info)^;
  except
    Result := '(error reading filename)';
  end;
end;

function StdEditorDialog(Dialog: SmallInt; Info: Pointer): Word;
var
  R: TRect;
  T: TPoint;
  FormattedMsg: string;
begin
  case Dialog of
    edOutOfMemory:
      Result := MessageBox(sOutOfMemory, nil, mfError + mfOkButton);
    edReadError:
      begin
        FormattedMsg := Format('Error reading file: %s', [GetFileNameFromInfo(Info)]);
        Result := MessageBox(ShortString(FormattedMsg), nil, mfError + mfOkButton);
      end;
    edWriteError:
      begin
        FormattedMsg := Format('Error writing file: %s', [GetFileNameFromInfo(Info)]);
        Result := MessageBox(ShortString(FormattedMsg), nil, mfError + mfOkButton);
      end;
    edCreateError:
      begin
        FormattedMsg := Format('Error creating file: %s', [GetFileNameFromInfo(Info)]);
        Result := MessageBox(ShortString(FormattedMsg), nil, mfError + mfOkButton);
      end;
    edSaveModify:
      begin
        FormattedMsg := Format('%s has been modified. Save?', [GetFileNameFromInfo(Info)]);
        Result := MessageBox(ShortString(FormattedMsg), nil, mfInformation + mfYesNoCancel);
      end;
    edSaveUntitled:
      Result := MessageBox(sFileUntitled, nil, mfInformation + mfYesNoCancel);
    edSaveAs:
      Result := Application^.ExecuteDialog(New(PFileDialog, Init('*.*',
        slSaveFileAs, slName, fdOkButton, 101)), Info);
    edFind:
      Result := Application^.ExecuteDialog(CreateFindDialog, Info);
    edSearchFailed:
      Result := MessageBox(sSearchStringNotFound, nil, mfError + mfOkButton);
    edReplace:
      Result := Application^.ExecuteDialog(CreateReplaceDialog, Info);
    edReplacePrompt:
      begin
        R.Assign(0, 1, 40, 8);
        R.Move((Desktop^.Size.X - R.B.X) div 2, 0);
        Desktop^.MakeGlobal(R.B, T);
        Inc(T.Y);
        if PPoint(Info)^.Y <= T.Y then
          R.Move(0, Desktop^.Size.Y - R.B.Y - 2);
        Result := MessageBoxRect(R, sReplaceThisOccurence,
          nil, mfYesNoCancel + mfInformation);
      end;
    edJumpToLine:
      Result := Application^.ExecuteDialog(JumpLineDialog, Info);
    edSetTabStops:
      Result := Application^.ExecuteDialog(TabStopDialog, Info);
    edPasteNotPossible:
      Result := MessageBox(sPasteNotPossible, nil, mfError + mfOkButton);
    edReformatDocument:
      Result := Application^.ExecuteDialog(ReformDocDialog, Info);
    edReformatNotAllowed:
      Result := MessageBox(sWordWrapOff, nil, mfError + mfOkButton);
    edReformNotPossible:
      Result := MessageBox(sReformatNotPossible, nil, mfError + mfOkButton);
    edReplaceNotPossible:
      Result := MessageBox(sReplaceNotPossible, nil, mfError + mfOkButton);
    edRightMargin:
      Result := Application^.ExecuteDialog(RightMarginDialog, Info);
    edWrapNotPossible:
      Result := MessageBox(sWordWrapNotPossible, nil, mfError + mfOKButton);
  else
    Result := MessageBox(sUnknownDialog, nil, mfError + mfOkButton);
  end;
end;

{****************************************************************************
                                 Helpers
****************************************************************************}

function CountLines(var Buf; Count: Sw_Word): Sw_Integer;
var
  P: PAnsiChar;
  Lines: Sw_Word;
begin
  P := PAnsiChar(@Buf);
  Lines := 0;
  while Count > 0 do
  begin
    if P^ in [AnsiChar(#10), AnsiChar(#13)] then
    begin
      Inc(Lines);
      if Ord((P + 1)^) + Ord(P^) = 23 then
      begin
        Inc(P);
        Dec(Count);
        if Count = 0 then
          Break;
      end;
    end;
    Inc(P);
    Dec(Count);
  end;
  Result := Lines;
end;

procedure GetLimits(var Buf; Count: Sw_Word; var Lim: TPoint);
var
  P: PAnsiChar;
  Len: Sw_Word;
begin
  Lim.X := 0;
  Lim.Y := 0;
  Len := 0;
  P := PAnsiChar(@Buf);
  while Count > 0 do
  begin
    if P^ in [AnsiChar(#10), AnsiChar(#13)] then
    begin
      if Sw_Integer(Len) > Lim.X then
        Lim.X := Len;
      Inc(Lim.Y);
      if Ord((P + 1)^) + Ord(P^) = 23 then
      begin
        Inc(P);
        Dec(Count);
      end;
      Len := 0;
    end
    else
      Inc(Len);
    Inc(P);
    Dec(Count);
  end;
end;

function ScanKeyMap(KeyMap: Pointer; KeyCode: Word): Word;
var
  P: PWord;
  Count: Sw_Word;
begin
  P := KeyMap;
  Count := P^;
  Inc(P);
  while Count > 0 do
  begin
    if (Lo(P^) = Lo(KeyCode)) and ((Hi(P^) = 0) or (Hi(P^) = Hi(KeyCode))) then
    begin
      Inc(P);
      Result := P^;
      Exit;
    end;
    Inc(P, 2);
    Dec(Count);
  end;
  Result := 0;
end;

type
  BTable = array[0..255] of Byte;

procedure BMMakeTable(const S: String; var T: BTable);
var
  X: Sw_Integer;
begin
  FillChar(T, SizeOf(T), Length(S));
  for X := Length(S) downto 1 do
    if T[Ord(S[X])] = Length(S) then
      T[Ord(S[X])] := Length(S) - X;
end;

function Scan(var Block; Size: Sw_Word; const Str: String): Sw_Word;
var
  Buffer: array[0..MaxBufLength - 1] of Byte absolute Block;
  S2: String;
  Len, Numb: Sw_Word;
  Found: Boolean;
  BT: BTable;
begin
  BMMakeTable(Str, BT);
  Len := Length(Str);
  SetLength(S2, Len);
  Found := False;
  Numb := Pred(Len);
  while (not Found) and (Numb < (Size - Len)) do
  begin
    if Buffer[Numb] = Ord(Str[Len]) then
    begin
      if Buffer[Numb - Pred(Len)] = Ord(Str[1]) then
      begin
        Move(Buffer[Numb - Pred(Len)], S2[1], Len);
        if Str = S2 then
        begin
          Found := True;
          Break;
        end;
      end;
      Inc(Numb);
    end
    else
      Inc(Numb, BT[Buffer[Numb]]);
  end;
  if not Found then
    Result := NotFoundValue
  else
    Result := Numb - Pred(Len);
end;

function IScan(var Block; Size: Sw_Word; const Str: String): Sw_Word;
var
  Buffer: array[0..MaxBufLength - 1] of AnsiChar absolute Block;
  S: AnsiString;
  Len, Numb, X: Sw_Word;
  Found: Boolean;
  BT: BTable;
  P: PAnsiChar;
  C: AnsiChar;
begin
  Len := Length(Str);
  if (Len = 0) or (Len > Size) then
  begin
    Result := NotFoundValue;
    Exit;
  end;
  { Create uppercased string }
  SetLength(S, Len);
  for X := 1 to Len do
  begin
    if CharInSet(Str[X], ['a'..'z']) then
      S[X] := AnsiChar(Ord(Str[X]) - 32)
    else
      S[X] := AnsiChar(Str[X]);
  end;
  BMMakeTable(String(S), BT);
  Found := False;
  Numb := Pred(Len);
  while (not Found) and (Numb < (Size - Len)) do
  begin
    C := Buffer[Numb];
    if C in [AnsiChar('a')..AnsiChar('z')] then
      C := AnsiChar(Ord(C) - 32);
    if C = S[Len] then
    begin
      P := @Buffer[Numb - Pred(Len)];
      X := 1;
      while X <= Len do
      begin
        if not (((P^ in [AnsiChar('a')..AnsiChar('z')]) and (AnsiChar(Ord(P^) - 32) = S[X])) or (P^ = S[X])) then
          Break;
        Inc(P);
        Inc(X);
      end;
      if X > Len then
      begin
        Found := True;
        Break;
      end;
      Inc(Numb);
    end
    else
      Inc(Numb, BT[Ord(C)]);
  end;
  if not Found then
    Result := NotFoundValue
  else
    Result := Numb - Pred(Len);
end;

{****************************************************************************
                                 TIndicator
****************************************************************************}

constructor TIndicator.Init(var Bounds: TRect);
begin
  inherited Init(Bounds);
  GrowMode := gfGrowLoY + gfGrowHiY;
end;

procedure TIndicator.Draw;
var
  Color: Byte;
  Frame: AnsiChar;
  L: array[0..1] of NativeInt;
  S: String[15];
  B: TDrawBuffer;
begin
  if State and sfDragging = 0 then
  begin
    Color := GetColor(1);
    Frame := #205;
  end
  else
  begin
    Color := GetColor(2);
    Frame := #196;
  end;
  MoveChar(B, Frame, Color, Size.X);
  { If the text has been modified, put an 'M' in the TIndicator display. }
  if Modified then
    WordRec(B[1]).Lo := 77;
  { If WordWrap is active put a 'W' in the TIndicator display. }
  if WordWrap then
    WordRec(B[2]).Lo := 87
  else
    WordRec(B[2]).Lo := Byte(Frame);
  { If AutoIndent is active put an 'I' in TIndicator display. }
  if AutoIndent then
    WordRec(B[0]).Lo := 73
  else
    WordRec(B[0]).Lo := Byte(Frame);
  L[0] := Location.Y + 1;
  L[1] := Location.X + 1;
  FormatStr(S, ' %d:%d ', L);
  MoveStr(B[9 - Pos(':', S)], S, Color);
  WriteBuf(0, 0, Size.X, 1, B);
end;

function TIndicator.GetPalette: PPalette;
const
  P: String[Length(CIndicator)] = CIndicator;
begin
  Result := PPalette(@P);
end;

procedure TIndicator.SetState(AState: Word; Enable: Boolean);
begin
  inherited SetState(AState, Enable);
  if AState = sfDragging then
    DrawView;
end;

procedure TIndicator.SetValue(ALocation: TPoint; IsAutoIndent: Boolean;
                              IsModified: Boolean; IsWordWrap: Boolean);
begin
  if (Location.X <> ALocation.X) or
     (Location.Y <> ALocation.Y) or
     (AutoIndent <> IsAutoIndent) or
     (Modified <> IsModified) or
     (WordWrap <> IsWordWrap) then
  begin
    Location := ALocation;
    AutoIndent := IsAutoIndent;
    Modified := IsModified;
    WordWrap := IsWordWrap;
    DrawView;
  end;
end;

{****************************************************************************
                                 TLineInfo
****************************************************************************}

constructor TLineInfo.Init;
begin
  MaxPos := 0;
  Grow(1);
end;

destructor TLineInfo.Done;
begin
  FreeMem(Info, MaxPos * SizeOf(TLineInfoRec));
  Info := nil;
end;

procedure TLineInfo.Grow(Pos: Sw_Word);
var
  NewSize: Sw_Word;
  P: Pointer;
begin
  NewSize := (Pos + LineInfoGrow - (Pos mod LineInfoGrow));
  GetMem(P, NewSize * SizeOf(TLineInfoRec));
  FillChar(P^, NewSize * SizeOf(TLineInfoRec), 0);
  if MaxPos > 0 then
    Move(Info^, P^, MaxPos * SizeOf(TLineInfoRec));
  if MaxPos > 0 then
    FreeMem(Info, MaxPos * SizeOf(TLineInfoRec));
  Info := P;
  MaxPos := NewSize;
end;

procedure TLineInfo.SetLen(Pos, Val: Sw_Word);
begin
  if Pos >= MaxPos then
    Grow(Pos);
  Info^[Pos].Len := Val;
end;

procedure TLineInfo.SetAttr(Pos, Val: Sw_Word);
begin
  if Pos >= MaxPos then
    Grow(Pos);
  Info^[Pos].Attr := Val;
end;

function TLineInfo.GetLen(Pos: Sw_Word): Sw_Word;
begin
  Result := Info^[Pos].Len;
end;

function TLineInfo.GetAttr(Pos: Sw_Word): Sw_Word;
begin
  Result := Info^[Pos].Attr;
end;

{****************************************************************************
                                 TEditor
****************************************************************************}

constructor TEditor.Init(var Bounds: TRect; AHScrollBar, AVScrollBar: PScrollBar;
                         AIndicator: PIndicator; ABufSize: Sw_Word);
var
  Element: Byte;
begin
  inherited Init(Bounds);
  GrowMode := gfGrowHiX + gfGrowHiY;
  Options := Options or ofSelectable;
  Flags := EditorFlags;
  EventMask := evMouseDown + evKeyDown + evCommand + evBroadcast;
  ShowCursor;

  HScrollBar := AHScrollBar;
  VScrollBar := AVScrollBar;

  Indicator := AIndicator;
  BufSize := ABufSize;
  CanUndo := True;
  InitBuffer;

  if Assigned(Buffer) then
    IsValid := True
  else
  begin
    EditorDialog(edOutOfMemory, nil);
    BufSize := 0;
  end;

  SetBufLen(0);

  for Element := 1 to 10 do
    Place_Marker[Element] := 0;

  Element := 1;
  Tab_Settings := '';
  while Element <= 70 do
  begin
    if Element mod 5 = 0 then
      Tab_Settings := Tab_Settings + 'x'
    else
      Tab_Settings := Tab_Settings + ' ';
    Inc(Element);
  end;
  { Default Right_Margin value. }
  Right_Margin := 76;
  TabSize := 8;
end;

destructor TEditor.Done;
begin
  DoneBuffer;
  inherited Done;
end;

function TEditor.BufChar(P: Sw_Word): AnsiChar;
begin
  if P >= CurPtr then
    Inc(P, GapLen);
  Result := Buffer^[P];
end;

function TEditor.BufPtr(P: Sw_Word): Sw_Word;
begin
  if P >= CurPtr then
    Result := P + GapLen
  else
    Result := P;
end;

procedure TEditor.Center_Text(Select_Mode: Byte);
var
  Spaces: array[1..80] of AnsiChar;
  Index: Byte;
  Line_Length: Sw_Integer;
  E, S: Sw_Word;
begin
  E := LineEnd(CurPtr);
  S := LineStart(CurPtr);
  if E = S then
    Exit;
  SetCurPtr(S, Select_Mode);
  Remove_EOL_Spaces(Select_Mode);
  if Buffer^[BufPtr(CurPtr)] = #32 then
  begin
    E := LineEnd(CurPtr);
    if NextWord(CurPtr) > E then
      Exit;
    if E - NextWord(CurPtr) > Sw_Word(Right_Margin) then
      Exit;
    DeleteRange(CurPtr, NextWord(CurPtr), True);
    E := LineEnd(CurPtr);
    SetCurPtr(LineStart(CurPtr), Select_Mode);
  end
  else
    if E - CurPtr > Sw_Word(Right_Margin) then
      Exit;
  Line_Length := E - CurPtr;
  for Index := 1 to ((Right_Margin - Line_Length) shr 1) do
    Spaces[Index] := #32;
  InsertText(@Spaces, Index, False);
  SetCurPtr(LineEnd(CurPtr), Select_Mode);
end;

procedure TEditor.ChangeBounds(var Bounds: TRect);
begin
  SetBounds(Bounds);
  Delta.X := Max(0, Min(Delta.X, Limit.X - Size.X));
  Delta.Y := Max(0, Min(Delta.Y, Limit.Y - Size.Y));
  Update(ufView);
end;

function TEditor.CharPos(P, Target: Sw_Word): Sw_Integer;
var
  Pos: Sw_Integer;
begin
  Pos := 0;
  while P < Target do
  begin
    if BufChar(P) = #9 then
      Pos := Pos or (TabSize - 1);
    Inc(Pos);
    Inc(P);
  end;
  Result := Pos;
end;

function TEditor.CharPtr(P: Sw_Word; Target: Sw_Integer): Sw_Word;
var
  Pos: Sw_Integer;
begin
  Pos := 0;
  while (Pos < Target) and (P < BufLen) and not (BufChar(P) in [AnsiChar(#10), AnsiChar(#13)]) do
  begin
    if BufChar(P) = #9 then
      Pos := Pos or (TabSize - 1);
    Inc(Pos);
    Inc(P);
  end;
  if Pos > Target then
    Dec(P);
  Result := P;
end;

procedure TEditor.Check_For_Word_Wrap(Select_Mode: Byte; Center_Cursor: Boolean);
begin
  if CurPos.X > Right_Margin then
    Do_Word_Wrap(Select_Mode, Center_Cursor);
end;

function TEditor.ClipCopy: Boolean;
begin
  Result := False;
  if Assigned(EditorDebugLog) then
    EditorDebugLog(Format('ClipCopy: Clipboard=%p Self=%p HasSelection=%s SelStart=%d SelEnd=%d',
      [Pointer(Clipboard), Pointer(@Self), BoolToStr(HasSelection, True), SelStart, SelEnd]));
  if not Assigned(Clipboard) then
  begin
    if Assigned(EditorDebugLog) then
      EditorDebugLog('ClipCopy: No clipboard assigned!');
    Exit;
  end;
  if Clipboard = @Self then
  begin
    if Assigned(EditorDebugLog) then
      EditorDebugLog('ClipCopy: Cannot copy to self');
    Exit;
  end;
  if not HasSelection then
  begin
    if Assigned(EditorDebugLog) then
      EditorDebugLog('ClipCopy: No selection to copy');
    Exit;
  end;
  { Clear existing clipboard content first }
  Clipboard^.SetSelect(0, Clipboard^.BufLen, True);
  Clipboard^.DeleteSelect;
  { Copy selection to clipboard }
  Result := Clipboard^.InsertFrom(@Self);
  if Assigned(EditorDebugLog) then
    EditorDebugLog(Format('ClipCopy: InsertFrom result=%s, Clipboard now has SelStart=%d SelEnd=%d BufLen=%d',
      [BoolToStr(Result, True), Clipboard^.SelStart, Clipboard^.SelEnd, Clipboard^.BufLen]));
  { Select all in clipboard so paste can use it }
  Clipboard^.SetSelect(0, Clipboard^.BufLen, False);
  Selecting := False;
  Update(ufUpdate);
end;

procedure TEditor.ClipCut;
begin
  if Assigned(EditorDebugLog) then
    EditorDebugLog('ClipCut: Starting');
  if ClipCopy then
  begin
    if Assigned(EditorDebugLog) then
      EditorDebugLog('ClipCut: Copy succeeded, deleting selection');
    Update_Place_Markers(0, SelEnd - SelStart, SelStart, SelEnd);
    DeleteSelect;
  end;
end;

procedure TEditor.ClipPaste;
begin
  if Assigned(EditorDebugLog) then
    EditorDebugLog(Format('ClipPaste: Clipboard=%p Self=%p', [Pointer(Clipboard), Pointer(@Self)]));
  if not Assigned(Clipboard) then
  begin
    if Assigned(EditorDebugLog) then
      EditorDebugLog('ClipPaste: No clipboard assigned!');
    Exit;
  end;
  if Clipboard = @Self then
  begin
    if Assigned(EditorDebugLog) then
      EditorDebugLog('ClipPaste: Cannot paste to self');
    Exit;
  end;
  if Assigned(EditorDebugLog) then
    EditorDebugLog(Format('ClipPaste: Clipboard SelStart=%d SelEnd=%d BufLen=%d HasSelection=%s',
      [Clipboard^.SelStart, Clipboard^.SelEnd, Clipboard^.BufLen, BoolToStr(Clipboard^.HasSelection, True)]));
  if not Clipboard^.HasSelection then
  begin
    if Assigned(EditorDebugLog) then
      EditorDebugLog('ClipPaste: Clipboard has no selection to paste');
    Exit;
  end;
  if Word_Wrap and (CurPos.X > Right_Margin) then
  begin
    EditorDialog(edPasteNotPossible, nil);
    Exit;
  end;
  if CurPtr = SelStart then
    Update_Place_Markers(Clipboard^.SelEnd - Clipboard^.SelStart, 0,
                         Clipboard^.SelStart, Clipboard^.SelEnd);
  InsertFrom(Clipboard);
  if Assigned(EditorDebugLog) then
    EditorDebugLog('ClipPaste: InsertFrom completed');
end;

procedure TEditor.ConvertEvent(var Event: TEvent);
var
  ShiftState: Byte;
  Key: Word;
begin
  ShiftState := GetShiftState;
  if Event.What = evKeyDown then
  begin
    if (ShiftState and $03 <> 0) and (Event.ScanCode >= $47) and (Event.ScanCode <= $51) then
      Event.CharCode := #0;
    Key := Event.KeyCode;
    if KeyState <> 0 then
    begin
      if (Lo(Key) >= $01) and (Lo(Key) <= $1A) then
        Inc(Key, $40);
      if (Lo(Key) >= $61) and (Lo(Key) <= $7A) then
        Dec(Key, $20);
    end;
    Key := ScanKeyMap(KeyMap[KeyState], Key);
    KeyState := 0;
    if Key <> 0 then
      if Hi(Key) = $FF then
      begin
        KeyState := Lo(Key);
        ClearEvent(Event);
      end
      else
      begin
        Event.What := evCommand;
        Event.Command := Key;
      end;
  end;
end;

function TEditor.CursorVisible: Boolean;
begin
  Result := (CurPos.Y >= Delta.Y) and (CurPos.Y < Delta.Y + Size.Y);
end;

procedure TEditor.DeleteRange(StartPtr, EndPtr: Sw_Word; DelSelect: Boolean);
begin
  Update_Place_Markers(0, EndPtr - StartPtr, StartPtr, EndPtr);
  if HasSelection and DelSelect then
    DeleteSelect
  else
  begin
    SetSelect(CurPtr, EndPtr, True);
    DeleteSelect;
    SetSelect(StartPtr, CurPtr, False);
    DeleteSelect;
  end;
end;

procedure TEditor.DeleteSelect;
begin
  InsertText(nil, 0, False);
end;

procedure TEditor.DoneBuffer;
begin
  ReallocMem(Buffer, 0);
end;

procedure TEditor.DoSearchReplace;
var
  I: Word;
  C: TPoint;
begin
  repeat
    I := cmCancel;
    if not Search(FindStr, Flags) then
    begin
      if Flags and (efReplaceAll + efDoReplace) <> (efReplaceAll + efDoReplace) then
        EditorDialog(edSearchFailed, nil);
    end
    else if Flags and efDoReplace <> 0 then
    begin
      I := cmYes;
      if Flags and efPromptOnReplace <> 0 then
      begin
        MakeGlobal(Cursor, C);
        I := EditorDialog(edReplacePrompt, Pointer(@C));
      end;
      if I = cmYes then
      begin
        if Word_Wrap and ((CurPos.X + Sw_Integer(Length(ReplaceStr)) - Sw_Integer(Length(FindStr))) > Right_Margin) then
          EditorDialog(edReplaceNotPossible, nil)
        else
        begin
          Lock;
          Search_Replace := True;
          if Length(ReplaceStr) < Length(FindStr) then
            Update_Place_Markers(0, Length(FindStr) - Length(ReplaceStr),
                                 CurPtr - Sw_Word(Length(FindStr)) + Sw_Word(Length(ReplaceStr)), CurPtr)
          else if Length(ReplaceStr) > Length(FindStr) then
            Update_Place_Markers(Length(ReplaceStr) - Length(FindStr), 0,
                                 CurPtr, CurPtr + Sw_Word(Length(ReplaceStr)) - Sw_Word(Length(FindStr)));
          InsertText(@ReplaceStr[1], Length(ReplaceStr), False);
          Search_Replace := False;
          TrackCursor(False);
          Unlock;
        end;
      end;
    end;
  until (I = cmCancel) or (Flags and efReplaceAll = 0);
end;

procedure TEditor.DoUpdate;
begin
  if UpdateFlags <> 0 then
  begin
    SetCursor(CurPos.X - Delta.X, CurPos.Y - Delta.Y);
    if UpdateFlags and ufView <> 0 then
      DrawView
    else if UpdateFlags and ufLine <> 0 then
      DrawLines(CurPos.Y - Delta.Y, 1, LineStart(CurPtr));
    if Assigned(HScrollBar) then
      HScrollBar^.SetParams(Delta.X, 0, Limit.X - Size.X, Size.X div 2, 1);
    if Assigned(VScrollBar) then
      VScrollBar^.SetParams(Delta.Y, 0, Limit.Y - Size.Y, Size.Y - 1, 1);
    if Assigned(Indicator) then
    begin
      if Assigned(EditorDebugLog) then
        EditorDebugLog(Format('DoUpdate: Setting indicator to CurPos=(%d,%d)',
          [CurPos.X, CurPos.Y]));
      Indicator^.SetValue(CurPos, AutoIndent, Modified, Word_Wrap);
    end;
    if State and sfActive <> 0 then
      UpdateCommands;
    UpdateFlags := 0;
  end;
end;

function TEditor.Do_Word_Wrap(Select_Mode: Byte; Center_Cursor: Boolean): Boolean;
var
  A, C, L, P, S: Sw_Word;
begin
  Result := False;
  Select_Mode := 0;
  if BufLen >= (BufSize - 1) then
    Exit;
  C := CurPtr;
  L := BufLen;
  S := LineStart(CurPtr);

  if AutoIndent and (Buffer^[BufPtr(S)] = ' ') then
  begin
    if NextWord(S) > CurPtr then
      A := CurPtr
    else
      A := NextWord(S);
  end
  else
    A := NextWord(S);

  Remove_EOL_Spaces(Select_Mode);
  if CurPos.X = 0 then
  begin
    NewLine(Select_Mode);
    Result := True;
    Exit;
  end;

  { Check for special conditions }
  if Buffer^[BufPtr(CurPtr)] = ' ' then
  begin
    SetCurPtr(PrevChar(CurPtr), Select_Mode);
    if Buffer^[BufPtr(CurPtr)] = ' ' then
    begin
      SetCurPtr(NextChar(CurPtr), Select_Mode);
      EditorDialog(edWrapNotPossible, nil);
      Exit;
    end;
  end
  else
  begin
    P := PrevWord(CurPtr);
    if P = LineStart(CurPtr) then
    begin
      EditorDialog(edWrapNotPossible, nil);
      Exit;
    end;
    SetCurPtr(P, Select_Mode);
    if Buffer^[BufPtr(CurPtr)] = ' ' then
      SetCurPtr(NextChar(CurPtr), Select_Mode);
  end;

  if not NewLine(Select_Mode) then
    Exit;

  if AutoIndent and (A > S) and (A < C) then
  begin
    P := A - S;
    while P > 0 do
    begin
      InsertText(@Buffer^[BufPtr(S)], 1, False);
      Dec(P);
    end;
  end;

  SetCurPtr(LineEnd(CurPtr), Select_Mode);
  Result := True;
end;

procedure TEditor.Draw;
begin
  DrawLines(0, Size.Y, LineMove(DrawPtr, Delta.Y - DrawLine));
end;

procedure TEditor.DrawLines(Y, Count: Sw_Integer; LinePtr: Sw_Word);
var
  B: TDrawBuffer;
  Color: Word;
begin
  Color := GetColor($0201);
  while Count > 0 do
  begin
    MoveChar(B, ' ', Byte(Color), Size.X);
    FormatLine(B, LinePtr, Size.X, Color);
    WriteLine(0, Y, Size.X, 1, B);
    LinePtr := NextLine(LinePtr);
    Inc(Y);
    Dec(Count);
  end;
end;

procedure TEditor.Find;
var
  FindRec: TFindDialogRec;
begin
  FindRec.Find := FindStr;
  FindRec.Options := Flags;
  if EditorDialog(edFind, @FindRec) <> cmCancel then
  begin
    FindStr := FindRec.Find;
    Flags := FindRec.Options and not efDoReplace;
    DoSearchReplace;
  end;
end;

procedure TEditor.FormatLine(var DrawBuf; LinePtr: Sw_Word; Width: Sw_Integer; Colors: Word);
var
  P: PWord;
  X: Sw_Integer;
  C: AnsiChar;
  Color, SelColor: Byte;
  SelS, SelE: Sw_Integer;
begin
  P := @DrawBuf;
  X := 0;
  Color := Lo(Colors);
  SelColor := Hi(Colors);

  { Calculate selection range }
  if (SelStart <> SelEnd) and (LinePtr < SelEnd) then
  begin
    SelS := 0;
    if LinePtr < SelStart then
      SelS := CharPos(LinePtr, SelStart);
    SelE := CharPos(LinePtr, Min(LineEnd(LinePtr), SelEnd));
  end
  else
  begin
    SelS := MaxLineLength;
    SelE := MaxLineLength;
  end;

  while (X < Width + Delta.X) and (LinePtr < BufLen) do
  begin
    C := BufChar(LinePtr);
    if C in [AnsiChar(#10), AnsiChar(#13)] then
      Break;
    if C = #9 then
    begin
      repeat
        if X >= Delta.X then
        begin
          if (X >= SelS) and (X < SelE) then
            P^ := (SelColor shl 8) or Ord(' ')
          else
            P^ := (Color shl 8) or Ord(' ');
          Inc(P);
        end;
        Inc(X);
      until (X mod TabSize = 0) or (X >= Width + Delta.X);
    end
    else
    begin
      if X >= Delta.X then
      begin
        if (X >= SelS) and (X < SelE) then
          P^ := (SelColor shl 8) or Ord(C)
        else
          P^ := (Color shl 8) or Ord(C);
        Inc(P);
      end;
      Inc(X);
    end;
    Inc(LinePtr);
  end;

  { Fill rest with spaces }
  while X < Width + Delta.X do
  begin
    if X >= Delta.X then
    begin
      P^ := (Color shl 8) or Ord(' ');
      Inc(P);
    end;
    Inc(X);
  end;
end;

function TEditor.GetMousePtr(Mouse: TPoint): Sw_Word;
begin
  MakeLocal(Mouse, Mouse);
  Mouse.X := Max(0, Min(Mouse.X, Size.X - 1));
  Mouse.Y := Max(0, Min(Mouse.Y, Size.Y - 1));
  Result := CharPtr(LineMove(DrawPtr, Mouse.Y + Delta.Y - DrawLine), Mouse.X + Delta.X);
end;

function TEditor.GetPalette: PPalette;
const
  P: String[Length(CEditor)] = CEditor;
begin
  Result := PPalette(@P);
end;

procedure TEditor.HandleEvent(var Event: TEvent);
var
  CenterCursor: Boolean;
  SelectMode: Byte;
  NewPtr: Sw_Word;
  D, Mouse: TPoint;
  ShiftState: Byte;

  function CheckScrollBar(P: PScrollBar; var D: Sw_Integer): Boolean;
  begin
    Result := False;
    if (Event.InfoPtr = P) and (P^.Value <> D) then
    begin
      D := P^.Value;
      Update(ufView);
      Result := True;
    end;
  end;

begin
  inherited HandleEvent(Event);
  CenterCursor := not CursorVisible;
  SelectMode := 0;
  ShiftState := GetShiftState;
  { Check shift state BEFORE ConvertEvent changes evKeyDown to evCommand }
  if (ShiftState and $03 <> 0) and (Event.What = evKeyDown) then
    SelectMode := smExtend;
  ConvertEvent(Event);
  { Also check for commands - shift may still be held for cursor movement commands }
  if (ShiftState and $03 <> 0) and (Event.What = evCommand) then
    SelectMode := smExtend;

  case Event.What of
    evMouseDown:
      begin
        if Event.Double then
          SelectMode := smDouble;

        repeat
          Lock;
          if Event.What = evMouseAuto then
          begin
            MakeLocal(Event.Where, Mouse);
            D.X := 0;
            D.Y := 0;
            if Mouse.X < 0 then
              D.X := -1
            else if Mouse.X >= Size.X then
              D.X := 1;
            if Mouse.Y < 0 then
              D.Y := -1
            else if Mouse.Y >= Size.Y then
              D.Y := 1;
            if (D.X <> 0) or (D.Y <> 0) then
              ScrollTo(Delta.X + D.X, Delta.Y + D.Y);
          end;
          SetCurPtr(GetMousePtr(Event.Where), SelectMode);
          SelectMode := smExtend;
          Unlock;
        until not MouseEvent(Event, evMouseMove + evMouseAuto);
        ClearEvent(Event);
      end;

    evKeyDown:
      case Event.CharCode of
        #32..#255:
          begin
            Lock;
            if Overwrite and not HasSelection then
              if BufChar(CurPtr) <> #13 then
                SetSelect(CurPtr, NextChar(CurPtr), True);
            InsertText(@Event.CharCode, 1, False);
            if Word_Wrap then
              Check_For_Word_Wrap(SelectMode, CenterCursor);
            TrackCursor(CenterCursor);
            Unlock;
            ClearEvent(Event);
          end;
      else
        Exit;
      end;

    evCommand:
      begin
        Lock;
        case Event.Command of
          cmFind: Find;
          cmReplace: Replace;
          cmSearchAgain: DoSearchReplace;
          cmCut: ClipCut;
          cmCopy: ClipCopy;
          cmPaste: ClipPaste;
          cmUndo: Undo;
          cmClear: DeleteSelect;
          cmCharLeft: SetCurPtr(PrevChar(CurPtr), SelectMode);
          cmCharRight: SetCurPtr(NextChar(CurPtr), SelectMode);
          cmWordLeft: SetCurPtr(PrevWord(CurPtr), SelectMode);
          cmWordRight: SetCurPtr(NextWord(CurPtr), SelectMode);
          cmLineStart: SetCurPtr(LineStart(CurPtr), SelectMode);
          cmLineEnd: SetCurPtr(LineEnd(CurPtr), SelectMode);
          cmLineUp: SetCurPtr(LineMove(CurPtr, -1), SelectMode);
          cmLineDown: SetCurPtr(LineMove(CurPtr, 1), SelectMode);
          cmPageUp: SetCurPtr(LineMove(CurPtr, -(Size.Y - 1)), SelectMode);
          cmPageDown: SetCurPtr(LineMove(CurPtr, Size.Y - 1), SelectMode);
          cmTextStart: SetCurPtr(0, SelectMode);
          cmTextEnd: SetCurPtr(BufLen, SelectMode);
          cmNewLine: NewLine(SelectMode);
          cmBackSpace:
            if not HasSelection then
            begin
              if CurPtr > 0 then
              begin
                SetSelect(PrevChar(CurPtr), CurPtr, True);
                DeleteSelect;
              end;
            end
            else
              DeleteSelect;
          cmDelChar:
            if not HasSelection then
            begin
              if CurPtr < BufLen then
              begin
                SetSelect(CurPtr, NextChar(CurPtr), True);
                DeleteSelect;
              end;
            end
            else
              DeleteSelect;
          cmDelWord:
            if not HasSelection then
            begin
              SetSelect(CurPtr, NextWord(CurPtr), True);
              DeleteSelect;
            end
            else
              DeleteSelect;
          cmDelStart:
            if not HasSelection then
            begin
              SetSelect(LineStart(CurPtr), CurPtr, True);
              DeleteSelect;
            end
            else
              DeleteSelect;
          cmDelEnd:
            if not HasSelection then
            begin
              SetSelect(CurPtr, LineEnd(CurPtr), True);
              DeleteSelect;
            end
            else
              DeleteSelect;
          cmDelLine:
            begin
              SetSelect(LineStart(CurPtr), NextLine(CurPtr), True);
              DeleteSelect;
            end;
          cmInsMode: ToggleInsMode;
          cmStartSelect: StartSelect;
          cmEndSelect: Selecting := False;
          cmHideSelect: HideSelect;
          cmInsertLine: Insert_Line(SelectMode);
          cmIndentMode: AutoIndent := not AutoIndent;
          cmTabKey: Tab_Key(SelectMode);
          cmScrollUp: Scroll_Up;
          cmScrollDown: Scroll_Down;
          cmSelectWord: Select_Word;
          cmWordWrap: Word_Wrap := not Word_Wrap;
          cmReformPara: Reformat_Paragraph(SelectMode, CenterCursor);
          cmReformDoc: Reformat_Document(SelectMode, CenterCursor);
          cmRightMargin: Set_Right_Margin;
          cmSetTabs: Set_Tabs;
          cmCenterText: Center_Text(SelectMode);
          cmJumpLine: Jump_To_Line(SelectMode);
          cmSetMark0..cmSetMark9: Set_Place_Marker(Event.Command - cmSetMark0);
          cmJumpMark0..cmJumpMark9: Jump_Place_Marker(Event.Command - cmJumpMark0, SelectMode);
        else
          Unlock;
          Exit;
        end;
        TrackCursor(CenterCursor);
        Unlock;
        ClearEvent(Event);
      end;

    evBroadcast:
      case Event.Command of
        cmScrollBarChanged:
          if (Event.InfoPtr = HScrollBar) or (Event.InfoPtr = VScrollBar) then
          begin
            CheckScrollBar(HScrollBar, Delta.X);
            CheckScrollBar(VScrollBar, Delta.Y);
          end
          else
            Exit;
      else
        Exit;
      end;
  end;
  ClearEvent(Event);
end;

function TEditor.HasSelection: Boolean;
begin
  Result := SelStart <> SelEnd;
end;

procedure TEditor.HideSelect;
begin
  Selecting := False;
  SetSelect(CurPtr, CurPtr, False);
end;

procedure TEditor.InitBuffer;
begin
  Buffer := nil;
end;

procedure TEditor.Insert_Line(Select_Mode: Byte);
var
  P: Sw_Word;
begin
  P := CurPtr;
  NewLine(Select_Mode);
  SetCurPtr(P, Select_Mode);
end;

function TEditor.InsertBuffer(var P: PEditBuffer; Offset, Length: Sw_Word;
                              AllowUndo, SelectText: Boolean): Boolean;
var
  SelLen, DelLen: Sw_Word;
  SelLines, Lines: Sw_Word;
  NewSize: LongInt;
begin
  Result := True;
  Selecting := False;
  SelLen := SelEnd - SelStart;

  if Assigned(EditorDebugLog) then
    EditorDebugLog(Format('InsertBuffer: CurPos=(%d,%d) CurPtr=%d Length=%d SelLen=%d',
      [CurPos.X, CurPos.Y, CurPtr, Length, SelLen]));

  if (SelLen = 0) and (Length = 0) then
    Exit;

  DelLen := 0;
  if AllowUndo then
  begin
    if CurPtr = SelStart then
      DelLen := SelLen
    else if SelLen > InsCount then
      DelLen := SelLen - InsCount;
  end;

  NewSize := LongInt(BufLen + DelCount - SelLen + DelLen) + Length;
  if NewSize > BufLen + DelCount then
    if (NewSize > MaxBufLength) or not SetBufSize(NewSize) then
    begin
      EditorDialog(edOutOfMemory, nil);
      Result := False;
      SelEnd := SelStart;
      Exit;
    end;

  { Count lines in selection being deleted }
  SelLines := CountLines(Buffer^[BufPtr(SelStart)], SelLen);

  { Handle deletion when cursor is at end of selection }
  if CurPtr = SelEnd then
  begin
    if AllowUndo then
    begin
      if DelLen > 0 then
        Move(Buffer^[SelStart], Buffer^[CurPtr + GapLen - DelCount - DelLen], DelLen);
      Dec(InsCount, SelLen - DelLen);
    end;
    CurPtr := SelStart;
    Dec(CurPos.Y, SelLines);
  end;

  { Adjust Delta.Y if needed }
  if Delta.Y > CurPos.Y then
  begin
    Dec(Delta.Y, SelLines);
    if Delta.Y < CurPos.Y then
      Delta.Y := CurPos.Y;
  end;

  { Insert new text }
  if Length > 0 then
    Move(P^[Offset], Buffer^[CurPtr], Length);

  { Count lines in new text }
  Lines := CountLines(Buffer^[CurPtr], Length);
  Inc(CurPtr, Length);

  { Update cursor position }
  Inc(CurPos.Y, Lines);
  DrawLine := CurPos.Y;
  DrawPtr := LineStart(CurPtr);
  CurPos.X := CharPos(DrawPtr, CurPtr);

  if Assigned(EditorDebugLog) then
    EditorDebugLog(Format('InsertBuffer AFTER: CurPos=(%d,%d) Lines=%d CurPtr=%d',
      [CurPos.X, CurPos.Y, Lines, CurPtr]));

  { Update selection }
  if not SelectText then
    SelStart := CurPtr;
  SelEnd := CurPtr;

  { Update buffer length }
  if Length > SelLen then
  begin
    Inc(BufLen, Length - SelLen);
    Dec(GapLen, Length - SelLen);
  end
  else
  begin
    Dec(BufLen, SelLen - Length);
    Inc(GapLen, SelLen - Length);
  end;

  { Update undo info }
  if AllowUndo then
  begin
    Inc(DelCount, DelLen);
    Inc(InsCount, Length);
  end;

  { Update limits }
  Inc(Limit.Y, Sw_Integer(Lines) - Sw_Integer(SelLines));
  if Sw_Integer(CurPos.X) > Limit.X then
    Limit.X := CurPos.X;

  Modified := True;
  Update(ufView);
end;

function TEditor.InsertFrom(Editor: PEditor): Boolean;
begin
  Result := InsertBuffer(Editor^.Buffer, Editor^.BufPtr(Editor^.SelStart),
                         Editor^.SelEnd - Editor^.SelStart, CanUndo, IsClipboard);
end;

function TEditor.InsertText(Text: Pointer; Length: Sw_Word; SelectText: Boolean): Boolean;
begin
  Result := InsertBuffer(PEditBuffer(Text), 0, Length, CanUndo, SelectText);
end;

function TEditor.IsClipboard: Boolean;
begin
  Result := Clipboard = @Self;
end;

procedure TEditor.Jump_Place_Marker(Element: Byte; Select_Mode: Byte);
begin
  if (Element >= 0) and (Element <= 9) then
    if Place_Marker[Element + 1] <= BufLen then
      SetCurPtr(Place_Marker[Element + 1], Select_Mode);
end;

procedure TEditor.Jump_To_Line(Select_Mode: Byte);
var
  P: Sw_Word;
  LineNum: LongInt;
  Code: Integer;
begin
  if EditorDialog(edJumpToLine, @Line_Number) <> cmCancel then
  begin
    Val(Line_Number, LineNum, Code);
    if Code = 0 then
    begin
      Dec(LineNum);
      P := 0;
      while (LineNum > 0) and (P < BufLen) do
      begin
        P := NextLine(P);
        Dec(LineNum);
      end;
      SetCurPtr(P, Select_Mode);
    end;
  end;
end;

function TEditor.LineEnd(P: Sw_Word): Sw_Word;
begin
  while (P < BufLen) and not (BufChar(P) in [AnsiChar(#10), AnsiChar(#13)]) do
    Inc(P);
  Result := P;
end;

function TEditor.LineMove(P: Sw_Word; Count: Sw_Integer): Sw_Word;
var
  Pos: Sw_Integer;
  I: Sw_Word;
begin
  Pos := CharPos(LineStart(P), P);
  while Count <> 0 do
  begin
    I := P;
    if Count < 0 then
    begin
      P := PrevLine(P);
      Inc(Count);
    end
    else
    begin
      P := NextLine(P);
      Dec(Count);
    end;
    if P = I then
      Break;
  end;
  Result := CharPtr(P, Pos);
end;

function TEditor.LineNr(P: Sw_Word): Sw_Word;
var
  Count: Sw_Word;
begin
  Count := 0;
  while P > 0 do
  begin
    P := PrevLine(P);
    Inc(Count);
  end;
  Result := Count;
end;

function TEditor.LineStart(P: Sw_Word): Sw_Word;
begin
  while (P > 0) and not (BufChar(P - 1) in [AnsiChar(#10), AnsiChar(#13)]) do
    Dec(P);
  Result := P;
end;

procedure TEditor.Lock;
begin
  Inc(LockCount);
end;

function TEditor.NewLine(Select_Mode: Byte): Boolean;
begin
  Remove_EOL_Spaces(Select_Mode);
  Result := InsertText(@LineBreak[1], Length(LineBreak), False);
end;

function TEditor.NextChar(P: Sw_Word): Sw_Word;
begin
  if P < BufLen then
  begin
    Inc(P);
    if (P < BufLen) and (BufChar(P - 1) = #13) and (BufChar(P) = #10) then
      Inc(P);
  end;
  Result := P;
end;

function TEditor.NextLine(P: Sw_Word): Sw_Word;
begin
  Result := NextChar(LineEnd(P));
end;

function TEditor.NextWord(P: Sw_Word): Sw_Word;
begin
  while (P < BufLen) and (BufChar(P) in WordChars) do
    Inc(P);
  while (P < BufLen) and not (BufChar(P) in WordChars) do
    Inc(P);
  Result := P;
end;

function TEditor.PrevChar(P: Sw_Word): Sw_Word;
begin
  if P > 0 then
  begin
    Dec(P);
    if (P > 0) and (BufChar(P) = #10) and (BufChar(P - 1) = #13) then
      Dec(P);
  end;
  Result := P;
end;

function TEditor.PrevLine(P: Sw_Word): Sw_Word;
begin
  Result := LineStart(PrevChar(LineStart(P)));
end;

function TEditor.PrevWord(P: Sw_Word): Sw_Word;
begin
  while (P > 0) and not (BufChar(P - 1) in WordChars) do
    Dec(P);
  while (P > 0) and (BufChar(P - 1) in WordChars) do
    Dec(P);
  Result := P;
end;

procedure TEditor.Reformat_Document(Select_Mode: Byte; Center_Cursor: Boolean);
var
  Choice: Word;
  OldPtr: Sw_Word;
begin
  if not Word_Wrap then
  begin
    if not Allow_Reformat then
    begin
      EditorDialog(edReformatNotAllowed, nil);
      Exit;
    end;
  end;
  Choice := 0;
  if EditorDialog(edReformatDocument, @Choice) = cmCancel then
    Exit;
  OldPtr := CurPtr;
  if Choice = 1 then
    SetCurPtr(0, Select_Mode);

  while CurPtr < BufLen do
  begin
    if not Reformat_Paragraph(Select_Mode, Center_Cursor) then
      Break;
    SetCurPtr(NextLine(CurPtr), Select_Mode);
  end;

  SetCurPtr(OldPtr, Select_Mode);
end;

function TEditor.Reformat_Paragraph(Select_Mode: Byte; Center_Cursor: Boolean): Boolean;
begin
  Result := True;
  if CurPos.X > Right_Margin then
    Result := Do_Word_Wrap(Select_Mode, Center_Cursor);
end;

procedure TEditor.Remove_EOL_Spaces(Select_Mode: Byte);
var
  E: Sw_Word;
begin
  E := LineEnd(CurPtr);
  while (E > LineStart(CurPtr)) and (BufChar(E - 1) = ' ') do
    Dec(E);
  if CurPtr > E then
    SetCurPtr(E, Select_Mode);
  if E < LineEnd(E) then
    DeleteRange(E, LineEnd(E), False);
end;

procedure TEditor.Replace;
var
  ReplaceRec: TReplaceDialogRec;
begin
  ReplaceRec.Find := FindStr;
  ReplaceRec.Replace := ReplaceStr;
  ReplaceRec.Options := Flags;
  if EditorDialog(edReplace, @ReplaceRec) <> cmCancel then
  begin
    FindStr := ReplaceRec.Find;
    ReplaceStr := ReplaceRec.Replace;
    Flags := ReplaceRec.Options or efDoReplace;
    DoSearchReplace;
  end;
end;

procedure TEditor.Scroll_Down;
begin
  ScrollTo(Delta.X, Delta.Y + 1);
end;

procedure TEditor.Scroll_Up;
begin
  ScrollTo(Delta.X, Delta.Y - 1);
end;

procedure TEditor.ScrollTo(X, Y: Sw_Integer);
begin
  X := Max(0, Min(X, Limit.X - Size.X));
  Y := Max(0, Min(Y, Limit.Y - Size.Y));
  if (X <> Delta.X) or (Y <> Delta.Y) then
  begin
    Delta.X := X;
    Delta.Y := Y;
    Update(ufView);
  end;
end;

function TEditor.Search(const FindStr: String; Opts: Word): Boolean;
var
  I: Sw_Word;
  Pos: Sw_Word;
begin
  Result := False;
  if Length(FindStr) = 0 then
    Exit;

  Pos := CurPtr;
  repeat
    if Opts and efCaseSensitive <> 0 then
    begin
      if Pos < BufLen then
        I := Scan(Buffer^[BufPtr(Pos)], BufLen - Pos, FindStr)
      else
        I := NotFoundValue;
    end
    else
    begin
      if Pos < BufLen then
        I := IScan(Buffer^[BufPtr(Pos)], BufLen - Pos, FindStr)
      else
        I := NotFoundValue;
    end;

    if I <> NotFoundValue then
    begin
      Inc(I, Pos);
      { Check for whole words only if option is set }
      if (Opts and efWholeWordsOnly = 0) or
         not (((I <> 0) and (BufChar(I - 1) in WordChars)) or
              ((I + Sw_Word(Length(FindStr)) <> BufLen) and
               (BufChar(I + Sw_Word(Length(FindStr))) in WordChars))) then
      begin
        Lock;
        SetSelect(I, I + Sw_Word(Length(FindStr)), False);
        TrackCursor(not CursorVisible);
        Unlock;
        Result := True;
        Exit;
      end
      else
        Pos := I + 1;
    end;
  until I = NotFoundValue;
end;

procedure TEditor.Select_Word;
var
  S, E: Sw_Word;
begin
  S := CurPtr;
  while (S > 0) and (BufChar(S - 1) in WordChars) do
    Dec(S);
  E := CurPtr;
  while (E < BufLen) and (BufChar(E) in WordChars) do
    Inc(E);
  SetSelect(S, E, False);
end;

function TEditor.SetBufSize(NewSize: Sw_Word): Boolean;
begin
  Result := True;
end;

procedure TEditor.SetBufLen(Length: Sw_Word);
begin
  BufLen := Length;
  GapLen := BufSize - BufLen;
  SelStart := 0;
  SelEnd := 0;
  CurPtr := 0;
  CurPos.X := 0;
  CurPos.Y := 0;
  Delta.X := 0;
  Delta.Y := 0;
  Limit.X := MaxLineLength;
  Limit.Y := 1;
  if Assigned(Buffer) and (BufLen > 0) then
    GetLimits(Buffer^[GapLen], BufLen, Limit);
  Inc(Limit.Y);
  DrawLine := 0;
  DrawPtr := 0;
  DelCount := 0;
  InsCount := 0;
  Modified := False;
  Update(ufView);
end;

procedure TEditor.SetCmdState(Command: Word; Enable: Boolean);
begin
  if State and sfActive <> 0 then
  begin
    if Enable then
      EnableCommands([Command])
    else
      DisableCommands([Command]);
  end;
end;

procedure TEditor.SetCurPtr(P: Sw_Word; SelectMode: Byte);
var
  Anchor: Sw_Word;
begin
  if SelectMode and smExtend = 0 then
    Anchor := P
  else if CurPtr = SelStart then
    Anchor := SelEnd
  else
    Anchor := SelStart;

  if P < Anchor then
  begin
    if SelectMode and smDouble <> 0 then
    begin
      P := PrevLine(NextLine(P));
      Anchor := NextLine(PrevLine(Anchor));
    end;
    SetSelect(P, Anchor, True);
  end
  else
  begin
    if SelectMode and smDouble <> 0 then
    begin
      P := NextLine(P);
      Anchor := PrevLine(NextLine(Anchor));
    end;
    SetSelect(Anchor, P, False);
  end;
end;

procedure TEditor.SetSelect(NewStart, NewEnd: Sw_Word; CurStart: Boolean);
var
  P: Sw_Word;
  L: Sw_Word;
  UFlags: Byte;
begin
  if CurStart then
    P := NewStart
  else
    P := NewEnd;

  UFlags := ufUpdate;
  if (NewStart <> SelStart) or (NewEnd <> SelEnd) then
    if (NewStart <> NewEnd) or (SelStart <> SelEnd) then
      UFlags := ufView;

  if Assigned(EditorDebugLog) then
    EditorDebugLog(Format('SetSelect BEFORE: CurPos=(%d,%d) CurPtr=%d P=%d',
      [CurPos.X, CurPos.Y, CurPtr, P]));

  if P <> CurPtr then
  begin
    if P > CurPtr then
    begin
      { Moving forward: Move first, then count lines in destination }
      L := P - CurPtr;
      Move(Buffer^[CurPtr + GapLen], Buffer^[CurPtr], L);
      Inc(CurPos.Y, CountLines(Buffer^[CurPtr], L));
      CurPtr := P;
    end
    else
    begin
      { Moving backward: Set CurPtr first, count lines, then Move }
      { This order is critical - count lines BEFORE the Move corrupts the source }
      L := CurPtr - P;
      CurPtr := P;
      Dec(CurPos.Y, CountLines(Buffer^[CurPtr], L));
      Move(Buffer^[CurPtr], Buffer^[CurPtr + GapLen], L);
    end;
    DrawLine := CurPos.Y;
    DrawPtr := LineStart(CurPtr);
    CurPos.X := CharPos(DrawPtr, CurPtr);
    { Reset undo state when cursor moves }
    DelCount := 0;
    InsCount := 0;
    SetBufSize(BufLen);

    if Assigned(EditorDebugLog) then
      EditorDebugLog(Format('SetSelect AFTER: CurPos=(%d,%d) CurPtr=%d',
        [CurPos.X, CurPos.Y, CurPtr]));
  end;
  SelStart := NewStart;
  SelEnd := NewEnd;
  Update(UFlags);
end;

procedure TEditor.Set_Place_Marker(Element: Byte);
begin
  if (Element >= 0) and (Element <= 9) then
    Place_Marker[Element + 1] := CurPtr;
end;

procedure TEditor.Set_Right_Margin;
var
  MarginRec: TRightMarginRec;
  Code: Integer;
  NewMargin: Integer;
begin
  Str(Right_Margin, MarginRec.Margin_Position);
  if EditorDialog(edRightMargin, @MarginRec) <> cmCancel then
  begin
    Val(MarginRec.Margin_Position, NewMargin, Code);
    if Code = 0 then
      Right_Margin := NewMargin;
  end;
end;

procedure TEditor.Set_Tabs;
var
  TabRec: TTabStopRec;
begin
  TabRec.Tab_String := Tab_Settings;
  if EditorDialog(edSetTabStops, @TabRec) <> cmCancel then
    Tab_Settings := TabRec.Tab_String;
end;

procedure TEditor.SetState(AState: Word; Enable: Boolean);
begin
  inherited SetState(AState, Enable);
  case AState of
    sfActive:
      begin
        if Assigned(HScrollBar) then
          HScrollBar^.SetState(sfVisible, Enable);
        if Assigned(VScrollBar) then
          VScrollBar^.SetState(sfVisible, Enable);
        if Assigned(Indicator) then
          Indicator^.SetState(sfVisible, Enable);
        UpdateCommands;
      end;
    sfExposed:
      if Enable then
        Unlock;
  end;
end;

procedure TEditor.StartSelect;
begin
  HideSelect;
  Selecting := True;
end;

procedure TEditor.Tab_Key(Select_Mode: Byte);
var
  I: Integer;
begin
  if Overwrite then
    SetCurPtr(NextChar(CurPtr), Select_Mode)
  else
  begin
    I := TabSize - (CurPos.X mod TabSize);
    if I = 0 then
      I := TabSize;
    InsertText(@'        '[1], I, False);
  end;
end;

procedure TEditor.ToggleInsMode;
begin
  Overwrite := not Overwrite;
  SetState(sfCursorIns, Overwrite);
end;

procedure TEditor.TrackCursor(Center: Boolean);
begin
  if Center then
    ScrollTo(CurPos.X - Size.X div 2, CurPos.Y - Size.Y div 2)
  else
    ScrollTo(Max(CurPos.X - Size.X + 1, Min(Delta.X, CurPos.X)),
             Max(CurPos.Y - Size.Y + 1, Min(Delta.Y, CurPos.Y)));
end;

procedure TEditor.Undo;
begin
  if (DelCount > 0) or (InsCount > 0) then
  begin
    SetSelect(CurPtr - InsCount, CurPtr, True);
    InsertBuffer(Buffer, CurPtr + GapLen - DelCount, DelCount, False, True);
    DelCount := 0;
    InsCount := 0;
  end;
end;

procedure TEditor.Unlock;
begin
  if LockCount > 0 then
  begin
    Dec(LockCount);
    if LockCount = 0 then
      DoUpdate;
  end;
end;

procedure TEditor.Update(AFlags: Byte);
begin
  UpdateFlags := UpdateFlags or AFlags;
  if LockCount = 0 then
    DoUpdate;
end;

procedure TEditor.UpdateCommands;
begin
  SetCmdState(cmUndo, (DelCount > 0) or (InsCount > 0));
  if not IsClipboard then
  begin
    SetCmdState(cmCut, HasSelection);
    SetCmdState(cmCopy, HasSelection);
    SetCmdState(cmPaste, Assigned(Clipboard) and (Clipboard^.HasSelection));
  end;
  SetCmdState(cmClear, HasSelection);
  SetCmdState(cmFind, True);
  SetCmdState(cmReplace, True);
  SetCmdState(cmSearchAgain, True);
end;

procedure TEditor.Update_Place_Markers(AddCount: Word; KillCount: Word;
                                       StartPtr, EndPtr: Sw_Word);
var
  Element: Byte;
begin
  for Element := 1 to 10 do
  begin
    if Place_Marker[Element] >= StartPtr then
    begin
      if Place_Marker[Element] <= EndPtr then
        Place_Marker[Element] := StartPtr
      else
        Place_Marker[Element] := Place_Marker[Element] + AddCount - KillCount;
    end;
  end;
end;

function TEditor.Valid(Command: Word): Boolean;
begin
  Result := IsValid;
end;

{****************************************************************************
                                   TMemo
****************************************************************************}

function TMemo.DataSize: Word;
begin
  Result := BufSize + SizeOf(Sw_Word);
end;

procedure TMemo.GetData(var Rec);
var
  Data: TMemoData absolute Rec;
begin
  Data.Length := BufLen;
  Move(Buffer^, Data.Buffer, CurPtr);
  Move(Buffer^[CurPtr + GapLen], Data.Buffer[CurPtr], BufLen - CurPtr);
  FillChar(Data.Buffer[BufLen], BufSize - BufLen, 0);
end;

function TMemo.GetPalette: PPalette;
const
  P: String[Length(CMemo)] = CMemo;
begin
  Result := PPalette(@P);
end;

procedure TMemo.HandleEvent(var Event: TEvent);
begin
  if (Event.What <> evKeyDown) or (Event.KeyCode <> kbTab) then
    inherited HandleEvent(Event);
end;

procedure TMemo.SetData(var Rec);
var
  Data: TMemoData absolute Rec;
begin
  Move(Data.Buffer, Buffer^[BufSize - Data.Length], Data.Length);
  SetBufLen(Data.Length);
end;

{****************************************************************************
                               TFileEditor
****************************************************************************}

constructor TFileEditor.Init(var Bounds: TRect; AHScrollBar, AVScrollBar: PScrollBar;
                             AIndicator: PIndicator; AFileName: FNameStr);
begin
  inherited Init(Bounds, AHScrollBar, AVScrollBar, AIndicator, 0);
  if AFileName <> '' then
  begin
    FileName := FExpand(AFileName);
    if IsValid then
      IsValid := LoadFile;
  end;
end;

procedure TFileEditor.DoneBuffer;
begin
  ReallocMem(Buffer, 0);
end;

procedure TFileEditor.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);
  case Event.What of
    evCommand:
      case Event.Command of
        cmSave: Save;
        cmSaveAs: SaveAs;
        cmSaveDone:
          if Save then
            Message(Owner, evCommand, cmClose, nil);
      else
        Exit;
      end;
  else
    Exit;
  end;
  ClearEvent(Event);
end;

procedure TFileEditor.InitBuffer;
begin
  Assert(Buffer = nil, 'TFileEditor.InitBuffer: Buffer is not nil');
  ReallocMem(Buffer, MinBufLength);
  BufSize := MinBufLength;
end;

function TFileEditor.LoadFile: Boolean;
var
  FLength: Sw_Word;
  FSize: LongInt;
  FRead: Integer;
  F: File;
begin
  Result := False;
  FLength := 0;
  AssignFile(F, FileName);
  {$I-}
  Reset(F, 1);
  {$I+}
  if IOResult <> 0 then
    EditorDialog(edReadError, @FileName)
  else
  begin
    FSize := FileSize(F);
    if (FSize > MaxBufLength) or not SetBufSize(FSize) then
      EditorDialog(edOutOfMemory, nil)
    else
    begin
      {$I-}
      BlockRead(F, Buffer^[BufSize - FSize], FSize, FRead);
      {$I+}
      if (IOResult <> 0) or (FRead <> FSize) then
        EditorDialog(edReadError, @FileName)
      else
      begin
        Result := True;
        FLength := FRead;
      end;
    end;
    CloseFile(F);
  end;
  SetBufLen(FLength);
end;

function TFileEditor.Save: Boolean;
begin
  if FileName = '' then
    Result := SaveAs
  else
    Result := SaveFile;
end;

function TFileEditor.SaveAs: Boolean;
begin
  Result := False;
  if EditorDialog(edSaveAs, @FileName) <> cmCancel then
  begin
    FileName := FExpand(FileName);
    Message(Owner, evBroadcast, cmUpdateTitle, nil);
    Result := SaveFile;
    if IsClipboard then
      FileName := '';
  end;
end;

function TFileEditor.SaveFile: Boolean;
var
  F: File;
  BackupName: FNameStr;
  D: DirStr;
  N: NameStr;
  E: ExtStr;
begin
  Result := False;
  if Flags and efBackupFiles <> 0 then
  begin
    FSplit(FileName, D, N, E);
    BackupName := D + N + '.bak';
    {$I-}
    AssignFile(F, BackupName);
    Erase(F);
    AssignFile(F, FileName);
    Rename(F, BackupName);
    {$I+}
    IOResult;  { Clear any errors }
  end;
  AssignFile(F, FileName);
  {$I-}
  Rewrite(F, 1);
  {$I+}
  if IOResult <> 0 then
    EditorDialog(edCreateError, @FileName)
  else
  begin
    {$I-}
    BlockWrite(F, Buffer^, CurPtr);
    BlockWrite(F, Buffer^[CurPtr + GapLen], BufLen - CurPtr);
    {$I+}
    if IOResult <> 0 then
      EditorDialog(edWriteError, @FileName)
    else
    begin
      Modified := False;
      Update(ufUpdate);
      Result := True;
    end;
    CloseFile(F);
  end;
end;

function TFileEditor.SetBufSize(NewSize: Sw_Word): Boolean;
var
  N: Sw_Word;
begin
  Result := False;
  if NewSize = 0 then
    NewSize := MinBufLength
  else if NewSize > (MaxBufLength - MinBufLength) then
    NewSize := MaxBufLength
  else
    NewSize := (NewSize + (MinBufLength - 1)) and (MaxBufLength and (not (MinBufLength - 1)));

  if NewSize <> BufSize then
  begin
    if NewSize > BufSize then
      ReallocMem(Buffer, NewSize);
    N := BufLen - CurPtr + DelCount;
    Move(Buffer^[BufSize - N], Buffer^[NewSize - N], N);
    if NewSize < BufSize then
      ReallocMem(Buffer, NewSize);
    BufSize := NewSize;
    GapLen := BufSize - BufLen;
  end;
  Result := True;
end;

procedure TFileEditor.UpdateCommands;
begin
  inherited UpdateCommands;
  SetCmdState(cmSave, True);
  SetCmdState(cmSaveAs, True);
  SetCmdState(cmSaveDone, True);
end;

function TFileEditor.Valid(Command: Word): Boolean;
var
  D: SmallInt;
begin
  if Command = cmValid then
    Result := IsValid
  else
  begin
    Result := True;
    if Modified then
    begin
      if FileName = '' then
        D := edSaveUntitled
      else
        D := edSaveModify;
      case EditorDialog(D, @FileName) of
        cmYes: Result := Save;
        cmNo: Modified := False;
        cmCancel: Result := False;
      end;
    end;
  end;
end;

{****************************************************************************
                             TEditWindow
****************************************************************************}

constructor TEditWindow.Init(var Bounds: TRect; FileName: FNameStr; ANumber: SmallInt);
var
  HScrollBar: PScrollBar;
  VScrollBar: PScrollBar;
  Indicator: PIndicator;
  R: TRect;
begin
  inherited Init(Bounds, '', ANumber);
  Options := Options or ofTileable;

  R.Assign(18, Size.Y - 1, Size.X - 2, Size.Y);
  HScrollBar := New(PScrollBar, Init(R));
  HScrollBar^.Hide;
  Insert(HScrollBar);

  R.Assign(Size.X - 1, 1, Size.X, Size.Y - 1);
  VScrollBar := New(PScrollBar, Init(R));
  VScrollBar^.Hide;
  Insert(VScrollBar);

  R.Assign(2, Size.Y - 1, 16, Size.Y);
  Indicator := New(PIndicator, Init(R));
  Indicator^.Hide;
  Insert(Indicator);

  GetExtent(R);
  R.Grow(-1, -1);
  Editor := New(PFileEditor, Init(R, HScrollBar, VScrollBar, Indicator, FileName));
  Insert(Editor);
end;

procedure TEditWindow.Close;
begin
  if Editor^.IsClipboard then
    Hide
  else
    inherited Close;
end;

function TEditWindow.GetTitle(MaxSize: Sw_Integer): TTitleStr;
begin
  if Editor^.IsClipboard then
    Result := sClipboard
  else if Editor^.FileName = '' then
    Result := sUntitled
  else
    Result := Editor^.FileName;
end;

procedure TEditWindow.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);
  if Event.What = evBroadcast then
    case Event.Command of
      cmUpdateTitle:
        begin
          Frame^.DrawView;
          ClearEvent(Event);
        end;
      cmBludgeonStats:
        begin
          Editor^.Update(ufStats);
          ClearEvent(Event);
        end;
    end;
end;

procedure TEditWindow.SizeLimits(var Min, Max: TPoint);
begin
  inherited SizeLimits(Min, Max);
  Min.X := 23;
end;

end.
