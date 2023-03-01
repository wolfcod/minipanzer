/*
 * credits go to andreas n. from 
 * www.greyhat.ch who coded this class.
 * 
 *
 * version : 0.2
 * changes : 2009.07.05 - fixed a bug in the close method.
 *
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

module peinfo;



private import std.stdio;
private import std.string;
private import std.c.string;
private import std.c.windows.windows;

class PEInfo
{
  align struct IMAGE_EXPORT_DIRECTORY 
  {
    DWORD Characteristics;
    DWORD TimeDateStamp;
    WORD MajorVersion;
    WORD MinorVersion;
    DWORD Name;
    DWORD Base;
    DWORD NumberOfFunctions;
    DWORD NumberOfNames;
    DWORD AddressOfFunctions;
    DWORD AddressOfNames;
    DWORD AddressOfNameOrdinals;
  }


  align struct IMAGE_SECTION_HEADER 
  {
    BYTE Name[8];

    DWORD VirtualSize; /* ... and PhysicalAddress (Misc stuff) */
    DWORD VirtualAddress;
    DWORD SizeOfRawData;
    DWORD PointerToRawData;
    DWORD PointerToRelocations;
    DWORD PointerToLinenumbers;
    WORD NumberOfRelocations;
    WORD NumberOfLinenumbers;
    DWORD Characteristics;
  }

	
  align(1) struct IMAGE_THUNK_DATA32 
  {
    DWORD FunctionOrOrdinal;
  }


  align(1) struct IMAGE_IMPORT_DESCRIPTOR 
  {
    DWORD CharacteristicsOrOrdinalFirstThunk;
    DWORD TimeDateStamp;
    DWORD ForwarderChain;
    DWORD Name;
    DWORD FirstThunk;
  }


  struct MyIMAGE_IMPORT_DESCRIPTOR 
  {
    DWORD CharacteristicsOrOrdinalFirstThunk;
    DWORD TimeDateStamp;
    DWORD ForwarderChain;
    char []Name;
    DWORD FirstThunk;
  }


  align(1) struct IMAGE_IMPORT_BY_NAME 
  {
    WORD Hint;
    BYTE Name[1];
  } 


  align (1) struct IMAGE_DOS_HEADER
  {
    WORD e_magic;
    WORD e_cblp;
    WORD e_cp;
    WORD e_crlc;
    WORD e_cparhdr;
    WORD e_minalloc;
    WORD e_maxalloc;
    WORD e_ss;
    WORD e_sp;
    WORD e_csum;
    WORD e_ip;
    WORD e_cs;
    WORD e_lfarlc;
    WORD e_ovno;
    WORD e_res[4];
    WORD e_oemid;
    WORD e_oeminfo;
    WORD e_res2[10];
    LONG e_lfanew;
  }


  align(1) struct IMAGE_DATA_DIRECTORY 
  {
    DWORD VirtualAddress;
    DWORD Size;
  }


  align(1) struct IMAGE_OPTIONAL_HEADER 
  {
    WORD Magic;
    BYTE MajorLinkerVersion;
    BYTE MinorLinkerVersion;
    DWORD SizeOfCode;
    WORD SizeOfInitializedData;
    DWORD SizeOfUninitializedData;
    DWORD AddressOfEntryPoint;
    DWORD BaseOfCode;
    DWORD BaseOfData;
    DWORD ImageBase;
    DWORD SectionAlignment;
    DWORD FileAlignment;
    WORD MajorOperatingSystemVersion;
    WORD MinorOperatingSystemVersion;
    WORD MajorImageVersion;
    WORD MinorImageVersion;
    WORD MajorSubsystemVersion;
    WORD MinorSubsystemVersion;
    DWORD Reserved1;
    DWORD SizeOfImage;
    DWORD SizeOfHeaders;
    DWORD CheckSum;
    WORD Subsystem;
    WORD DllCharacteristics;
    DWORD SizeOfStackReserve;
    DWORD SizeOfStackCommit;
    DWORD SizeOfHeapReserve;
    DWORD SizeOfHeapCommit;
    DWORD LoaderFlags;
    DWORD NumberOfRvaAndSizes;
    IMAGE_DATA_DIRECTORY DataDirectory[16]; /* IMAGE_NUMBEROF_DIRECTORY_ENTRIES = 16 */
  }


  align(1) struct IMAGE_FILE_HEADER 
  {
    WORD Machine;
    WORD NumberOfSections;
    DWORD TimeDateStamp;
    DWORD PointerToSymbolTable;
    DWORD NumberOfSymbols;
    WORD SizeOfOptionalHeader;
    WORD Characteristics;
  }


  align (1) struct IMAGE_NT_HEADERS 
  {
    DWORD Signature;
    IMAGE_FILE_HEADER FileHeader;
    IMAGE_OPTIONAL_HEADER OptionalHeader;
  }


  align (1) struct MyExports
  {
    char []Name;
    DWORD AddressOfFunction;
    DWORD AddressOfFunctionNow; /* Pointes to the start of the function now (when the file is mapped). */
    DWORD AddressOfFunctionRVA;
  }



	
  const IMAGE_DOS_SIGNATURE = 0x5A4D;
  const IMAGE_NT_SIGNATURE = 0x4550;
  const IMAGE_DIRECTORY_ENTRY_IMPORT = 0x1;
  const IMAGE_DIRECTORY_ENTRY_EXPORT = 0x0;

  private void *fd, fm, map;
  private IMAGE_IMPORT_DESCRIPTOR *ImpDesc;
  private IMAGE_THUNK_DATA32 *Thunk;
  private IMAGE_THUNK_DATA32 *OrigThunk;
  private LONG Ordinal, IATEntry=0;
  private IMAGE_IMPORT_BY_NAME *ImportByName;



  public IMAGE_DOS_HEADER *Dos;
  public IMAGE_NT_HEADERS *Nt;
  public LONG SectionBegin;
  public IMAGE_SECTION_HEADER *SectionHdr; 
  public MyIMAGE_IMPORT_DESCRIPTOR ImportDescriptor;
  public IMAGE_EXPORT_DIRECTORY *Export;
  public MyExports Exports;
  public char[] FunctionName;
  public int FunctionOrdinal;






		
  public int OpenPeFile(char []name)
  {
    fd = CreateFileA(cast(char*)name, GENERIC_READ, FILE_SHARE_READ, cast(SECURITY_ATTRIBUTES*)0,
			OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, cast(HANDLE)0);
				
    if(cast(HANDLE)fd == cast(HANDLE)INVALID_HANDLE_VALUE)
    {
	return 1;	
    }

    fm = CreateFileMappingA(cast(HANDLE)fd, cast(SECURITY_ATTRIBUTES*)0, PAGE_READONLY, 0, 0, cast(char*)0);
    if(cast(int)fm == 0)
    {
      CloseHandle(cast(HANDLE)fd);
      return 2;	
    }

    map = MapViewOfFile(cast(HANDLE)fm, FILE_MAP_READ, 0, 0, 0);
    if(cast(int)map == 0)
    {
      CloseHandle(cast(HANDLE)fd);
      CloseHandle(cast(HANDLE)fm);
      return 3;	
    }

    Dos = cast(IMAGE_DOS_HEADER*)map;
    Nt = cast(IMAGE_NT_HEADERS*)(map + Dos.e_lfanew);
    SectionBegin = cast(LONG)(map + Dos.e_lfanew + IMAGE_NT_HEADERS.sizeof); //248 = sizeof IMAGE_NT_HEADERS

    //Export = cast(IMAGE_EXPORT_DIRECTORY*)(this.GetDataDirectoryExportRVA() + Nt.OptionalHeader.ImageBase);
    Export = cast(IMAGE_EXPORT_DIRECTORY*)(RvaToOffset(this.GetDataDirectoryExportRVA()) + cast(LONG)this.map);

    return 0;
  }
	
		
  public LONG GetImageBase()
  {
    return Nt.OptionalHeader.ImageBase;
  }

  public char[] NextSectionHeader(int index)
  {
    SectionHdr = cast(IMAGE_SECTION_HEADER*)( (cast(LONG)Nt + IMAGE_NT_HEADERS.sizeof) + (IMAGE_SECTION_HEADER.sizeof*index));				

    return (cast(char[])SectionHdr.Name)[0..8].dup;
  }



  public LONG GetDataDirectoryImportRVA()
  {
    return Nt.OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT].VirtualAddress;
  }


  public LONG GetDataDirectoryImportSize()
  {
    return Nt.OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT].Size;
  }


  public LONG GetDataDirectoryExportRVA()
  {
    return Nt.OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress;
  }

	
  public LONG GetDataDirectoryExportSize()
  {
    return Nt.OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT].Size;
  }


  public bool IsValid()
  {
    if(Dos.e_magic == IMAGE_DOS_SIGNATURE && Nt.Signature == IMAGE_NT_SIGNATURE)
      return true;
    else
      return false;
  }


  public int GetNumberOfSections()
  {
    return cast(int)Nt.FileHeader.NumberOfSections;
  }
		
		
		
  public LONG RvaToOffset(LONG RVA)
  {
    int nSections = cast(int)Nt.FileHeader.NumberOfSections;
    IMAGE_SECTION_HEADER *SectionTable = cast(IMAGE_SECTION_HEADER*)SectionBegin;
    IMAGE_SECTION_HEADER *Current = null;
    LONG result;
	
    for(int i=0; i < nSections; i++)
    {
      Current = cast(IMAGE_SECTION_HEADER*)(cast(LONG)SectionTable + i * IMAGE_SECTION_HEADER.sizeof);
      if(RVA >= (Current.VirtualAddress) && RVA <= (Current.VirtualAddress + Current.VirtualSize))
      {
        result = RVA + Current.PointerToRawData - Current.VirtualAddress;
        return result;
      }
    }

    return 0;
  }



  public void ImportFunctionStart()
  {
    Thunk = cast(IMAGE_THUNK_DATA32*)(cast(LONG)Dos + RvaToOffset(ImpDesc.FirstThunk));
    OrigThunk = Thunk;

    if(ImpDesc.CharacteristicsOrOrdinalFirstThunk != 0)
    {
      OrigThunk = cast(IMAGE_THUNK_DATA32*)(cast(LONG)Dos + RvaToOffset(ImpDesc.CharacteristicsOrOrdinalFirstThunk));
    }
    IATEntry = 0;
  }
		
  public bool ImportGetNextFunction()
  {
    if(OrigThunk.FunctionOrOrdinal <= 0)
    {
      return false;		
    }

    Ordinal = 0;
    if(OrigThunk.FunctionOrOrdinal >= 0x80000000)
    {
      Ordinal = (OrigThunk.FunctionOrOrdinal - 0x80000000);
    } else if(Thunk.FunctionOrOrdinal >= 0x80000000) {
      Ordinal = (Thunk.FunctionOrOrdinal - 0x80000000);
    } else {
      ImportByName = cast(IMAGE_IMPORT_BY_NAME*)(cast(LONG)Dos + RvaToOffset(Thunk.FunctionOrOrdinal));
      char *p = cast(char*)ImportByName.Name;
      FunctionName = p[0 .. std.c.string.strlen(p)];
    }

    if(Ordinal)
    {
      FunctionOrdinal = Ordinal;
      Ordinal = 0;
    }

    Thunk++;
    OrigThunk++;

    if(cast(int)OrigThunk == 0)
      OrigThunk = Thunk;

    IATEntry++;

    return true;
  }

		
  //This method *must* be called before ImportGetNextModule()!
  public void ImportModuleStart()
  {
    ImpDesc = cast(IMAGE_IMPORT_DESCRIPTOR*)(cast(LONG)Dos + RvaToOffset(Nt.OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT].VirtualAddress));

    //init
    ImpDesc--;
  }


  public bool ImportGetNextModule()
  {
    if((++ImpDesc).Name <= 0) 
      return false;

    char *p = (cast(char*)Dos + RvaToOffset(ImpDesc.Name));

    ImportDescriptor.Name = p[0 .. std.c.string.strlen(p)];
    ImportDescriptor.FirstThunk = ImpDesc.FirstThunk;
    ImportDescriptor.CharacteristicsOrOrdinalFirstThunk = ImpDesc.CharacteristicsOrOrdinalFirstThunk;
    ImportDescriptor.ForwarderChain = ImpDesc.ForwarderChain;
    ImportDescriptor.TimeDateStamp = ImpDesc.TimeDateStamp;						

    return true;
  }


  public char[] ExportGetInternalName()
  {
    char *p = (cast(char*)this.map + RvaToOffset(Export.Name));
    return p[0 .. std.c.string.strlen(p)];
  }


  public int ExportGetNumberOfFunctions()
  {
    return Export.NumberOfFunctions;
  }


  public int ExportGetNumberOfNames()
  {
    return Export.NumberOfNames;
  }


  public void ExportGetEntry(int index)
  {
    DWORD *pp = cast(DWORD*)(this.map + RvaToOffset(Export.AddressOfNames)+(index*4));
    char *p = cast(char*)(this.map + RvaToOffset(*pp));

    Exports.Name = p[0 .. std.c.string.strlen(p)];

    pp = cast(DWORD*)(this.map + cast(DWORD)RvaToOffset(Export.AddressOfFunctions)+(index*4));

    DWORD *p_dword = cast(DWORD*)(*pp + this.GetImageBase());
    Exports.AddressOfFunction = cast(DWORD)p_dword;
    Exports.AddressOfFunctionRVA = *pp;

    pp = cast(DWORD*)(this.map + cast(DWORD)RvaToOffset(Export.AddressOfFunctions)+(index*4));
    p_dword = cast(DWORD*)(cast(DWORD)RvaToOffset(*pp) + this.map);
    Exports.AddressOfFunctionNow = *p_dword;		
  }


  public void Close()
  {
    CloseHandle(cast(HANDLE) map);
    CloseHandle(cast(HANDLE) fm);
    CloseHandle(cast(HANDLE) fd);	

  }
}