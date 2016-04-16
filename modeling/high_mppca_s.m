function [mp_model,text_tot] = high_mppca_s(arg,clu_ini,pc_ini,cross,console,text_tot)

% Top-Down step, high-level procedure of MPPCA.
% Division in the samples of the unfolded data. The improvement measure is
% the summed square error. 
%
% [mp_model,text_tot] = high_mppca_s(arg,clu_ini,pc_ini,cross) % Output in MATLAB console
% [mp_model,text_tot] = high_mppca_s(arg,clu_ini,pc_ini,cross,console,text_tot) % Complete call
%
%
% INPUTS:
%
% arg: (structure) parameters for the algorithm.
%   arg.xini:(KxJxI) three-way batch data matrix, K(sampling times) x J(variables)
%           x I(batches)
%   arg.lag: (1x1) number of immediate lagged measurement-vectors (LMVs) added to the current
%           one in the row of the unfolded matrix.
%   arg.T: (1x1) improvement threshold for subdivisionin MPPCA.
%   arg.cross: (structure) the parameters.  
%       arg.cross.leave_m: (text) cross-validation procedure
%       arg.cross.blocks_r: (1x1) maximum number of blocks of samples
%       arg.cross.blocks_c: (1x1) maximum number of blocks of variables
%       arg.cross.fold_m: (text) folding method
%       arg.cross.order: (structure) to define a constant random ordering of columns and
%               rows.
%           arg.cross.order.input: (boolean)
%                   true: take ordering from the structure.
%                   false: compute it ramdomly (by default).
%           arg.cross.order.cols: (1xn_cols) columns ordering.
%           arg.cross.order.rows: (1xn_rows) rows ordering.
%   arg.absolute: (boolean) absolute improvement (true) or relative improvement
%           (false) in MPPCA.
%   arg.gamma: (1x1) factor to adjust the improvement of an additional PC and of a
%           division in MPPCA:
%           - [0-Inf]: constant value. 
%           - [-Inf-0): criterium of parsimony.
%   arg.minsize: (1x1) minimum number of sampling times in a phase in MPPCA
%   arg.n: (1x1) initial number of PCs in MPPCA
%   arg.prep: (1x1) preprocesing of the data
%           0: no preprocessing.
%           1: trajectory centering (average trajectory subtraction)
%           2: 1 + trajectory-scaling (scales data so that each pair variable and 
%               sampling time has variance 1) (default)  
%           3: 1 + variable-scaling (scales data so that each variable has
%               variance 1)
%           4: variable centering (subtraction of the average value of each
%               variable)
%           5: 4 + variable-scaling. 
%
% clu_ini: (n_timesx1) interval to analyze.
%
% pc_ini: (1x1) initial number of PCs.
%
% cross: (structure) the parameters.  
%   cross.leave_m: (text) cross-validation procedure
%   cross.blocks_r: (1x1) maximum number of blocks of samples
%   cross.blocks_c: (1x1) maximum number of blocks of variables
%   cross.fold_m: (text) folding method
%   cross.order: (structure) to define a constant random ordering of columns and
%       rows.
%       cross.order.input: (boolean)
%           true: take ordering from the structure.
%           false: compute it ramdomly (by default).
%       cross.order.cols: (1xn_cols) columns ordering.
%       cross.order.rows: (1xn_rows) rows ordering.
%
% console: (1x1) handle of the EditText of the interface, 0 stands for the
%   MATLAB console (by default)
%
% text_tot: (text) input text with information of the analysis ([] by default).
%
%
% OUTPUTS:
%
% mp_model: (structure) MP model (use the command "help MP_toolbox_h" for
%       more info)
%
% text_tot: (text) output text with information of the analysis.
%
%
% codified by: Jos� Camacho P�ez.
% version: 0.1
% last modification: 31/Oct/08.

% Parameters checking

if nargin < 4, error('Error in the number of arguments.'); end;
if nargin < 5, console = 0; end;
if nargin < 6, text_tot = []; end;

% Initialization

if arg.absolute
    baseline = crossval3D_s(arg.xini,0,arg.lag,clu_ini,arg.cross.leave_m,arg.cross.blocks_r,arg.cross.blocks_c,arg.cross.fold_m,arg.prep,arg.cross.order);
else
    baseline = cross;
end

repite = true;
pc = pc_ini;
clu = clu_ini;
s = size(arg.xini);
phase=find(clu_ini);
tree = [cross,pc,arg.lag,phase(1),phase(end)]; 

% Repite loop

while repite,
    text_tot = cprint(console,sprintf('Phase [%d, %d] with %d LVs ....',phase(1),phase(end),pc),text_tot);
    
    % Add a new PC
    if pc<s(2)*(arg.lag+1),
        cross1 = crossval3D_s(arg.xini,pc+1,arg.lag,clu_ini,arg.cross.leave_m,arg.cross.blocks_r,arg.cross.blocks_c,arg.cross.fold_m,arg.prep,arg.cross.order);
    else
        cross1 = Inf;
    end
    
    % Add a subdivision
    zone = find(clu);
    if length(zone) < 2*arg.minsize + arg.lag || pc==0,
        cross2=Inf;
    else
        clu2 = clu;
        zone2 = (max(1,zone(1)-arg.lag):zone(end))';
        
        [clu2(zone2(arg.lag+1:end)),q1,q2,indc] = low_mppca_s(arg.xini(zone2,:,:),pc,arg.lag,arg.minsize,arg.prep);
        [cross2,press2] = crossval3D_s(arg.xini,pc,arg.lag,clu2,arg.cross.leave_m,arg.cross.blocks_r,arg.cross.blocks_c,arg.cross.fold_m,arg.prep,arg.cross.order);
    end
    
    % Compute improvements
    
    imp1 = (cross - cross1)/baseline;
    imp2 = arg.gamma * (cross - cross2)/baseline;
    
    if isnan(imp2),
        imp2=0;
    end
    
    
    % Comparison
    if imp1 >= imp2,
        if imp1 > arg.T,
            % Add a PC         
            text_tot = cprint(console,'Add new PC',text_tot,2);
            
            cross = cross1;
            if ~arg.absolute, baseline = cross1; end;
            pc = pc+1;
            tree = [tree;cross,pc,arg.lag,phase(1),phase(end)]; 
        else
            repite = false;
        end
    else
        repite = false;
        if imp2 > arg.T,
                  
            text_tot = cprint(console,'Add new Division',text_tot,2);
            
            % Recursive call for phase 1
            indx_a = find(clu2==1);
            clu_a = zeros(size(clu2));
            clu_a(indx_a) = 1;
            [cross2,press2b] = crossval3D_s(arg.xini,pc,arg.lag,clu_a,arg.cross.leave_m,arg.cross.blocks_r,arg.cross.blocks_c,arg.cross.fold_m,arg.prep,arg.cross.order);
            [mp_model_a,text_tot] = high_mppca_s(arg,clu_a,pc,sum(press2b(indx_a)),console,text_tot);
            
            % Recursive call for phase 2
            indx_b = find(clu2==2);
            clu_b = zeros(size(clu2));
            clu_b(indx_b) = 1;
            [mp_model_b,text_tot] = high_mppca_s(arg,clu_b,pc,sum(press2(indx_b)),console,text_tot);
            
            % Joint data
            clu_a(indx_a) = mp_model_a.clu(indx_a);
            m_a = max(clu_a);
            clu(indx_a) = clu_a(indx_a);
            clu(indx_b) = mp_model_b.clu(indx_b) + m_a;
            tree = [tree; mp_model_a.tree; mp_model_b.tree];
        end
    end

end

mp_model=struct('type','SW-Div','arg',arg,'clu',clu,'phases',[],'tree',tree,'cumpress',0,'press',[]);
