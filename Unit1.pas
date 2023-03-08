unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Data.FMTBcd, Data.DB, Data.SqlExpr,
  Vcl.StdCtrls,
  Horse,Horse.Jhonson,Horse.Commons, Horse.BasicAuthentication,
  Horse.Compression,Horse.HandleException, Horse.OctetStream,
  Horse.Logger, // It's necessary to use the unit
  Horse.Logger.Provider.LogFile, // It's necessary to use the unit
  Horse.Paginate,Horse.Etag,
  System.JSON;

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
    LLogFileConfig: THorseLoggerLogFileConfig;
  public
    { Public declarations }
    procedure GetUsuario(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    procedure SetUsuario(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    procedure DeleteUsuario(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    function Autencicacao(const Ausername, APassWord: String):Boolean;
    procedure Iniciar;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses Dataset.Serialize;

function TForm1.Autencicacao(const Ausername, APassWord: String): Boolean;
begin
  Result := Ausername.Equals('user') and APassWord.Equals('password');
end;

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

    LLogFileConfig := THorseLoggerLogFileConfig.New
    .SetLogFormat('${request_clientip} [${time}] ${response_status}');

    THorseLoggerManager.RegisterProvider(THorseLoggerProviderLogFile.New(LLogFileConfig)); // Log
    App.Use(Compression());  // Comprimir
    App.Use(Jhonson);    // Tipo de requisição
    App.Use(HandleException);  // Exception
    App.Use(HorseBasicAuthentication(Autencicacao)); // Autenticação
    App.Use(OctetStream);  // Trafegar arquivo, imagem
    App.Use(Paginate);
    App.Use(THorseLoggerManager.HorseCallback);
    App.Use(eTag); //https://github.com/academiadocodigo/Horse-ETag
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
var i : Integer;
begin
  for I := 0 to 10000 do begin

  User := Req.Body<TJsonObject>.Clone as TJsonObject;
  Users.AddElement(User);
  Res.Send<TJsonAncestor>(User.Clone).Status(THttpStatus.Created);
  end;
end;

procedure TForm1.DeleteUsuario(Req: THorseRequest; Res: THorseResponse; Next: TProc);
Var Id : Integer;
begin
  Id := Req.Params.Items['ID'].ToInteger;
  USers.Remove(Id).Free;
  Res.Send<TJsonAncestor>(Users.Clone).Status(THttpStatus.NoContent);
end;

end.
