program PocketSaver;

{%File 'ModelSupport\CameraAnalyzerUnit\CameraAnalyzerUnit.txvpck'}
{%File 'ModelSupport\ImageFormUnit\ImageFormUnit.txvpck'}
{%File 'ModelSupport\HeapChecker\HeapChecker.txvpck'}
{%File 'ModelSupport\MainFormUnit\MainFormUnit.txvpck'}
{%File 'ModelSupport\デフォルト.txvpck'}
{%File 'ModelSupport\Unit1\Unit1.txvpck'}
{%File 'ModelSupport\VCLUtilUnit\VCLUtilUnit.txvpck'}
{%File 'ModelSupport\VCLUtilsUnit\VCLUtilsUnit.txvpck'}
{%File '..\readme.txt'}

uses
  HeapChecker in 'lib\HeapChecker.pas',
  Forms,
  MainFormUnit in 'MainFormUnit.pas' {MainForm},
  CameraAnalyzerUnit in 'CameraAnalyzerUnit.pas',
  VCLUtilsUnit in 'VCLUtilsUnit.pas';

{$R *.res}

begin
  HeapChecker.OutputClassName := True;
  HeapChecker.DumpLeakMemory := True;

  Application.Initialize;
  Application.Title := 'Pocket Saver ver 1.0.2';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
