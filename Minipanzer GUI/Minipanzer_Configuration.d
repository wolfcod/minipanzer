/*
 *
 *
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */





module Panzer.Config_Modul;


private import std.ctype;
private import std.date;
private import std.regexp;
private import std.c.windows.windows;
private import dfl.all;
private import dfl.internal.utf;
private import std.file;
private import std.utf;
private import std.stream;


/*
 * own data types
 *
 */

align  (2) struct sFileData 
{
  char lDataHeader[12];
  char lName[40];
  int lSize;
}


align(2) struct ICONDIRENTRY
{
  BYTE bWidth;               // Width of the image
  BYTE bHeight;              // Height of the image (times 2)
  BYTE bColorCount;          // Number of colors in image (0 if >=8bpp)
  BYTE bReserved;            // Reserved
  WORD wPlanes;              // Color Planes
  WORD wBitCount;            // Bits per pixel
  DWORD dwBytesInRes;         // how many bytes in this resource?
  DWORD dwImageOffset;        // where in the file is this image
}


align(2) struct ICONDIR
{
  WORD idReserved;   // Reserved
  WORD idType;       // resource type (1 for icons)
  WORD idCount;      // how many images?
  ICONDIRENTRY *idEntries; // the entries for each image
} 


align(2) struct ICONSIDEINFO
{
  int sIndex;
  char *sStartAddress;
  int sDataLength;
}


align(2) struct GROUPICON
{
  WORD Reserved1;       // reserved, must be 0
  WORD ResourceType;    // type is 1 for icons
  WORD ImageCount;      // number of icons in structure (1)
  BYTE Width;           // icon width (32)
  BYTE Height;          // icon height (32)
  BYTE Colors;          // colors (0 means more than 8 bits per pixel)
  BYTE Reserved2;       // reserved, must be 0
  WORD Planes;          // color planes
  WORD BitsPerPixel;    // bit depth
  DWORD ImageSize;      // size of structure
  WORD ResourceID;      // resource ID
}


align(2) struct ICONIMAGE
{
  UINT Width, Height, Colors; // Width, Height and bpp
  LPBYTE lpBits;                // ptr to DIB bits
  DWORD dwNumBytes;            // how many bytes?
  LPBITMAPINFO lpbi;            // ptr to header
  LPBYTE lpXOR;                 // ptr to XOR image bits
  LPBYTE lpAND;                 // ptr to AND image bits
}





/*
 * global constants
 *
 */


const char[] gVersion = "0.1";
const char[] gMainFormTitle = "Minipanzer " ~ gVersion;
const char[] gTitleDataHeader  = "DATAHEADER";

const int DEBUG = 1;
const int MAX_BUF_SIZE = 1024;
const int SBOX_SIZE = 1024;

/*
 * external functions
 *
 */

extern(Windows) 
{

  template MAKEINTRESOURCE_T (WORD i)
  {
    const LPTSTR MAKEINTRESOURCE_T = cast(LPTSTR)(i);
  }


  LPSTR MAKEINTRESOURCE(WORD i)
  {
    return cast(LPSTR)(i);
  }


  HANDLE CreateFileA(LPCSTR, DWORD, DWORD, LPSECURITY_ATTRIBUTES, DWORD, DWORD, HANDLE);
  HINSTANCE ShellExecuteA(HWND, LPCTSTR, LPCTSTR, LPCTSTR, LPCTSTR, INT);
  HANDLE BeginUpdateResourceA(LPCSTR, BOOL);
  HRSRC FindResourceA(HMODULE,LPCSTR,LPCSTR);
  HGLOBAL LoadResource(HINSTANCE,HRSRC);
  DWORD SizeofResource(HINSTANCE,HRSRC);
  BOOL UpdateResourceA(HANDLE, LPCSTR, LPCSTR, WORD, PVOID, DWORD);
  BOOL EndUpdateResourceA(HANDLE, BOOL);
  PVOID HeapAlloc(HANDLE, DWORD, DWORD);
  HANDLE GetProcessHeap(); 
  BOOL HeapFree(HANDLE, DWORD, LPVOID);
  HINSTANCE LoadLibraryA(LPCSTR);



  alias CreateFileA CreateFile;
  alias BeginUpdateResourceA BeginUpdateResource;
  alias UpdateResourceA UpdateResource;
  alias EndUpdateResourceA EndUpdateResource;
  alias FindResourceA FindResource;
  alias MAKEINTRESOURCEA MAKEINTRESOURCE;
  alias ulong UINT_PTR, ULONG_PTR, HANDLE_PTR;
  alias LoadLibraryA LoadLibrary;
  alias DWORD SIZE_T;
  
  const RT_ICON         = MAKEINTRESOURCE_T!(3);
  const RT_GROUP_ICON   = MAKEINTRESOURCE_T!(14);
}



/*
 * output directories
 *
 */

const char[] gPackagesOutputDir = "PACKAGES\\";
const char[] gStubPath = "MINIPANZER\\Binder_Stub.exe";
const char[] gDefaultEntertainer = "MINIPANZER\\Default_Entertainer.jpg";
const char[] gPayload = "MINIPANZER\\Minipanzer_Raw.exe";

/*
 * important global functions
 *
 */

char[] UTF8Compliance(void[] pString)
{
  char[] lReturnString;
  ubyte[] lUTF8BOM;
  
  lUTF8BOM = ByteOrderMarks[BOM.UTF8];
  
  if(pString.length >= lUTF8BOM.length && cast(ubyte[])pString[0 .. lUTF8BOM.length] == lUTF8BOM)
    return cast(char[])pString[lUTF8BOM.length .. pString.length];
        
  lReturnString = cast(char[])pString;
  try
  {
    // Check if valid UTF-8 or ASCII.
    std.utf.validate(lReturnString);
  } catch {
    // Fall back to ANSI.
     lReturnString = dfl.internal.utf.fromAnsi(lReturnString.ptr, lReturnString.length);
  } 
  

  if (find(lReturnString, "[^\r]{1}\n[^\r]{1}") >= 0)
    lReturnString = sub(lReturnString, "\n", "\r\n", "g");
  else if (find(lReturnString, "[^\n]{1}\r[^\n]{1}") >= 0)
    lReturnString = sub(lReturnString, "\r", "\r\n", "g");  
    
  return(lReturnString);	
}




public char[] selectFile(char[] pFileFilter)
{
  char[] lRetVal;
  OpenFileDialog ofd;
  
  ofd = new typeof(ofd);
  ofd.title = "Open Image";
  ofd.filter = pFileFilter;

	
  if(DialogResult.OK == ofd.showDialog())
    lRetVal = ofd.fileName;
  
  return(lRetVal);
}


