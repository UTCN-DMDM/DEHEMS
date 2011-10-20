program ser;

uses
  Forms,
  Fser in 'Fser.pas' {Formser};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TFormser, Formser);
  Application.Run;
end.
