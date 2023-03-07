unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Data.FMTBcd, Data.DB, Data.SqlExpr,
  Vcl.StdCtrls, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FireDAC.Stan.Async, FireDAC.DApt, FireDAC.Comp.DataSet, FireDAC.Comp.Client,
  Horse,Horse.Jhonson,Horse.Commons, System.JSON;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Memo1: TMemo;
    procedure Button1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    App : THorse;
    Caminho : String;
    Users: TJsonArray;
    User : TJsonObject;
  public
    { Public declarations }
    procedure GetUsuario(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    procedure SetUsuario(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    procedure DeleteUsuario(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    procedure Iniciar;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses Dataset.Serialize;

procedure TForm1.Button1Click(Sender: TObject);
begin
  Iniciar;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  Caminho := '/Users';
  App := THorse.Create;
  Iniciar;
end;

procedure TForm1.Iniciar;
begin
  if not Assigned(Users) then
    Users := TJsonArray.Create;

  if not App.IsRunning then
  begin
    App.Use(Jhonson);
    App.Get(Caminho,GetUsuario);
    App.Post(Caminho,SetUsuario);
    App.Delete(Caminho+'/:id',DeleteUsuario);
    App.Listen(9000);
    Memo1.Lines.Add('Iniciado');
  end else
  begin
    App.StopListen;
    Memo1.Lines.Add('Parou');
  end;
end;

procedure TForm1.GetUsuario(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  Res.Send<TJsonAncestor>(Users.Clone);
end;

procedure TForm1.SetUsuario(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  User := Req.Body<TJsonObject>.Clone as TJsonObject;
  Users.AddElement(User);
  Res.Send<TJsonAncestor>(User.Clone).Status(THttpStatus.Created);
end;

procedure TForm1.DeleteUsuario(Req: THorseRequest; Res: THorseResponse; Next: TProc);
Var Id : Integer;
begin
  Id := Req.Params.Items['ID'].ToInteger;
  USers.Remove(Id).Free;
  Res.Send<TJsonAncestor>(Users.Clone).Status(THttpStatus.NoContent);
end;

end.
