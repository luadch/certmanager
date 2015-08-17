--[[

    Luadch Certmanager

        Author:         pulsar
        License:        GNU GPLv2
        Environment:    wxLua-2.8.12.3-Lua-5.1.5-MSW-Unicode

        v1.2: 2015-08-17
            - using a random generated value for CN
            - servercert and cacert using the same CN value now
            - small gui changes

        v1.1: 2015-07-28

            - removing "cacert.pem" and "cakey.pem" auto deletion
                - the ca file is required for the keyprint verification in new clients

        v1.0: 2015-06-08

            - creating a ca cert first to sign the servercert
                - needed to prevent the "zero depth self signed cert error" / thx Night & Kungen
            - moved ressource file "res1.dll" to "libs/res1.dll"
            - moved ressource file "res2.dll" to "libs/res2.dll"
            - dirpicker control: add button to create new folder
            - improve log_broadcast function for smoother autoscroll
            - change some log output colors
            - add new acknowledgements to the about window
            - some other small code improvements

        v0.9: 2015-05-29

            - removed "img/icon_task.ico"
            - removed "img/icon_window.ico"
            - added "res1.dll" icon ressource file
            - added "res2.dll" icon ressource file
            - add tab icons
            - change style of the "about" window
            - change openssl command params
                - generate certs with Elliptic-Curve key (ECDSA) using prime256v1
            - creating "keyprint.txt" file if keyprint is generated on tab 2

        v0.8: 2015-04-20

            - create a keyprint.txt file
            - add a progress bar during the progress
            - optimized log output
            - code cleaning
            - renamed "lib" folder to "libs"
            - renamed "app_se.config" to "openssl.config"
            - moved "openssl.config" to "libs/openssl/"
            - changed method to execute openssl commands
                - using async process (child process)  to redirect input stream
            - enable make_cert button only if destination path is given
            - add "docs" folder
                - move "LICENSE" from "src" to "docs"
                - add "CHANGELOG"

        v0.7: 2015-04-18

            - add openssl config to prevent errors if no openssl installation was found  / thx Kaas
            - add tabs
            - customize textcolor in log

        v0.6: 2015-04-17

            - fix some typos
            - creating cert as temp_* first
            - increase app width (+40px)

        v0.5: 2015-04-17

            - fix small bug with path

        v0.4: 2015-04-17

            - update to OpenSSL to v1.0.2a
            - using a simpler method to generate the certificate
                - its required for a successful verification between Hub and Clients
                - without password
                - without issuer fields
                - without subject fields
                - a similar method is used by FlexHub

        v0.3:

            - added "Clear" button for issuer fields on tab 2
            - added "Clear" button for subject fields on tab 2
            - colorize "Make cert" button green if verify check was successfull
            - clear filepicker path if certinfos are not parseble
            - add keyprint field to tab 3
            - removed tab 1

        v0.2:

            - bigger size of keyprint field
            - add "Get" button to get keyprint on tab 1
            - clear keyprint field on each filepicker event on tab 1
            - changing some fonttypes (field titles on all tabs)
            - some typo fixes
            - using "*.pem" wildcard for fileselector
                - check if file is parseble
            - clear all field values in tab 1 if values exists and keyprint from new file is not parseble
            - clear all field values in tab 3 if values exists and cerinfos from new file are not parseble
            - reduce app_height to "677px"
            - update openssl to: v1.0.1j from 15 Oct 2014

        v0.1:

            - generate keyprint from cert
            - make cert
            - show certinfo

]]


-------------------------------------------------------------------------------------------------------------------------------------
--// IMPORTS //----------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

local filetype = ( os.getenv( "COMSPEC" ) and os.getenv( "WINDIR" and ".dll" ) ) or ".so"

package.path = package.path .. ";" .. "././libs/?/?.lua;"
package.cpath = package.cpath .. ";" .. "././libs/?/?" .. filetype .. ";"

local wx = require( "wx" )
local basexx = require( "basexx" )

-------------------------------------------------------------------------------------------------------------------------------------
--// BASIC CONST //------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

local app_name                 = "Luadch Certmanager"
local app_version              = "v1.2"
local app_copyright            = "Copyright © by pulsar"
local app_license              = "License: GPLv2"

local app_width                = 800
local app_height               = 637

local notebook_width           = 795
local notebook_height          = 270

local log_width                = 795
local log_height               = 322

local file_icon                = "libs/res1.dll"
local file_icon_2              = "libs/res2.dll"

local menu_title               = "Menu"
local menu_exit                = "Exit"
local menu_about               = "About"

-------------------------------------------------------------------------------------------------------------------------------------
--// IDS //--------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

id_dirpicker                   = 10
id_dirpicker_path              = 20
id_make_cert_button            = 30
id_filepicker                  = 40
id_filepicker_path             = 50

-------------------------------------------------------------------------------------------------------------------------------------
--// EVENT HANDLER //----------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

function HandleEvents( event )
    local name = event:GetEventObject():DynamicCast( "wxWindow" ):GetName()
end

-------------------------------------------------------------------------------------------------------------------------------------
--// ICONS //------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--// icons for task and app titlebar
local icons = wx.wxIconBundle()
icons:AddIcon( wx.wxIcon( file_icon, 3, 16, 16 ) )
icons:AddIcon( wx.wxIcon( file_icon, 3, 32, 32 ) )

--// icons for tabs
local tab_1_ico = wx.wxIcon( file_icon_2 .. ";0", wx.wxBITMAP_TYPE_ICO, 16, 16 )
local tab_2_ico = wx.wxIcon( file_icon_2 .. ";1", wx.wxBITMAP_TYPE_ICO, 16, 16 )

local tab_1_bmp = wx.wxBitmap(); tab_1_bmp:CopyFromIcon( tab_1_ico )
local tab_2_bmp = wx.wxBitmap(); tab_2_bmp:CopyFromIcon( tab_2_ico )

local notebook_image_list = wx.wxImageList( 16, 16 )

local tab_1_img = notebook_image_list:Add( wx.wxBitmap( tab_1_bmp ) )
local tab_2_img = notebook_image_list:Add( wx.wxBitmap( tab_2_bmp ) )

-------------------------------------------------------------------------------------------------------------------------------------
--// FONTS //------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

local cert_font = wx.wxFont( 7, wx.wxMODERN, wx.wxNORMAL, wx.wxNORMAL, false, "Verdana" )
local log_font = wx.wxFont( 8, wx.wxMODERN, wx.wxNORMAL, wx.wxNORMAL, false, "Lucida Console" )
local about_normal_1 = wx.wxFont( 9, wx.wxMODERN, wx.wxNORMAL, wx.wxNORMAL, false, "Verdana" )
local about_normal_2 = wx.wxFont( 10, wx.wxMODERN, wx.wxNORMAL, wx.wxNORMAL, false, "Verdana" )
local about_bold = wx.wxFont( 10, wx.wxMODERN, wx.wxNORMAL, wx.wxFONTWEIGHT_BOLD, false, "Verdana" )

-------------------------------------------------------------------------------------------------------------------------------------
--// DIFFERENT FUNCS //--------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--// about window
local show_about_window = function( frame )
    local di = wx.wxDialog(
        frame,
        wx.wxID_ANY,
        "About",
        wx.wxDefaultPosition,
        wx.wxSize( 320, 270 ),
        wx.wxSTAY_ON_TOP + wx.wxRESIZE_BORDER --wx.wxTHICK_FRAME --wx.wxCAPTION-- + wx.wxFRAME_TOOL_WINDOW
    )
    di:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
    di:SetMinSize( wx.wxSize( 320, 270 ) )
    di:SetMaxSize( wx.wxSize( 320, 270 ) )

    local icon = wx.wxIcon( file_icon, 3, 32, 32 )
    local logo = wx.wxBitmap()
    logo:CopyFromIcon( icon )
    local X, Y = logo:GetWidth(), logo:GetHeight()

    local control = wx.wxStaticBitmap( di, wx.wxID_ANY, wx.wxBitmap( logo ), wx.wxPoint( 120, 10 ), wx.wxSize( X, Y ) )
    control:Centre( wx.wxHORIZONTAL )

    control = wx.wxStaticText(
        di,
        wx.wxID_ANY,
        app_name .. " " .. app_version,
        wx.wxPoint( 27, 45 )
    )
    control:SetFont( about_bold )
    control:Centre( wx.wxHORIZONTAL )

    control = wx.wxStaticText(
        di,
        wx.wxID_ANY,
        app_copyright,
        wx.wxPoint( 25, 65 )
    )
    control:SetFont( about_normal_2 )
    control:Centre( wx.wxHORIZONTAL )

    control = wx.wxStaticText(
        di,
        wx.wxID_ANY,
        app_license,
        wx.wxPoint( 25, 80 )
    )
    control:SetFont( about_normal_2 )
    control:Centre( wx.wxHORIZONTAL )

    local panel = wx.wxPanel( di, wx.wxID_ANY, wx.wxPoint( 0, 115 ), wx.wxSize( 275, 90 ) )
    panel:SetBackgroundColour( wx.wxColour( 225, 225, 225 ) )
    panel:Centre( wx.wxHORIZONTAL )

    control = wx.wxStaticText(
        di,
        wx.wxID_ANY,
        "Greets fly out to:\n\n" ..
        "Baal, HeavyMetalMichi, Kungen, Night,\n" ..
        "Kaas and all the others for testing.\n" ..
        "Thanks.",
        wx.wxPoint( 10, 125 )
    )
    control:SetFont( about_normal_1 )
    control:SetBackgroundColour( wx.wxColour( 225, 225, 225 ) )
    control:Centre( wx.wxHORIZONTAL )

    -------------------------------------------------------------------------------------------------------------------------

    local button_ok = wx.wxButton( di, wx.wxID_ANY, "CLOSE", wx.wxPoint( 100, 221 ), wx.wxSize( 70, 20 ) )
    button_ok:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
    button_ok:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_BUTTON_CLICKED,
        function( event )
            di:Destroy()
        end
    )
    button_ok:Centre( wx.wxHORIZONTAL )

    -------------------------------------------------------------------------------------------------------------------------
    local result = di:ShowModal()
end

--// default timestamp for log window
local timestamp = function()
    return "[" .. os.date( "%Y-%m-%d/%H:%M:%S" ) .. "] "
end

--// generate cmd for log broadcast
local log_broadcast = function( control, msg, color )
    local timestamp = "[" .. os.date( "%Y-%m-%d/%H:%M:%S" ) .. "] "
    local before, after
    local log_color = function( l, m, c )
        before = l:GetNumberOfLines()
        l:SetInsertionPointEnd()
        l:SetDefaultStyle( wx.wxTextAttr( wx.wxLIGHT_GREY ) )
        l:WriteText( timestamp )
        after = l:GetNumberOfLines()
        l:ScrollLines( before - after + 2 )
        before = l:GetNumberOfLines()
        l:SetInsertionPointEnd()
        l:SetDefaultStyle( wx.wxTextAttr( c ) )
        l:WriteText( ( m .. "\n" ) )
        after = l:GetNumberOfLines()
        l:ScrollLines( before - after + 2 )
    end
    if control and msg and ( color == "WHITE" ) then log_color( control, msg, wx.wxWHITE ) end
    if control and msg and ( color == "GREEN" ) then log_color( control, msg, wx.wxGREEN ) end
    if control and msg and ( color == "RED" ) then log_color( control, msg, wx.wxRED ) end
    if control and msg and ( color == "CYAN" ) then log_color( control, msg, wx.wxCYAN ) end
    if control and msg and ( color == "ORANGE" ) then log_color( control, msg, wx.wxColour( 254, 96, 1 ) ) end
end

--// trim whitespaces from both ends of a string
local trim = function( s )
    return string.find( s, "^%s*$" ) and "" or string.match( s, "^%s*(.*%S)" )
end

--// trim ghost chars from input stream
local trim2 = function( s )
    local t = {
        "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
        "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
        "1", "2", "3", "4", "5", "6", "7", "8", "9", "0",
    }
    local str_tbl = {}
    for c in s:gmatch"." do for k, v in pairs( t ) do if v == c then table.insert( str_tbl, c ) end end end
    return table.concat( str_tbl )
end

--// get cert informations
local show_certinfo = function( path )
    local cmd, msg, proc, stream, certinfo_issuer, certinfo_subject, certinfo_dates, fingerprint
    local tbl_issuer, tbl_subject, tbl_dates, keyp_hex, keyp_base32, err = {}, {}, {}, "", "", false
    local lib_path = '.\\libs\\openssl\\'
    local stream_len = 500

    --// issuer
    cmd = lib_path .. 'openssl.exe x509 -noout -in ' .. '"' .. trim( path ) .. '"' .. ' -issuer'
    proc = wx.wxProcess.Open( cmd )  --> using wxEXEC_ASYNC
    proc:Redirect()
    stream = proc:GetInputStream()
    certinfo_issuer = stream:Read( stream_len )
    proc = nil
    if not string.find( certinfo_issuer, "issuer" ) then
        err = true
    else
        for k, v in string.gmatch( trim( certinfo_issuer ):gsub( "issuer= /", "" ):gsub( "/", "  " ), "(%S+)=(%S+)" ) do tbl_issuer[ k ] = v end
    end

    --// subject
    cmd = lib_path .. 'openssl.exe x509 -noout -in ' .. '"' .. trim( path ) .. '"' .. ' -subject'
    proc = wx.wxProcess.Open( cmd )  --> using wxEXEC_ASYNC
    proc:Redirect()
    stream = proc:GetInputStream()
    certinfo_subject = stream:Read( stream_len )
    proc = nil
    if not string.find( certinfo_subject, "subject" ) then
        err = true
    else
        for k, v in string.gmatch( trim( certinfo_subject ):gsub( "subject= /", "" ):gsub( "/", "  " ), "(%S+)=(%S+)" ) do tbl_subject[ k .. "2" ] = v end
    end

    --// dates
    cmd = lib_path .. 'openssl.exe x509 -noout -in ' .. '"' .. trim( path ) .. '"' .. ' -dates'
    proc = wx.wxProcess.Open( cmd )  --> using wxEXEC_ASYNC
    proc:Redirect()
    stream = proc:GetInputStream()
    certinfo_dates = stream:Read( stream_len )
    proc = nil
    if not string.find( certinfo_dates, "notBefore" ) then
        err = true
    else
        for str in trim( certinfo_dates ):gmatch( "[^\r\n]+" ) do for k, v in string.gmatch( str, "(%S+)=(.*)" ) do tbl_dates[ k ] = v end end
    end

    --// keyprint
    cmd = lib_path .. 'openssl.exe x509 -fingerprint -noout -sha256 -in "' .. trim( path ) .. '"'
    proc = wx.wxProcess.Open( cmd )  --> using wxEXEC_ASYNC
    proc:Redirect()
    stream = proc:GetInputStream()
    fingerprint = stream:Read( stream_len )
    proc = nil
    if not string.find( fingerprint, "SHA256 Fingerprint" ) then
        err = true
    else
        keyp_hex = trim2( trim( fingerprint ):gsub( " ", "" ):gsub( "(%S+)=(%S+)", "%2" ):lower():gsub( ":", "" ) )
        keyp_base32 = basexx.to_base32( basexx.from_hex( keyp_hex ) ):gsub( "=", "" )
    end

    return tbl_issuer, tbl_subject, tbl_dates, keyp_hex, keyp_base32, err
end

--// returns a random generated alphanumerical cn for the certs with length = len / based on a function by blastbeat (from luadch's util.lua)
local generate_cn = function( len )
    local len = tonumber( len )
    if not ( type( len ) == "number" ) or ( len < 0 ) or ( len > 1000 ) then len = 20 end
    local lower = { "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
                    "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z" }
    local upper = { "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
                    "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z" }
    math.randomseed( os.time() )
    local pwd = ""
    for i = 1, len do
        local X = math.random( 0, 9 )
        if X < 4 then
            pwd = pwd .. math.random( 0, 9 )
        elseif ( X >= 4 ) and ( X < 6 ) then
            pwd = pwd .. upper[ math.random( 1, 25 ) ]
        else
            pwd = pwd .. lower[ math.random( 1, 25 ) ]
        end
    end
    return pwd
end

-------------------------------------------------------------------------------------------------------------------------------------
--// MENUBAR //----------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

local menu = wx.wxMenu()
menu:Append( wx.wxID_ABOUT, menu_about ) --, menu_about_status )
menu:Append( wx.wxID_EXIT, menu_exit ) --, menu_exit_status )

local menu_bar = wx.wxMenuBar()
menu_bar:Append( menu, menu_title )

-------------------------------------------------------------------------------------------------------------------------------------
--// FRAME //------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

local frame = wx.wxFrame(
    wx.NULL,
    wx.wxID_ANY,
    app_name .. " " .. app_version,
    wx.wxPoint( 0, 0 ),
    wx.wxSize( app_width, app_height ),
    wx.wxMINIMIZE_BOX + wx.wxSYSTEM_MENU + wx.wxCAPTION + wx.wxCLOSE_BOX + wx.wxCLIP_CHILDREN
)

frame:Centre( wx.wxBOTH )
frame:SetMenuBar( menu_bar )
frame:SetIcons( icons )

local panel = wx.wxPanel( frame, wx.wxID_ANY, wx.wxPoint( 0, 0 ), wx.wxSize( app_width, app_height ) )
panel:SetBackgroundColour( wx.wxColour( 225, 225, 225 ) )

local notebook = wx.wxNotebook( panel, wx.wxID_ANY, wx.wxPoint( 0, 0 ), wx.wxSize( notebook_width, notebook_height ) )

local tab_1 = wx.wxPanel( notebook, wx.wxID_ANY )
tabsizer_1 = wx.wxBoxSizer( wx.wxVERTICAL )
tab_1:SetSizer( tabsizer_1 )
tabsizer_1:SetSizeHints( tab_1 )
tab_1:SetBackgroundColour( wx.wxColour( 225, 225, 225 ) )

local tab_2 = wx.wxPanel( notebook, wx.wxID_ANY )
tabsizer_2 = wx.wxBoxSizer( wx.wxVERTICAL )
tab_2:SetSizer( tabsizer_2 )
tabsizer_2:SetSizeHints( tab_2 )
tab_2:SetBackgroundColour( wx.wxColour( 225, 225, 225 ) )

notebook:AddPage( tab_1, "CREATE NEW CERTIFICATE" )
notebook:AddPage( tab_2, "GENERATE KEYPRINT FROM EXISTING CERTIFICATE" )

notebook:SetImageList( notebook_image_list )

notebook:SetPageImage( 0, tab_1_img )
notebook:SetPageImage( 1, tab_2_img )

-------------------------------------------------------------------------------------------------------------------------------------
--// LOG WINDOW //-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

local make_cert = wx.wxButton()

local log_window = wx.wxTextCtrl( panel, wx.wxID_ANY, "", wx.wxPoint( 0, 268 ), wx.wxSize( log_width, log_height ), wx.wxTE_READONLY + wx.wxTE_MULTILINE + wx.wxTE_RICH + wx.wxSUNKEN_BORDER + wx.wxHSCROLL )
log_window:SetBackgroundColour( wx.wxColour( 0, 0, 0 ) )
log_window:SetFont( log_font )

log_broadcast( log_window, app_name .. " ready.", "ORANGE" )

-------------------------------------------------------------------------------------------------------------------------------------
--// Tab 1 //------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

local control

--// controls tab 1
control = wx.wxStaticBox( tab_1, wx.wxID_ANY, "Subject Common Name", wx.wxPoint( 55, 80 ), wx.wxSize( 250, 43 ) )
control:SetFont( cert_font )
local certinfo_7 = wx.wxTextCtrl( tab_1, wx.wxID_ANY, "", wx.wxPoint( 70, 96 ), wx.wxSize( 220, 20 ), wx.wxTE_READONLY + wx.wxSUNKEN_BORDER + wx.wxTE_CENTRE )
certinfo_7:SetBackgroundColour( wx.wxColour( 225, 225, 225 ) )
certinfo_7:SetForegroundColour( wx.wxRED )

control = wx.wxStaticBox( tab_1, wx.wxID_ANY, "Issuer Common Name", wx.wxPoint( 55, 130 ), wx.wxSize( 250, 43 ) )
control:SetFont( cert_font )
local certinfo_1 = wx.wxTextCtrl( tab_1, wx.wxID_ANY, "", wx.wxPoint( 70, 146 ), wx.wxSize( 220, 20 ), wx.wxTE_READONLY + wx.wxSUNKEN_BORDER + wx.wxTE_CENTRE )
certinfo_1:SetBackgroundColour( wx.wxColour( 225, 225, 225 ) )
certinfo_1:SetForegroundColour( wx.wxRED )

control = wx.wxStaticBox( tab_1, wx.wxID_ANY, "Valid from", wx.wxPoint( 482, 80 ), wx.wxSize( 250, 43 ) )
control:SetFont( cert_font )
local certinfo_2 = wx.wxTextCtrl( tab_1, wx.wxID_ANY, "", wx.wxPoint( 497, 96 ), wx.wxSize( 220, 20 ), wx.wxTE_READONLY + wx.wxSUNKEN_BORDER + wx.wxTE_CENTRE )
certinfo_2:SetBackgroundColour( wx.wxColour( 225, 225, 225 ) )
certinfo_2:SetForegroundColour( wx.wxRED )

control = wx.wxStaticBox( tab_1, wx.wxID_ANY, "Valid until", wx.wxPoint( 482, 130 ), wx.wxSize( 250, 43 ) )
control:SetFont( cert_font )
local certinfo_3 = wx.wxTextCtrl( tab_1, wx.wxID_ANY, "", wx.wxPoint( 497, 146 ), wx.wxSize( 220, 20 ), wx.wxTE_READONLY + wx.wxSUNKEN_BORDER + wx.wxTE_CENTRE )
certinfo_3:SetBackgroundColour( wx.wxColour( 225, 225, 225 ) )
certinfo_3:SetForegroundColour( wx.wxRED )

control = wx.wxStaticBox( tab_1, wx.wxID_ANY, "Keyprint", wx.wxPoint( 165, 185 ), wx.wxSize( 440, 43 ) )
control:SetFont( cert_font )
local keyp_textctrl_1 = wx.wxTextCtrl( tab_1, wx.wxID_ANY, "", wx.wxPoint( 180, 200 ), wx.wxSize( 410, 20 ), wx.wxTE_READONLY + wx.wxSUNKEN_BORDER + wx.wxTE_CENTRE )
keyp_textctrl_1:SetBackgroundColour( wx.wxColour( 225, 225, 225 ) )
keyp_textctrl_1:SetForegroundColour( wx.wxRED )

control = wx.wxStaticBox( tab_1, wx.wxID_ANY, "Certificate destination path", wx.wxPoint( 5, 15 ), wx.wxSize( 777, 48 ) )
control:SetFont( cert_font )
local dirpicker_certpath = wx.wxTextCtrl( tab_1, id_dirpicker_path, "", wx.wxPoint( 20, 30 ), wx.wxSize( 670, 20 ), wx.wxTE_PROCESS_ENTER + wx.wxSUNKEN_BORDER )

local dirpicker = wx.wxDirPickerCtrl(
    tab_1,
    id_dirpicker,
    wx.wxGetCwd(),
    "Choose destination folder for cert:",
    wx.wxPoint( 698, 30 ),
    wx.wxSize( 80, 25 ),
    wx.wxDIRP_DEFAULT_STYLE + wx.wxDIRP_DIR_MUST_EXIST - wx.wxDIRP_USE_TEXTCTRL - wx.wxDIRP_CHANGE_DIR
)

dirpicker:Connect( id_dirpicker, wx.wxEVT_COMMAND_DIRPICKER_CHANGED,
    function( event )
        local path = dirpicker:GetPath()

        certinfo_1:SetValue( "" )
        certinfo_2:SetValue( "" )
        certinfo_3:SetValue( "" )
        certinfo_7:SetValue( "" )
        keyp_textctrl_1:SetValue( "" )
        dirpicker_certpath:SetValue( path )

        log_broadcast( log_window, "Using destination path: '" .. path .. "'", "CYAN" )
        make_cert:Enable( true )
    end
)

make_cert = wx.wxButton( tab_1, id_make_cert_button, "Make cert", wx.wxPoint( 352, 115 ), wx.wxSize( 80, 25 ) )
make_cert:SetBackgroundColour( wx.wxColour( 200, 200, 200 ) )
make_cert:Disable()
make_cert:Connect( id_make_cert_button, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        make_cert:Disable()
        wx.wxBeginBusyCursor()

        local progressDialog = wx.wxProgressDialog(
            app_name,
            "",
            18,
            wx.NULL,
            wx.wxPD_AUTO_HIDE + wx.wxPD_APP_MODAL + wx.wxPD_SMOOTH
        )
        progressDialog:SetSize( wx.wxSize( 600, 130 ) )
        progressDialog:Centre( wx.wxBOTH )

        progressDialog:Update( 1, "Generate: 'temp_cakey.pem'" )
        log_broadcast( log_window, "Generate: 'temp_cakey.pem'", "GREEN" )

        certinfo_1:SetValue( "" )
        certinfo_2:SetValue( "" )
        certinfo_3:SetValue( "" )
        certinfo_7:SetValue( "" )
        keyp_textctrl_1:SetValue( "" )

        local dest_path = dirpicker:GetPath():gsub( "/", "\\" )
        local curr_path = wx.wxGetCwd()
        local lib_path = '.\\libs\\openssl\\'
        local rnd_cn = generate_cn( 32 )

        local cmd1 = 'openssl ecparam -out temp_cakey.pem -name prime256v1 -genkey'
        local cmd2 = 'openssl req -config ' .. lib_path .. 'openssl.config -new -x509 -days 3650 -key temp_cakey.pem -out temp_cacert.pem -subj /CN=' .. rnd_cn
        local cmd3 = 'openssl ecparam -out temp_serverkey.pem -name prime256v1 -genkey'
        local cmd4 = 'openssl req -config ' .. lib_path .. 'openssl.config -new -key temp_serverkey.pem -out temp_servercert.pem -subj /CN=' .. rnd_cn
        local cmd5 = 'openssl x509 -req -days 3650 -in temp_servercert.pem -CA temp_cacert.pem -CAkey temp_cakey.pem -set_serial 01 -out temp_servercert.pem'

        local cmd_1 = lib_path .. cmd1
        local cmd_2 = lib_path .. cmd2
        local cmd_3 = lib_path .. cmd3
        local cmd_4 = lib_path .. cmd4
        local cmd_5 = lib_path .. cmd5

        local proc_1 = wx.wxProcess(); proc_1:Redirect()
        local pid_1 = nil

        local proc_2 = wx.wxProcess(); proc_2:Redirect()
        local pid_2 = nil

        local proc_3 = wx.wxProcess(); proc_3:Redirect()
        local pid_3 = nil

        local proc_4 = wx.wxProcess(); proc_4:Redirect()
        local pid_4 = nil

        local proc_5 = wx.wxProcess(); proc_5:Redirect()
        local pid_5 = nil

        proc_1:Connect( wx.wxEVT_END_PROCESS, function( event )
            proc_1 = nil
            wx.wxSleep( 1 )
            progressDialog:Update( 2, "Generate: 'temp_cacert.pem'" )
            log_broadcast( log_window, "Generate: 'temp_cacert.pem'", "GREEN" )
            pid_2 = wx.wxExecute( cmd_2, wx.wxEXEC_ASYNC + wx.wxEXEC_MAKE_GROUP_LEADER, proc_2 )
        end )

        proc_2:Connect( wx.wxEVT_END_PROCESS, function( event )
            proc_2 = nil
            wx.wxSleep( 1 )
            progressDialog:Update( 3, "Generate: 'temp_serverkey.pem'" )
            log_broadcast( log_window, "Generate: 'temp_serverkey.pem'", "GREEN" )
            pid_3 = wx.wxExecute( cmd_3, wx.wxEXEC_ASYNC + wx.wxEXEC_MAKE_GROUP_LEADER, proc_3 )
        end )

        proc_3:Connect( wx.wxEVT_END_PROCESS, function( event )
            proc_3 = nil
            wx.wxSleep( 1 )
            progressDialog:Update( 4, "Generate: 'temp_servercert.pem'" )
            log_broadcast( log_window, "Generate: 'temp_servercert.pem'", "GREEN" )
            pid_4 = wx.wxExecute( cmd_4, wx.wxEXEC_ASYNC + wx.wxEXEC_MAKE_GROUP_LEADER, proc_4 )
        end )

        proc_4:Connect( wx.wxEVT_END_PROCESS, function( event )
            proc_4 = nil
            wx.wxSleep( 1 )
            progressDialog:Update( 5, "Sign: 'temp_servercert.pem'  with: 'temp_cacert.pem'" )
            log_broadcast( log_window, "Sign: 'temp_servercert.pem'  with: 'temp_cacert.pem'", "GREEN" )
            pid_5 = wx.wxExecute( cmd_5, wx.wxEXEC_ASYNC + wx.wxEXEC_MAKE_GROUP_LEADER, proc_5 )
        end )

        proc_5:Connect( wx.wxEVT_END_PROCESS, function( event )
            proc_5 = nil
            wx.wxSleep( 1 )
            progressDialog:Update( 6, "Certificates successfully created." )
            log_broadcast( log_window, "Certificates successfully created.", "WHITE" )
            wx.wxSleep( 2 )

            dirpicker_certpath:SetValue( "" )

            local keyp_path = curr_path .. "\\temp_servercert.pem"
            local tbl_issuer, tbl_subject, tbl_dates, keyp_hex, keyp_base32, err = show_certinfo( keyp_path )

            if err then
                progressDialog:Update( 7, "Error can not parse data from file, file is not valid." )
                log_broadcast( log_window, "Error can not parse data from file, file is not valid.", "RED" )
                wx.wxSleep( 3 )

                wx.wxMessageBox( "Error can not parse data from file, file is not valid.", "Parsing fingerprint...", wx.wxOK + wx.wxICON_INFORMATION, frame )
            else
                progressDialog:Update( 7, "Parsing fingerprint..." )
                log_broadcast( log_window, "Parsing fingerprint...", "GREEN" )
                local CN = tbl_issuer[ "CN" ] or ""
                local CN2 = tbl_subject[ "CN2" ] or ""
                local notBefore = tbl_dates[ "notBefore" ] or ""
                local notAfter = tbl_dates[ "notAfter" ] or ""
                wx.wxSleep( 1 )

                progressDialog:Update( 8, "Import informations..." )
                log_broadcast( log_window, "Import informations...", "GREEN" )
                certinfo_1:SetValue( CN )
                certinfo_2:SetValue( notBefore )
                certinfo_3:SetValue( notAfter )
                certinfo_7:SetValue( CN2 )
                keyp_textctrl_1:SetValue( keyp_base32 )
                wx.wxSleep( 1 )

                log_broadcast( log_window, "SHA256 keyprint as HEX: " .. keyp_hex, "WHITE" )
                log_broadcast( log_window, "SHA256 keyprint as BASE32: " .. keyp_base32, "WHITE" )
                log_broadcast( log_window, "Import keyprint...", "GREEN" )

                progressDialog:Update( 9, "Creating keyprint file..." )
                log_broadcast( log_window, "Creating keyprint file...", "GREEN" )
                local f = wx.wxFile( curr_path .. "\\temp_keyprint.txt", wx.wxFile.write )
                f:Write( keyp_base32 )
                f:Flush()
                f:Close()
                wx.wxSleep( 1 )

                progressDialog:Update( 10, "Copy and rename file: 'temp_servercert.pem'" )
                log_broadcast( log_window, "Copy file: 'temp_servercert.pem'  to: '"..dest_path.."\\servercert.pem'", "CYAN" )
                wx.wxCopyFile( curr_path .. "\\temp_servercert.pem", dest_path .. "\\servercert.pem", true )
                wx.wxSleep( 1 )

                progressDialog:Update( 11, "Copy and rename file: 'temp_serverkey.pem'" )
                log_broadcast( log_window, "Copy file: 'temp_serverkey.pem'  to: '"..dest_path.."\\serverkey.pem'", "CYAN" )
                wx.wxCopyFile( curr_path .. "\\temp_serverkey.pem", dest_path .. "\\serverkey.pem", true )
                wx.wxSleep( 1 )

                progressDialog:Update( 12, "Copy and rename file: 'temp_cacert.pem'" )
                log_broadcast( log_window, "Copy file: 'temp_cacert.pem'  to: '"..dest_path.."\\cacert.pem'", "CYAN" )
                wx.wxCopyFile( curr_path .. "\\temp_cacert.pem", dest_path .. "\\cacert.pem", true )
                wx.wxSleep( 1 )

                progressDialog:Update( 13, "Copy and rename file: 'temp_cakey.pem'" )
                log_broadcast( log_window, "Copy file: 'temp_cakey.pem'  to: '"..dest_path.."\\cakey.pem'", "CYAN" )
                wx.wxCopyFile( curr_path .. "\\temp_cakey.pem", dest_path .. "\\cakey.pem", true )
                wx.wxSleep( 1 )

                progressDialog:Update( 14, "Copy and rename file: 'temp_keyprint.txt'" )
                log_broadcast( log_window, "Copy file: 'temp_keyprint.txt'  to: '"..dest_path.."\\keyprint.txt'", "CYAN" )
                wx.wxCopyFile( curr_path .. "\\temp_keyprint.txt", dest_path .. "\\keyprint.txt", true )
                wx.wxSleep( 1 )

                progressDialog:Update( 15, "Deleting file: 'temp_servercert.pem'" )
                log_broadcast( log_window, "Deleting file: '"..curr_path.."\\temp_servercert.pem'", "CYAN" )
                wx.wxRemoveFile( curr_path .. "\\temp_servercert.pem" )
                wx.wxSleep( 1 )

                progressDialog:Update( 16, "Deleting file: 'temp_serverkey.pem'" )
                log_broadcast( log_window, "Deleting file: '"..curr_path.."\\temp_serverkey.pem'", "CYAN" )
                wx.wxRemoveFile( curr_path .. "\\temp_serverkey.pem" )
                wx.wxSleep( 1 )

                progressDialog:Update( 17, "Deleting file: 'temp_keyprint.txt'" )
                log_broadcast( log_window, "Deleting file: '"..curr_path.."\\temp_keyprint.txt'", "CYAN" )
                wx.wxRemoveFile( curr_path .. "\\temp_keyprint.txt" )
                wx.wxSleep( 1 )

                progressDialog:Update( 18, "Deleting file: 'temp_cakey.pem'" )
                log_broadcast( log_window, "Deleting file: '"..curr_path.."\\temp_cakey.pem'", "CYAN" )
                wx.wxRemoveFile( curr_path .. "\\temp_cakey.pem" )
                wx.wxSleep( 1 )

                progressDialog:Update( 19, "Deleting file: 'temp_cacert.pem'" )
                log_broadcast( log_window, "Deleting file: '"..curr_path.."\\temp_cacert.pem'", "CYAN" )
                wx.wxRemoveFile( curr_path .. "\\temp_cacert.pem" )
                wx.wxSleep( 1 )
            end

            progressDialog:Update( 20, "Done." )
            log_broadcast( log_window, "Done.", "WHITE" )
            wx.wxSleep( 2 )

            log_broadcast( log_window, app_name .. " ready.", "ORANGE" )

            progressDialog:Destroy()
            wx.wxEndBusyCursor()

            wx.wxMessageBox( "Done.", "INFO", wx.wxOK + wx.wxICON_INFORMATION, frame )
        end )

        pid_1 = wx.wxExecute( cmd_1, wx.wxEXEC_ASYNC + wx.wxEXEC_MAKE_GROUP_LEADER, proc_1 )

    end
)

-------------------------------------------------------------------------------------------------------------------------------------
--// Tab 2 //------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--// controls tab 2
control = wx.wxStaticBox( tab_2, wx.wxID_ANY, "Subject Common Name", wx.wxPoint( 55, 80 ), wx.wxSize( 250, 43 ) )
control:SetFont( cert_font )
local certinfo_8 = wx.wxTextCtrl( tab_2, wx.wxID_ANY, "", wx.wxPoint( 70, 96 ), wx.wxSize( 220, 20 ), wx.wxTE_READONLY + wx.wxSUNKEN_BORDER + wx.wxTE_CENTRE )
certinfo_8:SetBackgroundColour( wx.wxColour( 225, 225, 225 ) )
certinfo_8:SetForegroundColour( wx.wxRED )

control = wx.wxStaticBox( tab_2, wx.wxID_ANY, "Issuer Common Name", wx.wxPoint( 55, 130 ), wx.wxSize( 250, 43 ) )
control:SetFont( cert_font )
local certinfo_4 = wx.wxTextCtrl( tab_2, wx.wxID_ANY, "", wx.wxPoint( 70, 146 ), wx.wxSize( 220, 20 ), wx.wxTE_READONLY + wx.wxSUNKEN_BORDER + wx.wxTE_CENTRE )
certinfo_4:SetBackgroundColour( wx.wxColour( 225, 225, 225 ) )
certinfo_4:SetForegroundColour( wx.wxRED )

control = wx.wxStaticBox( tab_2, wx.wxID_ANY, "Valid from", wx.wxPoint( 482, 80 ), wx.wxSize( 250, 43 ) )
control:SetFont( cert_font )
local certinfo_5 = wx.wxTextCtrl( tab_2, wx.wxID_ANY, "", wx.wxPoint( 497, 96 ), wx.wxSize( 220, 20 ), wx.wxTE_READONLY + wx.wxSUNKEN_BORDER + wx.wxTE_CENTRE )
certinfo_5:SetBackgroundColour( wx.wxColour( 225, 225, 225 ) )
certinfo_5:SetForegroundColour( wx.wxRED )

control = wx.wxStaticBox( tab_2, wx.wxID_ANY, "Valid until", wx.wxPoint( 482, 130 ), wx.wxSize( 250, 43 ) )
control:SetFont( cert_font )
local certinfo_6 = wx.wxTextCtrl( tab_2, wx.wxID_ANY, "", wx.wxPoint( 497, 146 ), wx.wxSize( 220, 20 ), wx.wxTE_READONLY + wx.wxSUNKEN_BORDER + wx.wxTE_CENTRE )
certinfo_6:SetBackgroundColour( wx.wxColour( 225, 225, 225 ) )
certinfo_6:SetForegroundColour( wx.wxRED )

control = wx.wxStaticBox( tab_2, wx.wxID_ANY, "Keyprint", wx.wxPoint( 165, 185 ), wx.wxSize( 440, 43 ) )
control:SetFont( cert_font )
local keyp_textctrl_2 = wx.wxTextCtrl( tab_2, wx.wxID_ANY, "", wx.wxPoint( 180, 200 ), wx.wxSize( 410, 20 ), wx.wxTE_READONLY + wx.wxSUNKEN_BORDER + wx.wxTE_CENTRE )
keyp_textctrl_2:SetBackgroundColour( wx.wxColour( 225, 225, 225 ) )
keyp_textctrl_2:SetForegroundColour( wx.wxRED )

control = wx.wxStaticBox( tab_2, wx.wxID_ANY, "Certificate source file", wx.wxPoint( 5, 15 ), wx.wxSize( 777, 48 ) )
control:SetFont( cert_font )
local filepicker_certpath2 = wx.wxTextCtrl( tab_2, id_filepicker_path, "", wx.wxPoint( 20, 30 ), wx.wxSize( 670, 20 ), wx.wxTE_PROCESS_ENTER + wx.wxSUNKEN_BORDER )

local filepicker_cert2 = wx.wxFilePickerCtrl(
    tab_2,
    id_filepicker,
    wx.wxGetCwd(),
    wx.wxFileSelectorPromptStr,
    "servercert.pem", --wx.wxFileSelectorDefaultWildcardStr,
    wx.wxPoint( 698, 30 ),
    wx.wxSize( 80, 25 ),
    wx.wxFLP_OPEN + wx.wxFLP_FILE_MUST_EXIST
)

filepicker_cert2:Connect( id_filepicker, wx.wxEVT_COMMAND_FILEPICKER_CHANGED,
    function( event )
        local path = filepicker_cert2:GetPath()
        local tbl_issuer, tbl_subject, tbl_dates, keyp_hex, keyp_base32, err = show_certinfo( path )

        certinfo_4:SetValue( "" )
        certinfo_5:SetValue( "" )
        certinfo_6:SetValue( "" )
        certinfo_8:SetValue( "" )
        keyp_textctrl_2:SetValue( "" )

        local progressDialog = wx.wxProgressDialog(
            app_name,
            "Generating keyprint, please wait...",
            6,
            wx.NULL,
            wx.wxPD_AUTO_HIDE + wx.wxPD_APP_MODAL + wx.wxPD_SMOOTH
        )
        progressDialog:SetSize( wx.wxSize( 600, 130 ) )
        progressDialog:Centre( wx.wxBOTH )

        wx.wxBeginBusyCursor()

        progressDialog:Update( 1, "Generating keyprint, please wait..." )
        wx.wxSleep( 1 )

        log_broadcast( log_window, "Parsing data from file...", "GREEN" )
        progressDialog:Update( 2, "Parsing data from file..." )
        wx.wxSleep( 2 )

        if err then
            log_broadcast( log_window, "Error can not parse data from file, file is not valid.", "RED" )
            progressDialog:Update( 3, "Error can not parse data from file, file is not valid." )
            wx.wxSleep( 2 )

            progressDialog:Destroy()

            filepicker_certpath2:SetValue( "" )

            wx.wxMessageBox( "Error can not parse data from file, file is not valid.", "Parsing fingerprint...", wx.wxOK + wx.wxICON_INFORMATION, frame )
        else
            log_broadcast( log_window, "Using file: '" .. path .. "'", "CYAN" )
            progressDialog:Update( 3, "Using file: '" .. path .. "" )
            wx.wxSleep( 2 )

            filepicker_certpath2:SetValue( path )

            log_broadcast( log_window, "Parsing fingerprint...", "GREEN" )
            progressDialog:Update( 4, "Parsing fingerprint..." )
            wx.wxSleep( 2 )
            local CN = tbl_issuer[ "CN" ] or ""
            local CN2 = tbl_subject[ "CN2" ] or ""
            local notBefore = tbl_dates[ "notBefore" ] or ""
            local notAfter = tbl_dates[ "notAfter" ] or ""

            log_broadcast( log_window, "Import informations...", "GREEN" )
            progressDialog:Update( 5, "Import informations..." )
            wx.wxSleep( 2 )
            certinfo_4:SetValue( CN )
            certinfo_8:SetValue( CN2 )
            certinfo_5:SetValue( notBefore )
            certinfo_6:SetValue( notAfter )
            keyp_textctrl_2:SetValue( keyp_base32 )

            log_broadcast( log_window, "SHA256 keyprint as HEX: " .. keyp_hex, "WHITE" )
            log_broadcast( log_window, "SHA256 keyprint as BASE32: " .. keyp_base32, "WHITE" )
            log_broadcast( log_window, "Import keyprint...", "GREEN" )

            progressDialog:Update( 6, "Creating keyprint file..." )
            log_broadcast( log_window, "Creating keyprint file...", "GREEN" )

            local des_path = path:gsub( "\servercert.pem", "" )
            local f = wx.wxFile( des_path .. "\\keyprint.txt", wx.wxFile.write )
            f:Write( keyp_base32 )
            f:Flush()
            f:Close()

            log_broadcast( log_window, "Done.", "WHITE" )
            progressDialog:Update( 7, "Done." )
            wx.wxSleep( 2 )
        end

        log_broadcast( log_window, app_name .. " ready.", "ORANGE" )

        progressDialog:Destroy()
        wx.wxEndBusyCursor()

        wx.wxMessageBox( "Keyprint successfully generated.", "INFO", wx.wxOK + wx.wxICON_INFORMATION, frame )
    end
)

-------------------------------------------------------------------------------------------------------------------------------------
--// MAIN LOOP //--------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

local main = function()

    frame:Connect( wx.wxID_EXIT, wx.wxEVT_COMMAND_MENU_SELECTED, -- HandleEvents,
        function( event )
            frame:Close( true )
        end
    )
    frame:Connect( wx.wxID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED,
        function( event )
            show_about_window( frame )
        end
    )
    frame:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_NOTEBOOK_PAGE_CHANGED, HandleEvents )
    frame:Show( true )
end

main()
wx.wxGetApp():MainLoop()