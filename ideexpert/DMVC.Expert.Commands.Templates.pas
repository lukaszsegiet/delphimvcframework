unit DMVC.Expert.Commands.Templates;

interface

uses
  System.Generics.Collections, DMVC.Expert.CodeGen.Executor;

procedure FillProgramTemplates(Gen: TMVCCodeGenerator);
procedure FillControllerTemplates(Gen: TMVCCodeGenerator);
procedure FillWebModuleTemplates(Gen: TMVCCodeGenerator);
procedure FillWebModuleDFMTemplates(Gen: TMVCCodeGenerator);
procedure FillJSONRPCTemplates(Gen: TMVCCodeGenerator);

implementation

uses
  DMVC.Expert.Commons,
  DMVC.Expert.CodeGen.Commands;

procedure FillProgramTemplates(Gen: TMVCCodeGenerator);
begin
  Gen.Commands.AddRange([
    TUnitProgramCommand.Create,
    TUnitRunServerProcBody.Create,
    TUnitMainBeginEndCommand.Create
  ]);
end;

procedure FillControllerTemplates(Gen: TMVCCodeGenerator);
begin
  Gen.Commands.AddRange([
    TUnitControllerCommand.Create,
    TUnitControllerEntityDeclarationCommand.Create,
    TUnitControllerControllerDeclarationCommand.Create,
    TUnitFooterCommand.Create
    ]);
end;

procedure FillWebModuleTemplates(Gen: TMVCCodeGenerator);
begin
  Gen.Commands.AddRange([
    TUnitWebModuleDeclarationCommand.Create
    ]);
end;

procedure FillJSONRPCTemplates(Gen: TMVCCodeGenerator);
begin
  Gen.Commands.AddRange([
    TUnitJSONRPCDeclarationCommand.Create
    ]);
end;

procedure FillWebModuleDFMTemplates(Gen: TMVCCodeGenerator);
begin
  Gen.Commands.AddRange([
    TWebModuleDFMCommand.Create
    ]);
end;


end.
