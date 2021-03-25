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
    // ��͂���
    procedure Analyze;

    // ��͌��X�g���[��
    property SourceStream: TStream read FSourceStream write FSourceStream;
    // �o�͐�C���[�W
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
        // ���s
        for i := Low(Result) to High(Result) do
          Result[i] := 0;
        Exit;
      end;

      // 1�o�C�g���r�b�g��ɒu������
      // ��: $03 = 2#00000011
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
