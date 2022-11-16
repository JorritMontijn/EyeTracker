function output = isint(input)
% ISINT True for variables that are integers (non-fractional).
%    ISINT(A) returns true for every element of A that is an integer and false
%    otherwise.
% 
%    Example:
%       isint(	[0	1i	-2	2.2	inf	nan])
%       returns [1	 0	 1	  0	  0	  0]
     
	output = isnumeric(input) & (real(input) == input) & (floor(input) == input) & isfinite(input);
end

