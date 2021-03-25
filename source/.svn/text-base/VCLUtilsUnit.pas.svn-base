unit VCLUtilsUnit;

interface

uses SysUtils, Classes, Forms;

// フォームのデータの読み込み
procedure LoadFormFromFile(Form: TForm);
// フォームのデータの書き込み
procedure SaveFormToFile(Form: TForm);

implementation

function GetFormFileName(Form: TForm): string;
begin
  Result := ChangeFileExt(Application.ExeName, '.' + Form.Name + '.dat')
end;

procedure LoadFormFromFile(Form: TForm);
var
  fs: TFileStream;
  FileName, fn: string;
begin
  FileName := GetFormFileName(Form);
  if not FileExists(FileName) then
    Exit;

  fs := TFileStream.Create(FileName, fmOpenRead);
  try
    try
      fn := Form.Name;
      while Form.ComponentCount > 0 do
        Form.Components[0].Free;
      fs.ReadComponent(Form); // ここでForm.Nameが変わってしまう
      Form.Name := fn;
    except
    end;
  finally
    fs.Free;
  end;
end;

procedure SaveFormToFile(Form: TForm);
var
  fs: TFileStream;
begin
  fs := TFileStream.Create(GetFormFileName(Form), fmCreate);
  try
    fs.WriteComponent(Form);
  finally
    fs.Free;
  end;
end;

end.
