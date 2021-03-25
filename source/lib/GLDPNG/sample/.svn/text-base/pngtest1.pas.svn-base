unit pngtest1;

//-----------------------------------------------
//      TGLDPNGのサンプルプログラムです。
//
//          適当に作ってあります。(^^;;
//-----------------------------------------------

interface

{$I taki.inc}

uses              
  Windows, Messages, SysUtils, Classes, Graphics, Controls,
  Forms, Dialogs, GLDPNG, ExtCtrls, StdCtrls, pngtest2;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Button1: TButton;
    Button2: TButton;
    RadioGroup1: TRadioGroup;
    RadioGroup2: TRadioGroup;
    RadioGroup3: TRadioGroup;
    CheckBox1: TCheckBox;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    Panel2: TPanel;
    ScrollBox1: TScrollBox;
    AlphaPanel: TScrollBox;
    PicImage: TImage;
    AlphaImage: TImage;
    CheckBox2: TCheckBox;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure PicImageProgress(Sender: TObject; Stage: TProgressStage;
      PercentDone: Byte; RedrawNow: Boolean; const R: TRect;
      const Msg: String);
  private
    FBGColor: TCOLORREF;
    FGamma: double;
    procedure DecodeEvt(sender: TObject; pbuf: pbyte; buflen,lineno: integer; password: string);
    procedure EncodeEvt(sender: TObject; pbuf: pbyte; buflen,lineno: integer; password: string);
    procedure PasswordEvt(sender: TObject; var password: string);
  public
    { Public 宣言 }
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

// 画像読み込み
procedure TForm1.Button1Click(Sender: TObject);
var
 png: TGLDPNG;
 alpha: TBitmap;

begin
 if OpenDialog1.Execute then
  begin
   png:=TGLDPNG.Create;
   alpha:=TBitmap.Create;
   // プログレス表示用フォーム表示
   Form2:=TForm2.Create(Application);
   Form2.label2.Caption:='Read Graphic File';
   Form2.Show;  Form2.Update;

   try
    // 拡張子をチェックする
    if ExtractFileExt(UpperCase(OpenDialog1.Filename))='.PNG' then
     // PNG
     with png do
     begin
      // 復号イベントを設定
      OnDecode:=DecodeEvt;
      OnPassword:=PasswordEvt;
      // プログレスイベントを設定
      OnProgress:=PicImage.OnProgress;
      // 読み込み
      LoadFromFile(OpenDialog1.FileName);

      // 背景色保存
      FBGColor:=BGColor;
      // ガンマ値保存
      FGamma:=Gamma;
      if AlphaChannel then
       // アルファチャネルがある場合は取得
       begin
        AlphaBitmapAssignTo(alpha);
        AlphaImage.Picture.Graphic:=alpha;
        AlphaPanel.Visible:=TRUE;
       end
      else
       // ない場合は無効にする
       begin
        AlphaPanel.Visible:=FALSE;
        AlphaImage.Picture.Assign(nil);
       end;
      PicImage.Picture.Assign(png);
     end
    else
     // その他
     begin
      FBGColor:=COLORREF(-1);
      FGamma:=0;
      AlphaPanel.Visible:=FALSE;
      AlphaImage.Picture.Assign(nil);
      PicImage.Picture.LoadFromFile(OpenDialog1.Filename);
     end;
   finally
    png.Free;
    alpha.Free;
    Form2.Free;
   end;
  end;
end;

// PNG 保存
procedure TForm1.Button2Click(Sender: TObject);
var
 png: TGLDPNG;
 bmp: TGraphic;
 flg: boolean;

const
 compre: array [0..3] of integer=(gplNone,gplDefault,gplSpeed,gplBest);

begin
 if (Assigned(PicImage.Picture.Graphic)) and (not PicImage.Picture.Graphic.Empty) then
  if SaveDialog1.Execute then
   begin
    flg:=FALSE;
    png:=TGLDPNG.Create;
    // プログレス表示用フォーム表示
    Form2:=TForm2.Create(Application);
    Form2.label2.Caption:='Write Graphic File';
    Form2.Show; Form2.Update;
    try
     // 表示されているイメージの管理クラスが知らないものならTbitmapあたりに変換
     if not ((PicImage.Picture.Graphic is TBitmap)
     ) then
      begin
       bmp:=TBitmap.Create;
       TBitmap(bmp).Assign(PicImage.Picture.Graphic);
       flg:=TRUE;
      end
     else
      bmp:=PicImage.Picture.Graphic;
     png.Assign(bmp);
     // オプション設定
     with png do
     begin
      // 圧縮タイプ設定
      CompressLevel:=compre[RadioGroup1.ItemIndex];
      // フィルタータイプ設定
      FilterType:=TGLDPNGFilterType(RadioGroup2.ItemIndex);
      // インタレース設定
      InterlaceType:=TGLDPNGInterlaceType(RadioGroup3.ItemIndex);
      // グレイスケール設定
      GrayScale:=CheckBox1.Checked;
      // アルファチャネルがあれば指定
      if Assigned(AlphaImage.Picture.Graphic) and (not AlphaImage.Picture.Graphic.Empty) then
       begin
        AlphaChannel:=TRUE;
        AlphaBitmap:=TBitmap(AlphaImage.Picture.Graphic);
       end;
      // 背景色設定
      BGColor:=FBGColor;
      // ガンマ値設定
      Gamma:=FGamma;
      // パスワードと暗号イベントを追加
      if CheckBox2.Checked then
       begin
        Password:='GLDPNG3 By Tarquin';
        OnEncode:=EncodeEvt;
       end;
      // プログレスイベントを設定して保存
      OnProgress:=PicImage.OnProgress;
      SaveToFile(SaveDialog1.FileName);
     end;
    finally
     if flg then bmp.Free;
     png.Free;
     Form2.Free;
    end;
   end;
end;

// 復号イベント（あくまで例でてきとーなものです）
procedure TForm1.DecodeEvt(sender: TObject; pbuf: pbyte; buflen,lineno: integer; password: string);
var
 i,st,mx,af,n: integer;
 pc: pchar;

begin
 mx:=length(password);
 pc:=pchar(password);
 st:=((lineno+3) and 2);
 if st>=mx then st:=st-mx;
 Inc(pc,st);
 af:=0;
 for i:=0 to Pred(buflen) do
 begin
  n:=pbuf^;
  pbuf^:=((pbuf^ xor af)+pbyte(pc)^) and $FF;
  af:=n;
  Inc(st); Inc(pc);
  if st>=mx then
   begin
    st:=0;
    pc:=pchar(password);
   end;
  Inc(pbuf);
 end;
end;


// 暗号イベント（あくまで例でてきとーなものです）
procedure TForm1.EncodeEvt(sender: TObject; pbuf: pbyte; buflen,lineno: integer; password: string);
var
 i,st,mx,af: integer;
 pc: pchar;

begin
 mx:=length(password);
 pc:=pchar(password);
 st:=((lineno+3) and 2);
 if st>=mx then st:=st-mx;
 Inc(pc,st);
 af:=0;
 for i:=0 to Pred(buflen) do
 begin
  af:=((pbuf^-pbyte(pc)^) and $FF) xor af;
  pbuf^:=af;
  Inc(st); Inc(pc);
  if st>=mx then
   begin
    st:=0;
    pc:=pchar(password);
   end;
  Inc(pbuf);
 end;
end;

// パスワードイベント これもてきとー
procedure TForm1.PasswordEvt(sender: TObject; var password: string);
begin
 password:='GLDPNG3 By Tarquin';
end;                                  

// プログレスイベント
procedure TForm1.PicImageProgress(Sender: TObject; Stage: TProgressStage;
  PercentDone: Byte; RedrawNow: Boolean; const R: TRect;
  const Msg: String);
begin
 with Form2 do
 begin
  label1.Caption:=inttostr(PercentDone)+'%';
  ProgressBar1.Position:=PercentDone;
  label1.Update;
  Application.ProcessMessages;
 end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
 OpenDialog1.InitialDir:=ExtractFileDir(Application.ExeName);
 OpenDialog1.Filter:='All|*.bmp;*.rle;*.dib;*.png|Bitmap File(*.bmp)|*.bmp;*.rle;*.dib|PNG File(*.png)|*.png';
 SaveDialog1.InitialDir:=ExtractFileDir(Application.ExeName);
 SaveDialog1.Filter:='PNG File(*.png)|*.png';
 FBGColor:=COLORREF(-1);
end;

end.
 