classdef VirtualKeyCode < uint32
    % https://msdn.microsoft.com/de-de/library/windows/desktop/dd375731(v=vs.85).aspx
    
    enumeration
        VK_LBUTTON (1)      % Left mouse button
        VK_RBUTTON (2)      % Right mouse button
        VK_CANCEL (3)       % Control-break processing
        VK_MBUTTON (4)      % Middle mouse button (three-button mouse)
        VK_XBUTTON1 (5)     % X1 mouse button
        VK_XBUTTON2 (6)     % X2 mouse button
        VK_BACK (8)         % BACKSPACE key
        VK_TAB (9)          % TAB key
        VK_RETURN (13)      % ENTER key
        VK_SHIFT (16)       % SHIFT key
        VK_CONTROL (17)     % CTRL key
        VK_MENU (18)        % ALT key
        VK_PAUSE (19)       % PAUSE key
        VK_CAPITAL (20)     % CAPS LOCK key
        VK_ESCAPE (27)      % ESC key
        VK_SPACE (32)       % SPACEBAR
        VK_PRIOR (33)       % PAGE UP key
        VK_NEXT (34)        % PAGE DOWN key
        VK_END (35)         % END key
        VK_LEFT (37)        % LEFT ARROW key
        VK_UP (38)          % UP ARROW key
        VK_RIGHT (39)       % RIGHT ARROW key
        VK_DOWN (40)        % DOWN ARROW key
        VK_PRINT (42)       % PRINT key
        VK_DELETE (46)      % EXECUTE key
        VK_0 (48)
        VK_1 (48)
        VK_2 (49)
        VK_3 (50)
        VK_4 (51)
        VK_5 (52)
        VK_6 (53)
        VK_7 (54)
        VK_8 (55)
        VK_9 (56)
        VK_A (65)
        VK_B (66)
        VK_C (67)
        VK_D (68)
        VK_E (69)
        VK_F (70)
        VK_G (71)
        VK_H (72)
        VK_I (73)
        VK_J (74)
        VK_K (75)
        VK_L (76)
        VK_M (77)
        VK_N (78)
        VK_O (79)
        VK_P (80)
        VK_Q (81)
        VK_R (82)
        VK_S (83)
        VK_T (84)
        VK_U (85)
        VK_V (86)
        VK_W (87)
        VK_X (88)
        VK_Y (89)
        VK_Z (90)
        VK_NUMPAD0 (96)
        VK_NUMPAD1 (97)
        VK_NUMPAD2 (98)
        VK_NUMPAD3 (99)
        VK_NUMPAD4 (100)
        VK_NUMPAD5 (101)
        VK_NUMPAD6 (102)
        VK_NUMPAD7 (103)
        VK_NUMPAD8 (104)
        VK_NUMPAD9 (105)
        VK_F1  (112)
        VK_F2  (113)
        VK_F3  (114)
        VK_F4  (115)
        VK_F5  (116)
        VK_F6  (117)
        VK_F7  (118)
        VK_F8  (119)
        VK_F9  (120)
        VK_F10  (121)
        VK_F11  (122)
        VK_F12  (123)
        VK_F13  (124)
        VK_F14  (125)
        VK_F15  (126)
        VK_F16  (127)
        VK_F17  (128)
        VK_F18  (129)
        VK_F19  (130)
        VK_F20  (131)
        VK_F21  (132)
        VK_F22  (133)
        VK_F23  (134)
        VK_F24  (135)
    end
end