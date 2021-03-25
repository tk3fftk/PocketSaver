unit CameraAnalyzerUnit;

interface

uses
  Classes, Graphics;
type
  TCameraAnalyzer = class
  public const
    BlockWidth = 8;
  private
    FSourceStream: TStream;
    FDestImage: TBitmap;
  public
    // 解析する
    procedure Analyze;

    // 解析元ストリーム
    property SourceStream: TStream read FSourceStream write FSourceStream;
    // 出力先イメージ
    property DestImage: TBitmap read FDestImage write FDestImage;
  end;

implementation

uses Windows;

procedure TCameraAnalyzer.Analyze;

  procedure AnalyzeBlock(const StartX, StartY: Integer);
  type
    TGBPixelTable = array [0..8 - 1] of Byte;

    function GetNextTable: TGBPixelTable;
    var
      i: Integer;
      ByteData: Byte;
    begin
      if FSourceStream.Read(ByteData, SizeOf(ByteData)) <> SizeOf(ByteData) then begin
        // 失敗
        for i := Low(Result) to High(Result) do
          Result[i] := 0;
        Exit;
      end;

      // 1バイトをビット列に置き換え
      // 例: $03 = 2#00000011
      for i := Low(Result) to High(Result) do
        Result[i] := (ByteData shr (High(Result) - i)) and 1
    end;

    function AddTable(const LowTable, HighTable: TGBPixelTable): TGBPixelTable;
    var
      i: Integer;
    begin
      for i := Low(Result) to High(Result) do
        Result[i] := HighTable[i] shl 1 + LowTable[i];
    end;
  var
    x, y: Integer;
    pDest: PLongWord;

    LowBit, HighBit, TotalBit: TGBPixelTable;
    Color: Byte;
  begin
    for y := 0 to BlockWidth - 1 do begin
      LowBit := GetNextTable;
      HighBit := GetNextTable;
      TotalBit := AddTable(LowBit, HighBit);

      pDest := FDestImage.ScanLine[StartY + y];
      Inc(pDest, StartX);
      for x := 0 to BlockWidth - 1 do begin
        Color := $FF - TotalBit[x] * $FF div 3;
        pDest^ := RGB(Color, Color, Color);
        Inc(pDest);
      end
    end;
  end;

var x, y: Integer;
begin
  DestImage.PixelFormat := pf32bit;
  
  for y := 0 to FDestImage.Height div BlockWidth - 1 do
    for x := 0 to FDestImage.Width div BlockWidth - 1 do
      AnalyzeBlock(x * BlockWidth, y * BlockWidth);
end;

end.
