function []=plot_contributions(xini, test, phases, flagmode, flagstatistics, prep, varNames, timek)

% Computes the D-statistic and SPE charts for on-line monitoring. 
%
% [pdet,ph,pr,detect,h,r,ph95,pr95,h95,r95,t,q] = plot_onstat(xini, test, phases, 
%   prep, opt) % call with standard parameters
%
% [pdet,ph,pr,detect,h,r,ph95,pr95,h95,r95,t,q] = plot_onstat(xini, test, phases, 
%   prep, opt, alph, alpr, alph95, alpr95) % output in MATLAB console
%
% [pdet,ph,pr,detect,h,r,ph95,pr95,h95,r95,t,q] = plot_onstat(xini, test, phases, 
%   prep, opt, alph, alpr, alph95, alpr95, axes1, axes2) % complete call
%
%
% INPUTS:
%
% xini: (KxJxI) three-way batch data matrix for calibration, K(sampling times) 
%       x J(variables) x I(batches)
%
% test: (KxJxI2) three-way batch data matrix for test, K(sampling times) 
%       x J(variables) x I2(batches)
%
% phases: (n_phasesx5) phases of the MP model. Each row contains the information 
%   of a phase, namely [PRESS, PCs, lags, initial time, end time]. 
%
% prep: (1x1) preprocesing of the data
%       0: no preprocessing.
%       1: trajectory centering (average trajectory subtraction)
%       2: 1 + trajectory-scaling (scales data so that each pair variable and 
%           sampling time has variance 1) (default)  
%       3: 1 + variable-scaling (scales data so that each variable has
%           variance 1)
%       4: variable centering (subtraction of the average value of each
%           variable)
%       5: 4 + variable-scaling. 
%
% opt: boolean (1x1) 
%       true: plot results.
%       false: do not plot results.
%
% flag
% codified by: Jose Gonzalez Martinez.



% Parameters checking

if nargin < 3, error('Numero de argumentos erroneos.'); end;


if ndims(xini)~=3, error('Incorrect number of dimensions of xini.'); end;
s = size(xini);
if find(s<1), error('Incorrect content of xini.'); end;

if ndims(test)~=2, error('Incorrect number of dimensions of test.'); end;
st=size(test);
if s(1)~=st(1) || s(2)~=st(2),
    error('Incorrect content of test.')
end

if ndims(phases)~=2, error('Incorrect number of dimensions of phases.'); end;
sp=size(phases);
if (sp(1)<1||sp(2)~=5), error('Incorrect content of phases.'); end;
if find(phases(:,1:3)<0), error('Incorrect content of phases.'); end;
if find(phases(:,4:5)<1), error('Incorrect content of phases.'); end;
if find(phases(:,3:5)>s(1)), error('Incorrect content of phases.'); end;
if flagmode < 0 || flagmode > 1, errodlg('Flag not expected.'); end
if flagstatistics < 0 || flagstatistics > 1, errodlg('Flag not expected.'); end
if nargin < 6, prep = 2; end;
if nargin < 7, varNames = []; end
if nargin < 8, timek=1; end


% Main code

num = s(3); 
m=sp(1);

[xce,av,sta] = preprocess3D(xini,prep);

if ndims(test)==3,
    for i=1:st(3),
        teste(:,:,i) = (test(:,:,i)-av)./sta;
    end
else
    teste = (test-av)./sta;
    st(3)=1;
end

t=[];
q=[];
pcs=[];
res=zeros(s(3),s(2),s(1));
jContribhotk = [];
contribresk = [];

if phases(:,2)>0,
    for i=1:m,
        ind=(max(phases(i,4)-phases(i,3),1):phases(i,5));
        ind_ini=find(ind==phases(i,4));
        xu=unfold(xce(ind,:,:),phases(i,3));
        [U,S,V] = svd(xu,'econ');
        tAll = U*S;
        pAll = V;
        p = pAll(:,1:phases(i,2));
        t = tAll(:,1:phases(i,2));
        
        % Projection of the test batch on the latent subspace
        testu=unfold(teste(ind,:,:),phases(i,3));
        tpred = testu*p;
        resb=testu-tpred*p';
        resb=fold(resb,1,phases(i,3));
        menor_en=phases(i,3)-ind_ini;        
        if ind_ini<phases(i,3)+1,
            menor_en=phases(i,3)-ind_ini;
            % Estimate covariance matrices for TSR-based imputation
            theta = cov(tAll);
            theta_A = cov(t);

            for j=0:menor_en,
                jindb=1:s(2)*(ind_ini+j);
                jind2=phases(i,4)+j; 
                % IMPUTATION USING TSR
                t_t = theta_A*p(jindb,:)'*p(jindb,:)*inv(p(jindb,:)'*pAll(jindb,:)*theta*pAll(jindb,:)'*p(jindb,:))*p(jindb,:)'*xu(1:s(3),jindb)';
                cov_inv=inv(cov(t_t'));
                t_t = theta_A*p(jindb,:)'*p(jindb,:)*inv(p(jindb,:)'*pAll(jindb,:)*theta*pAll(jindb,:)'*p(jindb,:))*p(jindb,:)'*testu(1,jindb)';
                % Calculate contributions to Hotelling-T2
                ck=[];
                for z = jindb(end-s(2)+1):jindb(end)
                    %ck = [ck,
                    %t_t'*cov_inv*(testu(1:st(3),z)'*p(z,:)*inv(p(jindb,:)'*p(jindb,:)))'];
                    
%                     dist=0;
%                     for a=1:phases(i,2)
%                         dist =  dist  + ((t_t(a)/sqrt(cov_inv(a,a)))^2)*p(z,a)^2;
%                     end 
%                     ck = [ck, testu(1,z).*sqrt(dist)];
                    

                    ck = [ck, real(t_t'*sqrt(cov_inv)*p(z,:)')];
                end
                a=t_t'*cov_inv*t_t;
                jContribhotk = [jContribhotk; ck];
                contribresk = [contribresk; (permute(teste(jind2,:,:),[3 2 1])-t_t'*p(jindb(end-s(2)+1:end),:)').^2]; 
                q=[q ;sum((permute(teste(jind2,:,:),[3 2 1])-t_t'*p(jindb(end-s(2)+1:end),:)').^2)];
            end        
        end
        ssc=size(t);
        j=1;
%         for o=1:s(3):ssc(1),
%             sc_model = t(o:o+s(3)-1,:);
%             cov_inv = inv(cov(sc_model));
%             indb=1:s(2)*(ind_ini+menor_en+j);
%             ck=[];
%             for z = indb(end-s(2)+1):indb(end)
%             %ck = [ck, t_t'*cov_inv*(testu(1:st(3),z)'*p(z,:)*inv(p(indb,:)'*p(indb,:)))'];
%             ck = [ck, tpred(j,:)*cov_inv*(testu(1:st(3),z)'*p(z,:)*inv(p(indb,:)'*p(indb,:)))'];
%             end
%             jContribhotk = [jContribhotk; ck];            j=j+1;
%        end
        for o=1:s(3):ssc(1),
            sc_model = t(o:o+s(3)-1,:);
            cov_inv = inv(cov(sc_model));
            indb=size(testu,2)-s(2)+1;
            ck=[];
            for z=indb:size(testu,2)
                %ck = [ck, tpred(j,:)*cov_inv*(testu(j,z)*p(z,:)*inv(p(indb:end,:)'*p(indb:end,:)))'];
                %ck = [ck, tpred(j,:)*sqrt(cov_inv)*p(z,:)'];
            end
            jContribhotk = [jContribhotk; ck];            j=j+1;
       end
        q=[q;squeeze(sum(sum(resb((phases(i,3)+1):end,:,:).^2,3),2))];
        contribresk = [contribresk; resb((phases(i,3)+1):end,:,:)]; 
        pcs=[pcs phases(i,2)*ones(1,phases(i,5)-phases(i,4)+1)];
    end
else
    res = permute(xce,[3 2 1]);
    q=squeeze(sum(sum(teste.^2,3),2));
    pcs=zeros(1,s(1));
end


switch flagstatistics  
    case 0
        label = 'Contribution to T^2';
        if ~flagmode
            % Calculation
            Sinv = inv(cov(t));  
            contrb = real(testu*p*sqrt(Sinv)*p')';
        else
           h=figure;
           bar(jContribhotk(timek,:));
           xlabel('Variables','FontSize',12,'FontWeight','bold');
           ylabel('Contribution to D','FontSize',12,'FontWeight','bold');
           return;
        end
    case 1
        label = 'Contribution to SPE';
        if ~flagmode
            % Contribution to SPE

            contrb = (unfold(resb,Inf).^2)';
        else
           h=figure;
           bar(contribresk(timek,:));
           xlabel('Variables','FontSize',12,'FontWeight','bold');
           ylabel('Contribution to SPE','FontSize',12,'FontWeight','bold');
           return;
        end
        
     otherwise
        errordlg('An error in depicting the contributions has occurred.');
end       

jContrib = zeros(s(2),1);
kContrib = zeros(s(1),1);

ovContrib = [];
for i=1:s(2)
    ovContrib = [ovContrib; contrb(i:s(2):s(1)*s(2))];
end 
for j=1:s(2)
    jContrib(j,1) = sum(contrb(j:s(2):s(1)*s(2)));
end
for k=1:s(1)
    kContrib(k,1)= sum(contrb((k-1)*s(2)+1:s(2)*k));
end
Diagnosis(xini, test, av, ovContrib, jContrib, kContrib, phases(:,4), varNames,label);
