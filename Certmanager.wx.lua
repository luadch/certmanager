--[[

    Luadch Certmanager

        Author:         pulsar
        License:        GNU GPLv3
        Environment:    wxLua-2.8.12.3-Lua-5.1.5-MSW-Unicode

        v1.5: 2022-06-04

            - add parameters to wxMenu
            - add separator to menubar
            - changed wxImageList method
                - fix problem with disappearing icons
            - fixed some wrong element behaviours

        v1.4: 2022-06-03

            - fix typo
            - changed button colors
            - changed some other visuals
            - added "READY" / "BUSY" to the right side of the statusbar
            - set current working directory as default path for make cert  / thx Sopor
            - possibility to set the period of validity
            - code cleanup

        v1.3: 2022-06-02

            - menubar:
                - using icons
                - using hotkeys
            - using other folder structure
                - added "cfg/constants.lua" to define default path constants
            - added logfile
                - added additional log window to show/clean logfile (use menubar or press "F6")
            - changed visuals
            - added "check_files_exists" function for integrity check on startup
            - added "new_id" function
            - using .png instead of .ico files and removed .dll ressource files
            - added statusbar to show status informations about controls and menu entrys
            - changed "about" window
            - added "Copy to clipboard" button for keyprint
            - CN value starts with "Luadch_" now

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
--// PATH CONSTANTS //---------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--// import path constants
dofile( "data/cfg/constants.lua" )

-------------------------------------------------------------------------------------------------------------------------------------
--// IMPORTS //----------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--// lib path
package.path = ";./" .. LUALIB_PATH .. "?.lua" ..
               ";./" .. LUALIB_PATH .. "?/?.lua" ..
               ";./" .. CORE_PATH .. "?.lua"

package.cpath = ";./" .. CLIB_PATH .. "?.dll" ..
                ";./" .. CLIB_PATH .. "?/?.dll"

--// openssl bash command path
local openssl_bash_path = '.\\data\\lib\\openssl\\'

--// libs
local wx     = require( "wx" )
local basexx = require( "basexx" )

-------------------------------------------------------------------------------------------------------------------------------------
--// BASIC CONST //------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

local app_name         = "Luadch Certmanager"
local app_version      = "1.5"
local app_copyright    = "Copyright © by pulsar"
local app_license      = "GNU General Public License Version 3"
local app_env          = "Environment: " .. wxlua.wxLUA_VERSION_STRING
local app_build        = "Built with: "..wx.wxVERSION_STRING
local app_path         = wx.wxGetCwd() -- do not touch this

local app_width        = 800
local app_height       = 637

local notebook_width   = 795
local notebook_height  = 270

local log_width        = 795
local log_height       = 298

local logwindow_width  = app_width - 40
local logwindow_height = app_height - 80

local settings_width   = 400
local settings_height  = 500

--// files
local file_tbl = {
    --// ressources
    [ 1 ] = RES_PATH .. "GPLv3_160x80.png",
    [ 2 ] = RES_PATH .. "osi_75x100.png",
    [ 3 ] = RES_PATH .. "appicon_16x16.png",
    [ 4 ] = RES_PATH .. "appicon_32x32.png",
    [ 5 ] = RES_PATH .. "appicon_48x48.png",
    [ 6 ] = RES_PATH .. "cert_16x16.png",
    [ 7 ] = RES_PATH .. "keyprint_16x16.png",
    [ 8 ] = RES_PATH .. "certmanager.ico",
    --// logfiles
    [ 9 ] = LOG_PATH .. "log.txt",
}

--// controls
local control, di, result
local id_counter
local frame
local panel
local notebook
local make_cert

--// functions
local new_id
local log_write
local log_handler
local show_error_window
local check_files_exists
local show_about_window
local show_log_window
local timestamp
local log_broadcast
local trim
local trim2
local show_certinfo
local generate_cn
local tab_1
local tab_2
local clipBoard

--// fonts
local font_cert         = wx.wxFont( 7,  wx.wxMODERN, wx.wxNORMAL, wx.wxNORMAL,          false, "Verdana" )
local font_log          = wx.wxFont( 8,  wx.wxMODERN, wx.wxNORMAL, wx.wxNORMAL,          false, "Lucida Console" )
local font_about_normal = wx.wxFont( 10, wx.wxMODERN, wx.wxNORMAL, wx.wxNORMAL,          false, "Verdana" )
local font_about_bold   = wx.wxFont( 12, wx.wxMODERN, wx.wxNORMAL, wx.wxFONTWEIGHT_BOLD, false, "Verdana" )
local font_statusbar    = wx.wxFont( 8,  wx.wxMODERN, wx.wxNORMAL, wx.wxNORMAL,          false, "Lucida Console" )
local font_buttons      = wx.wxFont( 8,  wx.wxMODERN, wx.wxNORMAL, wx.wxFONTWEIGHT_BOLD, false, "Verdana" )

--// for the file integrity check
local exec = true

-------------------------------------------------------------------------------------------------------------------------------------
--// STRINGS //----------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--// menu
local msg_menu_menu         = "Menu"
local msg_menu_help         = "Help"
local msg_menu_about        = "About"
local msg_menu_about_status = "Informations about"
local msg_menu_logs         = "Log"
local msg_menu_logs_status  = "Open Log"
local msg_menu_close        = "Close"
local msg_menu_close_status = "Close Programm"
--// buttons
local msg_button_ok         = "OK"
local msg_button_clean      = "Clean"
local msg_button_makecert   = "Make cert"
--// etc
local msg_error_1           = "Error"
local msg_error_2           = "Error: "
local msg_file_not_found    = "File not found: "
local msg_closing_program   = "Files that are necessary to start the program are missing.\nThe program will be closed.\n\nPlease read the log file."
local msg_really_close      = "Really quit?"
local msg_warning           = "Warning"
local msg_log_empty         = "Logfile is Empty"
local msg_log_cleaned       = "Logfile was cleaned"
local msg_ready             = "ready"
local msg_closed            = "closed"
local msg_busy              = "busy"

-------------------------------------------------------------------------------------------------------------------------------------
--// IDS //--------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--// ID generator
id_counter = wx.wxID_HIGHEST + 1
new_id = function() id_counter = id_counter + 1; return id_counter end

--// IDs
ID_LOGS              = new_id()
ID_DIRPICKER         = new_id()
ID_DIRPICKER_PATH    = new_id()
ID_MAKE_CERT_BUTTON  = new_id()
ID_FILEPICKER        = new_id()
ID_FILEPICKER_PATH   = new_id()

-------------------------------------------------------------------------------------------------------------------------------------
--// MENUBAR //----------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--// icons menubar
local bmp_logs_16x16  = wx.wxArtProvider.GetBitmap( wx.wxART_REPORT_VIEW, wx.wxART_TOOLBAR )
local bmp_exit_16x16  = wx.wxArtProvider.GetBitmap( wx.wxART_QUIT,        wx.wxART_TOOLBAR )
local bmp_about_16x16 = wx.wxArtProvider.GetBitmap( wx.wxART_INFORMATION, wx.wxART_TOOLBAR )

local menu_item = function( menu, id, name, status, bmp )
    local mi = wx.wxMenuItem( menu, id, name, status )
    mi:SetBitmap( bmp ); bmp:delete()
    return mi
end

local main_menu = wx.wxMenu( "", 0 )
main_menu:Append( menu_item( main_menu, ID_LOGS, msg_menu_logs .. "\tF6", msg_menu_logs_status, bmp_logs_16x16 ) )
main_menu:AppendSeparator()
main_menu:Append( menu_item( main_menu, wx.wxID_EXIT, msg_menu_close .. "\tF4", msg_menu_close_status, bmp_exit_16x16 ) )

local help_menu = wx.wxMenu( "", 0 )
help_menu:Append( menu_item( help_menu, wx.wxID_ABOUT,  msg_menu_about .. "\tF2", msg_menu_about_status .. " " .. app_name, bmp_about_16x16 ) )

local menu_bar = wx.wxMenuBar()
menu_bar:Append( main_menu, msg_menu_menu )
menu_bar:Append( help_menu, msg_menu_help )

--// icons for tabs
tab_1_bmp = wx.wxBitmap():ConvertToImage(); tab_1_bmp:LoadFile( file_tbl[ 6 ] )
tab_2_bmp = wx.wxBitmap():ConvertToImage(); tab_2_bmp:LoadFile( file_tbl[ 7 ] )

notebook_image_list = wx.wxImageList( 16, 16 )
notebook_image_list:Add( wx.wxBitmap( tab_1_bmp ) )
notebook_image_list:Add( wx.wxBitmap( tab_2_bmp ) )

-------------------------------------------------------------------------------------------------------------------------------------
--// DIFFERENT FUNCS //--------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--// about window
show_about_window = function()
   local di_abo = wx.wxDialog(
        wx.NULL,
        wx.wxID_ANY,
        msg_menu_about .. " " .. app_name,
        wx.wxDefaultPosition,
        wx.wxSize( 320, 395 ),
        wx.wxSTAY_ON_TOP + wx.wxDEFAULT_DIALOG_STYLE - wx.wxCLOSE_BOX - wx.wxMAXIMIZE_BOX - wx.wxMINIMIZE_BOX
    )
    di_abo:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
    di_abo:SetMinSize( wx.wxSize( 320, 395 ) )
    di_abo:SetMaxSize( wx.wxSize( 320, 395 ) )

    --// app logo
    local app_logo = wx.wxBitmap():ConvertToImage()
    app_logo:LoadFile( file_tbl[ 5 ] )

    control = wx.wxStaticBitmap( di_abo, wx.wxID_ANY, wx.wxBitmap( app_logo ), wx.wxPoint( 0, 5 ), wx.wxSize( app_logo:GetWidth(), app_logo:GetHeight() ) )
    control:Centre( wx.wxHORIZONTAL )

    --// app name / version
    control = wx.wxStaticText( di_abo, wx.wxID_ANY, app_name .. " " .. app_version, wx.wxPoint( 0, 60 ) )
    control:SetFont( font_about_bold )
    control:Centre( wx.wxHORIZONTAL )

    --// app copyright
    control = wx.wxStaticText( di_abo, wx.wxID_ANY, app_copyright, wx.wxPoint( 0, 90 ) )
    control:SetFont( font_about_normal )
    control:Centre( wx.wxHORIZONTAL )

    --// environment
    control = wx.wxStaticText( di_abo, wx.wxID_ANY, app_env, wx.wxPoint( 0, 122 ) )
    control:SetFont( font_about_normal )
    control:Centre( wx.wxHORIZONTAL )

    --// build with
    control = wx.wxStaticText( di_abo, wx.wxID_ANY, app_build, wx.wxPoint( 0, 137 ) )
    control:SetFont( font_about_normal )
    control:Centre( wx.wxHORIZONTAL )

    --// horizontal line
    control = wx.wxStaticLine( di_abo, wx.wxID_ANY, wx.wxPoint( 0, 168 ), wx.wxSize( 275, 1 ) )
    control:Centre( wx.wxHORIZONTAL )

    --// license
    control = wx.wxStaticText( di_abo, wx.wxID_ANY, app_license, wx.wxPoint( 0, 180 ) )
    control:SetFont( font_about_normal )
    control:Centre( wx.wxHORIZONTAL )

    --// GPL logo
    local gpl_logo = wx.wxBitmap():ConvertToImage()
    gpl_logo:LoadFile( file_tbl[ 1 ] )

    control = wx.wxStaticBitmap( di_abo, wx.wxID_ANY, wx.wxBitmap( gpl_logo ), wx.wxPoint( 20, 220 ), wx.wxSize( gpl_logo:GetWidth(), gpl_logo:GetHeight() ) )

    --// OSI Logo
    local osi_logo = wx.wxBitmap():ConvertToImage()
    osi_logo:LoadFile( file_tbl[ 2 ] )

    control = wx.wxStaticBitmap( di_abo, wx.wxID_ANY, wx.wxBitmap( osi_logo ), wx.wxPoint( 200, 210 ), wx.wxSize( osi_logo:GetWidth(), osi_logo:GetHeight() ) )

    --// button "OK"
    local about_btn_ok = wx.wxButton( di_abo, wx.wxID_ANY, msg_button_ok, wx.wxPoint( 0, 335 ), wx.wxSize( 60, 25 ) )
    about_btn_ok:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
    about_btn_ok:Centre( wx.wxHORIZONTAL )

    --// event - button "OK"
    about_btn_ok:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_BUTTON_CLICKED,
        function( event )
            app_logo:Destroy()
            gpl_logo:Destroy()
            osi_logo:Destroy()
            di_abo:Destroy()
        end
    )

    --// show dialog
    di_abo:ShowModal()
end

--// log window
show_log_window = function()
    local di_log = wx.wxDialog(
        wx.NULL,
        wx.wxID_ANY,
        msg_menu_logs,
        wx.wxDefaultPosition,
        wx.wxSize( logwindow_width, logwindow_height ),
        wx.wxSTAY_ON_TOP + wx.wxDEFAULT_DIALOG_STYLE - wx.wxCLOSE_BOX - wx.wxMAXIMIZE_BOX - wx.wxMINIMIZE_BOX
    )
    di_log:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
    di_log:SetMinSize( wx.wxSize( log_width, log_height ) )
    di_log:SetMaxSize( wx.wxSize( log_width, log_height ) )

    --// logfile window
    local logfile_window = wx.wxTextCtrl(
        di_log,
        wx.wxID_ANY,
        "",
        wx.wxPoint( 5, 5 ),
        wx.wxSize( logwindow_width - 30 , logwindow_height - 80 ),
        wx.wxTE_READONLY + wx.wxTE_MULTILINE + wx.wxTE_RICH + wx.wxSUNKEN_BORDER + wx.wxHSCROLL
    )
    logfile_window:SetBackgroundColour( wx.wxColour( 0, 0, 0 ) )
    logfile_window:SetFont( font_log )
    logfile_window:Centre( wx.wxHORIZONTAL )
    logfile_window:SetDefaultStyle( wx.wxTextAttr( wx.wxLIGHT_GREY ) )

    --// button "OK"
    local log_btn_ok = wx.wxButton( di_log, wx.wxID_ANY, msg_button_ok, wx.wxPoint( 75, logwindow_height - 65 ), wx.wxSize( 60, 25 ) )
    log_btn_ok:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
    log_btn_ok:Centre( wx.wxHORIZONTAL )
    --// event - button "OK"
    log_btn_ok:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_BUTTON_CLICKED,
        function( event )
            di_log:Destroy()
        end
    )

    --// button "Clean"
    local log_btn_clean = wx.wxButton( di_log, wx.wxID_ANY, msg_button_clean, wx.wxPoint( 20, logwindow_height - 65 ), wx.wxSize( 60, 25 ) )
    log_btn_clean:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
    log_btn_clean:Disable()
    --// event - button "Clean"
    log_btn_clean:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_BUTTON_CLICKED,
        function( event )
            log_handler( file_tbl[ 9 ], logfile_window, "clean", log_btn_clean )
        end
    )
    log_handler( file_tbl[ 9 ], logfile_window, "read", log_btn_clean )
    di_log:ShowModal()
end

--// default timestamp for log window
timestamp = function()
    return "[" .. os.date( "%Y-%m-%d/%H:%M:%S" ) .. "] "
end

--// generate cmd for log broadcast
log_broadcast = function( control, msg, color )
    local before, after
    local log_color = function( l, m, c )
        before = l:GetNumberOfLines()
        l:SetInsertionPointEnd()
        l:SetDefaultStyle( wx.wxTextAttr( wx.wxLIGHT_GREY ) )
        l:WriteText( timestamp() )
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
trim = function( s )
    return string.find( s, "^%s*$" ) and "" or string.match( s, "^%s*(.*%S)" )
end

--// trim ghost chars from input stream
trim2 = function( s )
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
show_certinfo = function( path )
    local cmd, msg, proc, stream, certinfo_issuer, certinfo_subject, certinfo_dates, fingerprint
    local tbl_issuer, tbl_subject, tbl_dates, keyp_hex, keyp_base32, err = {}, {}, {}, "", "", false
    local stream_len = 500

    --// issuer
    cmd = openssl_bash_path .. 'openssl.exe x509 -noout -in ' .. '"' .. trim( path ) .. '"' .. ' -issuer'
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
    cmd = openssl_bash_path .. 'openssl.exe x509 -noout -in ' .. '"' .. trim( path ) .. '"' .. ' -subject'
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
    cmd = openssl_bash_path .. 'openssl.exe x509 -noout -in ' .. '"' .. trim( path ) .. '"' .. ' -dates'
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
    cmd = openssl_bash_path .. 'openssl.exe x509 -fingerprint -noout -sha256 -in "' .. trim( path ) .. '"'
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
generate_cn = function( len )
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

--// add text to logfile / make logfile if not exists
log_write = function( msg )
    wx.wxSetWorkingDirectory( app_path )
    local f = io.open( file_tbl[ 9 ], "a" )
    f:write( timestamp() .. msg .. "\n" )
    f:close()
end

--// open or clean logfile
log_handler = function( file, parent, mode, button )
    if mode == "read" then
        local f = io.open( file_tbl[ 9 ], "r" )
        local content = f:read( "*a" ); f:close()
        if content == "" then
            parent:AppendText( msg_log_empty )
        else
            if button then button:Enable( true ) end
            parent:AppendText( content )
        end
        local al = parent:GetNumberOfLines()
        parent:ScrollLines( al + 1 )
    end
    if mode == "clean" then
        local f = io.open( file, "w" ); f:close()
        parent:Clear()
        parent:AppendText( msg_log_cleaned )
        log_write( msg_log_cleaned )
        if button then button:Disable() end
    end
end

--// error Window
show_error_window = function()
    di = wx.wxMessageDialog(
        wx.NULL,
        msg_closing_program,
        msg_error_1,
        wx.wxOK + wx.wxICON_ERROR + wx.wxCENTRE
    )
    result = di:ShowModal(); di:Destroy()
    if result == wx.wxID_OK then
        if event then event:Skip() end
        if frame then frame:Destroy() end
        exec = false
        return nil
    end
end

--// check if files exists
check_files_exists = function( tbl )
    local missing_file = false
    for k, v in ipairs( tbl ) do
        if type( v ) ~= "table" then
            if not wx.wxFile.Exists( v ) then
                log_write( msg_error_2 .. msg_file_not_found .. v )
                missing_file = true
            end
        else
            if not wx.wxFile.Exists( v[ 1 ] ) then
                log_write( msg_error_2 .. msg_file_not_found .. v[ 1 ] )
                missing_file = true
            end
        end
    end
    if missing_file then show_error_window() end
end

-------------------------------------------------------------------------------------------------------------------------------------
--// FRAME //------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--// app icons (menubar)
local app_icons = wx.wxIconBundle()
app_icons:AddIcon( wx.wxIcon( file_tbl[ 3 ], wx.wxBITMAP_TYPE_PNG, 16, 16 ) )
app_icons:AddIcon( wx.wxIcon( file_tbl[ 4 ], wx.wxBITMAP_TYPE_PNG, 32, 32 ) )

--// frame
frame = wx.wxFrame( wx.NULL, wx.wxID_ANY, app_name .. " " .. app_version, wx.wxPoint( 0, 0 ), wx.wxSize( app_width, app_height ), wx.wxMINIMIZE_BOX + wx.wxSYSTEM_MENU + wx.wxCAPTION + wx.wxCLOSE_BOX + wx.wxCLIP_CHILDREN )
frame:Centre( wx.wxBOTH )
frame:SetMenuBar( menu_bar )
frame:SetIcons( app_icons )

--// statusbar
local statusBar = frame:CreateStatusBar( 2 )
frame:SetStatusWidths( { ( app_width / 100 * 90 ), ( app_width / 100 * 10 ) } )

local statusBar_txt_green = wx.wxStaticText( statusBar, wx.wxID_ANY, " READY ", wx.wxPoint( 730, 5 ) ); statusBar_txt_green:SetForegroundColour( wx.wxGREEN ); statusBar_txt_green:SetFont( font_statusbar )
statusBar_txt_green:SetBackgroundColour( wx.wxColour( 0, 0, 0 ) )

local statusBar_txt_red = wx.wxStaticText( statusBar, wx.wxID_ANY, " BUSY ", wx.wxPoint( 730, 5 ) ); statusBar_txt_red:SetForegroundColour( wx.wxRED ); statusBar_txt_red:SetFont( font_statusbar )
statusBar_txt_red:SetBackgroundColour( wx.wxColour( 0, 0, 0 ) )

statusBar_txt_green:Show( true ); statusBar_txt_red:Show( false )
--statusBar_txt_red:Show( true ); statusBar_txt_green:Show( false )

--// panel
panel = wx.wxPanel( frame, wx.wxID_ANY, wx.wxPoint( 0, 0 ), wx.wxSize( app_width, app_height ) )
panel:SetBackgroundColour( wx.wxColour( 245, 245, 245 ) )

--// notebook
notebook = wx.wxNotebook( panel, wx.wxID_ANY, wx.wxPoint( 0, 0 ), wx.wxSize( notebook_width, notebook_height ) )

--// tab 1
tab_1 = wx.wxPanel( notebook, wx.wxID_ANY )
tab_1:SetBackgroundColour( wx.wxColour( 245, 245, 245 ) )

--// tab 2
tab_2 = wx.wxPanel( notebook, wx.wxID_ANY )
tab_2:SetBackgroundColour( wx.wxColour( 245, 245, 245 ) )

--// add tabs to notebook
notebook:SetImageList( notebook_image_list )

notebook:AddPage( tab_1, "CREATE NEW CERTIFICATE", true, 0 )
notebook:AddPage( tab_2, "GENERATE KEYPRINT FROM EXISTING CERTIFICATE", false, 1 )

--// add log wondow to panel
local log_window = wx.wxTextCtrl( panel, wx.wxID_ANY, "", wx.wxPoint( 0, 268 ), wx.wxSize( log_width, log_height ), wx.wxTE_READONLY + wx.wxTE_MULTILINE + wx.wxTE_RICH + wx.wxSUNKEN_BORDER + wx.wxHSCROLL )
log_window:SetBackgroundColour( wx.wxColour( 0, 0, 0 ) )
log_window:SetFont( font_log )

-------------------------------------------------------------------------------------------------------------------------------------
--// Tab 1 //------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--//Subject Common Name
control = wx.wxStaticText( tab_1, wx.wxID_ANY, "Subject Common Name:", wx.wxPoint( 70, 80 ) )
control:SetFont( font_cert )
local certinfo_7 = wx.wxTextCtrl( tab_1, wx.wxID_ANY, "", wx.wxPoint( 70, 96 ), wx.wxSize( 220, 23 ), wx.wxTE_READONLY + wx.wxSUNKEN_BORDER + wx.wxTE_CENTRE )
certinfo_7:SetBackgroundColour( wx.wxColour( 245, 245, 245 ) )
certinfo_7:SetForegroundColour( wx.wxRED )
certinfo_7:SetFont( font_log )
certinfo_7:Connect( wx.wxEVT_ENTER_WINDOW, function( event ) frame:SetStatusText( "Status: READ ONLY", 0 ) end )
certinfo_7:Connect( wx.wxEVT_LEAVE_WINDOW, function( event ) frame:SetStatusText( "", 0 ) end )

--//Issuer Common Name
control = wx.wxStaticText( tab_1, wx.wxID_ANY, "Issuer Common Name:", wx.wxPoint( 70, 130 ) )
control:SetFont( font_cert )
local certinfo_1 = wx.wxTextCtrl( tab_1, wx.wxID_ANY, "", wx.wxPoint( 70, 146 ), wx.wxSize( 220, 23 ), wx.wxTE_READONLY + wx.wxSUNKEN_BORDER + wx.wxTE_CENTRE )
certinfo_1:SetBackgroundColour( wx.wxColour( 245, 245, 245 ) )
certinfo_1:SetForegroundColour( wx.wxRED )
certinfo_1:SetFont( font_log )
certinfo_1:Connect( wx.wxEVT_ENTER_WINDOW, function( event ) frame:SetStatusText( "Status: READ ONLY", 0 ) end )
certinfo_1:Connect( wx.wxEVT_LEAVE_WINDOW, function( event ) frame:SetStatusText( "", 0 ) end )

--//Valid from
control = wx.wxStaticText( tab_1, wx.wxID_ANY, "Valid from:", wx.wxPoint( 497, 80 ) )
control:SetFont( font_cert )
local certinfo_2 = wx.wxTextCtrl( tab_1, wx.wxID_ANY, "", wx.wxPoint( 497, 96 ), wx.wxSize( 220, 23 ), wx.wxTE_READONLY + wx.wxSUNKEN_BORDER + wx.wxTE_CENTRE )
certinfo_2:SetBackgroundColour( wx.wxColour( 245, 245, 245 ) )
certinfo_2:SetForegroundColour( wx.wxRED )
certinfo_2:SetFont( font_log )
certinfo_2:Connect( wx.wxEVT_ENTER_WINDOW, function( event ) frame:SetStatusText( "Status: READ ONLY", 0 ) end )
certinfo_2:Connect( wx.wxEVT_LEAVE_WINDOW, function( event ) frame:SetStatusText( "", 0 ) end )

--//Valid until
control = wx.wxStaticText( tab_1, wx.wxID_ANY, "Valid until:", wx.wxPoint( 497, 130 ) )
control:SetFont( font_cert )
local certinfo_3 = wx.wxTextCtrl( tab_1, wx.wxID_ANY, "", wx.wxPoint( 497, 146 ), wx.wxSize( 220, 23 ), wx.wxTE_READONLY + wx.wxSUNKEN_BORDER + wx.wxTE_CENTRE )
certinfo_3:SetBackgroundColour( wx.wxColour( 245, 245, 245 ) )
certinfo_3:SetForegroundColour( wx.wxRED )
certinfo_3:SetFont( font_log )
certinfo_3:Connect( wx.wxEVT_ENTER_WINDOW, function( event ) frame:SetStatusText( "Status: READ ONLY", 0 ) end )
certinfo_3:Connect( wx.wxEVT_LEAVE_WINDOW, function( event ) frame:SetStatusText( "", 0 ) end )

--// Keyprint
control = wx.wxStaticText( tab_1, wx.wxID_ANY, "Keyprint:", wx.wxPoint( 180, 185 ) )
control:SetFont( font_cert )
local keyp_textctrl_1 = wx.wxTextCtrl( tab_1, wx.wxID_ANY, "", wx.wxPoint( 180, 201 ), wx.wxSize( 410, 23 ), wx.wxTE_READONLY + wx.wxSUNKEN_BORDER + wx.wxTE_CENTRE )
keyp_textctrl_1:SetBackgroundColour( wx.wxColour( 245, 245, 245 ) )
keyp_textctrl_1:SetForegroundColour( wx.wxRED )
keyp_textctrl_1:SetFont( font_log )
keyp_textctrl_1:Connect( wx.wxEVT_ENTER_WINDOW, function( event ) frame:SetStatusText( "Status: READ ONLY", 0 ) end )
keyp_textctrl_1:Connect( wx.wxEVT_LEAVE_WINDOW, function( event ) frame:SetStatusText( "", 0 ) end )

--// button copy to clipboard
local btn_clip_1 = wx.wxButton( tab_1, wx.wxID_ANY, "Copy", wx.wxPoint( 600, 200 ), wx.wxSize( 40, 25 ) )
btn_clip_1:SetBackgroundColour( wx.wxColour( 225, 225, 225 ) )
btn_clip_1:Disable()

--// Certificate destination path (for dirpicker)
control = wx.wxStaticBox( tab_1, wx.wxID_ANY, "Certificate destination path:", wx.wxPoint( 5, 13 ), wx.wxSize( 777, 50 ) )
control:SetFont( font_cert )
local dirpicker_certpath = wx.wxTextCtrl( tab_1, ID_DIRPICKER_PATH, "", wx.wxPoint( 20, 31 ), wx.wxSize( 670, 21 ), wx.wxTE_READONLY + wx.wxSUNKEN_BORDER )
dirpicker_certpath:SetBackgroundColour( wx.wxColour( 245, 245, 245 ) )
dirpicker_certpath:SetForegroundColour( wx.wxRED )
dirpicker_certpath:SetFont( font_log )
dirpicker_certpath:SetValue( wx.wxGetCwd() )
dirpicker_certpath:Connect( wx.wxEVT_ENTER_WINDOW, function( event ) frame:SetStatusText( "Status: READ ONLY", 0 ) end )
dirpicker_certpath:Connect( wx.wxEVT_LEAVE_WINDOW, function( event ) frame:SetStatusText( "", 0 ) end )

--// dirpicker
local dirpicker = wx.wxDirPickerCtrl(
    tab_1,
    ID_DIRPICKER,
    wx.wxGetCwd(),
    "Choose destination folder for cert:",
    wx.wxPoint( 698, 30 ),
    wx.wxSize( 80, 25 ),
    wx.wxDIRP_DEFAULT_STYLE + wx.wxDIRP_DIR_MUST_EXIST + wx.wxDIRP_USE_TEXTCTRL + wx.wxDIRP_CHANGE_DIR
)
--// dirpicker - event
dirpicker:Connect( wx.wxEVT_ENTER_WINDOW, function( event ) frame:SetStatusText( "Choose destination folder for cert", 0 ) end )
dirpicker:Connect( wx.wxEVT_LEAVE_WINDOW, function( event ) frame:SetStatusText( "", 0 ) end )
dirpicker:Connect( ID_DIRPICKER, wx.wxEVT_COMMAND_DIRPICKER_CHANGED,
    function( event )
        local path = dirpicker:GetPath()

        certinfo_1:SetValue( "" )
        certinfo_2:SetValue( "" )
        certinfo_3:SetValue( "" )
        certinfo_7:SetValue( "" )
        keyp_textctrl_1:SetValue( "" )
        dirpicker_certpath:SetValue( path )

        log_broadcast( log_window, "Using destination path: '" .. path .. "'", "CYAN" )
        log_write( "Using destination path: '" .. path .. "'" )
        make_cert:Enable( true )
        btn_clip_1:Disable()
    end
)

--// button copy to clipboard - event
btn_clip_1:Connect( wx.wxEVT_ENTER_WINDOW, function( event ) frame:SetStatusText( "Copy keyprint to clipboard", 0 ) end )
btn_clip_1:Connect( wx.wxEVT_LEAVE_WINDOW, function( event ) frame:SetStatusText( "", 0 ) end )
btn_clip_1:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        clipBoard = wx.wxClipboard.Get()
        if clipBoard and clipBoard:Open() then
            clipBoard:SetData( wx.wxTextDataObject( keyp_textctrl_1:GetValue() ) )
            clipBoard:Close()
        end
        certinfo_1:SetValue( "" )
        certinfo_2:SetValue( "" )
        certinfo_3:SetValue( "" )
        certinfo_7:SetValue( "" )
        keyp_textctrl_1:SetValue( "" )
        dirpicker_certpath:SetValue( "" )
        btn_clip_1:Disable()

        log_broadcast( log_window, "Keyprint added to ClipBoard", "WHITE" )
        log_write( "Keyprint added to ClipBoard" )
    end
)

--// static box
control = wx.wxStaticBox( tab_1, wx.wxID_ANY, "", wx.wxPoint( 331, 65 ), wx.wxSize( 123, 125 ) )

--// Period of validity
control = wx.wxStaticText( tab_1, wx.wxID_ANY, "Period of validity:", wx.wxPoint( 347, 80 ) )
control:SetFont( font_cert )

--// validity_choice
local validity_time = 3650 -- default period of validity
local validity_choice = wx.wxChoice(
    tab_1,
    wx.wxID_ANY,
    wx.wxPoint( 347, 98 ),
    wx.wxSize( 90, 25 ),
    { "1 Year", "2 Years", "3 Years", "4 Years", "5 Years", "6 Years", "7 Years", "8 Years", "9 Years", "10 Years" }
)
validity_choice:Select( 9 )
validity_choice:SetForegroundColour( wx.wxRED )
validity_choice:SetFont( font_cert )

--// validity_choice - event
validity_choice:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_CHOICE_SELECTED,
    function( event )
        local sel = validity_choice:GetCurrentSelection()
        local str = validity_choice:GetStringSelection()
        local val_tbl = { [0]=365,[1]=730,[2]=1095,[3]=1460,[4]=1825,[5]=2190,[6]=2555,[7]=2920,[8]=3285,[9]=3650 }
        validity_time = val_tbl[ sel ]
        log_broadcast( log_window, "Period of validity: " .. str .. " (" .. validity_time .. " Days)", "CYAN" )
    end
)

--// button make_cert
make_cert = wx.wxButton( tab_1, ID_MAKE_CERT_BUTTON, msg_button_makecert, wx.wxPoint( 347, 125 ), wx.wxSize( 90, 50 ) )
make_cert:SetBackgroundColour( wx.wxColour( 225, 225, 225 ) )
make_cert:SetFont( font_buttons )
make_cert:Connect( wx.wxEVT_ENTER_WINDOW, function( event ) frame:SetStatusText( "Make cert in current directory...", 0 ) end )
make_cert:Connect( wx.wxEVT_LEAVE_WINDOW, function( event ) frame:SetStatusText( "", 0 ) end )
--make_cert:Disable()

--// button make_cert - event
make_cert:Connect( ID_MAKE_CERT_BUTTON, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        wx.wxBeginBusyCursor()
        statusBar_txt_red:Show( true ); statusBar_txt_green:Show( false )

        local progressDialog = wx.wxProgressDialog(
            "Generating cert, please wait...",
            "",
            18,
            wx.NULL,
            wx.wxPD_AUTO_HIDE + wx.wxPD_APP_MODAL + wx.wxPD_SMOOTH
        )
        progressDialog:SetSize( wx.wxSize( 600, 120 ) )
        progressDialog:Centre( wx.wxBOTH )
        progressDialog:SetFocus()

        progressDialog:Update( 1, "Generate: 'temp_cakey.pem'" )
        log_broadcast( log_window, "Generate: 'temp_cakey.pem'", "GREEN" )
        log_write( "Generate CA Key: 'temp_cakey.pem'" )
        log_write( "Using: prime256v1" )

        certinfo_1:SetValue( "" )
        certinfo_2:SetValue( "" )
        certinfo_3:SetValue( "" )
        certinfo_7:SetValue( "" )
        keyp_textctrl_1:SetValue( "" )

        local dest_path = dirpicker:GetPath():gsub( "/", "\\" )
        local curr_path = wx.wxGetCwd()
        local rnd_cn = "Luadch_" .. generate_cn( 20 )

        log_write( "Subject: " .. rnd_cn )
        log_write( "Issuer: " .. rnd_cn .. " (self signed)" )

        local cmd1 = 'openssl ecparam -out temp_cakey.pem -name prime256v1 -genkey'
        local cmd2 = 'openssl req -config ' .. openssl_bash_path .. 'openssl.config -new -x509 -days ' .. validity_time .. ' -key temp_cakey.pem -out temp_cacert.pem -subj /CN=' .. rnd_cn
        local cmd3 = 'openssl ecparam -out temp_serverkey.pem -name prime256v1 -genkey'
        local cmd4 = 'openssl req -config ' .. openssl_bash_path .. 'openssl.config -new -key temp_serverkey.pem -out temp_servercert.pem -subj /CN=' .. rnd_cn
        local cmd5 = 'openssl x509 -req -days 3650 -in temp_servercert.pem -CA temp_cacert.pem -CAkey temp_cakey.pem -set_serial 01 -out temp_servercert.pem'

        local cmd_1 = openssl_bash_path .. cmd1
        local cmd_2 = openssl_bash_path .. cmd2
        local cmd_3 = openssl_bash_path .. cmd3
        local cmd_4 = openssl_bash_path .. cmd4
        local cmd_5 = openssl_bash_path .. cmd5

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
            log_write( "Generate CA Cert: 'temp_cacert.pem'" )
            pid_2 = wx.wxExecute( cmd_2, wx.wxEXEC_ASYNC + wx.wxEXEC_MAKE_GROUP_LEADER, proc_2 )
        end )

        proc_2:Connect( wx.wxEVT_END_PROCESS, function( event )
            proc_2 = nil
            wx.wxSleep( 1 )
            progressDialog:Update( 3, "Generate: 'temp_serverkey.pem'" )
            log_broadcast( log_window, "Generate: 'temp_serverkey.pem'", "GREEN" )
            log_write( "Generate: 'temp_serverkey.pem'" )
            pid_3 = wx.wxExecute( cmd_3, wx.wxEXEC_ASYNC + wx.wxEXEC_MAKE_GROUP_LEADER, proc_3 )
        end )

        proc_3:Connect( wx.wxEVT_END_PROCESS, function( event )
            proc_3 = nil
            wx.wxSleep( 1 )
            progressDialog:Update( 4, "Generate: 'temp_servercert.pem'" )
            log_broadcast( log_window, "Generate: 'temp_servercert.pem'", "GREEN" )
            log_write( "Generate: 'temp_servercert.pem'" )
            pid_4 = wx.wxExecute( cmd_4, wx.wxEXEC_ASYNC + wx.wxEXEC_MAKE_GROUP_LEADER, proc_4 )
        end )

        proc_4:Connect( wx.wxEVT_END_PROCESS, function( event )
            proc_4 = nil
            wx.wxSleep( 1 )
            progressDialog:Update( 5, "Sign: 'temp_servercert.pem'  with: 'temp_cacert.pem'" )
            log_broadcast( log_window, "Sign: 'temp_servercert.pem'  with: 'temp_cacert.pem'", "GREEN" )
            log_write( "Sign: 'temp_servercert.pem'" )
            pid_5 = wx.wxExecute( cmd_5, wx.wxEXEC_ASYNC + wx.wxEXEC_MAKE_GROUP_LEADER, proc_5 )
        end )

        proc_5:Connect( wx.wxEVT_END_PROCESS, function( event )
            proc_5 = nil
            wx.wxSleep( 1 )
            progressDialog:Update( 6, "Certificates successfully created." )
            log_broadcast( log_window, "Certificates successfully created.", "WHITE" )
            log_write( "Certificates successfully created." )
            wx.wxSleep( 2 )

            local keyp_path = curr_path .. "\\temp_servercert.pem"
            local tbl_issuer, tbl_subject, tbl_dates, keyp_hex, keyp_base32, err = show_certinfo( keyp_path )

            if err then
                dirpicker_certpath:SetValue( "" )

                progressDialog:Update( 7, "Error can not parse data from file, file is not valid." )
                log_broadcast( log_window, "Error can not parse data from file, file is not valid.", "RED" )
                log_write( "Error can not parse data from file, file is not valid." )
                wx.wxSleep( 3 )

                wx.wxMessageBox( "Error can not parse data from file, file is not valid.", "Parsing fingerprint...", wx.wxOK + wx.wxICON_INFORMATION, frame )
            else
                progressDialog:Update( 7, "Parsing fingerprint..." )
                log_broadcast( log_window, "Parsing fingerprint...", "GREEN" )
                log_write( "Parsing fingerprint..." )
                local CN = tbl_issuer[ "CN" ] or ""
                local CN2 = tbl_subject[ "CN2" ] or ""
                local notBefore = tbl_dates[ "notBefore" ] or ""
                local notAfter = tbl_dates[ "notAfter" ] or ""
                wx.wxSleep( 1 )

                progressDialog:Update( 8, "Import informations..." )
                log_broadcast( log_window, "Import informations...", "GREEN" )
                log_write( "Import informations..." )
                certinfo_1:SetValue( CN )
                certinfo_2:SetValue( notBefore )
                certinfo_3:SetValue( notAfter )
                certinfo_7:SetValue( CN2 )
                keyp_textctrl_1:SetValue( keyp_base32 )
                wx.wxSleep( 1 )

                log_broadcast( log_window, "SHA256 keyprint as HEX: " .. keyp_hex, "WHITE" )
                log_write( "SHA256 keyprint as HEX: " .. keyp_hex )
                log_broadcast( log_window, "SHA256 keyprint as BASE32: " .. keyp_base32, "WHITE" )
                log_write( "SHA256 keyprint as BASE32: " .. keyp_base32 )
                log_broadcast( log_window, "Import keyprint...", "GREEN" )
                log_write( "Import keyprint..." )

                progressDialog:Update( 9, "Creating keyprint file..." )
                log_broadcast( log_window, "Creating keyprint file...", "GREEN" )
                log_write( "Creating keyprint file..." )
                local f = wx.wxFile( curr_path .. "\\temp_keyprint.txt", wx.wxFile.write )
                f:Write( keyp_base32 )
                f:Flush()
                f:Close()
                wx.wxSleep( 1 )

                progressDialog:Update( 10, "Copy and rename file: 'temp_servercert.pem'" )
                log_broadcast( log_window, "Copy file: 'temp_servercert.pem'  to: '"..dest_path.."\\servercert.pem'", "CYAN" )
                log_write( "Copy file: 'temp_servercert.pem'  to: '"..dest_path.."\\servercert.pem'" )
                wx.wxCopyFile( curr_path .. "\\temp_servercert.pem", dest_path .. "\\servercert.pem", true )
                wx.wxSleep( 1 )

                progressDialog:Update( 11, "Copy and rename file: 'temp_serverkey.pem'" )
                log_broadcast( log_window, "Copy file: 'temp_serverkey.pem'  to: '"..dest_path.."\\serverkey.pem'", "CYAN" )
                log_write( "Copy file: 'temp_serverkey.pem'  to: '"..dest_path.."\\serverkey.pem'" )
                wx.wxCopyFile( curr_path .. "\\temp_serverkey.pem", dest_path .. "\\serverkey.pem", true )
                wx.wxSleep( 1 )

                progressDialog:Update( 12, "Copy and rename file: 'temp_cacert.pem'" )
                log_broadcast( log_window, "Copy file: 'temp_cacert.pem'  to: '"..dest_path.."\\cacert.pem'", "CYAN" )
                log_write( "Copy file: 'temp_cacert.pem'  to: '"..dest_path.."\\cacert.pem'" )
                wx.wxCopyFile( curr_path .. "\\temp_cacert.pem", dest_path .. "\\cacert.pem", true )
                wx.wxSleep( 1 )

                progressDialog:Update( 13, "Copy and rename file: 'temp_cakey.pem'" )
                log_broadcast( log_window, "Copy file: 'temp_cakey.pem'  to: '"..dest_path.."\\cakey.pem'", "CYAN" )
                log_write( "Copy file: 'temp_cakey.pem'  to: '"..dest_path.."\\cakey.pem'" )
                wx.wxCopyFile( curr_path .. "\\temp_cakey.pem", dest_path .. "\\cakey.pem", true )
                wx.wxSleep( 1 )

                progressDialog:Update( 14, "Copy and rename file: 'temp_keyprint.txt'" )
                log_broadcast( log_window, "Copy file: 'temp_keyprint.txt'  to: '"..dest_path.."\\keyprint.txt'", "CYAN" )
                log_write( "Copy file: 'temp_keyprint.txt'  to: '"..dest_path.."\\keyprint.txt'" )
                wx.wxCopyFile( curr_path .. "\\temp_keyprint.txt", dest_path .. "\\keyprint.txt", true )
                wx.wxSleep( 1 )

                progressDialog:Update( 15, "Deleting file: 'temp_servercert.pem'" )
                log_broadcast( log_window, "Deleting file: '"..curr_path.."\\temp_servercert.pem'", "CYAN" )
                log_write( "Deleting file: '"..curr_path.."\\temp_servercert.pem'" )
                wx.wxRemoveFile( curr_path .. "\\temp_servercert.pem" )
                wx.wxSleep( 1 )

                progressDialog:Update( 16, "Deleting file: 'temp_serverkey.pem'" )
                log_broadcast( log_window, "Deleting file: '"..curr_path.."\\temp_serverkey.pem'", "CYAN" )
                log_write( "Deleting file: '"..curr_path.."\\temp_serverkey.pem'" )
                wx.wxRemoveFile( curr_path .. "\\temp_serverkey.pem" )
                wx.wxSleep( 1 )

                progressDialog:Update( 17, "Deleting file: 'temp_keyprint.txt'" )
                log_broadcast( log_window, "Deleting file: '"..curr_path.."\\temp_keyprint.txt'", "CYAN" )
                log_write( "Deleting file: '"..curr_path.."\\temp_keyprint.txt'" )
                wx.wxRemoveFile( curr_path .. "\\temp_keyprint.txt" )
                wx.wxSleep( 1 )

                progressDialog:Update( 18, "Deleting file: 'temp_cakey.pem'" )
                log_broadcast( log_window, "Deleting file: '"..curr_path.."\\temp_cakey.pem'", "CYAN" )
                log_write( "Deleting file: '"..curr_path.."\\temp_cakey.pem'" )
                wx.wxRemoveFile( curr_path .. "\\temp_cakey.pem" )
                wx.wxSleep( 1 )

                progressDialog:Update( 19, "Deleting file: 'temp_cacert.pem'" )
                log_broadcast( log_window, "Deleting file: '"..curr_path.."\\temp_cacert.pem'", "CYAN" )
                log_write( "Deleting file: '"..curr_path.."\\temp_cacert.pem'" )
                wx.wxRemoveFile( curr_path .. "\\temp_cacert.pem" )
                wx.wxSleep( 1 )
            end

            progressDialog:Update( 20, "Done." )
            log_broadcast( log_window, "Done.", "WHITE" )
            log_write( "Done." )
            wx.wxSleep( 2 )

            log_broadcast( log_window, app_name .. " " .. app_version .. " " .. msg_ready, "ORANGE" )
            log_write( app_name .. " " .. app_version .. " " .. msg_ready )
            --dirpicker_certpath:SetValue( wx.wxGetCwd() )
            statusBar_txt_green:Show( true ); statusBar_txt_red:Show( false )
            progressDialog:Destroy()
            wx.wxEndBusyCursor()
            make_cert:Disable()

            wx.wxMessageBox( "Done.", "INFO", wx.wxOK + wx.wxICON_INFORMATION, frame )
            btn_clip_1:Enable( true )
        end )

        pid_1 = wx.wxExecute( cmd_1, wx.wxEXEC_ASYNC + wx.wxEXEC_MAKE_GROUP_LEADER, proc_1 )

    end
)

-------------------------------------------------------------------------------------------------------------------------------------
--// Tab 2 //------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--// Subject Common Name
control = wx.wxStaticText( tab_2, wx.wxID_ANY, "Subject Common Name:", wx.wxPoint( 70, 80 ) )
control:SetFont( font_cert )
local certinfo_8 = wx.wxTextCtrl( tab_2, wx.wxID_ANY, "", wx.wxPoint( 70, 96 ), wx.wxSize( 220, 23 ), wx.wxTE_READONLY + wx.wxSUNKEN_BORDER + wx.wxTE_CENTRE )
certinfo_8:SetBackgroundColour( wx.wxColour( 245, 245, 245 ) )
certinfo_8:SetForegroundColour( wx.wxRED )
certinfo_8:SetFont( font_log )
certinfo_8:Connect( wx.wxEVT_ENTER_WINDOW, function( event ) frame:SetStatusText( "Status: READ ONLY", 0 ) end )
certinfo_8:Connect( wx.wxEVT_LEAVE_WINDOW, function( event ) frame:SetStatusText( "", 0 ) end )

--// Issuer Common Name
control = wx.wxStaticText( tab_2, wx.wxID_ANY, "Issuer Common Name:", wx.wxPoint( 70, 130 ) )
control:SetFont( font_cert )
local certinfo_4 = wx.wxTextCtrl( tab_2, wx.wxID_ANY, "", wx.wxPoint( 70, 146 ), wx.wxSize( 220, 23 ), wx.wxTE_READONLY + wx.wxSUNKEN_BORDER + wx.wxTE_CENTRE )
certinfo_4:SetBackgroundColour( wx.wxColour( 245, 245, 245 ) )
certinfo_4:SetForegroundColour( wx.wxRED )
certinfo_4:SetFont( font_log )
certinfo_4:Connect( wx.wxEVT_ENTER_WINDOW, function( event ) frame:SetStatusText( "Status: READ ONLY", 0 ) end )
certinfo_4:Connect( wx.wxEVT_LEAVE_WINDOW, function( event ) frame:SetStatusText( "", 0 ) end )

--// Valid from
control = wx.wxStaticText( tab_2, wx.wxID_ANY, "Valid from:", wx.wxPoint( 497, 80 ) )
control:SetFont( font_cert )
local certinfo_5 = wx.wxTextCtrl( tab_2, wx.wxID_ANY, "", wx.wxPoint( 497, 96 ), wx.wxSize( 220, 23 ), wx.wxTE_READONLY + wx.wxSUNKEN_BORDER + wx.wxTE_CENTRE )
certinfo_5:SetBackgroundColour( wx.wxColour( 245, 245, 245 ) )
certinfo_5:SetForegroundColour( wx.wxRED )
certinfo_5:SetFont( font_log )
certinfo_5:Connect( wx.wxEVT_ENTER_WINDOW, function( event ) frame:SetStatusText( "Status: READ ONLY", 0 ) end )
certinfo_5:Connect( wx.wxEVT_LEAVE_WINDOW, function( event ) frame:SetStatusText( "", 0 ) end )

--// Valid until
control = wx.wxStaticText( tab_2, wx.wxID_ANY, "Valid until:", wx.wxPoint( 497, 130 ) )
control:SetFont( font_cert )
local certinfo_6 = wx.wxTextCtrl( tab_2, wx.wxID_ANY, "", wx.wxPoint( 497, 146 ), wx.wxSize( 220, 23 ), wx.wxTE_READONLY + wx.wxSUNKEN_BORDER + wx.wxTE_CENTRE )
certinfo_6:SetBackgroundColour( wx.wxColour( 245, 245, 245 ) )
certinfo_6:SetForegroundColour( wx.wxRED )
certinfo_6:SetFont( font_log )
certinfo_6:Connect( wx.wxEVT_ENTER_WINDOW, function( event ) frame:SetStatusText( "Status: READ ONLY", 0 ) end )
certinfo_6:Connect( wx.wxEVT_LEAVE_WINDOW, function( event ) frame:SetStatusText( "", 0 ) end )

--// Keyprint
control = wx.wxStaticText( tab_2, wx.wxID_ANY, "Keyprint:", wx.wxPoint( 180, 185 ) )
control:SetFont( font_cert )
local keyp_textctrl_2 = wx.wxTextCtrl( tab_2, wx.wxID_ANY, "", wx.wxPoint( 180, 201 ), wx.wxSize( 410, 23 ), wx.wxTE_READONLY + wx.wxSUNKEN_BORDER + wx.wxTE_CENTRE )
keyp_textctrl_2:SetBackgroundColour( wx.wxColour( 245, 245, 245 ) )
keyp_textctrl_2:SetForegroundColour( wx.wxRED )
keyp_textctrl_2:SetFont( font_log )
keyp_textctrl_2:Connect( wx.wxEVT_ENTER_WINDOW, function( event ) frame:SetStatusText( "Status: READ ONLY", 0 ) end )
keyp_textctrl_2:Connect( wx.wxEVT_LEAVE_WINDOW, function( event ) frame:SetStatusText( "", 0 ) end )

--// button copy to clipboard
local btn_clip_2 = wx.wxButton( tab_2, wx.wxID_ANY, "Copy", wx.wxPoint( 600, 200 ), wx.wxSize( 40, 25 ) )
btn_clip_2:SetBackgroundColour( wx.wxColour( 225, 225, 225 ) )
btn_clip_2:Disable()

--// Certificate source file
control = wx.wxStaticBox( tab_2, wx.wxID_ANY, "Certificate source file:", wx.wxPoint( 5, 13 ), wx.wxSize( 777, 50 ) )
control:SetFont( font_cert )
local filepicker_certpath2 = wx.wxTextCtrl( tab_2, ID_FILEPICKER_PATH, "", wx.wxPoint( 20, 31 ), wx.wxSize( 670, 21 ), wx.wxTE_READONLY + wx.wxSUNKEN_BORDER )
filepicker_certpath2:SetBackgroundColour( wx.wxColour( 245, 245, 245 ) )
filepicker_certpath2:SetForegroundColour( wx.wxRED )
filepicker_certpath2:SetFont( font_log )
filepicker_certpath2:Connect( wx.wxEVT_ENTER_WINDOW, function( event ) frame:SetStatusText( "Status: READ ONLY", 0 ) end )
filepicker_certpath2:Connect( wx.wxEVT_LEAVE_WINDOW, function( event ) frame:SetStatusText( "", 0 ) end )

--// button copy to clipboard - event
btn_clip_2:Connect( wx.wxEVT_ENTER_WINDOW, function( event ) frame:SetStatusText( "Copy keyprint to clipboard", 0 ) end )
btn_clip_2:Connect( wx.wxEVT_LEAVE_WINDOW, function( event ) frame:SetStatusText( "", 0 ) end )
btn_clip_2:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        clipBoard = wx.wxClipboard.Get()
        if clipBoard and clipBoard:Open() then
            clipBoard:SetData( wx.wxTextDataObject( keyp_textctrl_2:GetValue() ) )
            clipBoard:Close()
        end
        certinfo_4:SetValue( "" )
        certinfo_5:SetValue( "" )
        certinfo_6:SetValue( "" )
        certinfo_8:SetValue( "" )
        keyp_textctrl_2:SetValue( "" )
        filepicker_certpath2:SetValue( "" )
        btn_clip_2:Disable()

        log_broadcast( log_window, "Keyprint added to ClipBoard", "WHITE" )
        log_write( "Keyprint added to ClipBoard" )
    end
)

--// filepicker
local filepicker_cert2 = wx.wxFilePickerCtrl(
    tab_2,
    ID_FILEPICKER,
    wx.wxGetCwd(),
    wx.wxFileSelectorPromptStr,
    "servercert.pem", --wx.wxFileSelectorDefaultWildcardStr,
    wx.wxPoint( 698, 30 ),
    wx.wxSize( 80, 25 ),
    wx.wxFLP_DEFAULT_STYLE - wx.wxFLP_USE_TEXTCTRL,--wx.wxFLP_OPEN + wx.wxFLP_FILE_MUST_EXIST
    wx.wxDefaultValidator, "test"
)
--// filepicker - event
filepicker_cert2:Connect( wx.wxEVT_ENTER_WINDOW, function( event ) frame:SetStatusText( "Choose certificate source file", 0 ) end )
filepicker_cert2:Connect( wx.wxEVT_LEAVE_WINDOW, function( event ) frame:SetStatusText( "", 0 ) end )
filepicker_cert2:Connect( ID_FILEPICKER, wx.wxEVT_COMMAND_FILEPICKER_CHANGED,
    function( event )
        local path = filepicker_cert2:GetPath()
        local tbl_issuer, tbl_subject, tbl_dates, keyp_hex, keyp_base32, err = show_certinfo( path )

        certinfo_4:SetValue( "" )
        certinfo_5:SetValue( "" )
        certinfo_6:SetValue( "" )
        certinfo_8:SetValue( "" )
        keyp_textctrl_2:SetValue( "" )

        local progressDialog = wx.wxProgressDialog(
            "Generating keyprint, please wait...",
            "",
            6,
            wx.NULL,
            wx.wxPD_AUTO_HIDE + wx.wxPD_APP_MODAL + wx.wxPD_SMOOTH
        )
        progressDialog:SetSize( wx.wxSize( 600, 120 ) )
        progressDialog:Centre( wx.wxBOTH )
        progressDialog:SetFocus()

        wx.wxBeginBusyCursor()
        statusBar_txt_red:Show( true ); statusBar_txt_green:Show( false )

        log_broadcast( log_window, "Generating keyprint, please wait...", "GREEN" )
        log_write( "Generating keyprint, please wait..." )
        progressDialog:Update( 1, "Generating keyprint, please wait..." )
        wx.wxSleep( 1 )

        log_broadcast( log_window, "Parsing data from file...", "GREEN" )
        log_write( "Parsing data from file..." )
        progressDialog:Update( 2, "Parsing data from file..." )
        wx.wxSleep( 2 )

        if err then
            filepicker_certpath2:SetValue( "" )

            log_broadcast( log_window, "Error can not parse data from file, file is not valid.", "RED" )
            log_write( "Error can not parse data from file, file is not valid." )
            progressDialog:Update( 3, "Error can not parse data from file, file is not valid." )
            wx.wxSleep( 2 )

            progressDialog:Destroy()

            wx.wxMessageBox( "Error can not parse data from file, file is not valid.", "Parsing fingerprint...", wx.wxOK + wx.wxICON_INFORMATION, frame )
        else
            filepicker_certpath2:SetValue( path )

            log_broadcast( log_window, "Using file: '" .. path .. "'", "CYAN" )
            log_write( "Using file: '" .. path .. "'" )
            progressDialog:Update( 3, "Using file: '" .. path .. "" )
            wx.wxSleep( 2 )

            log_broadcast( log_window, "Parsing fingerprint...", "GREEN" )
            log_write( "Parsing fingerprint..." )
            progressDialog:Update( 4, "Parsing fingerprint..." )
            wx.wxSleep( 2 )
            local CN = tbl_issuer[ "CN" ] or ""
            local CN2 = tbl_subject[ "CN2" ] or ""
            local notBefore = tbl_dates[ "notBefore" ] or ""
            local notAfter = tbl_dates[ "notAfter" ] or ""

            log_broadcast( log_window, "Import informations...", "GREEN" )
            log_write( "Import informations..." )
            progressDialog:Update( 5, "Import informations..." )
            wx.wxSleep( 2 )
            certinfo_4:SetValue( CN )
            certinfo_8:SetValue( CN2 )
            certinfo_5:SetValue( notBefore )
            certinfo_6:SetValue( notAfter )
            keyp_textctrl_2:SetValue( keyp_base32 )

            log_broadcast( log_window, "SHA256 keyprint as HEX: " .. keyp_hex, "WHITE" )
            log_write( "SHA256 keyprint as HEX: " .. keyp_hex )
            log_broadcast( log_window, "SHA256 keyprint as BASE32: " .. keyp_base32, "WHITE" )
            log_write( "SHA256 keyprint as BASE32: " .. keyp_base32 )
            log_broadcast( log_window, "Import keyprint...", "GREEN" )
            log_write( "Import keyprint..." )

            progressDialog:Update( 6, "Creating keyprint file..." )
            log_broadcast( log_window, "Creating keyprint file...", "GREEN" )
            log_write( "Creating keyprint file..." )

            local des_path = path:gsub( "\servercert.pem", "" )
            local f = wx.wxFile( des_path .. "\\keyprint.txt", wx.wxFile.write )
            f:Write( keyp_base32 )
            f:Flush()
            f:Close()

            log_broadcast( log_window, "Done.", "WHITE" )
            log_write( "Done." )
            progressDialog:Update( 7, "Done." )
            wx.wxSleep( 2 )
        end

        log_broadcast( log_window, app_name .. " " .. app_version .. " " .. msg_ready, "ORANGE" )
        log_write( app_name .. " " .. app_version .. " " .. msg_ready )
        statusBar_txt_green:Show( true ); statusBar_txt_red:Show( false )

        progressDialog:Destroy()
        wx.wxEndBusyCursor()

        wx.wxMessageBox( "Keyprint successfully generated.", "INFO", wx.wxOK + wx.wxICON_INFORMATION, frame )
        btn_clip_2:Enable( true )
    end
)

-------------------------------------------------------------------------------------------------------------------------------------
--// MAIN LOOP //--------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

main = function()
    check_files_exists( file_tbl )
    if exec then
        frame:Connect( wx.wxEVT_CLOSE_WINDOW,
            function( event )
                di = wx.wxMessageDialog( wx.NULL, msg_really_close, msg_warning, wx.wxYES_NO + wx.wxICON_QUESTION + wx.wxCENTRE )
                result = di:ShowModal(); di:Destroy()
                if result == wx.wxID_YES then
                    if event then event:Skip() end
                    if frame then frame:Destroy() end
                    notebook_image_list:delete()
                end
            end
        )
        frame:Connect( wx.wxID_EXIT, wx.wxEVT_COMMAND_MENU_SELECTED,
            function( event )
                frame:Close( true )
            end
        )
        frame:Connect( wx.wxID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED,
            function( event )
                show_about_window( frame )
            end
        )
        frame:Connect( ID_LOGS, wx.wxEVT_COMMAND_MENU_SELECTED,
            function( event )
                show_log_window( frame )
            end
        )
        frame:Show( true )
        log_broadcast( log_window, app_name .. " " .. app_version .. " " .. msg_ready, "ORANGE" )
    else
        -- kill frame
        if event then event:Skip() end
        if frame then frame:Destroy() end
    end
end

main(); wx.wxGetApp():MainLoop()