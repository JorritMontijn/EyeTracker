function r =  circ_dist(x,y)
%
% r = circ_dist(alpha, beta)
%   Pairwise difference x_i-y_i around the circle computed efficiently.
%
%   Input:
%     alpha      sample of linear random variable
%     beta       sample of linear random variable or one single angle
%
%   Output:
%     r       matrix with differences
%
% References:
%     Biostatistical Analysis, J. H. Zar, p. 651
%
% PHB 3/19/2009
%
% Circular Statistics Toolbox for Matlab

% By Philipp Berens, 2009
% berens@tuebingen.mpg.de - www.kyb.mpg.de/~berens/circStat.html

if nargin == 1 && numel(x) == 2
	y = x(end);
	x = x(1);
end

z=bsxfun(@rdivide,exp(1i*x),exp(1i*y));
r = atan2(imag(z), real(z));