% THIS FUNCTION IS PRIVATE AND SHOULD NOT BE CALLED BY OUTSIDE CODE!
%
%Edited by Jorrit: added identifier to connection failure to catch error
%
function [sm] = ChkConn( sm )
	
	if( sm.in_chkconn )
		return;
	end
	sWarn = warning('off');
	sm.in_chkconn = 1;
	
	if( sm.handle == -1 )
		
		sm.handle = CalinsNetMex( 'create', sm.host, sm.port );
		if( isempty( CalinsNetMex( 'connect', sm.handle ) ) )
			error([mfilename ':ConnectFail'], 'Unable to connect to server.' );
		end
		
		sm.ver = DoQueryCmd( sm, 'GETVERSION' );
		
	else
		
		ok = CalinsNetMex( 'sendstring', sm.handle, sprintf( 'NOOP\n' ) );
		
		if( isempty( ok ) || isempty( CalinsNetMex( 'readline', sm.handle ) ) )
			
			if( isempty( CalinsNetMex( 'connect', sm.handle ) ) )
				error( 'Still unable to connect to server.' );
			end
		end
	end
	%restore
	warning(sWarn);
	sm.in_chkconn = 0;
end
