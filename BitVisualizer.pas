unit BitVisualizer;

interface

procedure Register;

implementation

uses
  Classes, {Forms,} SysUtils, ToolsAPI;

resourcestring
  sBitVisualizerName = 'Bit Visualizer for Delphi';
  sBitVisualizerDescription = 'Displays Hex and bit representations of Bytes';

type
  TDebuggerBitVisualizer = class(TInterfacedObject, IOTADebuggerVisualizer,
    IOTADebuggerVisualizerValueReplacer, IOTAThreadNotifier, IOTAThreadNotifier160)
  private
    FNotifierIndex: Integer;
    FCompleted: Boolean;
    FDeferredResult: string;
  public
    { IOTADebuggerVisualizer }
    function GetSupportedTypeCount: Integer;
    procedure GetSupportedType(Index: Integer; var TypeName: string;
      var AllDescendants: Boolean);
    function GetVisualizerIdentifier: string;
    function GetVisualizerName: string;
    function GetVisualizerDescription: string;
    { IOTADebuggerVisualizerValueReplacer }
    function GetReplacementValue(const Expression, TypeName, EvalResult: string): string;
    { IOTAThreadNotifier }
    procedure EvaluteComplete(const ExprStr: string; const ResultStr: string;
      CanModify: Boolean; ResultAddress: Cardinal; ResultSize: Cardinal;
      ReturnCode: Integer);
    procedure ModifyComplete(const ExprStr: string; const ResultStr: string;
      ReturnCode: Integer);
    procedure ThreadNotify(Reason: TOTANotifyReason);
    procedure AfterSave;
    procedure BeforeSave;
    procedure Destroyed;
    procedure Modified;
    { IOTAThreadNotifier160 }
    procedure EvaluateComplete(const ExprStr: string; const ResultStr: string;
      CanModify: Boolean; ResultAddress: TOTAAddress; ResultSize: LongWord;
      ReturnCode: Integer);
  end;

  TTypeLang = (tlDelphi, tlCpp);
  TBitType = (btByte);

  TBitVisualizerType = record
    TypeName: string;
    TypeLang: TTypeLang;
    BitType: TBitType;
  end;

const
  BitVisualizerTypes: array[0..0] of TBitVisualizerType =
  (
    (TypeName: 'Byte'; TypeLang: tlDelphi; BitType: btByte;),
//    (TypeName: 'TDate'; TypeLang: tlDelphi; DateTimeType: TBitType;),
//    (TypeName: 'TTime'; TypeLang: tlDelphi; DateTimeType: TBitType;),
    (TypeName: 'function: Byte'; TypeLang: tlDelphi; BitType: btByte;)
//    (TypeName: 'function: TDate'; TypeLang: tlDelphi; DateTimeType: TBitType;),
//    (TypeName: 'function: TTime'; TypeLang: tlDelphi; DateTimeType: TBitType;),
//    (TypeName: 'System::TDateTime'; TypeLang: tlCpp; DateTimeType: TBitType;),
//    (TypeName: 'System::TDateTime &'; TypeLang: tlCpp; DateTimeType: TBitType;),
//    (TypeName: 'TDateTime &'; TypeLang: tlCpp; DateTimeType: TBitType;),
//    (TypeName: 'System::TDate'; TypeLang: tlCpp; DateTimeType: TBitType;),
//    (TypeName: 'TDate &'; TypeLang: tlCpp; DateTimeType: TBitType;),
//    (TypeName: 'System::TTime'; TypeLang: tlCpp; DateTimeType: TBitType;),
//    (TypeName: 'TTime &'; TypeLang: tlCpp; DateTimeType: TBitType;)
  );

{ TDebuggerDateTimeVisualizer }

procedure TDebuggerBitVisualizer.AfterSave;
begin
  // don't care about this notification
end;

procedure TDebuggerBitVisualizer.BeforeSave;
begin
  // don't care about this notification
end;

procedure TDebuggerBitVisualizer.Destroyed;
begin
  // don't care about this notification
end;

procedure TDebuggerBitVisualizer.Modified;
begin
  // don't care about this notification
end;

procedure TDebuggerBitVisualizer.ModifyComplete(const ExprStr,
  ResultStr: string; ReturnCode: Integer);
begin
  // don't care about this notification
end;

procedure TDebuggerBitVisualizer.EvaluteComplete(const ExprStr,
  ResultStr: string; CanModify: Boolean; ResultAddress, ResultSize: Cardinal;
  ReturnCode: Integer);
begin
  EvaluateComplete(ExprStr, ResultStr, CanModify, TOTAAddress(ResultAddress),
    LongWord(ResultSize), ReturnCode);
end;

procedure TDebuggerBitVisualizer.EvaluateComplete(const ExprStr,
  ResultStr: string; CanModify: Boolean; ResultAddress: TOTAAddress; ResultSize: LongWord;
  ReturnCode: Integer);
begin
  FCompleted := True;
  if ReturnCode = 0 then
    FDeferredResult := ResultStr;
end;

procedure TDebuggerBitVisualizer.ThreadNotify(Reason: TOTANotifyReason);
begin
  // don't care about this notification
end;

function TDebuggerBitVisualizer.GetReplacementValue(
  const Expression, TypeName, EvalResult: string): string;
var
  Lang: TTypeLang;
  BitType: TBitType;
  I: Integer;
  CurProcess: IOTAProcess;
  CurThread: IOTAThread;
  ResultStr: array[0..255] of Char;
  CanModify: Boolean;
  ResultAddr, ResultSize, ResultVal: LongWord;
  EvalRes: TOTAEvaluateResult;
  DebugSvcs: IOTADebuggerServices;

  function IntToBinByte(Value: Byte): string;
  var
    i: Integer;
  begin
    SetLength(Result, 8);
    for i := 1 to 8 do begin
      if (Value shr (8-i)) and 1 = 0 then begin
        Result[i] := '0'
      end else begin
        Result[i] := '1';
      end;
    end;
  end;

  function FormatResult(const LEvalResult: string; BitType: TBitType; out ResStr: string): Boolean;
  var
    B: Byte;
    E: Integer;
  begin
    Result := True;
    try
      Val(LEvalResult, B, E);
      if not E = 0 then
        Result := False
      else
        case BitType of
          btByte: ResStr := Format('%0:d, $%0:x, (%1:s)', [B, IntToBinByte(B)]);
        end;
    except
      Result := False;
    end;
  end;

begin
  Lang := TTypeLang(-1);
  BitType := TBitType(-1);
  for I := Low(BitVisualizerTypes) to High(BitVisualizerTypes) do
  begin
    if TypeName = BitVisualizerTypes[I].TypeName then
    begin
      Lang := BitVisualizerTypes[I].TypeLang;
      BitType := BitVisualizerTypes[I].BitType;
      Break;
    end;
  end;

  if Lang = tlDelphi then
  begin
    if not FormatResult(EvalResult, BitType, Result) then
      Result := EvalResult;
  end else if Lang = tlCpp then
  begin
    Result := EvalResult;
    if Supports(BorlandIDEServices, IOTADebuggerServices, DebugSvcs) then
      CurProcess := DebugSvcs.CurrentProcess;
    if CurProcess <> nil then
    begin
      CurThread := CurProcess.CurrentThread;
      if CurThread <> nil then
      begin
        EvalRes := CurThread.Evaluate(Expression+'.Val', @ResultStr, Length(ResultStr),
          CanModify, eseAll, '', ResultAddr, ResultSize, ResultVal, '', 0);
        if EvalRes = erOK then
        begin
          if FormatSettings.DecimalSeparator <> '.' then
          begin
            for I := 0 to Length(ResultStr) - 1 do
            begin
              if ResultStr[I] = '.' then
              begin
                ResultStr[I] := FormatSettings.DecimalSeparator;
                break;
              end;
            end;
          end;
          if not FormatResult(ResultStr, BitType, Result) then
            Result := EvalResult;
        end else if EvalRes = erDeferred then
        begin
          FCompleted := False;
          FDeferredResult := '';
          FNotifierIndex := CurThread.AddNotifier(Self);
          while not FCompleted do
            DebugSvcs.ProcessDebugEvents;
          CurThread.RemoveNotifier(FNotifierIndex);
          FNotifierIndex := -1;
          if (FDeferredResult = '') or not FormatResult(FDeferredResult, BitType, Result) then
            Result := EvalResult;
        end;
      end;
    end;
  end;
end;

function TDebuggerBitVisualizer.GetSupportedTypeCount: Integer;
begin
  Result := Length(BitVisualizerTypes);
end;

procedure TDebuggerBitVisualizer.GetSupportedType(Index: Integer; var TypeName: string;
  var AllDescendants: Boolean);
begin
  AllDescendants := False;
  TypeName := BitVisualizerTypes[Index].TypeName;
end;

function TDebuggerBitVisualizer.GetVisualizerDescription: string;
begin
  Result := sBitVisualizerDescription;
end;

function TDebuggerBitVisualizer.GetVisualizerIdentifier: string;
begin
  Result := ClassName;
end;

function TDebuggerBitVisualizer.GetVisualizerName: string;
begin
  Result := sBitVisualizerName;
end;

var
  DateTimeVis: IOTADebuggerVisualizer;

procedure Register;
begin
  DateTimeVis := TDebuggerBitVisualizer.Create;
  (BorlandIDEServices as IOTADebuggerServices).RegisterDebugVisualizer(DateTimeVis);
end;

procedure RemoveVisualizer;
var
  DebuggerServices: IOTADebuggerServices;
begin
  if Supports(BorlandIDEServices, IOTADebuggerServices, DebuggerServices) then
  begin
    DebuggerServices.UnregisterDebugVisualizer(DateTimeVis);
    DateTimeVis := nil;
  end;
end;

initialization

finalization
  RemoveVisualizer;
end.

