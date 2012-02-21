Unit bbs_Edit_Full;

{$I M_OPS.PAS}

Interface

Function AnsiEditor (Var Lines: SmallInt; WrapPos: Byte; MaxLines: SmallInt; TEdit, Forced: Boolean; Var Subj: String) : Boolean;

Implementation

Uses
  m_Strings,
  bbs_Common,
  bbs_Core;

Procedure Print (S: String);
Begin
  {$IFNDEF UNIX}
  If Not Session.LocalMode Then Session.io.BufAddStr(S);
  {$ENDIF}

  Screen.WriteStr(S);
End;

Procedure PrintLn (S: String);
Begin
  Print (S + #13#10);
End;

Function AnsiEditor (Var Lines: Integer; WrapPos: Byte; MaxLines: Integer; TEdit, Forced: Boolean; Var Subj: String) : Boolean;
Const
  WinStart   : Byte    = 2;
  WinEnd     : Byte    = 22;
  InsertMode : Boolean = True;

Var
  Done         : Boolean;
  Save         : Boolean;
  Ch           : Char;
  tColor       : Byte;
  CurX         : Byte;
  CurY         : Integer;
  CurLine      : Integer;
  TotalLine    : Integer;
  QuoteCurLine : Integer;
  QuoteTopPage : Integer;

Procedure UpdatePosition;
Begin
  If CurLine > TotalLine Then TotalLine := CurLine;
  If CurX > Length(Session.Msgs.MsgText[CurLine]) Then CurX := Length(Session.Msgs.MsgText[CurLine]) + 1;

  Session.io.AnsiGotoXY (CurX, CurY);
End;

Procedure ScreenRefreshPart;
Var
  A,
  B : Integer;
Begin
  Session.io.AnsiGotoXY (1, CurY);

  A := CurY;
  B := CurLine;

  Repeat
    If B <= TotalLine Then Print(Session.Msgs.MsgText[B]);
    If B <= TotalLine + 1 Then Begin
      Session.io.AnsiClrEOL;
      PrintLn('');
    End;

    Inc (A);
    Inc (B);
  Until A > WinEnd;

  UpdatePosition;
End;

Procedure ScreenRefreshFull;
Var
  A,
  B  : Integer;
Begin
  CurY := WinStart + 5;
  B    := CurLine  - 5;

  If B < 1 Then Begin
    CurY := WinStart + (5 + B - 1);
    B    := 1;
  End;

  Session.io.AnsiGotoXY (1, WinStart);

  A := WinStart;

  Repeat
    If B <= TotalLine Then Print(Session.Msgs.MsgText[B]);
    Session.io.AnsiClrEOL;
    PrintLn('');
    Inc (A);
    Inc (B);
  Until A > WinEnd;

  UpdatePosition;
End;

Procedure InsertLine (Num: Integer);
Var
  A : Integer;
Begin
  Inc (TotalLine);

  For A := TotalLine DownTo Num + 1 Do
    Session.Msgs.MsgText[A] := Session.Msgs.MsgText[A - 1];

  Session.Msgs.MsgText[Num] := '';
End;

Procedure DeleteLine (Num: Integer);
Var
  Count : Integer;
Begin
  For Count := Num To TotalLine - 1 Do
    Session.Msgs.MsgText[Count] := Session.Msgs.MsgText[Count + 1];

  Session.Msgs.MsgText[TotalLine] := '';

  Dec (TotalLine);
End;

Procedure TextReformat;
Var
  OldStr  : String;
  NewStr  : String;
  Line    : Integer;
  A       : Integer;
  NewY    : Integer;
  NewLine : Integer;
  Moved   : Boolean;
Begin
  If TotalLine = MaxLines Then Exit;

  Line    := CurLine;
  OldStr  := Session.Msgs.MsgText[Line];
  NewY    := CurY;
  NewLine := CurLine;
  Moved   := False;

  Repeat
      If Pos(' ', OldStr) = 0 Then Begin
        Inc        (Line);
        InsertLine (Line);

        Session.Msgs.MsgText[Line]      := Copy(OldStr, CurX, Length(OldStr));
        Session.Msgs.MsgText[Line-1][0] := Chr(CurX - 1);

        If CurX > WrapPos Then Begin
          Inc (NewLine);
          Inc (NewY);
          CurX := 1;
        End;

        If NewY <= WinEnd Then ScreenRefreshPart;

        CurY    := NewY;
        CurLine := NewLine;

        If CurY > WinEnd Then ScreenRefreshFull Else UpdatePosition;

        Exit;
      End Else Begin
        A := strWrap (OldStr, NewStr, WrapPos);

        If (A > 0) And (Not Moved) And (CurX > Length(OldStr) + 1) Then Begin
          CurX  := CurX - A;
          Moved := True;
          Inc (NewLine);
          Inc (NewY);
        End;

        Session.Msgs.MsgText[Line] := OldStr;
        Inc (Line);

        If (Session.Msgs.MsgText[Line] = '') or ((Pos(' ', Session.Msgs.MsgText[Line]) = 0) And (Length(Session.Msgs.MsgText[Line]) >= WrapPos)) Then Begin
          InsertLine(Line);
          OldStr := NewStr;
        End Else
          OldStr := NewStr + ' ' + Session.Msgs.MsgText[Line];
      End;
  Until Length(OldStr) <= WrapPos;

  Session.Msgs.MsgText[Line] := OldStr;

  If NewY <= WinEnd Then Begin
    Session.io.AnsiGotoXY(1, CurY);

    A := CurLine;

    Repeat
      If (CurY + (A - CurLine) <= WinEnd) and (A <= TotalLine) Then Begin
        Print(Session.Msgs.MsgText[A]);
        Session.io.AnsiClrEOL;
        PrintLn('');
      End Else
        Break;

      Inc (A);
    Until False;
  End;

  Session.io.BufFlush;

  CurY    := NewY;
  CurLine := NewLine;

  If CurY > WinEnd Then ScreenRefreshFull Else UpdatePosition;
End;

Procedure keyEnter;
Begin
  If TotalLine = MaxLines Then Exit;

  InsertLine (CurLine + 1);

  If CurX < Length(Session.Msgs.MsgText[CurLine]) + 1 Then Begin
    Session.Msgs.MsgText[CurLine+1] := Copy(Session.Msgs.MsgText[CurLine], CurX, Length(Session.Msgs.MsgText[CurLine]));
    Delete (Session.Msgs.MsgText[CurLine], CurX, Length(Session.Msgs.MsgText[CurLine]));
  End;

  If CurY + 1 > WinEnd Then ScreenRefreshFull Else ScreenRefreshPart;

  CurX := 1;

  Inc(CurY);
  Inc(CurLine);

  UpdatePosition;
End;

Procedure keyDownArrow;
Begin
  If CurLine = TotalLine Then Exit;

  If CurY = WinEnd Then
    ScreenRefreshFull
  Else Begin
    Inc (CurY);
    Inc (CurLine);
    UpdatePosition;
  End;
End;

Procedure keyUpArrow (EOL: Boolean);
Begin
  If CurLine > 1 Then Begin
    If EOL then begin
      CurX := Length(Session.Msgs.MsgText[CurLine - 1]) + 1;
      If CurX > WrapPos Then CurX := WrapPos + 1;
    End;

    If CurY = WinStart Then
      ScreenRefreshFull
    Else Begin
      Dec (CurY);
      Dec (CurLine);
      UpdatePosition;
    End;
  End;
End;

Procedure keyBackspace;
Var
  A : Integer;
Begin
  If CurX > 1 Then Begin
    Session.io.OutBS(1, True);
    Dec (CurX);
    Delete (Session.Msgs.MsgText[CurLine], CurX, 1);
    If CurX < Length(Session.Msgs.MsgText[CurLine]) + 1 Then Begin
      Print (Copy(Session.Msgs.MsgText[CurLine], CurX, Length(Session.Msgs.MsgText[CurLine])) + ' ');
      UpdatePosition;
    End;
  End Else
  If CurLine > 1 Then Begin
    If Length(Session.Msgs.MsgText[CurLine - 1]) + Length(Session.Msgs.MsgText[CurLine]) <= WrapPos Then Begin
      CurX := Length(Session.Msgs.MsgText[CurLine - 1]) + 1;
      Session.Msgs.MsgText[CurLine - 1] := Session.Msgs.MsgText[CurLine - 1] + Session.Msgs.MsgText[CurLine];
      DeleteLine (CurLine);
      Dec (CurLine);
      Dec (CurY);
      If CurY < WinStart Then ScreenRefreshFull Else ScreenRefreshPart;
    End Else
    If Pos(' ', Session.Msgs.MsgText[CurLine]) > 0 Then Begin
      For A := Length(Session.Msgs.MsgText[CurLine]) DownTo 1 Do
        If (Session.Msgs.MsgText[CurLine][A] = ' ') and (Length(Session.Msgs.MsgText[CurLine - 1]) + A - 1 <= WrapPos) Then Begin
          CurX := Length(Session.Msgs.MsgText[CurLine - 1]) + 1;
          Session.Msgs.MsgText[CurLine - 1] := Session.Msgs.MsgText[CurLine - 1] + Copy(Session.Msgs.MsgText[CurLine], 1, A - 1);
          Delete (Session.Msgs.MsgText[CurLine], 1, A);
          Dec (CurLine);
          Dec (CurY);
          If CurY < WinStart Then ScreenRefreshFull Else ScreenRefreshPart;
          Exit;
        End;
      keyUpArrow(True);
    End;
  End;
End;

Procedure keyLeftArrow;
begin
  if curx > 1 then Begin
    Dec (CurX);
    UpdatePosition;
  end else
    keyUpArrow(true);
End;

Procedure keyRightArrow;
Begin
  if curx < length(Session.Msgs.MsgText[curline])+1 then begin
    Inc (CurX);
    UpdatePosition;
  End Else Begin
    If CurY < TotalLine Then CurX := 1;
    keyDownArrow;
  End;
End;

Procedure AddChar (Ch: Char);
Begin
  If InsertMode Then Begin
    Insert (Ch, Session.Msgs.MsgText[Curline], CurX);
    Print (Copy(Session.Msgs.MsgText[CurLine], CurX, Length(Session.Msgs.MsgText[CurLine])));
  End Else Begin
    If CurX > Length(Session.Msgs.MsgText[CurLine]) Then Inc(Session.Msgs.MsgText[CurLine][0]);
    Session.Msgs.MsgText[CurLine][CurX] := Ch;
    Print (Ch); {outchar}
  End;
  Inc (CurX);
  UpdatePosition;
End;

Procedure ToggleInsert (Toggle: Boolean);
Begin
  If Toggle Then InsertMode := Not InsertMode;

  Session.io.AnsiColor  (Session.io.ScreenInfo[3].A);
  Session.io.AnsiGotoXY (Session.io.ScreenInfo[3].X, Session.io.ScreenInfo[3].Y);

  If InsertMode Then Print('INS') else Print('OVR'); { ++lang }

  Session.io.AnsiGotoXY   (CurX, CurY);
  Session.io.AnsiColor (tColor);
End;

Procedure FullReDraw;
Begin
  If TEdit Then Session.io.OutFile ('ansitext', True, 0) Else Session.io.OutFile ('ansiedit', True, 0);

  WinStart := Session.io.ScreenInfo[1].Y;
  WinEnd   := Session.io.ScreenInfo[2].Y;
  tColor   := Session.io.ScreenInfo[1].A;

  ToggleInsert (False);

  ScreenRefreshFull;
End;

Procedure Quote;
Var
  InFile : Text;
  Start,
  Finish : Integer;
  NumLines : Integer;
  Text   : Array[1..mysMaxMsgLines] of String[80];
  PI1    : String;
  PI2    : String;
Begin
  Assign (InFile, Session.TempPath + 'msgtmp');
  {$I-} Reset (InFile); {$I+}
  If IoResult <> 0 Then Begin
    Session.io.OutFullLn (Session.GetPrompt(158));
    Exit;
  End;

  NumLines   := 0;
  Session.io.AllowPause := True;

  While Not Eof(InFile) Do Begin
    Inc    (NumLines);
    ReadLn (InFile, Text[NumLines]);
  End;

  Close (InFile);

  PI1 := Session.io.PromptInfo[1];
  PI2 := Session.io.PromptInfo[2];

  Session.io.OutFullLn(Session.GetPrompt(452));

  For Start := 1 to NumLines Do Begin
    Session.io.PromptInfo[1] := strI2S(Start);
    Session.io.PromptInfo[2] := Text[Start];

    Session.io.OutFullLn (Session.GetPrompt(341));

    If (Session.io.PausePtr >= Session.User.ThisUser.ScreenSize) and (Session.io.AllowPause) Then
      Case Session.io.MorePrompt of
        'N' : Break;
        'C' : Session.io.AllowPause := False;
      End;
  End;

  Session.io.AllowPause := True;

  Session.io.OutFull (Session.GetPrompt(159));
  Start := strS2I(Session.io.GetInput(3, 3, 11, ''));

  Session.io.OutFull (Session.GetPrompt(160));
  Finish := strS2I(Session.io.GetInput(3, 3, 11, ''));

  If (Start > 0) and (Start <= NumLines) and (Finish <= NumLines) Then Begin
    If Finish = 0 Then Finish := Start;
    For NumLines := Start to Finish Do Begin
      If TotalLine = mysMaxMsgLines Then Break;
      If Session.Msgs.MsgText[CurLine] <> '' Then Begin
        Inc (CurLine);
        InsertLine (CurLine);
      End;
      Session.Msgs.MsgText[CurLine] := Text[NumLines];
    End;
    If CurLine < MaxLines then Inc(CurLine);
  End;

  Session.io.PromptInfo[1] := PI1;
  Session.io.PromptInfo[2] := PI2;
End;

Procedure QuoteWindow;
Var
  QText      : Array[1..mysMaxMsgLines] of String[80];
  InFile     : Text;
  QuoteLines : Integer;
  NoMore     : Boolean;

  Procedure UpdateBar (On: Boolean);
  Begin
    Session.io.AnsiGotoXY (1, QuoteCurLine + Session.io.ScreenInfo[2].Y);
    If On Then
      Session.io.AnsiColor (Session.Lang.QuoteColor)
    Else
      Session.io.AnsiColor (Session.io.ScreenInfo[2].A);

    Print (strPadR(QText[QuoteTopPage + QuoteCurLine], 79, ' '));
  End;

  Procedure UpdateWindow;
  Var
    A : Integer;
  Begin
    Session.io.AnsiGotoXY   (1, Session.io.ScreenInfo[2].Y);
    Session.io.AnsiColor (Session.io.ScreenInfo[2].A);
    For A := QuoteTopPage to QuoteTopPage + 5 Do Begin
      If A <= QuoteLines Then Print (QText[A]);
      Session.io.AnsiClrEOL;
      If A <= QuoteLines Then PrintLn('');
    End;
    UpdateBar(True);
  End;

Var
  Scroll : Integer;
  Temp1  : Integer;
  Ch     : Char;
  Added  : Boolean;
Begin
  Added := False;

  Assign (InFile, Session.TempPath + 'msgtmp');
  {$I-} Reset(InFile); {$I+}
  If IoResult <> 0 Then Exit;

  QuoteLines := 0;
  NoMore     := False;
  Scroll     := CurLine + 4;

  While Not Eof(InFile) Do Begin
    Inc (QuoteLines);
    ReadLn (InFile, QText[QuoteLines]);
  End;

  Close (InFile);

  Session.io.OutFile ('ansiquot', True, 0);

  If CurY >= Session.io.ScreenInfo[1].Y Then Begin
    Session.io.AnsiColor(tColor);
    Temp1  := WinEnd;
    WinEnd := Session.io.ScreenInfo[1].Y;
    ScreenRefreshFull;
    WinEnd := Temp1;
  End;

  UpdateWindow;

  Repeat
    Ch := Session.io.GetKey;

    If Session.io.IsArrow Then Begin
      Case Ch of
        #71 : If QuoteCurLine > 0 Then Begin
                QuoteTopPage := 1;
                QuoteCurLine := 0;
                UpdateWindow;
              End;
        #72 : Begin
                If QuoteCurLine > 0 Then Begin
                  UpdateBar(False);
                  Dec(QuoteCurLine);
                  UpdateBar(True);
                End Else
                If QuoteTopPage > 1 Then Begin
                  Dec (QuoteTopPage);
                  UpdateWindow;
                End;
                NoMore := False;
              End;
        #73,
        #75 : Begin
                If QuoteTopPage > 6 Then
                  Dec (QuoteTopPage, 6)
                Else Begin
                  QuoteTopPage := 1;
                  QuoteCurLine := 0;
                End;
                NoMore := False;
                UpdateWindow;
              End;
        #79 : Begin
                If QuoteLines <= 6 Then
                  QuoteCurLine := QuoteLines - QuoteTopPage
                Else Begin
                  QuoteTopPage := QuoteLines - 5;
                  QuoteCurLine := 5;
                End;

                UpdateWindow;
              End;
        #80 : If QuoteTopPage + QuoteCurLine < QuoteLines Then Begin
                If QuoteCurLine = 5 Then Begin
                  Inc (QuoteTopPage);
                  UpdateWindow;
                End Else Begin
                  UpdateBar(False);
                  Inc (QuoteCurLine);
                  UpdateBar(True);
                End;
              End;
        #77,
        #81 : Begin
                If QuoteLines <= 6 Then
                  QuoteCurLine := QuoteLines - QuoteTopPage
                Else
                If QuoteTopPage + 6 < QuoteLines - 6 Then
                  Inc (QuoteTopPage, 6)
                Else Begin
                  QuoteTopPage := QuoteLines - 5;
                  QuoteCurLine := 5;
                End;

                UpdateWindow;
              End;
      End;
    End Else
      Case Ch of
        #27 : Break;
        #13 : If (TotalLine < mysMaxMsgLines) and (Not NoMore) Then Begin
                Added := True;

                If QuoteTopPage + QuoteCurLine = QuoteLines Then NoMore := True;

                InsertLine (CurLine);
                Session.Msgs.MsgText[CurLine] := QText[QuoteTopPage + QuoteCurLine];
                Inc (CurLine);

                Session.io.AnsiColor(tColor);

                Temp1  := WinEnd;
                WinEnd := Session.io.ScreenInfo[1].Y;
                If CurLine - Scroll + WinStart + 4 >= WinEnd Then Begin
                  ScreenRefreshFull;
                  Scroll := CurLine;
                End Else Begin
                  Dec (CurLine);
                  ScreenRefreshPart;
                  Inc (CurLine);
                  Inc (CurY);
                End;
                WinEnd := Temp1;

                If QuoteTopPage + QuoteCurLine < QuoteLines Then
                  If QuoteCurLine = 5 Then Begin
                    Inc (QuoteTopPage);
                    UpdateWindow;
                  End Else Begin
                    UpdateBar(False);
                    Inc (QuoteCurLine);
                    UpdateBar(True);
                  End;
              End;
      End;
  Until False;
  Session.io.OutFull('|16');
  If (CurLine < mysMaxMsgLines) And Added Then Inc(CurLine);
End;

Procedure Commands;
Var
  Ch  : Char;
  Str : String;
Begin
  Done := False;
  Save := False;

  Repeat
    Session.io.OutFull (Session.GetPrompt(354));
    Ch := Session.io.OneKey ('?ACHQRSTU', True);
    Case Ch of
      '?' : Session.io.OutFullLn (Session.GetPrompt(355));
      'A' : If Forced Then Begin
              Session.io.OutFull (Session.GetPrompt(307));
              Exit;
            End Else Begin
              Done := Session.io.GetYN(Session.GetPrompt(356), False);
              Exit;
            End;
      'C' : Exit;
      'H' : Begin
              Session.io.OutFile ('fshelp', True, 0);
              Exit;
            End;
      'Q' : Begin
              If Session.User.ThisUser.UseLBQuote Then
                QuoteWindow
              Else
                Quote;
              Exit;
            End;
      'R' : Exit;
      'S' : Begin
              Save := True;
              Done := True;
            End;
      'T' : Begin
              Session.io.OutFull(Session.GetPrompt(463));
              Str := Session.io.GetInput(60, 60, 11, Subj);
              If Str <> '' Then Subj := Str;
              Session.io.PromptInfo[2] := Subj;
              Exit;
            End;
      'U' : Begin
              Session.Msgs.MessageUpload(CurLine);
              TotalLine := CurLine;
              Exit;
            End;
    End;
  Until Done;
End;

Procedure keyPageUp;
Begin
  If CurLine > 1 Then Begin
    If LongInt(CurLine - (WinEnd - WinStart)) >= 1 Then
      Dec (CurLine, (WinEnd - WinStart)) {scroll one page up}
    Else
      CurLine := 1;
    ScreenRefreshFull;
  End;
End;

Procedure keyPageDown;
Begin
  If CurLine < TotalLine Then Begin

    If CurLine + (WinEnd - WinStart) <= TotalLine Then
      Inc (CurLine, (WinEnd - WinStart))
    Else
      CurLine := TotalLine;

    ScreenRefreshFull;
  End;
End;

Procedure keyEnd;
Begin
  CurX := Length(Session.Msgs.MsgText[CurLine]) + 1;

  If CurX > WrapPos Then CurX := WrapPos + 1;

  UpdatePosition;
End;

Var
  A : Integer;
Begin
  QuoteCurLine := 0;
  QuoteTopPage := 1;
  CurLine      := Lines;

  If Lines = 0 Then CurLine := 1;

  Done      := False;
  CurX      := 1;
  CurY      := WinStart;
  TotalLine := CurLine;

  Dec (WrapPos);

  FillChar(Session.Msgs.MsgText, SizeOf(Session.Msgs.MsgText), #0);

  FullReDraw;

  Session.io.AllowArrow := True;

  Repeat
    Ch := Session.io.GetKey;

    If Session.io.IsArrow Then Begin
      Case Ch of
        #71 : Begin
                CurX := 1;
                UpdatePosition;
              End;
        #72 : keyUpArrow(False);
        #73 : keyPageUp;
        #75 : keyLeftArrow;
        #77 : keyRightArrow;
        #79 : keyEnd;
        #80 : keyDownArrow;
        #81 : keyPageDown;
        #82 : ToggleInsert(True);
        #83 : If CurX <= Length(Session.Msgs.MsgText[CurLine]) Then Begin
                Delete (Session.Msgs.MsgText[CurLine], CurX, 1);
                Print (Copy(Session.Msgs.MsgText[CurLine], CurX, Length(Session.Msgs.MsgText[CurLine])) + ' ');
                UpdatePosition;
              End Else
              If CurLine < TotalLine Then
                If (Session.Msgs.MsgText[CurLine] = '') and (TotalLine > 1) Then Begin
                  DeleteLine (CurLine);
                  ScreenRefreshPart;
                End Else
                If TotalLine > 1 Then
                  If Length(Session.Msgs.MsgText[CurLine]) + Length(Session.Msgs.MsgText[CurLine + 1]) <= WrapPos Then Begin
                    Session.Msgs.MsgText[CurLine] := Session.Msgs.MsgText[CurLine] + Session.Msgs.MsgText[CurLine + 1];
                    DeleteLine (CurLine + 1);
                    ScreenRefreshPart;
                  End Else
                    For A := Length(Session.Msgs.MsgText[CurLine + 1]) DownTo 1 Do
                      If (Session.Msgs.MsgText[CurLine + 1][A] = ' ') and (Length(Session.Msgs.MsgText[CurLine]) + A <= WrapPos) Then Begin
                        Session.Msgs.MsgText[CurLine] := Session.Msgs.MsgText[CurLine] + Copy(Session.Msgs.MsgText[CurLine + 1], 1, A - 1);
                        Delete (Session.Msgs.MsgText[CurLine + 1], 1, A);
                        ScreenRefreshPart;
                      End;
      End;
    End Else
    Case Ch of
      ^A  : Begin
              Done := True;
              Save := False;
            End;
      ^B  : FullReDraw;
      ^D  : keyRightArrow;
      ^E  : keyUpArrow(False);
      ^F  : Begin
              CurX := 1;
              UpdatePosition;
            End;
      ^G  : keyEnd;
      ^H  : keyBackspace;
      ^I  : If CurX <= WrapPos Then Begin
              Repeat
                If (CurX < WrapPos) and (CurX = Length(Session.Msgs.MsgText[CurLine]) + 1) Then
                  Session.Msgs.MsgText[CurLine] := Session.Msgs.MsgText[CurLine] + ' ';

                Inc (CurX);
              Until (CurX MOD 5 = 0) or (CurX = WrapPos);

              UpdatePosition;
            End;
      ^J  : Begin
              Session.Msgs.MsgText[CurLine] := '';

              CurX := 1;

              UpdatePosition;

              Session.io.AnsiClrEOL;
            End;
      ^K  : ; // cuttext
      ^L,
      ^M  : Begin
              Session.io.PurgeInputBuffer;
              keyEnter;
            End;
      ^N  : keyPageDown;
      ^O  : Begin
              Session.io.OutFile('fshelp', True, 0);
              FullReDraw;
            End;
      ^P  : keyPageUp;
      ^Q  : Begin
              If Session.User.ThisUser.UseLBQuote Then
                QuoteWindow
              Else
                Quote;

              FullReDraw;
            End;
      ^R  : ; // paste
      ^T  : If CurX > 1 Then Begin
              While (CurX > 1) and (Session.Msgs.MsgText[CurLine][CurX] <> ' ') Do Dec(CurX);
              While (CurX > 1) and (Session.Msgs.MsgText[CurLine][CurX] =  ' ') Do Dec(CurX);
              While (CurX > 1) and (Session.Msgs.MsgText[CurLine][CurX] <> ' ') Do Dec(CurX);

              If CurX > 1 Then Inc (CurX);

              UpdatePosition;
            End;
      ^U  : Begin
              While CurX < Length(Session.Msgs.MsgText[CurLine]) + 1 Do Begin
                Inc (CurX);

                If Session.Msgs.MsgText[CurLine][CurX] = ' ' Then Begin
                  If CurX < Length(Session.Msgs.MsgText[CurLine]) + 1 Then Inc(CurX);
                  Break;
                End;
              End;

              UpdatePosition;
            End;
      ^V  : ToggleInsert (True);
      ^W  : ; // delete word left
      ^X  : keyDownArrow;
      ^Y  : Begin
              DeleteLine (curline);
              ScreenRefreshPart;
            End;
      ^[  : Begin
              Commands;

              If (Not Save) and (Not Done) Then FullReDraw;

              Session.io.AllowArrow := True;
            End;
      #32..
      #254: Begin
              If Length(Session.Msgs.MsgText[CurLine]) >= WrapPos Then begin
                If TotalLine < MaxLines Then Begin
                  AddChar (Ch);
                  TextReformat;
                End;
              End Else
              If (CurX = 1) and (Ch = '/') Then Begin
                Commands;
                If (Not Save) and (Not Done) Then FullReDraw;
                Session.io.AllowArrow := True;
              End Else
                AddChar (Ch);
            End;
    End;
  Until Done;

  Session.io.AllowArrow := False;

  If Save Then Begin
    A := TotalLine;
    While (Session.Msgs.MsgText[A] = '') and (A > 1) Do Begin
      Dec(A);
      Dec(TotalLine);
    End;
    Lines := TotalLine;
  End;

  Result := (Save = True);

  Session.io.AnsiGotoXY (1, Session.User.ThisUser.ScreenSize);
End;

End.
