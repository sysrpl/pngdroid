unit ImageDetails;

{$mode delphi}

interface

const
  MinSize = 0.05;
  MaxSize = 5.00;

type
  TImageSize = record
    Width: Integer;
    Height: Integer;
  end;

  TUnitKind = (ukInch, ukCentimeter);

  TDotsPerInch = (dpiLow, dpiMedium, dpiHigh, dpiExtraHigh);

const
  Centimeter = 2.54;

  DotsPerInch: array[TDotsPerInch] of Single = (
    120.0, 160.0, 240.0, 320.0);

  DotsPerCentimeter: array[TDotsPerInch] of Single = (
    120.0 / Centimeter, 160.0 / Centimeter, 240.0 / Centimeter,
    320 / Centimeter);

type
  TImageDetails = record
    Valid: Boolean;
    Source: string;
    Dest: string;
    Width: Integer;
    Height: Integer;
    UnitKind: TUnitKind;
    DesiredWidth: Single;
    DesiredHeight: Single;
    Sizes: array[TDotsPerInch] of TImageSize;
    procedure Resize;
  end;

implementation

procedure TImageDetails.Resize;
var
  Dots: Single;
  I: TDotsPerInch;
begin
  if DesiredWidth < MinSize  then
    DesiredWidth := MinSize
  else if DesiredWidth > MaxSize  then
    DesiredWidth := MaxSize;
  if (Width > 0) and (Height > 0) then
    DesiredHeight := DesiredWidth * (Height / Width)
  else
    DesiredHeight := 0;
  for I := Low(Sizes) to High(Sizes) do
  begin
    if UnitKind = ukInch then
      Dots := DotsPerInch[I]
    else
      Dots := DotsPerCentimeter[I];
    Sizes[I].Width := Round(DesiredWidth * Dots);
    Sizes[I].Height := Round(DesiredHeight * Dots);
  end;
end;

end.

