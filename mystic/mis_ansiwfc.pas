// ====================================================================
// Mystic BBS Software               Copyright 1997-2013 By James Coyle
// ====================================================================
//
// This file is part of Mystic BBS.
//
// Mystic BBS is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Mystic BBS is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Mystic BBS.  If not, see <http://www.gnu.org/licenses/>.
//
// ====================================================================

Procedure DrawStatusScreen;
Const
  IMAGEDATA_WIDTH=80;
  IMAGEDATA_DEPTH=25;
  IMAGEDATA_LENGTH=518;
  IMAGEDATA : array [1..518] of Char = (
     #1,#23,' ','M','y','s','t','i','c',' ','I','n','t','e','r','n','e',
    't',' ','S','e','r','v','e','r',#25,#30, #0,'t','e','l','n','e','t',
    '/','s','m','t','p','/','p','o','p','3','/','f','t','p','/','n','n',
    't','p',' ',#24, #8,#16,#26,'O','�',#24,'�', #1,'�',' ', #7,'C','o',
    'n','n','e','c','t','i','o','n','s',' ', #1,#26,'%','�','�', #8,'�',
     #1,'�',' ', #7,'S','t','a','t','i','s','t','i','c','s',' ', #1,#26,
     #9,'�','�', #8,'�',#24,'�', #1,'�',#25,'2','�', #8,'�', #1,'�',#25,
    #21,'�', #8,'�',#24,'�', #1,'�',#25,'2','�', #8,'�', #1,'�',#25, #5,
     #7,'P','o','r','t', #8,':',#25,#10, #1,'�', #8,'�',#24,'�', #1,'�',
    #25,'2','�', #8,'�', #1,'�',#25, #6, #7,'M','a','x', #8,':',#25,#10,
     #1,'�', #8,'�',#24,'�', #1,'�',#25,'2','�', #8,'�', #1,'�',#25, #3,
     #7,'A','c','t','i','v','e', #8,':',#25,#10, #1,'�', #8,'�',#24,'�',
     #1,'�',#25,'2','�', #8,'�', #1,'�',#25, #2, #7,'B','l','o','c','k',
    'e','d', #8,':',#25,#10, #1,'�', #8,'�',#24,'�', #1,'�',#25,'2','�',
     #8,'�', #1,'�',#25, #2, #7,'R','e','f','u','s','e','d', #8,':',#25,
    #10, #1,'�', #8,'�',#24,'�', #1,'�',#25,'2','�', #8,'�', #1,'�',#25,
     #4, #7,'T','o','t','a','l', #8,':',#25,#10, #1,'�', #8,'�',#24,'�',
     #1,'�',#25,'2','�', #8,'�', #1,'�',#25,#21,'�', #8,'�',#24,'�', #1,
    '�',#26,'2','�','�', #8,'�', #1,'�',#26,#21,'�','�', #8,'�',#24,#26,
    'O','�',#24,'�', #1,'�',' ', #7,'S','e','r','v','e','r',' ','S','t',
    'a','t','u','s',' ', #1,#26,'<','�','�', #8,'�',#24,'�', #1,'�',#25,
    'K','�', #8,'�',#24,'�', #1,'�',#25,'K','�', #8,'�',#24,'�', #1,'�',
    #25,'K','�', #8,'�',#24,'�', #1,'�',#25,'K','�', #8,'�',#24,'�', #1,
    '�',#25,'K','�', #8,'�',#24,'�', #1,'�',#25,'K','�', #8,'�',#24,'�',
     #1,'�',#25,'K','�', #8,'�',#24,'�', #1,'�',#25,'K','�', #8,'�',#24,
    '�', #1,'�',#26,'K','�','�', #8,'�',#24,#26,'O','�',#24,#23,' ', #1,
    'T','A','B','/','S','w','i','t','c','h',' ','W','i','n','d','o','w',
    #25, #2,' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',#25, #2,'S','P',
    'A','C','E','/','L','o','c','a','l',#25, #2,'A','L','T','-','K','/',
    'K','i','l','l',' ','U','s','e','r',#25, #2,'E','S','C','/','S','h',
    'u','t','d','o','w','n',' ',#24);
Begin
  Console.LoadScreenImage(ImageData, ImageData_Length, ImageData_Width, 1, 1);

  //Console.WriteXY (25, 1, 113, strPadC(mysVersionText, 30, ' '));

  Console.WriteXY (1, 25, 113, strPadC('SPACE/Local TELNET     TAB/Switch     ESC/Shutdown', 79, ' '));
End;
