// ***************************************************************************
//
// Delphi MVC Framework
//
// Copyright (c) 2010-2024 Daniele Teti and the DMVCFramework Team
//
// https://github.com/danieleteti/delphimvcframework
//
// ***************************************************************************
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// ***************************************************************************
//
// This IDE expert is based off of the one included with the DUnitX
// project.  Original source by Robert Love.  Adapted by Nick Hodges and Daniele Teti.
//
// The DUnitX project is run by Vincent Parrett and can be found at:
//
// https://github.com/VSoftTechnologies/DUnitX
// ***************************************************************************


unit DMVC.Expert.ProjectWizardEx;

interface

uses
  ToolsApi,
  VCL.Graphics,
  PlatformAPI;

type
  TDMVCNewProjectWizard = class
  private
    class function GetUnitName(aFilename: string): string;
  public
    class procedure RegisterDMVCProjectWizard(const APersonality: string);
  end;

implementation

{$I ..\sources\dmvcframework.inc}

uses
  MVCFramework.Logger,
  DccStrs,
  System.IOUtils,
  VCL.Controls,
  VCL.Forms,
  WinApi.Windows,
  System.SysUtils,
  DMVC.Expert.Forms.NewProjectWizard,
  DMVC.Expert.CodeGen.NewDMVCProject,
  DMVC.Expert.CodeGen.NewControllerUnit,
  DMVC.Expert.CodeGen.NewWebModuleUnit,
  ExpertsRepository,
  JsonDataObjects,
  DMVC.Expert.Commons;

resourcestring
  sNewDMVCProjectCaption = 'DelphiMVCFramework Project';
  sNewDMVCProjectHint = 'Create New DelphiMVCFramework Project with Controller';

  { TDUnitXNewProjectWizard }

class function TDMVCNewProjectWizard.GetUnitName(aFilename: string): string;
begin
  Result := TPath.GetFileNameWithoutExtension(aFilename);
end;

class procedure TDMVCNewProjectWizard.RegisterDMVCProjectWizard(const APersonality: string);
begin
  RegisterPackageWizard(TExpertsRepositoryProjectWizardWithProc.Create(APersonality, sNewDMVCProjectHint, sNewDMVCProjectCaption,
    'DMVC.Wizard.NewProjectWizard', // do not localize
    'DMVCFramework', 'DMVCFramework Team - https://github.com/danieleteti/delphimvcframework', // do not localize
    procedure
    var
      WizardForm: TfrmDMVCNewProject;
      ModuleServices: IOTAModuleServices;
      Project: IOTAProject;
      Config: IOTABuildConfiguration;
      ControllerUnit: IOTAModule;
      JSONRPCUnit: IOTAModule;
      WebModuleUnit: IOTAModule;
      ControllerCreator: IOTACreator;
      JSONRPCUnitCreator: IOTACreator;
      WebModuleCreator: IOTAModuleCreator;
      lProjectSourceCreator: IOTACreator;
      lJSONRPCUnitName: string;
      lJSON: TJSONObject;
    begin
      WizardForm := TfrmDMVCNewProject.Create(Application);
      try
        if WizardForm.ShowModal = mrOk then
        begin
          LogI('step10');
          if not WizardForm.AddToProjectGroup then
          begin
            (BorlandIDEServices as IOTAModuleServices).CloseAll;
          end;
          ModuleServices := (BorlandIDEServices as IOTAModuleServices);
          LogI('step20');
          lJSON := WizardForm.GetConfigModel;

          // Create Project Source
          lProjectSourceCreator := TDMVCProjectFile.Create(APersonality, lJSON);
          LogI('step30');
          TDMVCProjectFile(lProjectSourceCreator).DefaultPort := WizardForm.ServerPort;
          TDMVCProjectFile(lProjectSourceCreator).UseMSHeapOnWindows := WizardForm.UseMSHeapOnWindows;
          ModuleServices.CreateModule(lProjectSourceCreator);
          LogI('step40');
          Project := GetActiveProject;
          LogI('step50');

          Config := (Project.ProjectOptions as IOTAProjectOptionsConfigurations).BaseConfiguration;
          Config.SetValue(sUnitSearchPath, '$(DMVC)');
          Config.SetValue(sFramework, 'VCL');
          LogI('step60');
          // Create Controller Unit
          if WizardForm.CreateControllerUnit then
          begin
            LogI('step70');
            ControllerCreator := TNewControllerUnitEx.Create(
              lJSON,
              WizardForm.CreateIndexMethod,
              WizardForm.CreateCRUDMethods,
              WizardForm.CreateActionFiltersMethods,
              WizardForm.ControllerClassName,
              APersonality);
            LogI('step80');
            ControllerUnit := ModuleServices.CreateModule(ControllerCreator);
            LogI('step90');
            if Project <> nil then
            begin
              Project.AddFile(ControllerUnit.FileName, True);
            end;
          end;

          lJSONRPCUnitName := '';
          // Create JSONRPC Unit
          if lJSON.B[TConfigKey.jsonrpc_generate] then
          begin
            LogI('step100');
            JSONRPCUnitCreator := TNewJSONRPCUnitEx.Create(
              lJSON,
              //WizardForm.JSONRPCClassName,
              APersonality);
            LogI('step110');
            JSONRPCUnit := ModuleServices.CreateModule(JSONRPCUnitCreator);
            LogI('step120');
            lJSONRPCUnitName := GetUnitName(JSONRPCUnit.FileName);
            //lJSON.S[TConfigKey.jsonrpc_unit_name] := lJSONRPCUnitName;
            if Project <> nil then
            begin
              Project.AddFile(JSONRPCUnit.FileName, True);
              LogI('step130');
            end;
          end;

          LogI('step140');
          // Create Webmodule Unit
          WebModuleCreator := TNewWebModuleUnitEx.Create(
            lJSON,
            WizardForm.WebModuleClassName,
            WizardForm.ControllerClassName,
            GetUnitName(ControllerUnit.FileName),
            WizardForm.Middlewares,
            WizardForm.JSONRPCClassName,
            lJSONRPCUnitName,
            APersonality);
          WebModuleUnit := ModuleServices.CreateModule(WebModuleCreator);
          LogI('step150');
          if Project <> nil then
          begin
            Project.AddFile(WebModuleUnit.FileName, True);
          end;
        end;
      finally
        WizardForm.Free;
      end;
    end,
    function: Cardinal
    begin
      Result := LoadIcon(HInstance, 'DMVCNewProjectIcon');
    end, TArray<string>.Create(cWin32Platform, cWin64Platform
    {$IF Defined(TOKYOORBETTER)}
    , cLinux64Platform
    {$ENDIF}
    ), nil));
end;

end.
