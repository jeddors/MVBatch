function [p,t] = pcamv(x,pc)

% Principal Component Analysis.
%
% [p,t] = pca(x,pc)     % complete call
%
% INPUTS:
%
% x: (NxM) Two-way batch data matrix, N(observations) x M(variables)
%
% pc: number of principal components.
%
%
% OUTPUTS:
%
% p: (M x pc) matrix of loadings.
%
% t: (N x pc) matrix of scores.
%
%
% coded by: Jose Camacho Paez (josecamacho@ugr.es)
% last modification: 23/Apr/09
%
% Copyright (C) 2014  University of Granada, Granada
% Copyright (C) 2014  Jose Camacho Paez
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

% Parameters checking

if nargin < 2, error('Error in the number of arguments.'); end;
if ndims(x)~=2, error('Incorrect number of dimensions of x.'); end;
s = size(x);
if find(s<1), error('Incorrect content of x.'); end;
if pc<0, error('Incorrect value of prep.'); end;
dmin = min(s);
if pc>dmin, pc=dmin; end;

% Computation

if 10*s(1)>s(2),
        [p,t]=princomp(x);
        p = p(:,1:pc);
        t = t(:,1:pc);
else,
        [p,t]=princomp(x,'econ');
        p = p(:,1:pc);
        t = t(:,1:pc);
end
        



