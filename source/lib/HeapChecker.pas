unit HeapChecker;
(***********************************************************

	HeapChecker

	�N���X�C���X�^���X��AGetMem�Ŋm�ۂ����q�[�v�̊J�����Y������o���郆�j�b�g�B


	�g����
		�v���W�F�N�g�\�[�X(*.dpr)�̐擪��

			uses HeapChecker;

		�ƋL�q����BHeapChecker�̑O�ɕʂ̃��j�b�g�����w�肵�Ă͂����Ȃ��B
		�v���W�F�N�g�\�[�X�̐擪��
		begin
			HeapChecker.OutputClassName := True;
			HeapChecker.DumpLeakMemory := True;
			...
		end;
		�̓�s��ǉ�����ƃ��[�N�����������̃_���v��
		���ꂪ�N���X�ł���΃N���X����\������B

	�T���v��
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

	���ӎ���
		Delphi6�Ńp�b�`��K�p�����Ɏ��s�����5�̊J�����Y�ꂪ���o����邪�A
		�����VCL�̃o�O�B

***********************************************************)
interface

// �g�p����q�[�v�}�l�[�W��
//{$define UseOriginalMemoryManager �������͓��삵�Ȃ�}
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

// ���ˑ��̌x����OFF�ɂ���
{$WARN UNIT_PLATFORM OFF}
{$WARN SYMBOL_PLATFORM OFF}
{$WARN SYMBOL_DEPRECATED OFF}

{$ifdef Release}
	// �����[�X�r���h�p�̐ݒ�
	{$DEBUGINFO OFF} // OFF�ɂ���ƃR�[�h�⊮�@�\���g���Ȃ��Ȃ�B
	{$LOCALSYMBOLS ON}
	{$REFERENCEINFO ON}
	{$OPTIMIZATION ON}
	{$OVERFLOWCHECKS OFF}
	{$RANGECHECKS OFF}
{$else}
	// �f�o�b�O�r���h�p�̐ݒ�
	{$DEBUGINFO ON}
	{$OPTIMIZATION OFF}
	{$OVERFLOWCHECKS ON}
	{$RANGECHECKS ON}
{$endif}

var
	/// ���[�N�̃`�F�b�N�𖳌��ɂ���t���O
	DisabledChecking: Boolean;

	/// ���[�N���Ă��郁�����̈�̃_���v���o�͂���B
	DumpLeakMemory: Boolean;

	/// ���[�N���Ă���̈���N���X�C���X�^���X�Ƃ݂Ȃ��āA���̖��O��\������B
	/// �댯!!���������AccessViolation����������B���̏ꍇ��OFF�ɂ���B
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

// �o�͂��J�X�^�}�C�Y��������Ώ������ς݃J�X�^���I�u�W�F�N�g�̃|�C���^��ݒ肷��B
var
	ErrorReporter: ^TErrorReporter;
	LogFileReporter: TLogFileErrorReporter;

implementation

// System, Windows���j�b�g�ȊO���g���Ă͂����Ȃ�
// ��OSysUtils�Ɉˑ�����̂Ŏg�p�֎~
uses
	Windows;

// ���[�e�B���e�B�֐��BString�̓q�[�v���g���̂ŃG���[���|�[�g���̂ݎg�p���邱�ƁB

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
// AllocMemCount���g�����`�F�b�N

procedure Initialize;
begin
	if AllocMemCount <> 0 then
	begin
		ShowMessage(
			'NtHeapChecker�̎g�������Ԉ���Ă��܂��B'+sLineBreak+
			'�v���W�F�N�g�\�[�X(.dpr)�̐擪��uses���ĉ������B');
		DisabledChecking := True;
		Halt(1);
	end;
end;

procedure Finalize;
begin
	if DisabledChecking then
		Exit;

	if AllocMemCount <> 0 then
		ShowMessage(IntToStr(AllocMemCount) + '�̃q�[�v�̈悪���J���ł��B');
end;
{$endif UseOriginalMemoryManager}

{$ifdef UseWin32MemoryManager}
// GlobalAlloc/Free/Realloc���g�����`�F�b�N
// ����Ƀ����N���X�g�̏����������ă��[�N�����̈���_���v�o����悤�ɂ���B

// �q�[�v�̐擪�ɕt������ǉ��w�b�_
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
	// P�̓��[�U�[���x���̃A�h���X�œn�����
	CheckHeap(P);
	hh := PtoH(P);
	Result:=Pointer(GlobalRealloc(HGLOBAL(hh), PtoHSize(Size), 0));
	if Result = nil then
	begin // �g���Ɏ��s�����nil���Ԃ�炵���B���ɂ悭���s����B
		Result := GetMem(Size);
		Move(P^, Result^, Min(PtoH(P).Size, Size));
		if FreeMem(P) <> 0 then
			; // ignore todo:���|�[�g���ׂ���
	end
	else
	begin
		PHeapHeader(Result).Size := Size; // ���T�C�Y�����B
		HtoT(Result)^ := Result; // �t�b�^�̕t���ւ�
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
			'HeapChecker�̎g�������Ԉ���Ă��܂��B'+sLineBreak+
			'�v���W�F�N�g�\�[�X(.dpr)�̐擪��uses���ĉ������B');
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
	ErrorReporter := @LogFileReporter; //@DefaultErrorReporter;<-�x����
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
		// ���o��
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
		if (Windows.MessageBox(0, PChar(IntToStr(AllocMemCount) + '�̃q�[�v�̈悪���J���ł��B'+sLineBreak+'�ڍׂ��o�͂��܂����H'),
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
							// �������N���X����\�����Ă݂�
							vmt := DWORD(HToP(p)^);
							if ($00400000 <= vmt) and (vmt <= $00500000) then // ���Ȃ肢�������Ȕ���
								s := '(����N���X��:'+TObject(HtoP(p)).ClassName+')';
						end;
					except
						// ignore exception
					end;

					if DumpLeakMemory then
					begin
						MemoryDump(HtoP(p), p^.Size, '������̈�'+IntToStr(i) + s);
			//			MemoryDUmp(PtoH, PtoHSize(p^.Size), '������̈�'+IntToStr(i)+'(�w�b�_��)');
					end;
					Inc(i);
					p := p.Next;
				end;

				ErrorReporter^.close;
			end
			else
				ShowMessage('���|�[�g�I�u�W�F�N�g�̏������Ɏ��s���܂���');
		end;
//		ShowMessage(IntToStr(AllocMemCount) + '�̃q�[�v�̈悪���J���ł��B');
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
