unit HeapChecker;
(***********************************************************

	HeapChecker

	クラスインスタンスや、GetMemで確保したヒープの開放し忘れを検出するユニット。


	使い方
		プロジェクトソース(*.dpr)の先頭に

			uses HeapChecker;

		と記述する。HeapCheckerの前に別のユニット名を指定してはいけない。
		プロジェクトソースの先頭で
		begin
			HeapChecker.OutputClassName := True;
			HeapChecker.DumpLeakMemory := True;
			...
		end;
		の二行を追加するとリークしたメモリのダンプと
		それがクラスであればクラス名を表示する。

	サンプル
		program HeapCheckerSample;

		uses
			HeapChecker,
			Forms,
			Unit1 in 'Unit1.pas' {Form1};

		{$R *.res}

		begin
			HeapChecker.OutputClassName := True;
			HeapChecker.DumpLeakMemory := True;

			Application.Initialize;
			Application.CreateForm(TForm1, Form1);
			Application.Run;
		end.

	注意事項
		Delphi6でパッチを適用せずに実行すると5個の開放し忘れが検出されるが、
		これはVCLのバグ。

***********************************************************)
interface

// 使用するヒープマネージャ
//{$define UseOriginalMemoryManager こっちは動作しない}
{$define UseWin32MemoryManager}

//{$DEFINE Release}
{$DEFINE DEBUG}
{$EXTENDEDSYNTAX ON} 
{$HINTS ON}
{$IOCHECKS ON}
{$OPENSTRINGS ON}
{$REALCOMPATIBILITY OFF}
{$TYPEDADDRESS ON}
{$VARSTRINGCHECKS ON}
{$WARNINGS ON}
{$STACKFRAMES OFF}
{$WRITEABLECONST OFF}

// 環境依存の警告をOFFにする
{$WARN UNIT_PLATFORM OFF}
{$WARN SYMBOL_PLATFORM OFF}
{$WARN SYMBOL_DEPRECATED OFF}

{$ifdef Release}
	// リリースビルド用の設定
	{$DEBUGINFO OFF} // OFFにするとコード補完機能が使えなくなる。
	{$LOCALSYMBOLS ON}
	{$REFERENCEINFO ON}
	{$OPTIMIZATION ON}
	{$OVERFLOWCHECKS OFF}
	{$RANGECHECKS OFF}
{$else}
	// デバッグビルド用の設定
	{$DEBUGINFO ON}
	{$OPTIMIZATION OFF}
	{$OVERFLOWCHECKS ON}
	{$RANGECHECKS ON}
{$endif}

var
	/// リークのチェックを無効にするフラグ
	DisabledChecking: Boolean;

	/// リークしているメモリ領域のダンプを出力する。
	DumpLeakMemory: Boolean;

	/// リークしている領域をクラスインスタンスとみなして、その名前を表示する。
	/// 危険!!判定を誤るとAccessViolationが発生する。その場合はOFFにする。
	OutputClassName: Boolean;

type
	TErrorReporter = object
	public
		constructor init;
		destructor done; virtual;
		function open: Boolean; virtual;
		procedure close; virtual;
		procedure output(s: string); virtual;
	end;

	TLogFileErrorReporter = object(TErrorReporter)
	private
		FHandle: THandle;
	public
		function open: Boolean; virtual;
		procedure close; virtual;
		procedure output(s: string); virtual;
	end;

// 出力をカスタマイズしたければ初期化済みカスタムオブジェクトのポインタを設定する。
var
	ErrorReporter: ^TErrorReporter;
	LogFileReporter: TLogFileErrorReporter;

implementation

// System, Windowsユニット以外を使ってはいけない
// 例外SysUtilsに依存するので使用禁止
uses
	Windows;

// ユーティリティ関数。Stringはヒープを使うのでエラーリポート時のみ使用すること。

function IntToStr(n: Integer): String;
begin
	Str(n, Result);
end;

procedure ShowMessage(msg: String);
begin
	MessageBox(0, PChar(msg), PChar(ParamStr(0)), MB_OK or MB_ICONERROR);
end;

function Min(a, b: Integer): Integer;
begin
	if a > b then Result := b else Result := a;
end;

{$ifdef UseOriginalMemoryManager}
// AllocMemCountを使ったチェック

procedure Initialize;
begin
	if AllocMemCount <> 0 then
	begin
		ShowMessage(
			'NtHeapCheckerの使い方が間違っています。'+sLineBreak+
			'プロジェクトソース(.dpr)の先頭でusesして下さい。');
		DisabledChecking := True;
		Halt(1);
	end;
end;

procedure Finalize;
begin
	if DisabledChecking then
		Exit;

	if AllocMemCount <> 0 then
		ShowMessage(IntToStr(AllocMemCount) + '個のヒープ領域が未開放です。');
end;
{$endif UseOriginalMemoryManager}

{$ifdef UseWin32MemoryManager}
// GlobalAlloc/Free/Reallocを使ったチェック
// さらにリンクリストの情報を持たせてリークした領域をダンプ出来るようにする。

// ヒープの先頭に付加する追加ヘッダ
type
	PHeapHeader = ^THeapHeader;
	PPHeapHeader = ^PHeapHeader;
	THeapHeader = record
		Prev: PHeapHeader;
		Next: PHeapHeader;
		Size: DWord;
		Boundary: PHeapHeader;
	end;

function HtoP(p: Pointer): Pointer;
begin
	Result := Pointer(DWord(p) + SizeOf(THeapHeader));
end;

function PtoH(p: Pointer): PHeapHeader;
begin
	Result := PHeapHeader(DWord(p) - SizeOf(THeapHeader));
end;

function PtoHSize(Size: Integer): Integer;
begin
	Result := Size + SizeOf(THeapHeader) + SizeOf(PHeapHeader);
end;

function HtoT(p: PHeapHeader): PPHeapHeader;
begin
	Result := PPHeapHeader(Integer(p) + Integer(p^.Size) + SizeOf(THeapHeader));
end;

var
	AllocMemCount: Integer;
	oldmm: TMemoryManager;
	Top: THeapHeader;
	DefaultErrorReporter: TErrorReporter;

function GetMem(Size : Integer) : Pointer;
var
	hh: PHeapHeader;
begin
	hh := PHeapHeader(GlobalAlloc(GMEM_FIXED, PToHSize(Size)));
	if hh <> nil then
	begin
		hh.Next := @Top;
		hh.Prev := Top.Prev;
		hh.Next.Prev := hh;
		hh.Prev.Next := hh;

		hh.Size := Size;
		hh.Boundary := hh;

		Result := HtoP(hh);
		HtoT(hh)^ := hh;

		Inc(AllocMemCount);
	end
	else
		Result := nil;
end;

function CheckHeap(P: Pointer): Boolean;
var
	hh: PHeapHeader;
begin
	hh := PtoH(p);
	
	Result := True;
	if hh.Boundary = hh then
		Exit;
	
	if HtoT(hh)^ = hh then
		Exit;

	Result := False;
	DebugBreak;
end;

function FreeMem(P : Pointer) : Integer;
var
	hh: PHeapHeader;
begin
	CheckHeap(P)
	;
	hh := PtoH(P);
	hh^.Prev^.Next := hh^.Next;
	hh^.Next^.Prev := hh^.Prev;

	Result:=GlobalFree(HGLOBAL(hh));
	if Result = 0 then
		Dec(AllocMemCount);
end;

function ReallocMem(P : Pointer; Size : Integer) : Pointer;
var
	hh: PHeapHeader;
begin
	// Pはユーザーレベルのアドレスで渡される
	CheckHeap(P);
	hh := PtoH(P);
	Result:=Pointer(GlobalRealloc(HGLOBAL(hh), PtoHSize(Size), 0));
	if Result = nil then
	begin // 拡張に失敗するとnilが返るらしい。実によく失敗する。
		Result := GetMem(Size);
		Move(P^, Result^, Min(PtoH(P).Size, Size));
		if FreeMem(P) <> 0 then
			; // ignore todo:レポートすべきか
	end
	else
	begin
		PHeapHeader(Result).Size := Size; // リサイズした。
		HtoT(Result)^ := Result; // フッタの付け替え
		Result := HtoP(Result);
	end;
end;

procedure Initialize;
var
	newmm: TMemoryManager;
begin
	GetMemoryManager(oldmm);
	if AllocMemCount <> 0 then
	begin
		ShowMessage(
			'HeapCheckerの使い方が間違っています。'+sLineBreak+
			'プロジェクトソース(.dpr)の先頭でusesして下さい。');
		DisabledChecking := True;
		Halt(1);
	end;

	newmm.GetMem := GetMem;
	newmm.FreeMem := FreeMem;
	newmm.ReallocMem := ReallocMem;
	SetMemoryManager(newmm);

	Top.Next := @Top;
	Top.Prev := @Top;

	DefaultErrorReporter.init;
	LogFileReporter.init;
	ErrorReporter := @LogFileReporter; //@DefaultErrorReporter;<-遅すぎ
end;

procedure Finalize;
	procedure output(s: string);
	begin
		ErrorReporter^.output(s);
	end;


	procedure MemoryDump(addr: Pointer; size: Integer; Caption: String);
	const
		h = '0123456789ABCDEF ';

		procedure Hex(buf: PChar; n: DWORD; width: Integer = 8);
		var
			i: Integer;
			p: PChar;
		begin
			for i := 0 to width - 1 do
			begin
				p := buf + width-1-i;
				p^ := h[n and $f+1];
				n := n div $10;
			end;
		end;

	var
		p, q: ^Byte;
		s, t: String;
		i: Integer;
		c: PChar;
	begin
		s := '12345678 |                        -                        | ????????????????';
		t := '-----------------------------------------------------------------------------';

		p := addr;
		q := addr; Inc(q, size);
		// 見出し
		output(t);
		output(' ADDRESS | ' + Caption+ '(size:'+ IntToStr(size) + ')');
		output(t);
		while DWord(p) < DWord(q) do
		begin
			hex(@s[1], DWORD(p));
			for i := 0 to 15 do
			begin
				c := @s[62+i];
				if DWord(p)<DWord(q) then
				begin
//					if p^ in [$20..$7f-1] then
					if not(p^ in [$00..$19]) then
						c^ := Char(p^);
					hex(@s[12+i*3], p^, 2);
				end else
					c^ := ' ';

				Inc(p);
			end;
			output(s);
		end;
		output(t);
	end;
var
	p: PHeapHeader;
	i: Integer;
	vmt: DWord;
	s: String;
begin
	if DisabledChecking then
		Exit;

	SetMemoryManager(oldmm);

	if AllocMemCount <> 0 then
	begin
		if (Windows.MessageBox(0, PChar(IntToStr(AllocMemCount) + '個のヒープ領域が未開放です。'+sLineBreak+'詳細を出力しますか？'),
			'HeapChecker', MB_YESNO) = IDYES) then
		begin
			if ErrorReporter^.open then
			begin
				p := Top.Next;
				i := 1;
				while p <> @Top do
				begin
					s := '';
					try
						if OutputClassName then
						begin
							// 無理やりクラス名を表示してみる
							vmt := DWORD(HToP(p)^);
							if ($00400000 <= vmt) and (vmt <= $00500000) then // かなりいい加減な判定
								s := '(推定クラス名:'+TObject(HtoP(p)).ClassName+')';
						end;
					except
						// ignore exception
					end;

					if DumpLeakMemory then
					begin
						MemoryDump(HtoP(p), p^.Size, '未解放領域'+IntToStr(i) + s);
			//			MemoryDUmp(PtoH, PtoHSize(p^.Size), '未解放領域'+IntToStr(i)+'(ヘッダつき)');
					end;
					Inc(i);
					p := p.Next;
				end;

				ErrorReporter^.close;
			end
			else
				ShowMessage('レポートオブジェクトの初期化に失敗しました');
		end;
//		ShowMessage(IntToStr(AllocMemCount) + '個のヒープ領域が未開放です。');
	end;
	DefaultErrorReporter.done;
  LogFileReporter.done;
end;
{$endif}

{ TErrorReporter }

function TErrorReporter.open: Boolean;
begin
	Result := True;
end;

procedure TErrorReporter.close;
begin
	// do nothing
end;

procedure TErrorReporter.output(s: string);
begin
	Windows.OutputDebugString(PChar(s+sLineBreak));
end;

destructor TErrorReporter.done;
begin

end;

constructor TErrorReporter.init;
begin

end;

{ TLogFileErrorReporter }

procedure TLogFileErrorReporter.close;
begin
	CloseHandle(FHandle);
	FHandle := INVALID_HANDLE_VALUE;
end;

function TLogFileErrorReporter.open: Boolean;
begin
	FHandle := CreateFile(PChar(ParamStr(0)+'.heapchecker.log'), GENERIC_WRITE,0,nil,CREATE_ALWAYS,0,0);
	Result := FHandle <> INVALID_HANDLE_VALUE ;
end;

procedure TLogFileErrorReporter.output(s: string);
var
	w: Cardinal;
begin
	s := s + sLineBreak;
	WriteFile(FHandle, PChar(s)^, Length(s), w, nil);
end;

initialization
	Initialize;
finalization
	Finalize;
end.
