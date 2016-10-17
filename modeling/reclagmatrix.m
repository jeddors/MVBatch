function y = reclagmatrix(x,lags)

% Fold two-way matrix to the original structure (KxJ)
%
% y = reclagmatrix(x,lags)     % complete call
%
%
% INPUTS:
%
% x: ((K-lag)x(J(1+lag))) lagged matrix. [x(k) ... x(k-lag+1) x(k -lag)]
%
% lag: (1x1) number of immediate lagged measurement-vectors (LMVs) added to the current
% one in the row of the unfolded matrix.
%
%
% OUTPUTS:
%
% y: (K,J) data matrix.
%
%
% coded by: Jos� M. Gonz�lez Mart�nez (jogonmar@gmail.com)
%
% Copyright (C) 2016  Technical University of Valencia, Valencia
% Copyright (C) 2016  Jos� M. Gonz�lez Mart�nez
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
if ndims(x)~=2, error('Incorrect number of dimensions of x.'); end
s = size(x);
if lags<0, error('Incorrect value of lags.'); end;
nvar = s(2)/(lags+1);
if ~isint(nvar), error('Incorrect value of lags.'); end;

y=x(:,1:nvar);
for i=1:lags   
   y = [y; x(end,i*nvar+1:(i+1)*nvar)];
end