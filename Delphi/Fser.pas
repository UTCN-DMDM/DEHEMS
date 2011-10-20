
unit Fser;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, StdCtrls, ExtCtrls,Menus, math;

type
  proces = record
           //variabile
           indm: integer;     // Indice esantion curent
           u: double;         // Semnalul de control
           w1,w2,w3 :double;   // coeficienti de ponderare
           // y_sim - vector temperatura locuinta
           // Twe - vector temperatura estimata perete exterior
           // tout - vector temperatura exterioara
           // Q  - consumul de energie
           y_sim, Twe_vect,tout, Q : array [0..60] of double;
           // Ta, Tav: temperatura actuala si precedenta in locuinta
           // Tae, Twe, Twev: temperaturi estimate locuinta, perete, perete anterior
           Ta,Tav,Tae,Twe,Twev, Q_est: double;
           // castig energie de la: appliances, lumina, solar, occupant, alte
           Q_app, Q_light, Q_solar, Q_occ, Q_loss, Q_other: double;
           k_fe,k_oe,k_ie,Cae,Cwe: double;  //parametri model
           tranz:double; // indice regim tranzitoriu
           m_abatere: array[0..10] of double;  // vector abatere modele
           m_par: array[0..10] of array[0..4] of double;  // vector modele
           //cvasiconstante
           nmem:integer;   //  numar date memorate
           n_sim:integer;  // numar date simulare on_line
           T: integer;     // perioada de esantionare
           umax,umin: double;    // valorile extreme ale comenzii
           // limite maxime si minime ale parametrilor modelului
           k_fe_max,k_oe_max,k_ie_max,Cae_max,Cwe_max,k_fe_min,k_oe_min,k_ie_min,Cae_min,Cwe_min: double;
           end;
    TFormser = class(TForm)
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure pas_conducere;
    procedure StepModel;
    procedure Simulare_Model;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Formser: TFormser;
  Fistext, Fistext1:TextFile;
  numefisier:String;
  pr: proces;

  implementation

{$R *.DFM}


procedure TFormser.FormActivate(Sender: TObject);
var i,j:integer;
begin
for i:=0 to 10 do pr.m_abatere[i]:=1000;
AssignFile(Fistext,'DataInit.txt');
Reset(Fistext);            // citire date din fisierul de initializare
  readln(Fistext,j);       // parametri algoritm ; j este numarul de esantioane
  readln(Fistext,pr.indm); // indice esantion curent
  readln(Fistext,pr.umax, pr.umin);       //  citire limite comanda
  readln(Fistext,pr.nmem);     // numar pachete date memorate
  readln(Fistext,pr.n_sim);    // numar  date simulare on-line
  readln(Fistext,pr.w1);       // coeficienti ponderare
  readln(Fistext,pr.w2);
  readln(Fistext,pr.w3);
  readln(Fistext,pr.T);         // perioada de esantionare
  // initializari si limite parametri
  readln(Fistext, pr.k_fe, pr.k_oe, pr.k_ie, pr.Cae, pr.Cwe);
  readln(Fistext,pr.k_fe_max, pr.k_fe_min);
  readln(Fistext, pr.k_oe_max, pr.k_oe_min);
  readln(Fistext, pr.k_ie_max, pr.k_ie_min);
  readln(Fistext, pr.Cae_max, pr.Cae_min);
  readln(Fistext, pr.Cwe_max, pr.Cwe_min);
CloseFile(Fistext);
// initializari energii aditionale
pr.Q_app:=0; pr.Q_light:=0; pr.Q_solar:=0; pr.Q_occ:=0; pr.Q_loss:=0; pr.Q_other:=0;
AssignFile(Fistext, 'DataIn.txt');
Reset(Fistext);
AssignFile(Fistext1,'DataOut.txt');
Rewrite(Fistext1);
for i:=0 to j do       // j este numarul total de perechi de date citite
begin
    read(Fistext,pr.indm);    // indice
    pas_conducere;            // calcul comanda curenta
    // scrie valori estimatii parametri model, energie, temp. perete, tranz
    Writeln(Fistext1, i, pr.k_fe, pr.k_oe, pr.k_ie, pr.Cae,pr.Cwe, pr.Q_est, pr.Twe, pr.tranz);
end;
CloseFile(Fistext);
CloseFile(Fistext1);
Close;
end;

procedure TFormser.FormClose(Sender: TObject; var Action: TCloseAction);
begin
    Action := caFree;
end;

procedure TFormser.pas_conducere;
var
i,j:integer;
begin
for i:=pr.nmem downto 1 do  pr.y_sim[i]:=pr.y_sim[i-1]; // deplasare un pas
read(Fistext,pr.u);          // citiri date din fisier: comanda,
readln(Fistext, pr.Ta);      //  temperatura in locuinta
readln(Fistext, pr.TOut[0]); // temperatura exterioara
StepModel;                   // un pas executie model
 for j:=pr.nmem downto 1 do     // deplasare un pasa temp. exterioara si
  begin                         // comanda
  pr.tout[j]:=pr.tout[j-1];
  pr.Q[j]:=pr.Q[j-1];
  end;
// adaugam energii secundare
pr.Q[0]:=pr.u+pr.Q_app+pr.Q_light+pr.Q_solar+pr.Q_occ-pr.Q_loss+pr.Q_other;
if pr.Q[0]<0 then pr.Q[0]:=0;
pr.y_sim[0]:=pr.Ta ;
end;

procedure TFormser.StepModel;
var i:integer;
begin  // un pas model conform ecuatiilor modelului
 if (pr.Cae>0) and (pr.Cwe>0)  and (pr.indm>40) then Simulare_Model;
 if (pr.k_fe>0) and (pr.Cae>0)then
  begin
    pr.Twe:=pr.Twev+pr.T*(pr.K_ie*(pr.Tav-pr.Twev)-pr.K_oe*(pr.Twev-pr.Tout[1]))/pr.Cwe;
    pr.Tae:=pr.Tav+pr.T*(pr.Q_est-pr.K_ie*(pr.Tav-pr.Twev)-pr.K_fe*(pr.Tav-pr.Tout[1]))/pr.Cae;
    pr.Q_est:=(pr.Ta-pr.Tav)*pr.Cae/pr.T+pr.K_ie*(pr.Tav-pr.Twe)+pr.k_fe*(pr.Tav-pr.Tout[1]);
    for i:=40 downto 1 do begin pr.Twe_vect[i]:=pr.Twe_vect[i-1];  end;
    pr.Twe_vect[0]:= pr.Twe;
    pr.Twev:=pr.Twe;
   end;
 pr.Tav:=pr.Ta;
end;

procedure TFormser.Simulare_Model;
var
Ta_sim, Tw_sim: array[0..4000] of double;
i,j,j1,i1,i2,i3, i4, i5, i10,i20,i30, i40, i50:integer;
abatere, abatere1, abatere2:double;
m_ab: array[0..10] of double;
gasit:boolean;
test_introducere, aux:double;
numar:integer;
sumaq:double;
qqest:double;
begin       // procedura de simulare a comportarii modelelor din bank
Ta_sim[pr.n_sim+1]:=pr.y_sim[pr.n_sim+1];   // initializare
Tw_sim[pr.n_sim+1]:=pr.Twe_vect[pr.n_sim];  //fara masurare twm[n_sim]
abatere:=0;
for i:=pr.n_sim downto 1 do   // simulare  model curent
  begin
  Ta_sim[i]:=Ta_sim[i+1]+pr.T*(pr.Q[i]-pr.K_ie*(Ta_sim[i+1]-Tw_sim[i+1])-pr.K_fe*(Ta_sim[i+1]-pr.Tout[i+1]))/pr.Cae;
  Tw_sim[i]:=Tw_sim[i+1]+pr.T*(pr.K_ie*(Ta_sim[i+1]-Tw_sim[i+1])-pr.K_oe*(Tw_sim[i+1]-pr.Tout[i+1]))/pr.Cwe;
  qqest:=(Ta_sim[i]-Ta_sim[i+1])*pr.Cae/pr.T+pr.K_ie*(Ta_sim[i+1]-Tw_sim[i])+pr.k_fe*(Ta_sim[i+1]-pr.Tout[i+1]);
  abatere:=abatere+(1-pr.w3)*abs(Ta_sim[i]-pr.y_sim[i])+ pr.w3*abs(qqest-pr.q[i]);
  end;
j1:=-1;
for j:=0 to 10 do          // simulari modele din bank
  begin
  m_ab[j]:=0;
  for i:=pr.n_sim downto 1 do
    begin
      if pr.m_par[j,3]>0 then Ta_sim[i]:=Ta_sim[i+1]+pr.T*(pr.Q[i]-pr.m_par[j,0]*(Ta_sim[i+1]-Tw_sim[i+1])-pr.m_par[j,1]*(Ta_sim[i+1]-pr.Tout[i+1]))/pr.m_par[j,3];
      if pr.m_par[j,4]>0 then Tw_sim[i]:=Tw_sim[i+1]+pr.T*(pr.m_par[j,0]*(Ta_sim[i+1]-Tw_sim[i+1])-pr.m_par[j,2]*(Tw_sim[i+1]-pr.Tout[i+1]))/pr.m_par[j,4];
      qqest:=(Ta_sim[i]-Ta_sim[i+1])*pr.m_par[j,3]/pr.T+pr.m_par[j,0]*(Ta_sim[i+1]-Tw_sim[i])+pr.m_par[j,1]*(Ta_sim[i+1]-pr.Tout[i+1]);
      m_ab[j]:=m_ab[j]+(1-pr.w3)*abs(Ta_sim[i]-pr.y_sim[i])+ pr.w3*abs(qqest-pr.q[i]);
    end;
  if (m_ab[j]<abatere) and (pr.m_par[j,3]>0) and (pr.m_par[j,4]>0) then
    begin
    abatere:=m_ab[j];
    j1:=j;               // j1 este indicele celui mai "bun" model
    end;
  end;
if ((j1>-1) and (pr.tranz>0.1)) then
  begin                         // noile valori ale parametrilor modelului
  pr.K_ie:=pr.m_par[j1,0];
  pr.K_fe:=pr.m_par[j1,1];
  pr.K_oe:=pr.m_par[j1,2];
  pr.Cae:= pr.m_par[j1,3];
  pr.Cwe:= pr.m_par[j1,4];
  end;
pr.tranz:=0; abatere:=1000;  sumaq:=1;
for i:=pr.n_sim downto 2 do begin pr.tranz:=pr.tranz+abs(pr.Q[i]-pr.Q[i-1]); sumaq:=sumaq+pr.Q[i];end;
if sumaq>0 then pr.tranz:=100*pr.tranz/(pr.n_sim*sumaq)
           else pr.tranz:=0;
if (pr.tranz>0.1) then
begin          // cautare in jurul parametrilor actuali ai modelului
i10:=0;i20:=0;i30:=0; i40:=0; i50:=0;
numar:=2;
if pr.tranz>0.1 then
for i1:=-numar to numar do
  for i2:=-numar to numar do
    for i3:=-numar to numar do    
    for i4:=-numar to numar do
    for i5:=-numar to numar do
    begin
    abatere1:=0;
    for i:=pr.n_sim downto 1 do
     begin
      Ta_sim[i]:=Ta_sim[i+1]+pr.T*(pr.Q[i]-pr.K_ie*(1+i1/pr.w2)*(Ta_sim[i+1]-Tw_sim[i+1])-pr.K_fe*(1+i2/pr.w2)*(Ta_sim[i+1]-pr.Tout[i+1]))/(pr.Cae*(1+i4/pr.w2));
      Tw_sim[i]:=Tw_sim[i+1]+pr.T*(pr.K_ie*(1+i1/pr.w2)*(Ta_sim[i+1]-Tw_sim[i+1])-pr.K_oe*(1+i3/pr.w2)*(Tw_sim[i+1]-pr.Tout[i+1]))/(pr.Cwe*(1+i5/pr.w2));
      qqest:=(Ta_sim[i]-Ta_sim[i+1])*pr.Cae*(1+i4/pr.w2)/pr.T+pr.K_ie*(1+i1/pr.w2)*(Ta_sim[i+1]-Tw_sim[i])+pr.k_fe*(1+i2/pr.w2)*(Ta_sim[i+1]-pr.Tout[i+1]);
      abatere1:=abatere1+(1-pr.w3)*abs(Ta_sim[i]-pr.y_sim[i])+ pr.w3*abs(qqest-pr.q[i]);
     end;
    if abs(abatere1)<=abs(abatere) then
        begin i10:=i1;i20:=i2;i30:=i3; i40:=i4; i50:=i5; abatere:=abatere1; end;
    end;
pr.K_ie:=(1-pr.w1)*pr.K_ie+pr.w1*pr.K_ie*(1+i10/pr.w2);     // noi valori de cautare
pr.K_fe:=(1-pr.w1)*pr.K_fe+pr.w1*pr.K_fe*(1+i20/pr.w2);
pr.K_oe:=(1-pr.w1)*pr.K_oe+pr.w1*pr.K_oe*(1+i30/pr.w2);
pr.Cae:=(1-pr.w1)*pr.Cae+pr.w1*pr.Cae*(1+i40/pr.w2);
pr.Cwe:=(1-pr.w1)*pr.Cwe+pr.w1*pr.Cwe*(1+i50/pr.w2);
      test_introducere:=1000;
      for i:=0 to 10 do
        begin
          for j:=0 to 10 do
            begin
              aux:=0;
              aux:=aux+abs(pr.m_par[i,0]-pr.K_ie)/pr.K_ie;
              aux:=aux+abs(pr.m_par[i,1]-pr.K_fe)/pr.K_fe;
              aux:=aux+abs(pr.m_par[i,2]-pr.K_oe)/pr.K_oe;
              aux:=aux+abs(pr.m_par[i,3]-pr.Cae)/pr.Cae;
              aux:=aux+abs(pr.m_par[i,4]-pr.Cwe)/pr.Cwe;
              if (aux<test_introducere) then test_introducere:=aux;
            end;
        end;
      if test_introducere>0.001 then
        begin
          gasit:=false;        // introducere model in bank
          i:=0;
          while (i<11) and (gasit=false) do
            begin
              if  abatere<pr.m_abatere[i] then
                begin
                  gasit:=true;
                  pr.m_par[i,0]:= pr.K_ie;
                  pr.m_par[i,1]:= pr.K_fe;
                  pr.m_par[i,2]:= pr.K_oe;
                  pr.m_par[i,3]:= pr.Cae;
                  pr.m_par[i,4]:= pr.Cwe;
                  pr.m_abatere[i]:=abatere;
                end;
               i:=i+1;
             end;
        end;
end;
// verificam extremele acceptate ale parametrilor
if pr.Cae>pr.Cae_max then pr.Cae:=pr.Cae_max;
if pr.Cae<pr.Cae_min then pr.Cae:=pr.Cae_min;
if pr.Cwe>pr.Cwe_max then pr.Cwe:=pr.Cwe_max;
if pr.Cwe<pr.Cwe_min then pr.Cwe:=pr.Cwe_min;
if pr.K_ie>pr.K_ie_max then pr.K_ie:=pr.K_ie_max;
if pr.K_ie<pr.K_ie_min then pr.K_ie:=pr.K_ie_min;
if pr.K_fe>pr.K_fe_max then pr.K_fe:=pr.K_fe_max;
if pr.K_fe<pr.K_fe_min then pr.K_fe:=pr.K_fe_min;
if pr.K_oe>pr.K_oe_max then pr.K_oe:=pr.K_oe_max;
if pr.K_oe<pr.K_oe_min then pr.K_oe:=pr.K_oe_min;
end;

end.
