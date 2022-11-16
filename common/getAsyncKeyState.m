function keypressed = getAsyncKeyState(key)

if ~libisloaded('user32')
    loadlibrary('user32.dll','user32.h')
end

keypressed = calllib('user32','GetAsyncKeyState',int32(key)) ~= 0;

end