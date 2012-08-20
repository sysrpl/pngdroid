unit main;

{$mode delphi}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, ExtDlgs,
  { Cross units }
  CrossGraphics, CrossCtrls, CrossFiles, CrossXml,  CrossStrings, CrossStorage,
  { Program units }
  ImageDetails;

{ TMainForm }

type
  TMainForm = class(TForm)
    OpenDialog: TOpenPictureDialog;
    PreviewImage: TAlphaImage;
    Banner: TImage;
    Logo: TAlphaImage;
    DirectoryDialog: TSelectDirectoryDialog;
    Shadow: TAlphaImage;
    SourceButton: TAlphaSpeedButton;
    ProjectButton: TAlphaSpeedButton;
    DetailsLabel: TLabel;
    QuitButton: TButton;
    DetailsBox: TScrollBox;
    ProjectEdit: TEdit;
    ProjectLabel: TLabel;
    UnitsBox: TComboBox;
    SizeEdit: TEdit;
    BannerLabel: TLabel;
    SizeLabel: TLabel;
    UnitsLabel: TLabel;
    ResizeButton: TButton;
    SourceEdit: TEdit;
    SourceLabel: TLabel;
    Platform: TPlatformLayout;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure SizeEditExit(Sender: TObject);
    procedure SourceEditExit(Sender: TObject);
    procedure UnitsBoxChange(Sender: TObject);
    procedure SourceButtonClick(Sender: TObject);
    procedure ProjectButtonClick(Sender: TObject);
    procedure ResizeButtonClick(Sender: TObject);
    procedure QuitButtonClick(Sender: TObject);
  private
    FDetails: TImageDetails;
    FSettings: IFiler;
    procedure LoadSettings;
    procedure SaveSettings;
    function LoadThumbnail: Boolean;
    procedure FormatDetails;
    { Settings }
  private
    function GetDesiredSize: Single;
    procedure SetDesiredSize(Value: Single);
  public
    property DesiredSize: Single read GetDesiredSize write SetDesiredSize;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

const
  AppName = 'pngdroid';

{ TMainForm persistance }

procedure TMainForm.LoadSettings;
const
  DefaultSize = 1;
begin
  FSettings := XmlSettingsLoad(AppName);
  UnitsBox.ItemIndex := FSettings.ReadInt('units');
  DesiredSize := FSettings.ReadFloat('size', DefaultSize);
  SourceEdit.Text := FSettings.ReadStr('source');
  ProjectEdit.Text := FSettings.ReadStr('project');
  if UnitsBox.ItemIndex < 0 then
    UnitsBox.ItemIndex := 0;
end;

procedure TMainForm.SaveSettings;
begin
  FSettings.WriteFloat('size', DesiredSize);
  FSettings.WriteInt('units', UnitsBox.ItemIndex);
  FSettings.WriteStr('source', SourceEdit.Text);
  FSettings.WriteStr('project', ProjectEdit.Text);
  XmlSettingsSave(AppName, FSettings);
end;

{ TMainForm event handlers }

procedure TMainForm.FormCreate(Sender: TObject);
var
  C: TColor;
begin
  FormCreateFooter(Self, QuitButton);
  C := ColorDefault(Self);
  DetailsBox.Color := ColorDarken(C, 0.9);
  DetailsLabel.Caption := '';
  LoadSettings;
  LoadThumbnail;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  SaveSettings;
end;

procedure TMainForm.FormPaint(Sender: TObject);
var
  R: TRect;
begin
  R := DetailsBox.BoundsRect;
  R.Top := 0;
  Canvas.Brush.Color := DetailsBox.Color;
  Canvas.FillRect(R);
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  { Align labels based on actual platform control sizes }
  if Tag = 0 then
  begin
    Tag := 1;
    ControlCenterVertical(SizeEdit, SizeLabel);
    ControlCenterVertical(UnitsBox, UnitsLabel);
    ControlCenterVertical(SourceEdit, SourceButton);
    ControlCenterVertical(ProjectEdit, ProjectButton);
  end;
end;

function TMainForm.GetDesiredSize: Single;
begin
  Result := FDetails.DesiredWidth;
end;

function ReduceDecimal(Value: Single): AnsiString;
var
  S: string;
begin
  S := Format('%.3f', [Value]);
  if Pos(S, '.') > -1 then
  begin
    while S[Length(S)] = '0' do
      SetLength(S, Length(S) - 1);
    if  S[Length(S)] = '.' then
      SetLength(S, Length(S) - 1);
  end;
  Result := S;
end;

procedure TMainForm.SetDesiredSize(Value: Single);
var
  S: string;
begin
  if Value < MinSize  then
    Value := MinSize
  else if Value > MaxSize  then
    Value := MaxSize;
  Value := Round(Value * 1000) / 1000;
  S := ReduceDecimal(Value);
  SizeEdit.Text := S;
  Value := StrToFloat(S);
  if FDetails.DesiredWidth <> Value then
  begin
    FDetails.DesiredWidth := Value;
    FDetails.Resize;
    FormatDetails;
  end;
end;

function TMainForm.LoadThumbnail: Boolean;

  procedure CenterThumbnail;
  const
    MaxSize = 160;
  var
    X, Y: Integer;
    Scale: Single;
  begin
    X := PreviewImage.Image.Width;
    Y := PreviewImage.Image.Height;
    if X > Y then
    begin
      if X > MaxSize then
        Scale := MaxSize / X
      else
        Scale := 1;
      PreviewImage.Width := Round(X * Scale);
      Scale := PreviewImage.Image.Height / PreviewImage.Image.Width;
      PreviewImage.Height := Round(PreviewImage.Width * Scale);
    end
    else
    begin
      if Y > MaxSize then
        Scale := MaxSize / Y
      else
        Scale := 1;
      PreviewImage.Height := Round(Y * Scale);
      Scale := PreviewImage.Image.Width / PreviewImage.Image.Height;
      PreviewImage.Width := Round(PreviewImage.Height * Scale);
    end;
    PreviewImage.Left := (DetailsBox.Width - PreviewImage.Width) div 2 - 6;
  end;

var
  Strings: TStrings;
  S: string;
begin
  PreviewImage.ImageClear;
  PreviewImage.Hint := '';
  PreviewImage.Width := 0;
  PreviewImage.Height := 0;
  S := Trim(SourceEdit.Text);
  FDetails.Source := S;
  SourceEdit.Text := S;
  FDetails.Valid := False;
  if FileExists(S) then
  try
    PreviewImage.ImageLoad(S);
    Strings := TStringList.Create;
    try
      Strings.Add('File size');
      Strings.Add(Format('%s bytes', [FloatToStrF(FileSize(S), ffNumber, 18, 0)]));
      PreviewImage.Hint := Strings.Text;
    finally
      Strings.Free;
    end;
    FDetails.Valid := True;
    FDetails.Dest := '';
    FDetails.Width := PreviewImage.Image.Width;
    FDetails.Height := PreviewImage.Image.Height;
    if UnitsBox.ItemIndex = 0 then
      FDetails.UnitKind := ukInch
    else
      FDetails.UnitKind := ukCentimeter;
    FDetails.Resize;
  except
    { Ignore loading errors }
  end;
  if FDetails.Valid then
    CenterThumbnail
  else
    DetailsLabel.Top := PreviewImage.Top;
  FormatDetails;
  Result := FDetails.Valid;
end;

procedure TMainForm.FormatDetails;
const
  Indent = '  ';
  UnitAffix: array[TUnitKind] of string = ('in', 'cm');
  DpiTitles: array[TDotsPerInch] of AnsiString =
    ('low', 'medium', 'high', 'x-high');
var
  Strings: TStrings;
  Size: TImageSize;
  P: Integer;
  I: TDotsPerInch;
begin
  if FDetails.Valid then
  begin
    P := DetailsBox.VertScrollBar.Position;
    DetailsLabel.AutoSize := True;
    DetailsLabel.Align := alNone;
    DetailsLabel.Alignment := taLeftJustify;
    DetailsLabel.Layout := tlTop;
    DetailsLabel.Top := PreviewImage.Top + PreviewImage.Height + 8;
    DetailsLabel.Left := 8;
    Strings := TStringList.Create;
    try
      Strings.Add('Source');
      Strings.Add(Indent + ExtractFileName(FDetails.Source));
      Strings.Add('Size');
      Strings.Add(Indent + IntToStr(FDetails.Width) + ' x ' + IntToStr(FDetails.Height));
      Strings.Add(Indent + Format('%s %s by %s %s', [
        ReduceDecimal(FDetails.DesiredWidth), UnitAffix[FDetails.UnitKind],
        ReduceDecimal(FDetails.DesiredHeight), UnitAffix[FDetails.UnitKind]]));
      Strings.Add('Size at dpis');
      for I := Low(FDetails.Sizes) to High(FDetails.Sizes) do
      begin
        Size := FDetails.Sizes[I];
        Strings.Add(Indent + DpiTitles[I] +
          Format(' %d x %d', [Size.Width, Size.Height]));
      end;
      DetailsLabel.Caption := Strings.Text;
    finally
      Strings.Free;
    end;
    DetailsBox.VertScrollBar.Position := P;
  end
  else
  begin
    DetailsLabel.Caption := '';;
    DetailsLabel.AutoSize := False;
    DetailsLabel.Align := alClient;
    DetailsLabel.Alignment := taCenter;
    DetailsLabel.Layout := tlCenter;
    DetailsLabel.Caption := 'No image';
  end;
end;

{ TMainForm child control event handlers }

procedure TMainForm.SizeEditExit(Sender: TObject);
begin
  DesiredSize := StrToFloatDef(SizeEdit.Text, FDetails.DesiredWidth);
end;

procedure TMainForm.SourceEditExit(Sender: TObject);
var
  S: AnsiString;
begin
  S := Trim(SourceEdit.Text);
  if S <> FDetails.Source then
    LoadThumbnail;
end;

procedure TMainForm.UnitsBoxChange(Sender: TObject);
begin
  if UnitsBox.ItemIndex = 0 then
    FDetails.UnitKind := ukInch
  else
    FDetails.UnitKind := ukCentimeter;
  FDetails.Resize;
  FormatDetails;
end;

procedure TMainForm.SourceButtonClick(Sender: TObject);
begin
  if OpenDialog.Execute then
  begin
    SourceEdit.Text := OpenDialog.FileName;
    LoadThumbnail;
  end;
end;

procedure TMainForm.ProjectButtonClick(Sender: TObject);
begin
  if DirectoryExists(ProjectEdit.Text) then
    DirectoryDialog.FileName := ProjectEdit.Text;
  if DirectoryDialog.Execute then
  begin
    ProjectEdit.Text := DirectoryDialog.FileName;
  end;
end;

procedure TMainForm.ResizeButtonClick(Sender: TObject);
type
  TDpiFolders = array[TDotsPerInch] of string;

  function CheckSizes: Boolean;
  var
    I: TDotsPerInch;
  begin
    Result :=  True;
    for I := Low(FDetails.Sizes) to High(FDetails.Sizes) do
    begin
      if FDetails.Sizes[I].Width < 1 then
        Result := False
      else if FDetails.Sizes[I].Height < 1 then
        Result := False;
      if not Result then
        Exit;
    end;
  end;

  function FindFolders(const Path: string; var Folders: TDpiFolders): Boolean;
  const
    DpiAffix: array[TDotsPerInch] of string = (
      'ldpi', 'mdpi', 'hdpi', 'xhdpi');
  var
    Valid: Boolean;
    A, B: string;
    I: TDotsPerInch;
  begin
    Valid := False;
    A := PathAppend(Path, 'res');
    if not FolderExists(A) then
      A := Path;
    for I := Low(Folders) to High(Folders) do
    begin
      B := PathAppend(A, 'drawable-' + DpiAffix[I]);
      if FolderExists(B) then
      begin
        Folders[I] := B;
        Valid := True;
      end
      else
        Folders[I] := '';
    end;
    Result := Valid;
  end;

const
  SourceInvalid = 'The source is not a valid png image file';
  DestInvalid = 'The destination is not an Android project folder';
  SizeInvalid = 'The desired size is too small';
var
  Folders: TDpiFolders;
  Bitmap: TAlphaBitmap;
  Size: TImageSize;
  F, S: string;
  I: TDotsPerInch;
begin
  ControlValidate(SourceEdit, SourceInvalid, LoadThumbnail);
  ControlValidate(ProjectEdit, DestInvalid, FindFolders(ProjectEdit.Text, Folders));
  ControlValidate(SizeEdit, SizeInvalid, CheckSizes);
  F := ExtractFileName(SourceEdit.Text);
  for I := Low(Folders) to High(Folders) do
  begin
    S := Folders[I];
    if S = '' then
      Continue;
    Size := FDetails.Sizes[I];
    Bitmap := PreviewImage.Image.Resize(Size.Width, Size.Height);
    try
      Bitmap.SaveToFile(PathAppend(Folders[I], F));
    finally
      Bitmap.Free;
    end;
  end;
  SaveSettings;
  ShowInformation('Resize and copy completed');
end;

procedure TMainForm.QuitButtonClick(Sender: TObject);
begin
  Close;
end;

end.

