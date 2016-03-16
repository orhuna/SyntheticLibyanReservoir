% Generate3DSLModels.m
% Script to generate multiple StudioSL runs starting from some base case
clear all; close all;
clc
%% Set Paths
BaselineRunDirectory = '../DataFiles/';
TrialName = 'ScopingRuns';

% Path to baseline case
BaseCaseDatPath = [BaselineRunDirectory 'BaseCase.dat'];

% Allocate a cell array that we will use to store the baseline
s=cell(GetNumberOfLines(BaseCaseDatPath),1);

fid = fopen(BaseCaseDatPath);
lineCt = 1;
tline = fgetl(fid);

while ischar(tline)
    s{lineCt} = (tline);
    lineCt = lineCt + 1;
    tline = fgetl(fid);
end

%%  Latin Hypercube Sampling
NbSimu = 5;     % Number of simulations
NbParams = 12;  % Number of parameters we will vary

% Fixed seed for reproducibility
rng('shuffle');

%  NbSimu x NbParams Matrix
ParametersValues = lhsdesign(NbSimu,NbParams,'criterion',...
    'correlation','iterations',50);

%% Set Parameter Ranges
% ParameterRanges is a struct that contains
Normal = 0;
Uniform = 1;

ParameterRanges = struct();
ParameterRanges.('Swir') = [0.2 0.2 Normal]; % Irreducible water saturation
ParameterRanges.('Swor') = [0.2 0.2 Normal]; % Irreducible oil saturation
ParameterRanges.('krw_end') = [0.3 0.2 Normal]; % End point water rel perm
ParameterRanges.('kro_end') = [0.7 0.2 Normal]; % End point oil rel perm
ParameterRanges.('no') = [2.5 0.2 Normal]; % Oil exponent
ParameterRanges.('nw') = [2 0.2 Normal]; % Oil exponent
ParameterRanges.('FaultMulti1') = [0.2 0.8 Uniform]; % Fault 1 trans multiplier
ParameterRanges.('FaultMulti2') = [0.2 0.8 Uniform]; % Fault 2 trans multiplier
ParameterRanges.('FaultMulti3') = [0.2 0.8 Uniform]; % Fault 3 trans multiplier
ParameterRanges.('FaultMulti4') = [0.2 0.8 Uniform]; % Fault 4 trans multiplier
ParameterRanges.('Viscosity') = [4 0.2 Normal];      % Oil viscosity
ParameterRanges.('OWC') = [1061 1076 Uniform];       % Oil water contact

%% Generate actual parameters
ParameterNames = fieldnames(ParameterRanges);
ParameterMatrix = struct();

rng('shuffle');

for i = 1:numel(ParameterNames)
    ParameterName = ParameterNames{i};
    ParameterRange = ParameterRanges.(ParameterName);
    
    if (i <7)
        if (ParameterRange(3) == Normal)
            Value = ParameterRange(1) + ParameterRange(2)* ParametersValues(:,i);
        elseif(ParameterRange(3) == Uniform)
            Value = ParameterRange(1) + ParametersValues(:,i)*...
                (ParameterRange(2) - ParameterRange(1));
        end
    else
        
        if (ParameterRange(3) == Normal)
            Value = ParameterRange(1) + ParameterRange(2)* randn(NbSimu,1);
        elseif(ParameterRange(3) == Uniform)
            Value = ParameterRange(1) + rand(NbSimu,1)*...
                (ParameterRange(2) - ParameterRange(1));
        end
    end
    
    ParameterMatrix.(ParameterName) = Value;
end

OutputDirectory = ['../DataFiles/' TrialName '/' ];
mkdir_if_not_exist(OutputDirectory);
save([OutputDirectory '/ParameterMatrix.mat'],'ParameterMatrix');

%% Construct Rel Perm curves to verify consistency
clear SW_corey_m;
RelPermEntries = 25;
SW_corey_m = zeros(NbSimu,RelPermEntries);
krw_model = zeros(NbSimu,RelPermEntries);
kro_model = zeros(NbSimu,RelPermEntries);

for i=1:NbSimu
    SW_corey_m(i,:) = linspace(ParameterMatrix.('Swir')(i), ...
        1 - ParameterMatrix.('Swor')(i),RelPermEntries);
end

for i=1:NbSimu
    krw_model(i,:) = ParameterMatrix.('krw_end')(i) .* ...
        ((SW_corey_m(i,:)-ParameterMatrix.('Swir')(i))./...
        (1-ParameterMatrix.('Swir')(i)-...
        ParameterMatrix.('Swor')(i))).^ParameterMatrix.('nw')(i);
    kro_model(i,:) = ParameterMatrix.('kro_end')(i) .* ...
        ((1 - SW_corey_m(i,:) - ParameterMatrix.('Swor')(i))./...
        (1 - ParameterMatrix.('Swir')(i) - ParameterMatrix.('Swor')(i))).^...
        ParameterMatrix.('no')(i);
    
    plot(SW_corey_m(i,:), krw_model(i,:),'b-', SW_corey_m(i,:), ...
        kro_model(i,:), 'r-');
    xlabel('S_w');
    ylabel('Relative Permeability');
    xlim([0 1]); ylim([0 1]); grid on; hold on;
end

%% Writing out the 'dat' files
BaselineRunDirectory = OutputDirectory;

for k=1:NbSimu
    
    FolderNameIteration = [BaselineRunDirectory 'Run', num2str(k)];
    
    %creating an new folder for this iteration
    %checking if there is already a folder with that name
    if exist(FolderNameIteration,'dir') ~= 7
        mkdir(FolderNameIteration);
    end
    
    % Create new file
    file_name = [FolderNameIteration '/Run', num2str(k), '.dat'];
    fileID = fopen(file_name,'w+');
    
    % Loading everything before the Faultmultiplier
    for j=1:33
        fprintf(fileID,'%c',s{j});
        fprintf(fileID,'\n');
    end
    
    % Fault Multiplier
    fprintf(fileID,'%s\n', '--Fault Multiplier');
    fprintf(fileID,'%s\n', 'MULTFLT');
    s{34}=['fault_1' blanks(1) ...
        num2str(ParameterMatrix.('FaultMulti1')(k)) blanks(1) '/'];
    s{35}=['fault_2' blanks(1) ...
        num2str(ParameterMatrix.('FaultMulti2')(k)) blanks(1) '/'];
    s{36}=['fault_3' blanks(1) ...
        num2str(ParameterMatrix.('FaultMulti3')(k)) blanks(1) '/'];
    s{37}=['fault_4' blanks(1) ...
        num2str(ParameterMatrix.('FaultMulti4')(k)) blanks(1) '/'];
    
    fprintf(fileID,'%s',s{34});
    fprintf(fileID,'\n');
    fprintf(fileID,'%s',s{35});
    fprintf(fileID,'\n');
    fprintf(fileID,'%s',s{36});
    fprintf(fileID,'\n');
    fprintf(fileID,'%s',s{37});
    fprintf(fileID,'\n');
    fprintf(fileID,'%s\n\n', '/');
    
    
    % Writing everything before Viscosity
    for j=40:50
        fprintf(fileID,'%c',s{j});
        fprintf(fileID,'\n');
    end
    
    % Printing the PVTs out - in this case only viscosity is changed
    fprintf(fileID,'\n');
    fprintf(fileID,'%s\n', 'BAVG');
    fprintf(fileID,'%s\n', '1.2 0.178 1.0 /');
    fprintf(fileID,'%s\n', 'CVISCOSITIES');
    s{54}=[num2str(ParameterMatrix.('Viscosity')(k)) blanks(1) '0.1 0.4 /'];
    fprintf(fileID,'%s',s{54});
    fprintf(fileID,'\n');
    fprintf(fileID,'%s\n', 'SCDENSITIES UNITS= METRIC');
    fprintf(fileID,'%s\n', '800. 0.9611 1009. /');
    fprintf(fileID,'\n');
    fprintf(fileID,'%s\n', 'RSAVG = 0.0');
    fprintf(fileID,'\n');
    
    % Writing everything before Viscosity
    for j=60:74
        fprintf(fileID,'%c',s{j});
        fprintf(fileID,'\n');
    end
    
    % Writing out the Relperms
    
    formatSpecRelPerm = '%4.4f %4.8f %4.8f %s\n';
    
    fprintf(fileID,'%s\n', 'KRWO');
    fprintf(fileID,'%s\n', '--    Sw        krw       kro      Pc');
    for j=1:RelPermEntries
        fprintf(fileID,formatSpecRelPerm,SW_corey_m(k,j),...
            krw_model(k,j),kro_model(k,j));
        fprintf(fileID,'\n');
    end
    fprintf(fileID, '/\n');
    fprintf(fileID,'%s\n', 'END RELPERMS');
    %check if the slash works in the simulation
    
    % Writing everything before OWC
    for j=102:112
        fprintf(fileID,'%c',s{j});
        fprintf(fileID,'\n');
    end
    
    % Writing out the OWC
    fprintf(fileID,'%s\n', 'OWC');
    s{114}=['-', num2str(ParameterMatrix.('OWC')(k))];
    fprintf(fileID,'%s',s{114});
    fprintf(fileID,'\n');
    fprintf(fileID, '/\n');
    
    % Writing out the rest
    for j=116:165
        fprintf(fileID,'%c',s{j});
        fprintf(fileID,'\n');
    end
    
    fclose(fileID);
end






