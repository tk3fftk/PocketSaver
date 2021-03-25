program pngtest;

uses
  Forms,
  pngtest1 in 'pngtest1.pas' {Form1},
  pngtest2 in 'pngtest2.pas' {Form2};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
