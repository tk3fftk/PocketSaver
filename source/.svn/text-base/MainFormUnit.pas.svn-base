unit MainFormUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, XPMan, ImgList, ComCtrls, ExtCtrls, ShellAPI, IniFiles, StdActns, ActnList, Menus, ToolWin, ActnMan,
  ActnCtrls, ActnMenus, XPStyleActnCtrls, GLDPNG, JPEG, gifimage, CommDlg, Clipbrd, Contnrs;

const
  // 画像サイズ
  ImageWidth = 128;
  ImageHeight = 112;

  // 最大画像数
  MaxImageNum = 30;

  // 開始Offset
  StartOffset = 8192;
  // いくつごとにデータがあるか
  DataCycleSize = 4096;

  // 順番データのOffset
  OrderValueOffset = $11B2;

const
  ExtLists: array [1..4] of string = (
    'png', 'gif', 'jpg', 'bmp');
type
  TOrderData = class
  private
    FImageIndex: Integer;
    FOrderValue: Integer;
  end;

  TMainForm = class(TForm)
    ImageListView: TListView;
    StatusBar1: TStatusBar;
    ImageList: TImageList;
    MenuImageList: TImageList;
    ActionManager: TActionManager;
    ActionToolBar: TActionToolBar;
    ActionMainMenuBar: TActionMainMenuBar;
    FileOpen: TFileOpen;
    FileSaveAs: TFileSaveAs;
    FileExit: TFileExit;
    EditCopy: TEditCopy;
    ShowRawDataAction: TAction;
    procedure ActionManagerUpdate(Action: TBasicAction; var Handled: Boolean);
    procedure ShowRawDataActionExecute(Sender: TObject);
    procedure EditCopyExecute(Sender: TObject);
    procedure FileSaveAsSaveDialogTypeChange(Sender: TObject);
    procedure ImageListViewDblClick(Sender: TObject);
    procedure FileOpenAccept(Sender: TObject);
    procedure FileSaveAsAccept(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ImageListViewCustomDrawItem(Sender: TCustomListView; Item: TListItem; State: TCustomDrawState;
      var DefaultDraw: Boolean);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private 宣言 }
    FImages: array [0..MaxImageNum - 1] of TBitmap;
    FSaveFileName: string;

    FImageOrderList: TObjectList;

    procedure WMDropFiles(var Msg: TWMDropFiles); message WM_DROPFILES;

    procedure LoadSettings;
    procedure SaveSettings;

    function GetImage(const aIndex: Integer): TBitmap;
    function SelectedImage: TBitmap;
    procedure UpdateImageListView;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    { Public 宣言 }
    // SRAMデータの読み込み
    procedure LoadFromSRAMFile(const aFileName: string);
    // 選択データをセーブ
    procedure SaveToFile(const aFileName: string);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  CameraAnalyzerUnit, VCLUtilsUnit;

procedure TMainForm.FormCreate(Sender: TObject);

  procedure MakeImages;
  var i: Integer;
  begin
    for i := Low(FImages) to High(FImages) do begin
      FImages[i] := TBitmap.Create;
      with FImages[i] do begin
        Width := ImageWidth;
        Height := ImageHeight;
      end;
    end
  end;

  procedure MakeImageOrderList;
  var i: Integer;
  begin
    FImageOrderList := TObjectList.Create;
    for i := 0 to MaxImageNum - 1 do
      FImageOrderList.Add(TOrderData.Create);
  end;

begin
  ImageList.Width := ImageWidth;
  ImageList.Height := ImageHeight;

  MakeImages;
  MakeImageOrderList;

  LoadSettings;

  Caption := Application.Title;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SaveSettings;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
  procedure FreeImages;
  var i: Integer;
  begin
    for i := Low(FImages) to High(FImages) do
      FreeAndNil(FImages[i]);
  end;
begin
  FreeAndNil(FImageOrderList);
  FreeImages;
end;

procedure TMainForm.CreateParams(var Params: TCreateParams);
begin
  inherited;

  // D & Dの許可
  Params.ExStyle := Params.ExStyle or WS_EX_ACCEPTFILES;
end;

// ドラッグアンドドロップ処理
procedure TMainForm.WMDropFiles(var Msg: TWMDropFiles);
var
  FileNum, i: Integer;
  Buffer: array [0..MAX_PATH - 1] of Char;
begin
  if 0 < Msg.Drop then begin
    FileNum := DragQueryFile(Msg.Drop, $FFFFFFFF, Buffer, MAX_PATH);

    for i := 0 to FileNum - 1 do begin
      DragQueryFile(Msg.Drop, i, Buffer, MAX_PATH);

      LoadFromSRAMFile(string(Buffer));

      Exit;
    end;

    DragFinish(Msg.Drop);
  end;
end;

function ImageOrderListCompare(Item1, Item2: Pointer): Integer;
begin
  Result := TOrderData(Item1).FOrderValue - TOrderData(Item2).FOrderValue;
end;


procedure TMainForm.LoadFromSRAMFile(const aFileName: string);
var
  Stream: TMemoryStream;
  Analyzer: TCameraAnalyzer;

  procedure AnalyzeImage(const Index: Integer; const Image: TBitmap);
  begin
    // 解析位置移動
    Stream.Position := StartOffset + DataCycleSize * Index;

    Analyzer.DestImage := Image;

    // 解析
    Analyzer.Analyze;

    // 16色に減色する
    Image.PixelFormat := pf4bit;
  end;

  procedure UpdateImageOrder;
  var
    i: Integer;
    Data: TOrderData;
    ByteData: Byte;
  begin
    Stream.Position := OrderValueOffset;
    for i := 0 to MaxImageNum - 1 do begin
      Data := TOrderData(FImageOrderList.Items[i]);
      Data.FImageIndex := i;

      // 順番データの読み込み
      if Stream.Read(ByteData, SizeOf(ByteData)) = SizeOf(ByteData) then
        Data.FOrderValue := ByteData
      else
        Data.FOrderValue := $FF;
    end;

    // 順番データにそって、ソート
    FImageOrderList.Sort(ImageOrderListCompare);
  end;

var
  i: Integer;
begin
  if aFileName = '' then
    Exit;

  Stream := TMemoryStream.Create;
  Analyzer := nil;
  try
    // とりあえず、一旦読み込み
    Stream.LoadFromFile(aFileName);

    // 解析器生成
    Analyzer := TCameraAnalyzer.Create;
    Analyzer.SourceStream := Stream;

    // 画像の解析と追加
    for i := 0 to MaxImageNum - 1 do
      AnalyzeImage(i, FImages[i]);

    UpdateImageOrder;
  finally
    FreeAndNil(Analyzer);
    FreeAndNil(Stream);
  end;

  FSaveFileName := aFileName;

  UpdateImageListView;

  // 最初の物を選択
  if 0 < ImageListView.Items.Count then
    ImageListView.ItemIndex := 0;
end;

procedure TMainForm.UpdateImageListView;

  procedure UpdateForRawData;
  var i: Integer;
  begin
    for i := 0 to MaxImageNum - 1 do
      ImageListView.Items.Add;
  end;

  procedure UpdateForOrderedData;
  var i: Integer;
  begin
    // 順番データで、無効なデータ($FF)が出るまで追加
    for i := 0 to MaxImageNum - 1 do begin
      if TOrderData(FImageOrderList.Items[i]).FOrderValue = $FF then
        Break;

      ImageListView.Items.Add;
    end
  end;

begin
  ImageListView.Clear;

  if ShowRawDataAction.Checked then
    UpdateForRawData
  else
    UpdateForOrderedData
end;


procedure TMainForm.SaveToFile(const aFileName: string);

  procedure SaveBMPToFile(
    const aImage: TBitmap; const aFileName: string);

    procedure SaveToGenerally(const GraphicClass: TGraphicClass);
    var Graphic: TGraphic;
    begin
      Graphic := GraphicClass.Create;
      try
        Graphic.Assign(aImage);
        Graphic.SaveToFile(aFileName);
      finally
        FreeAndNil(Graphic);
      end;
    end;

  var
    Ext: string;
  begin
    Ext := AnsiLowerCase(ExtractFileExt(aFileName));
    if Ext = '.bmp' then
      SaveToGenerally(TBitmap)
    else if Ext = '.png' then
      SaveToGenerally(TGLDPNG)
    else if Ext = '.jpg' then
      SaveToGenerally(TJPEGImage)
    else if Ext = '.gif' then
      SaveToGenerally(TGIFImage)
  end;

begin
  if ImageListView.ItemIndex < 0 then begin
    ShowMessage('画像を選択してください');
    Exit;
  end;

  SaveBMPToFile(SelectedImage, aFileName);
end;


procedure TMainForm.ImageListViewCustomDrawItem(
  Sender: TCustomListView; Item: TListItem; State: TCustomDrawState;
  var DefaultDraw: Boolean);

var
  ARect: TRect;

  procedure ClearRect;
  begin
    ImageListView.Canvas.Brush.Color := clWindow;
    ImageListView.Canvas.FillRect(ARect);
  end;

  procedure DrawSelectedArea;
  const Width = 3;
  var i: Integer;
  begin
    if not (cdsSelected in State) then Exit;

    with ImageListView.Canvas do begin
      Brush.Color := clHighlight;
      for i := 0 to Width - 1 do
        FrameRect(Rect(
          ARect.Left + i,
          ARect.Top + i,
          ARect.Right - i,
          ARect.Bottom - i));
    end;
  end;

  procedure DrawItemIndex;
  begin
    // Brush.Color, Font.Colorでは駄目なんだよなあ。何故……
    if cdsSelected in State then begin
      SetBkColor(ImageListView.Canvas.Handle, ColorToRGB(clHighlight));
      SetTextColor(ImageListView.Canvas.Handle, ColorToRGB(clWindow));
    end
    else begin
      SetBkColor(ImageListView.Canvas.Handle, ColorToRGB(clWindow));
      SetTextColor(ImageListView.Canvas.Handle, ColorToRGB(clWindowText));
    end;

    ImageListView.Canvas.TextOut(ARect.Left, ARect.Top, IntToStr(Item.Index + 1));
  end;

var
  ImageRect: TRect;
  Image: TBitmap;
begin
  ARect := Item.DisplayRect(drIcon);

  ClearRect;
  DrawSelectedArea;

  Image := GetImage(Item.Index);

  // 描画矩形の計算
  ImageRect.Left := Round(ARect.Left + (ARect.Right - ARect.Left - Image.Width) / 2);
  ImageRect.Right := ImageRect.Left + Image.Width;
  ImageRect.Top := Round(ARect.Top + (ARect.Bottom - ARect.Top - Image.Height) / 2);
  ImageRect.Bottom := ImageRect.Top + Image.Height;

  ImageListView.Canvas.CopyRect(
    ImageRect,
    Image.Canvas,
    Rect(0, 0, Image.Width, Image.Height));

  DrawItemIndex;
end;


procedure TMainForm.LoadSettings;

  procedure LoadFromIni;
  var
    Ini: TMemIniFile;
    Section: string;
  begin
    Ini := TMemIniFile.Create(ChangeFileExt(Application.ExeName, '.ini'));
    try
      Section := Self.Name;
      Left := Ini.ReadInteger(Section, 'Left', Left);
      Top := Ini.ReadInteger(Section, 'Top', Left);
      ClientWidth := Ini.ReadInteger(Section, 'ClientWidth', ClientWidth);
      ClientHeight := Ini.ReadInteger(Section, 'ClientHeight', ClientHeight);

      Section := 'Data';
      FSaveFileName := Ini.ReadString(Section, 'SaveFileName', FSaveFileName);
      ShowRawDataAction.Checked := Ini.ReadBool(Section, 'IsVisibleRawData', ShowRawDataAction.Checked);
    finally
      FreeAndNil(Ini);
    end;

  end;

begin
  LoadFromIni;

//  LoadFormFromFile(Self);
  LoadFromSRAMFile(FSaveFileName);
end;

procedure TMainForm.SaveSettings;

  procedure SaveToIni;
  var
    Ini: TMemIniFile;
    Section: string;
  begin
    Ini := TMemIniFile.Create(ChangeFileExt(Application.ExeName, '.ini'));
    try
      Section := Self.Name;
      Ini.WriteInteger(Section, 'Left', Left);
      Ini.WriteInteger(Section, 'Top', Left);
      Ini.WriteInteger(Section, 'ClientWidth', ClientWidth);
      Ini.WriteInteger(Section, 'ClientHeight', ClientHeight);

      Section := 'Data';
      Ini.WriteString(Section, 'SaveFileName', FSaveFileName);
      Ini.WriteBool(Section, 'IsVisibleRawData', ShowRawDataAction.Checked);

      Ini.UpdateFile;
    finally
      FreeAndNil(Ini);
    end;
  end;
begin
  SaveToIni;

//  SaveFormToFile(Self);
end;


procedure TMainForm.FileOpenAccept(Sender: TObject);
begin
  LoadFromSRAMFile(FileOpen.Dialog.FileName);
end;

procedure TMainForm.FileSaveAsAccept(Sender: TObject);
var AdditionalExt: string;
begin
  AdditionalExt := '.' + ExtLists[FileSaveAs.Dialog.FilterIndex];

  // 例: pngを選んでいて、hoge.pngでないなら、拡張子をくっつける
  if ExtractFileExt(FileSaveAs.Dialog.FileName) <> AdditionalExt then
    FileSaveAs.Dialog.FileName := FileSaveAs.Dialog.FileName + AdditionalExt;

  SaveToFile(FileSaveAs.Dialog.FileName);
end;

procedure TMainForm.ImageListViewDblClick(Sender: TObject);
begin
  if SelectedImage = nil then
    Exit;
    
  FileSaveAs.Execute;
end;

procedure TMainForm.FileSaveAsSaveDialogTypeChange(Sender: TObject);
begin
  FileSaveAs.Dialog.DefaultExt := ExtLists[FileSaveAs.Dialog.FilterIndex];
end;

procedure TMainForm.EditCopyExecute(Sender: TObject);
begin
  if SelectedImage = nil then
    Exit;
    
  Clipboard.Assign(SelectedImage);
end;


function TMainForm.GetImage(const aIndex: Integer): TBitmap;
begin
  if ShowRawDataAction.Checked then begin
    if (Low(FImages) <= aIndex) and (aIndex <= High(FImages)) then
      Result := FImages[aIndex]
    else
      Result := nil
  end
  else begin
    if (Low(FImages) <= aIndex) and (aIndex <= High(FImages)) and
        (TOrderData(FImageOrderList.Items[aIndex]).FOrderValue <> $FF) then
      Result := FImages[TOrderData(FImageOrderList.Items[aIndex]).FImageIndex]
    else
      Result := nil
  end;
end;

function TMainForm.SelectedImage: TBitmap;
begin
  Result := GetImage(ImageListView.ItemIndex);
end;

procedure TMainForm.ShowRawDataActionExecute(Sender: TObject);
begin
  UpdateImageListView;
end;


procedure TMainForm.ActionManagerUpdate(Action: TBasicAction; var Handled: Boolean);
var IsSelected: Boolean;
begin
  IsSelected := SelectedImage <> nil;

  FileSaveAs.Enabled := IsSelected;
  EditCopy.Enabled := IsSelected;
end;

end.
